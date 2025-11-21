## 1. Crash Diagnosis & Safeguards
- [x] 1.1 Reproduce the `LateInitializationError` triggered by the `late List<CameraDescription> cameras` field and capture stack trace.
- [x] 1.2 Replace the `late` field with an eagerly initialized list, update all call sites, and gate UI actions (switch camera, diagnostics toggle) on `_cameras.isNotEmpty`.

## 2. Controller Lifecycle Fixes
- [x] 2.1 Ensure `_startImageStream` reruns when the pose model finishes initializing so the camera feed starts reliably.
- [x] 2.2 Add state guards so `_controller` methods (`startImageStream`, `stopImageStream`, `dispose`) are only invoked when the controller exists and is initialized.

## 3. Verification
- [x] 3.1 Run `flutter analyze lib/demo/pose_estimation_demo.dart` to confirm no new warnings/errors.
- [ ] 3.2 Manually open `PoseEstimationDemo` (debug build) to verify the camera feed appears without crashing and the diagnostics toggle continues to function.

