# Pain Recognition Model PyTorch Lite Migration

## Summary
Successfully migrated the pain recognition model from ONNX Runtime to PyTorch Mobile (`.ptl` format) to align with the pose estimation model architecture.

## Changes Made

### 1. Conversion Script
- **File:** `assets/model/export_pain_to_ptl.py`
- **Purpose:** Converts `pain_recognition_model.pth` to `.ptl` format using PyTorch Mobile optimization
- **Status:** Script created and ready to use

### 2. Service Integration
- **File:** `lib/data/facial_pain_recognition_service.dart`
- **Changes:**
  - Switched from ONNX Runtime (`com.pocketpt/onnxruntime-pain`) to PyTorch Mobile (`com.pocketpt/pytorch`)
  - Updated model asset name from `pain_recognition_model.onnx` to `pain_recognition_model.ptl`
  - Renamed preprocessing method from `_preprocessImageForOnnx()` to `_preprocessImageForPyTorch()`
  - Updated inference method from `_runOnnxInference()` to `_runPyTorchInference()`
  - Added deprecated getters (`isOnnxReady`, `isOnnxEnabled`) for backward compatibility
  - Updated all initialization and verification methods

### 3. Assets Configuration
- **File:** `pubspec.yaml`
- **Status:** `assets/model/` directory already included, no changes needed
- **Note:** The `.ptl` file will be automatically included once placed in `assets/model/`

## Next Steps (Manual)

### 1. Convert Model to .ptl Format
```bash
cd assets/model
python export_pain_to_ptl.py
```
This will create `pain_recognition_model.ptl` in the `assets/model/` directory.

### 2. Verify Model Conversion
- Run test inference on sample images to verify outputs match original `.pth` model
- Ensure the model file is in the correct location: `assets/model/pain_recognition_model.ptl`

### 3. Testing
- Test model loading and initialization on Android device
- Verify inference outputs match expected format (3-class probabilities)
- Test real-time inference from camera feed
- Compare results with previous ONNX Runtime version if available

## Technical Details

### Model Specifications
- **Input:** 224x224 RGB images
- **Output:** 3 classes (Low, Moderate, Severe)
- **Normalization:** ImageNet mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]
- **Format:** PyTorch Lite (`.ptl`) optimized for mobile

### Backward Compatibility
- Deprecated getters `isOnnxReady` and `isOnnxEnabled` are maintained for compatibility
- Existing code using these getters will continue to work
- These should be migrated to `isPyTorchReady` and `isPyTorchEnabled` in future updates

### Method Channel
- Uses existing `com.pocketpt/pytorch` channel (same as pose estimation model)
- No changes needed to `MainActivity.kt` as it already supports PyTorch Mobile

## Files Modified
1. `lib/data/facial_pain_recognition_service.dart` - Complete migration to PyTorch Mobile
2. `assets/model/export_pain_to_ptl.py` - New conversion script
3. `openspec/changes/integrate-pain-model-pytorch-lite/` - Proposal and tasks

## Files Requiring Manual Action
1. `assets/model/pain_recognition_model.ptl` - Needs to be generated using the conversion script




