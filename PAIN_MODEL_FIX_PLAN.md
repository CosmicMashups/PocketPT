# Pain Model Fix Plan

## Issues Identified

### Issue 1: Model Always Returns "5.0 Moderate"
**Possible Causes:**
1. Model output logits are always the same (model not actually running or input preprocessing issue)
2. Softmax calculation issue causing always same probabilities
3. Model stuck in a state where it always predicts Moderate class
4. Input preprocessing always produces same normalized values
5. Model file issue or incorrect model loading

**Investigation Steps:**
- Check if model logits are varying in debug logs
- Verify softmax calculation is correct
- Check if input preprocessing is producing varying inputs
- Verify model file is correct and loaded properly

**Fixes:**
1. Add more detailed logging for model input/output
2. Verify softmax calculation
3. Check input preprocessing normalization
4. Add validation to detect if model output is stuck

### Issue 2: AROM Assessment Should Be Used Instead of Facial Recognition
**Current State:**
- `_proceedToPainLevelInput` already checks for `_currentAssessmentResult` and uses AROM values
- But `romPainLevel` in dialog might fall back to facial recognition
- Need to ensure AROM is always preferred when available

**Fixes:**
1. Ensure `_proceedToPainLevelInput` always uses AROM when `_currentAssessmentResult` is available
2. Remove fallback to facial recognition when AROM is available
3. Update dialog to always show AROM values when available
4. Ensure `c_painlevel.dart` receives AROM values from `UserAssess.painScale` and `AssessmentData.painScale`




