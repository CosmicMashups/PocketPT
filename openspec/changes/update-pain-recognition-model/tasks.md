## 1. Implementation
- [ ] 1.1 Rename the bundled ONNX asset to align with `pain_recognition_model.pth` and load it from `FacialPainRecognitionService`.
- [ ] 1.2 Update `FacialPainRecognitionService` so the ONNX asset name/metadata is exposed and the new file path is used when initializing the runtime.
- [ ] 1.3 Surface the active ONNX model name in the pain detection overlays embedded in `c_camera.dart` and `record_exercise.dart`, ensuring the service initializes before streaming.
- [ ] 1.4 Log or display any ONNX initialization failures so the flows degrade gracefully when the native runtime is unavailable.

## 2. Validation
- [ ] 2.1 Run `flutter analyze` to ensure the refactor introduces no lint violations.
- [ ] 2.2 Manually launch the camera assessment and exercise recording screens to confirm the new overlay text and successful pain detection feedback.

