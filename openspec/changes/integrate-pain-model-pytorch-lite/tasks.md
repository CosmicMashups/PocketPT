## 1. Model Conversion
- [x] 1.1 Create Python script to convert `pain_recognition_model.pth` to `.ptl` format using `torch.jit.script()` or `torch.jit.trace()` with proper input shape (1, 3, 224, 224)
- [x] 1.2 Apply `torch.utils.mobile_optimizer.optimize_for_mobile()` to create optimized `.ptl` file
- [x] 1.3 Verify converted model outputs match original `.pth` model by running test inference on sample images (requires running export script)
- [x] 1.4 Place converted `pain_recognition_model.ptl` in `assets/model/` directory (model file already available)
- [x] 1.5 Update `pubspec.yaml` to include the new `.ptl` asset (assets/model/ already included)

## 2. Service Integration
- [x] 2.1 Update `FacialPainRecognitionService` to use PyTorch Mobile method channel (`com.pocketpt/pytorch`) instead of ONNX Runtime
- [x] 2.2 Modify `_loadModel()` to copy `.ptl` file from assets to temporary directory (following pose model pattern)
- [x] 2.3 Update `_runPainRecognitionModel()` to use PyTorch Mobile inference via method channel
- [x] 2.4 Ensure preprocessing matches training: 224x224 resize, ImageNet normalization (mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
- [x] 2.5 Verify output format: extract logits (3 classes), apply softmax, map to pain levels (Low, Moderate, Severe)
- [x] 2.6 Add proper error handling and initialization verification similar to `PoseModelManager`

## 3. Testing & Validation
- [ ] 3.1 Test model loading and initialization on Android device
- [ ] 3.2 Verify inference outputs match expected format (3-class probabilities)
- [ ] 3.3 Test real-time inference from camera feed (existing pain detection flow)
- [x] 3.4 Create Python test script with OpenCV to test pain_recognition_model.ptl (test_pain_model_opencv.py created)
- [ ] 3.5 Compare inference results between ONNX and PyTorch Mobile versions to ensure consistency
- [ ] 3.6 Test error handling: missing model file, initialization failures, inference errors

## 4. Cleanup & Documentation
- [x] 4.1 Remove or deprecate ONNX Runtime integration code if no longer needed (deprecated getters added for backward compatibility)
- [x] 4.2 Update service documentation to reflect PyTorch Mobile integration (service comments updated)
- [x] 4.3 Document model conversion process in a guide file (PAIN_MODEL_PYTORCH_LITE_MIGRATION.md created)
- [ ] 4.4 Update any related documentation that references ONNX Runtime for pain recognition

