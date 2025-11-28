## Why

The pain recognition model integration in both `c_camera.dart` and `cameraPose.dart` is not functioning properly. The pain level and scale values do not change over time, indicating that either:
1. The model is not being invoked correctly
2. The model output is not being parsed correctly
3. The model is falling back to simulation mode with static values
4. There are mismatches between training and inference preprocessing/postprocessing

This prevents users from receiving real-time pain level feedback during assessments, which is a core feature of the application.

## What Changes

- **MODIFIED**: Fix pain recognition model integration to ensure real-time updates
  - Verify and fix ONNX model export from PyTorch training script
  - Align input preprocessing (normalization, channel ordering) with training code
  - Fix output parsing to correctly extract logits and apply softmax
  - Ensure method channel communication is working correctly
  - Fix frame rate limiting that may prevent updates
  - Add comprehensive error handling and logging
  - Verify model file format and compatibility

- **MODIFIED**: Align pain recognition service with pose estimation integration patterns
  - Use similar initialization and error handling patterns
  - Implement proper model verification on startup
  - Add diagnostic logging similar to pose detection

- **ADDED**: Create model export script for pain recognition
  - Export PyTorch model to ONNX format matching training architecture
  - Verify export produces correct input/output shapes
  - Document export process and requirements

## Impact

- **Affected specs**: `pain-recognition` (new capability)
- **Affected code**:
  - `lib/data/facial_pain_recognition_service.dart` - Core service implementation
  - `lib/assessment/c_camera.dart` - Assessment camera integration
  - `lib/dailyAssessment/cameraPose.dart` - Daily assessment integration
  - `android/app/src/main/kotlin/com/example/pocketpt/MainActivity.kt` - Native method channel
  - `assets/model/pain_train.py` - Training script reference
  - `assets/model/pain_test.py` - Testing script reference
  - New: `assets/model/export_pain_to_onnx.py` - Model export script





