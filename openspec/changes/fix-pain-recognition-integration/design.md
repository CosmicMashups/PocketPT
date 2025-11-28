## Context

The pain recognition model is trained using PyTorch (see `pain_train.py`) with ResNet18 or EfficientNet architecture, producing 3-class outputs (Low, Moderate, Severe). The model needs to be exported to ONNX format for mobile deployment via ONNX Runtime.

The current implementation uses a method channel (`com.pocketpt/onnxruntime-pain`) to communicate with native Android code that runs ONNX Runtime. However, the pain level values are not updating, suggesting a breakdown in the inference pipeline.

## Goals / Non-Goals

### Goals
- Fix pain recognition model integration to enable real-time pain level updates
- Ensure model inference produces varying outputs based on input
- Align preprocessing/postprocessing with training code
- Provide clear error messages when model fails

### Non-Goals
- Retraining the model (use existing trained model)
- Changing the model architecture
- Implementing new pain detection algorithms

## Decisions

### Decision: Use ONNX Runtime (not PyTorch Mobile)
- **Rationale**: ONNX Runtime is already set up for pain detection, and ONNX format is more portable
- **Alternatives**: PyTorch Mobile (like pose estimation), TensorFlow Lite
- **Trade-off**: Need to ensure proper ONNX export from PyTorch

### Decision: Match Training Preprocessing Exactly
- **Rationale**: Any mismatch in preprocessing will cause incorrect predictions
- **Implementation**: Use ImageNet normalization values from training: mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]
- **Verification**: Compare preprocessing output with training script

### Decision: Model Outputs Logits (Apply Softmax in Dart)
- **Rationale**: Training script shows model outputs raw logits, softmax is applied in inference
- **Implementation**: Extract logits from ONNX output, apply softmax, then argmax for class prediction
- **Verification**: Check training script inference pattern

### Decision: Keep Frame Rate Limiting but Fix Logic
- **Rationale**: 5 FPS is reasonable for pain detection, but current implementation may be too restrictive
- **Implementation**: Ensure frame rate limiting allows updates, not blocking all frames
- **Verification**: Test that updates occur at least every 200ms

## Risks / Trade-offs

### Risk: ONNX Export May Not Match Training
- **Mitigation**: Verify exported model with test inputs, compare outputs with PyTorch model
- **Detection**: Log model outputs and compare with expected values

### Risk: Preprocessing Mismatch
- **Mitigation**: Use exact normalization values from training, verify with test images
- **Detection**: Add validation logging for preprocessing steps

### Risk: Method Channel Communication Issues
- **Mitigation**: Add comprehensive error handling and logging
- **Detection**: Test method channel with known inputs/outputs

### Risk: Model File Format Issues
- **Mitigation**: Verify ONNX model file is valid, test with ONNX Runtime directly
- **Detection**: Check model file size and format

## Migration Plan

1. **Phase 1**: Diagnosis - Add logging to identify failure points
2. **Phase 2**: Model Export - Create and test export script
3. **Phase 3**: Preprocessing Fix - Align with training code
4. **Phase 4**: Output Parsing Fix - Correct logits extraction and softmax
5. **Phase 5**: Integration Testing - Verify end-to-end functionality
6. **Phase 6**: Documentation - Document process and requirements

## Open Questions

- Is the ONNX model file properly exported from the trained PyTorch model?
- What is the exact input name expected by the ONNX model?
- Are there any differences in model architecture between training and export?
- Is the method channel correctly handling the input/output tensors?





