## Context
The pain recognition model is currently deployed using ONNX Runtime through a separate method channel (`com.pocketpt/onnxruntime-pain`). However, the pose estimation model uses PyTorch Mobile (`.ptl` format) via the `com.pocketpt/pytorch` method channel. For consistency and to leverage PyTorch Mobile's optimizations, we should migrate the pain recognition model to the same deployment pattern.

The pain recognition model is trained using `pain_train.py` with:
- Architecture: ResNet18 (configurable, but ResNet18 is the default)
- Input: 224x224 RGB images
- Classes: 3 (Low, Moderate, Severe)
- Normalization: ImageNet mean/std (mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
- Output: Logits for 3 classes (softmax applied post-inference)

## Goals
- Migrate pain recognition model from ONNX Runtime to PyTorch Mobile
- Reuse existing PyTorch Mobile infrastructure (method channel already set up)
- Maintain inference accuracy and performance
- Ensure preprocessing matches training code exactly
- Provide clear error handling and fallback mechanisms

## Non-Goals
- Changing the model architecture or training pipeline
- Supporting multiple model formats simultaneously (eventual deprecation of ONNX path)
- Modifying the existing PyTorch Mobile method channel (already working for pose)

## Decisions

### Decision: Use PyTorch Mobile for Pain Recognition
**Rationale:**
- Consistency with pose estimation model deployment
- PyTorch Mobile is already integrated and tested
- Single method channel reduces code complexity
- `.ptl` format is optimized for mobile deployment

**Alternatives Considered:**
- Keep ONNX Runtime (current approach)
  - **Pros:** Already working, no conversion needed
  - **Cons:** Inconsistent with pose model, separate method channel overhead
- Use TensorFlow Lite
  - **Pros:** Cross-platform compatibility
  - **Cons:** Requires model conversion, adds new dependency

### Decision: Reuse Existing PyTorch Mobile Method Channel
**Rationale:**
- `com.pocketpt/pytorch` channel already exists in MainActivity.kt
- Method channel supports multiple model sessions via different initialization calls
- Pose model uses the same channel successfully
- No need to create separate channel infrastructure

**Alternatives Considered:**
- Create separate method channel for pain model
  - **Pros:** Clear separation of concerns
  - **Cons:** Code duplication, more maintenance overhead

### Decision: Model Conversion Approach
**Rationale:**
- Use `torch.jit.script()` or `torch.jit.trace()` for TorchScript conversion
- Apply `optimize_for_mobile()` for `.ptl` generation
- Follow same pattern as pose model conversion

**Implementation Notes:**
- Model input shape: [1, 3, 224, 224] (batch, channels, height, width)
- Model must be in eval mode during conversion
- Ensure model architecture matches training (ResNet18 or configured variant)

## Risks / Trade-offs

### Risk: Model Output Mismatch After Conversion
**Mitigation:**
- Validate converted model against original `.pth` using test images
- Compare softmax probabilities, not just predicted class
- Run inference on validation set and compare metrics

### Risk: Preprocessing Differences Between ONNX and PyTorch
**Mitigation:**
- Ensure preprocessing matches exactly: same normalization, resize method, channel order
- Use ImageNet normalization constants directly from training code
- Add unit tests comparing preprocessing outputs

### Risk: Performance Degradation
**Mitigation:**
- PyTorch Mobile is optimized for mobile, should perform similarly or better
- Monitor inference timing in real-time scenarios
- Fall back to ONNX if significant performance regression detected

### Risk: Breaking Existing Functionality
**Mitigation:**
- Maintain ONNX code path during transition (can be removed later)
- Add feature flag to switch between implementations
- Extensive testing before deployment

## Migration Plan

1. **Phase 1: Conversion**
   - Convert `.pth` to `.ptl` format
   - Validate converted model accuracy
   - Add asset to project

2. **Phase 2: Integration**
   - Update `FacialPainRecognitionService` to use PyTorch Mobile
   - Test initialization and basic inference
   - Verify preprocessing pipeline

3. **Phase 3: Testing**
   - Test on real device with camera feed
   - Compare outputs with ONNX version
   - Performance benchmarking

4. **Phase 4: Deployment**
   - Deploy updated service
   - Monitor for errors
   - Clean up ONNX code path after validation period

## Open Questions
- Should we maintain ONNX Runtime as fallback, or fully migrate?
- Do we need to support both formats during transition period?
- What is the expected inference time improvement with PyTorch Mobile?




