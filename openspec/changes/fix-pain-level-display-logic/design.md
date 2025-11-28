## Context

The pain level display shows a hardcoded "2/10" value because:
1. `_currentPainLevel` from facial pain recognition is always null or 'Low'
2. `_mapFacialPainScore()` returns 2 for 'Low' or null values
3. The facial pain recognition model may not be running or updating properly
4. There's a PyTorch model file (`pain_recognition_model.pth`) that may need proper mobile conversion

The AROM assessment system already provides accurate `painScore` values (0-10) from pose detection, which could be used as a more reliable source.

## Goals / Non-Goals

### Goals
- Fix pain level display to show actual model output instead of hardcoded "2/10"
- Ensure facial pain recognition model runs and updates `_currentPainLevel`
- Integrate PyTorch model file if needed for mobile deployment
- Use AROM assessment painScore as fallback when facial recognition unavailable

### Non-Goals
- Retraining the model (use existing `pain_recognition_model.pth`)
- Changing the model architecture
- Removing facial pain recognition (keep it, just fix the integration)

## Decisions

### Decision: Use AROM Assessment as Primary Source with Facial Recognition as Secondary
- **Rationale**: AROM assessment provides accurate 0-10 pain scores from pose detection, which is more reliable than categorical facial recognition
- **Implementation**: Display AROM `painScore` when available, use facial recognition as supplementary indicator
- **Fallback**: If AROM not available, use facial recognition; if both fail, show "N/A" instead of hardcoded "2"

### Decision: Fix Facial Recognition Integration First
- **Rationale**: Facial recognition should work independently and provide real-time updates
- **Implementation**: 
  - Verify model is running and producing outputs
  - Ensure `_currentPainLevel` updates from model results
  - Add logging to track model execution
- **Verification**: Check logs show model inference running and `_currentPainLevel` changing

### Decision: Convert PyTorch Model to ONNX (not TorchScript)
- **Rationale**: ONNX Runtime is already set up for pain detection, consistent with current architecture
- **Implementation**: Use existing `export_pain_to_onnx.py` script or create new one if needed
- **Verification**: Ensure exported model loads and runs on Android

### Decision: Improve Pain Level Mapping
- **Rationale**: Static mapping (Low=2, Moderate=5, Severe=8) doesn't reflect model confidence
- **Implementation**: 
  - Use model confidence to interpolate pain scale values
  - Or use AROM assessment painScore directly (more accurate)
  - Remove hardcoded "2" fallback
- **Verification**: Pain level changes reflect actual model/assessment output

## Risks / Trade-offs

### Risk: Model File May Not Exist or Be Corrupted
- **Mitigation**: Check if `pain_recognition_model.pth` exists, verify it's the correct model
- **Detection**: Log model loading errors, verify file size matches expected

### Risk: ONNX Export May Fail
- **Mitigation**: Test export script, verify exported model format
- **Detection**: Check export logs, validate ONNX model structure

### Risk: Model Output Not Reaching UI
- **Mitigation**: Add comprehensive logging, verify state updates trigger UI rebuilds
- **Detection**: Check logs for model inference, verify `setState()` calls

### Risk: AROM Assessment May Not Be Available
- **Mitigation**: Use AROM as primary but keep facial recognition as fallback
- **Detection**: Check if `_currentAssessmentResult` is null

## Migration Plan

1. **Phase 1**: Search for hardcoded values and verify current state
2. **Phase 2**: Fix facial recognition model integration
3. **Phase 3**: Convert/verify PyTorch model for mobile
4. **Phase 4**: Update pain level display logic
5. **Phase 5**: Test with real camera input
6. **Phase 6**: Documentation

## Open Questions

- Is `pain_recognition_model.pth` the correct model file to use?
- Should we use PyTorch Mobile (like pose) or ONNX Runtime (current)?
- Should pain level display use AROM assessment or facial recognition as primary?
- What is the expected behavior when both assessments are available?





