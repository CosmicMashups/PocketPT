## Why
`PoseEstimationDemo` intermittently crashes before the camera feed appears. The crash is reproducible when Flutter rebuilds the page faster than the asynchronous `availableCameras()` call finishes: the UI reads the `late List<CameraDescription> cameras` field (for button visibility and Stack layout) before it is assigned, throwing `LateInitializationError`. Similar races occur if `_controller` lifecycle methods are invoked before the controller starts streaming. Users see the page load for a few seconds, no camera feed renders, and then the app terminates.

### Failure modes we must eliminate
- **Late camera list access** – any access to `cameras.length` before `_initializeCamera` completes crashes the isolate.
- **Controller lifecycle race** – `_startImageStream` exits early when `_modelInitialized` is false and is never retried, leaving `_controller` idle while UI awaits frames.
- **Camera toggle state desync** – the switch-camera button assumes `cameras` is populated; as soon as a user taps quickly after navigation, `_controller` is disposed with an empty list and throws.

## What Changes
- Replace the `late` camera list with a safely initialized `_cameras = const []`, and gate all UI/control flows on that state so rebuilds cannot access uninitialized data.
- Add guards that start the image stream once the model is ready and prevent camera switching/toggling before initialization completes.
- Improve diagnostics (warnings + logs) so future regressions surface as visible UI messaging instead of crashes.

## Impact
- **Specs:** `pose-visualization`
- **Code:** `lib/demo/pose_estimation_demo.dart`
- **Testing:** Flutter analyzer + on-device smoke test of the pose demo page

