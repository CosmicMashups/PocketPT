## Why
The pain recognition model (`pain_recognition_model.pth`) currently uses ONNX Runtime integration, but to align with the pose estimation model architecture and leverage PyTorch Mobile's optimized inference, we need to convert it to PyTorch Lite (`.ptl`) format and integrate it using the same method channel pattern as pose estimation. This will ensure consistent model deployment architecture across all ML models in the app.

## What Changes
- Convert `pain_recognition_model.pth` to `.ptl` format using PyTorch Mobile optimization
- Update `FacialPainRecognitionService` to use PyTorch Mobile instead of ONNX Runtime
- Reuse the existing `com.pocketpt/pytorch` method channel (already set up in MainActivity.kt)
- Ensure preprocessing (224x224, ImageNet normalization) matches training code from `pain_train.py`
- Maintain backward compatibility during transition to avoid breaking existing functionality
- Add proper error handling and fallback mechanisms for inference failures

## Impact
- **Affected specs:** `pain-recognition` (new capability to be created)
- **Affected code:** 
  - `lib/data/facial_pain_recognition_service.dart` - Switch from ONNX to PyTorch Mobile
  - `assets/model/pain_recognition_model.pth` - Convert to `.ptl` format
  - `pubspec.yaml` - Add new model asset
  - `assets/model/export_pain_to_ptl.py` - New conversion script (optional)
- **Dependencies:** PyTorch Mobile (already integrated via pose model), existing method channel infrastructure




