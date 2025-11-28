## 1. Analysis and Diagnosis

- [x] 1.1 Compare pain recognition service with pose estimation service to identify integration pattern differences
- [x] 1.2 Verify ONNX model file exists and is properly formatted (`assets/model/pain_recognition_model.onnx`)
- [x] 1.3 Check if model export script exists and review export process
- [x] 1.4 Analyze training script (`pain_train.py`) to understand model architecture and preprocessing
- [x] 1.5 Review testing script (`pain_test.py`) to understand expected inference pattern
- [x] 1.6 Verify method channel setup in MainActivity.kt matches service expectations
- [x] 1.7 Add diagnostic logging to identify where the integration fails

## 2. Model Export and Verification

- [x] 2.1 Create `assets/model/export_pain_to_onnx.py` script to export PyTorch model to ONNX
- [x] 2.2 Ensure export script matches training architecture (ResNet18/EfficientNet from pain_train.py)
- [x] 2.3 Verify exported ONNX model has correct input shape [1, 3, 224, 224]
- [x] 2.4 Verify exported ONNX model has correct output shape [1, 3] (logits for 3 classes)
- [x] 2.5 Test exported model with sample input to verify output format
- [x] 2.6 Document export process and requirements

## 3. Input Preprocessing Alignment

- [x] 3.1 Verify normalization values match training: mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]
- [x] 3.2 Ensure channel ordering (NCHW) matches model expectations
- [x] 3.3 Verify image resize to 224x224 matches training
- [x] 3.4 Test preprocessing with known input to verify output tensor values
- [x] 3.5 Add validation logging for preprocessing steps

## 4. Output Parsing and Postprocessing

- [x] 4.1 Verify model outputs raw logits (not probabilities)
- [x] 4.2 Ensure softmax function correctly converts logits to probabilities
- [x] 4.3 Verify argmax correctly selects predicted class
- [x] 4.4 Test output parsing with known model outputs
- [x] 4.5 Add logging for raw model output, logits, probabilities, and final prediction

## 5. Method Channel Communication

- [x] 5.1 Verify input name "input" matches ONNX model input name
- [x] 5.2 Ensure input tensor shape [1, 3, 224, 224] is correctly passed
- [x] 5.3 Verify output parsing handles List<double> correctly
- [x] 5.4 Test method channel with test inference to verify communication
- [x] 5.5 Add error handling for method channel failures

## 6. Frame Rate and Update Logic

- [x] 6.1 Review frame rate limiting (5 FPS) - ensure it allows updates
- [x] 6.2 Verify `_shouldProcessFrame()` logic doesn't block all frames
- [x] 6.3 Ensure state updates trigger UI rebuilds
- [x] 6.4 Test with varying frame rates to verify updates occur

## 7. Error Handling and Fallback

- [x] 7.1 Remove or fix simulation fallback that returns static values
- [x] 7.2 Add proper error propagation when model fails
- [x] 7.3 Ensure initialization errors are clearly logged
- [x] 7.4 Add user-visible indicators when model is not working

## 8. Integration Testing

- [ ] 8.1 Test pain recognition in `c_camera.dart` with real camera input
- [ ] 8.2 Test pain recognition in `cameraPose.dart` with real camera input
- [ ] 8.3 Verify pain level changes over time with different facial expressions
- [ ] 8.4 Verify confidence values are reasonable (0.0-1.0)
- [ ] 8.5 Test error scenarios (no face detected, model failure, etc.)

## 9. Documentation

- [ ] 9.1 Document model export process
- [ ] 9.2 Document preprocessing requirements
- [ ] 9.3 Document expected model output format
- [ ] 9.4 Add troubleshooting guide for common issues

