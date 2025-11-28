# Pain Model and AROM Assessment Fixes

## Issues Fixed

### Issue 1: Model Always Returns "5.0 Moderate"

**Root Causes Identified:**
1. Model output logits might be identical (model stuck or input preprocessing issue)
2. Softmax calculation might be producing same probabilities
3. No validation to detect if model output is stuck

**Fixes Implemented:**

1. **Added Model Output Validation** (`lib/data/facial_pain_recognition_service.dart`):
   - Added check to detect if all logits are identical (within 0.001)
   - Added check to detect if all probabilities are identical
   - Added warning logs when model output appears stuck

2. **Enhanced Input Preprocessing Logging**:
   - Added logging of preprocessed input samples (start, mid, end)
   - This helps verify that input is actually varying between frames
   - Logs show normalized pixel values to detect preprocessing issues

3. **Enhanced Model Output Logging**:
   - More detailed logging of logits before softmax
   - More detailed logging of probabilities after softmax
   - Warnings when output appears stuck

**How to Diagnose:**
- Check logs for "WARNING - All logits are nearly identical!" - indicates model output is stuck
- Check logs for "WARNING - All probabilities are nearly identical!" - indicates softmax issue or stuck model
- Check preprocessed input samples - should vary between frames
- Check logits values - should vary between frames

### Issue 2: AROM Assessment Should Be Used Instead of Facial Recognition

**Root Causes Identified:**
1. `_proceedToPainLevelInput` had fallback logic that could use facial recognition even when AROM was available
2. `c_painlevel.dart` was only using `UserAssess.painScale` instead of checking `AssessmentData.painScale` (from AROM)
3. Dialog navigation could bypass AROM values

**Fixes Implemented:**

1. **Fixed `_proceedToPainLevelInput` in `c_camera.dart`**:
   - Changed to ALWAYS use AROM assessment result when `_currentAssessmentResult` is available
   - Removed conditional check - AROM is now always preferred
   - Added detailed logging to show which source is being used
   - Even for "Manual" input, AROM values are preserved as starting point

2. **Fixed `c_painlevel.dart` initialization**:
   - Changed to prefer `AssessmentData.painScale` (from AROM) over `UserAssess.painScale`
   - Added logging to show which values are being used
   - Ensures AROM assessment values are displayed when navigating to pain level page

3. **Fixed Dialog Navigation**:
   - Dialog now always uses AROM values when available
   - `romPainLevel` is already calculated from `_currentAssessmentResult` when available
   - Navigation properly passes AROM values to `_proceedToPainLevelInput`

**Data Flow:**
1. AROM assessment runs in `c_camera.dart` and sets `_currentAssessmentResult`
2. `_currentAssessmentResult` is used to update both `UserAssess` and `AssessmentData`
3. When navigating to `c_painlevel.dart`, `AssessmentData.painScale` (from AROM) is preferred
4. `_proceedToPainLevelInput` always uses `_currentAssessmentResult` when available

## Files Modified

1. **`lib/data/facial_pain_recognition_service.dart`**:
   - Added model output validation (detect stuck logits/probabilities)
   - Added input preprocessing sample logging
   - Enhanced diagnostic logging

2. **`lib/assessment/c_camera.dart`**:
   - Fixed `_proceedToPainLevelInput` to always prefer AROM assessment
   - Added detailed logging for AROM value usage
   - Fixed dialog navigation to use AROM values

3. **`lib/assessment/c_painlevel.dart`**:
   - Changed initialization to prefer `AssessmentData.painScale` (from AROM)
   - Added logging to show which values are being used

## Expected Behavior

### For Model Output:
- Logs will show warnings if model output is stuck
- Preprocessed input samples will show if input is varying
- Logits and probabilities will be logged for each inference

### For AROM Assessment:
- AROM assessment values are always used when available
- `c_painlevel.dart` will show AROM assessment values when navigating from camera
- Facial recognition is only used as fallback when AROM is not available
- Manual input preserves AROM values as starting point

## Testing Recommendations

1. **Test Model Output Variation**:
   - Check logs for model output warnings
   - Verify logits and probabilities vary between frames
   - Verify preprocessed input samples vary

2. **Test AROM Assessment Integration**:
   - Perform AROM assessment in camera
   - Navigate to pain level page
   - Verify pain level matches AROM assessment result
   - Check logs to confirm AROM values are being used

3. **Test Fallback Behavior**:
   - Test when AROM assessment is not available
   - Verify facial recognition fallback works
   - Verify manual input works correctly




