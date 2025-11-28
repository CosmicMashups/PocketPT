## Why
- A re-trained `pain_recognition_model.pth` is now available and needs to replace the previous pain detection weights. The new model must be exported as ONNX so the Flutter app can run it via the existing native ONNX runtime channel.

## What Changes
- Replace the shipped ONNX asset with the export derived from the new `.pth`, and point `FacialPainRecognitionService` at the new asset so every inference uses the updated weights.
- Surface the fact that the re-trained ONNX model is driving detections by showing the model name/metadata in the camera assessment and exercise recording overlays.
- Ensure both `c_camera.dart` and `record_exercise.dart` initialize the service before relying on detections, and handle any ONNX initialization issues that arise on-device.

## Impact
- Affected specs: `pain-recognition`
- Affected code: `lib/data/facial_pain_recognition_service.dart`, `lib/assessment/c_camera.dart`, `lib/record/record_exercise.dart`

