# Pain Recognition Model Integration Guide

## Overview

This document provides a comprehensive review and integration guide for implementing the newly trained `pain_detection_model.pth` in the Flutter application. The model uses a 3-class pain recognition system (Low/Moderate/Severe) based on PSPI (Prkachin and Solomon Pain Intensity) scores.

## Model Analysis

### Model Architecture
- **Base Model**: MobileNetV3-Small
- **Input Size**: 224x224 pixels
- **Classes**: 3 (Low, Moderate, Severe pain)
- **Training Framework**: PyTorch
- **Model File**: `assets/model/pain_detection_model.pth` (5.9MB)

### Key Features from Training Code (`pain_train.py`)

#### 1. **Class Thresholds**
```python
# PSPI-based thresholds for pain classification
t1, t2 = compute_class_thresholds(pspi_values)
# Typical thresholds: Low ≤ 1, Moderate ≤ 3, Severe > 3
```

#### 2. **Data Augmentation**
- Low-resolution augmentation (probability: 0.5)
- Gaussian blur augmentation (probability: 0.3)
- Distance-robust evaluation transforms

#### 3. **Face Detection Integration**
- Haar cascade face detection
- Face cropping with margin (default: 15%)
- Minimum face size filtering (default: 96px)
- Face tracking with exponential smoothing

#### 4. **Model Metadata**
The saved model includes comprehensive metadata:
```python
{
    "state_dict": model_weights,
    "class_names": ["Low", "Moderate", "Severe"],
    "thresholds": (t1, t2),
    "image_size": 224,
    "normalize_mean": [0.485, 0.456, 0.406],
    "normalize_std": [0.229, 0.224, 0.225],
    "face_crop_enabled": True,
    "min_face_size": 96,
    "face_margin": 0.15,
    "low_res_aug_p": 0.5,
    "blur_aug_p": 0.3
}
```

## Current Flutter Implementation Analysis

### Existing Implementation (`facial_pain_recognition_service.dart`)
- **Current Status**: Simulation mode only
- **Classes**: 2-class system (Pained/Not Pained)
- **Issues**: 
  - PyTorch integration disabled
  - No real model inference
  - Limited to binary classification

### Integration Points
1. **Camera Assessment**: `lib/demo/cameraPosePain.dart`
2. **ROM Assessment**: Various assessment modes
3. **Pain History**: `PainHistory.recordTodayAndSave()`

## Implementation Requirements

### 1. **Dependencies**
```yaml
dependencies:
  flutter_pytorch_lite: ^0.1.0  # For PyTorch model loading
  camera: ^0.10.5+5
  image: ^4.0.17
  opencv_dart: ^0.8.0  # For face detection
```

### 2. **Model Integration Architecture**

#### A. **Model Loading Service**
```dart
class PainRecognitionModelService {
  static const String MODEL_PATH = 'assets/model/pain_detection_model.pth';
  static const int INPUT_SIZE = 224;
  
  Module? _model;
  Map<String, dynamic>? _metadata;
  bool _isLoaded = false;
  
  Future<void> loadModel() async {
    _model = await FlutterPytorchLite.load(MODEL_PATH);
    _metadata = await _loadModelMetadata();
    _isLoaded = true;
  }
}
```

#### B. **Face Detection Integration**
```dart
class FaceDetectionService {
  late cv2.CascadeClassifier _faceCascade;
  
  Future<void> initialize() async {
    _faceCascade = cv2.CascadeClassifier(
      cv2.data.haarcascades + 'haarcascade_frontalface_default.xml'
    );
  }
  
  List<Rect> detectFaces(Image image) {
    // Multi-scale face detection implementation
    // Based on pain_test.py detect_faces_multiscale()
  }
}
```

#### C. **Pain Recognition Pipeline**
```dart
class PainRecognitionPipeline {
  Future<PainRecognitionResult> processFrame(CameraImage image) async {
    // 1. Convert camera image to processable format
    // 2. Detect faces using Haar cascade
    // 3. Crop face with margin
    // 4. Resize to 224x224
    // 5. Normalize using model metadata
    // 6. Run inference
    // 7. Return 3-class prediction with confidence
  }
}
```

### 3. **Data Flow Integration**

#### A. **Camera Assessment Integration**
```dart
// In cameraPosePain.dart
Future<void> _processFacialPainRecognition() async {
  final painService = PainRecognitionModelService();
  final result = await painService.recognizePain(_cameraImage);
  
  if (result != null) {
    setState(() {
      _facialPainLevel = result.painLevel;
      _facialPainConfidence = result.confidence;
      _overallPainScore = _combinePainScores(_posePainScore, result.painScore);
    });
  }
}
```

#### B. **Pain Score Mapping**
```dart
class PainScoreMapper {
  static int mapPainLevelToScore(String painLevel, double confidence) {
    switch (painLevel) {
      case 'Low':
        return (confidence > 0.7) ? 2 : 1;
      case 'Moderate':
        return (confidence > 0.7) ? 5 : 4;
      case 'Severe':
        return (confidence > 0.7) ? 8 : 7;
      default:
        return 1;
    }
  }
}
```

## Implementation Steps

### Phase 1: Model Integration
1. **Add PyTorch Dependencies**
   ```yaml
   dependencies:
     flutter_pytorch_lite: ^0.1.0
   ```

2. **Create Model Service**
   - Implement `PainRecognitionModelService`
   - Add model loading and metadata parsing
   - Implement inference pipeline

3. **Face Detection Integration**
   - Add OpenCV dependency
   - Implement multi-scale face detection
   - Add face tracking with smoothing

### Phase 2: Camera Integration
1. **Update Camera Assessment**
   - Integrate with existing `cameraPosePain.dart`
   - Add real-time pain recognition
   - Implement confidence-based filtering

2. **Pain Score Integration**
   - Map 3-class predictions to pain scores
   - Combine with pose-based assessments
   - Update pain history recording

### Phase 3: UI/UX Updates
1. **Visual Feedback**
   - Add pain level indicators
   - Show confidence levels
   - Implement color-coded feedback

2. **Assessment Flow**
   - Update assessment screens
   - Add facial pain recognition options
   - Integrate with existing ROM assessments

## Technical Considerations

### 1. **Performance Optimization**
- **Model Size**: 5.9MB (acceptable for mobile)
- **Inference Speed**: Target <100ms per frame
- **Memory Usage**: Monitor GPU/CPU usage
- **Battery Impact**: Implement frame rate limiting

### 2. **Accuracy Considerations**
- **Confidence Thresholds**: Minimum 0.7 for reliable predictions
- **Face Detection**: Ensure good face visibility
- **Lighting Conditions**: Handle various lighting scenarios
- **Distance Robustness**: Support different camera distances

### 3. **Error Handling**
```dart
class PainRecognitionError {
  static const String NO_FACE_DETECTED = 'NO_FACE_DETECTED';
  static const String MODEL_NOT_LOADED = 'MODEL_NOT_LOADED';
  static const String INFERENCE_FAILED = 'INFERENCE_FAILED';
  static const String LOW_CONFIDENCE = 'LOW_CONFIDENCE';
}
```

### 4. **Testing Strategy**
- **Unit Tests**: Model loading and inference
- **Integration Tests**: Camera pipeline
- **Performance Tests**: Frame rate and memory usage
- **Accuracy Tests**: Validation against ground truth

## Migration Plan

### Current State → New Implementation

1. **Phase 1**: Add new model service alongside existing simulation
2. **Phase 2**: Implement face detection and preprocessing
3. **Phase 3**: Integrate with camera assessment pipeline
4. **Phase 4**: Update UI components and user experience
5. **Phase 5**: Remove simulation mode and finalize

### Backward Compatibility
- Maintain existing API interfaces
- Add feature flags for gradual rollout
- Implement fallback to simulation mode
- Preserve existing pain history data

## Configuration Options

### Model Parameters
```dart
class PainRecognitionConfig {
  static const int MIN_FACE_SIZE = 96;
  static const double FACE_MARGIN = 0.15;
  static const double MIN_CONFIDENCE = 0.7;
  static const int MAX_FPS = 10; // Limit inference rate
  static const bool ENABLE_FACE_TRACKING = true;
}
```

### Assessment Integration
```dart
class AssessmentConfig {
  static const bool ENABLE_FACIAL_PAIN = true;
  static const double FACIAL_PAIN_WEIGHT = 0.3; // Weight in combined score
  static const bool REQUIRE_FACE_DETECTION = true;
}
```

## Expected Outcomes

### 1. **Improved Accuracy**
- 3-class pain recognition vs. binary
- PSPI-based thresholds for medical relevance
- Face detection for better feature extraction

### 2. **Enhanced User Experience**
- Real-time pain level feedback
- Visual confidence indicators
- Seamless integration with existing assessments

### 3. **Clinical Relevance**
- Standardized pain classification
- Research-grade accuracy
- Integration with medical workflows

## Next Steps

1. **Review and approve implementation plan**
2. **Set up development environment with dependencies**
3. **Implement model service and face detection**
4. **Integrate with camera assessment pipeline**
5. **Test and validate accuracy**
6. **Deploy and monitor performance**

This comprehensive guide provides the foundation for successfully integrating the new pain recognition model into the Flutter application while maintaining compatibility with existing systems and improving overall assessment accuracy.
