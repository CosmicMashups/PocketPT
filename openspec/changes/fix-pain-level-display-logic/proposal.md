## Why

The pain level display in the top-right corner of both `c_camera.dart` and `cameraPose.dart` always shows "2/10 Pain Level" regardless of facial expressions or model output. This indicates:

1. **Hardcoded fallback value**: The `_mapFacialPainScore()` function returns 2 for 'Low' pain or null, and `_currentPainLevel` is likely always null or 'Low'
2. **Model not updating**: The facial pain recognition model output is not properly updating `_currentPainLevel` in the UI
3. **Missing model integration**: The PyTorch model file `pain_recognition_model.pth` exists but may not be properly converted/loaded for mobile deployment

This prevents users from seeing real-time pain level feedback, which is critical for assessment accuracy and user trust in the system.

## What Changes

- **MODIFIED**: Fix pain level display to use actual model output instead of hardcoded values
  - Ensure `_currentPainLevel` is updated from model inference results
  - Replace hardcoded "2" fallback with proper model output or AROM assessment result
  - Use AROM assessment `painScore` as fallback when facial recognition is unavailable
  - Add validation to ensure pain level updates reflect model changes

- **MODIFIED**: Verify and fix facial pain recognition model integration
  - Ensure model inference is actually running and producing outputs
  - Verify model output is correctly parsed and mapped to pain levels
  - Add diagnostic logging to track model execution and output values
  - Fix any issues preventing model output from reaching the UI

- **ADDED**: Integrate PyTorch model file (`pain_recognition_model.pth`)
  - Convert PyTorch model to mobile-compatible format (ONNX or TorchScript)
  - Follow pose estimation model integration pattern for consistency
  - Ensure model loads correctly on Android
  - Verify model produces varying outputs based on input

- **MODIFIED**: Improve pain level mapping logic
  - Replace static `_mapFacialPainScore()` with dynamic calculation based on model confidence
  - Use AROM assessment `painScore` when available as more accurate source
  - Combine facial recognition and AROM assessment for comprehensive pain level

## Impact

- **Affected specs**: `pain-recognition` (existing capability)
- **Affected code**:
  - `lib/assessment/c_camera.dart` - Pain level display logic
  - `lib/dailyAssessment/cameraPose.dart` - Pain level display logic
  - `lib/data/facial_pain_recognition_service.dart` - Model integration and output handling
  - `assets/model/pain_recognition_model.pth` - Source PyTorch model (needs conversion)
  - `assets/model/export_pain_to_onnx.py` - Model export script (may need updates)
  - `android/app/src/main/kotlin/com/example/pocketpt/MainActivity.kt` - Native method channel (if using PyTorch Mobile)





