# CNN Model Integration Guide

This guide explains how to integrate the trained CNN model (`cnn_best.pt`) with the Flutter app for pose-based pain assessment.

## Files Created

### 1. CNN Pose Detection Service (`lib/data/cnn_pose_detection_service.dart`)
- **Purpose**: Handles CNN-based pose detection and pain assessment
- **Key Features**:
  - Image preprocessing for CNN input (224x224 RGB)
  - Simulated CNN inference (placeholder for actual model integration)
  - Pain classification (Pained/Not Pained)
  - Confidence scoring
  - Standardized assessment format

### 2. CNN Camera Page (`lib/assessment/cnn_camera.dart`)
- **Purpose**: Camera interface using CNN model instead of Google ML Kit
- **Key Features**:
  - Real-time CNN assessment during camera streaming
  - Video recording with continuous CNN analysis
  - Pain score visualization
  - Confidence display
  - Side selection (Left/Right)

### 3. CNN Demo Page (`lib/demo/cnn_poseDemo.dart`)
- **Purpose**: Demo version of CNN-based pose assessment
- **Key Features**:
  - Similar to original poseDemo.dart but using CNN
  - Daily re-assessment workflow
  - Skip and complete functionality

## Model Integration Steps

### Current Implementation
The current implementation uses a **simulated CNN inference** based on image characteristics (brightness, contrast). To integrate the actual `cnn_best.pt` model:

### 1. Add PyTorch Mobile Dependencies
Add to `pubspec.yaml`:
```yaml
dependencies:
  pytorch_lite: ^0.1.0  # For PyTorch model inference
  # or
  tflite_flutter: ^0.10.0  # For TensorFlow Lite
```

### 2. Convert PyTorch Model
Convert `cnn_best.pt` to mobile format:
```bash
# For PyTorch Mobile
python convert_to_mobile.py --model cnn_best.pt --output cnn_mobile.ptl

# For TensorFlow Lite
python convert_to_tflite.py --model cnn_best.pt --output cnn_model.tflite
```

### 3. Update CNN Service
Replace the `_simulatePainDetection` method in `cnn_pose_detection_service.dart`:

```dart
// Real CNN inference (example with PyTorch Mobile)
Future<int> _performRealCNNAssessment(Uint8List imageData) async {
  // Load model
  final model = await PyTorchMobile.loadModel('assets/models/cnn_mobile.ptl');
  
  // Prepare input tensor
  final inputTensor = Tensor.fromBytes(
    imageData,
    [1, 3, 224, 224], // Batch, Channels, Height, Width
    dtype: DType.float32,
  );
  
  // Run inference
  final output = await model.forward([inputTensor]);
  final predictions = output[0].data;
  
  // Get predicted class
  return predictions[0] > predictions[1] ? 0 : 1; // Pained : Not Pained
}
```

### 4. Model Asset Integration
1. Place `cnn_best.pt` in `assets/model/` directory
2. Update `pubspec.yaml`:
```yaml
flutter:
  assets:
    - assets/model/cnn_best.pt
```

## Usage

### Basic Usage
```dart
// Import the CNN service
import '../data/cnn_pose_detection_service.dart';

// Create service instance
final cnnService = CNNPoseDetectionService();

// Perform assessment on camera image
final assessment = await cnnService.performComprehensiveROMAssessment(cameraImage);

// Access results
final painScore = assessment['overallPainScore'];
final confidence = assessment['cnn']['confidence'];
final isPained = assessment['cnn']['isPained'];
```

### Navigation
```dart
// Navigate to CNN camera page
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => CNNAssessPainCamera()),
);

// Navigate to CNN demo page
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => CNNCameraPosePage()),
);
```

## Model Training Reference

The CNN model was trained using the `train_improved.py` script with:
- **Architecture**: ResNet18 (configurable)
- **Input Size**: 224x224 RGB images
- **Classes**: 2 (Pained: 0, Not Pained: 1)
- **Training**: 50 epochs with early stopping
- **Optimization**: Adam optimizer with cosine annealing
- **Data Augmentation**: Standard transforms

## Performance Considerations

1. **Processing Speed**: CNN inference is slower than ML Kit pose detection
2. **Memory Usage**: Model loading requires additional memory
3. **Battery Impact**: Continuous CNN processing may drain battery faster
4. **Accuracy**: CNN provides pain classification vs. pose landmark detection

## Future Enhancements

1. **Model Optimization**: Quantization for mobile deployment
2. **Edge Cases**: Handle low confidence predictions
3. **Batch Processing**: Process multiple frames for better accuracy
4. **Model Updates**: OTA model updates without app updates
5. **Privacy**: On-device processing without cloud dependencies

## Testing

Test the CNN integration:
1. Run the app with CNN camera page
2. Verify pain score updates in real-time
3. Check confidence scores are reasonable
4. Test video recording with CNN assessment
5. Validate pain level persistence

## Troubleshooting

### Common Issues
1. **Model Loading**: Ensure model file is in correct assets directory
2. **Memory**: Monitor memory usage during continuous inference
3. **Performance**: Adjust processing frequency if UI becomes sluggish
4. **Accuracy**: Fine-tune confidence thresholds based on validation data

### Debug Mode
Enable debug logging in `cnn_pose_detection_service.dart`:
```dart
static const bool DEBUG_MODE = true;

if (DEBUG_MODE) {
  debugPrint('CNN Prediction: $painClass, Confidence: $confidence');
}
```





