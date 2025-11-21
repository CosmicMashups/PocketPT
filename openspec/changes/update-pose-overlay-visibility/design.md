## Context
- Flutter demo `lib/demo/pose_estimation_demo.dart` embeds `CustomPoseDetectionService` → `PoseModelManager` which expects PyTorch Mobile via `com.pocketpt/pytorch`.
- Training (`assets/model/pose_train1.py`, `pose_train2.py`) and smoke testing (`pose_test.py`) rely on YOLO11 letterboxing (imgsz 416 & 320), RGB channel order, padding value 114, and confidence gates at 0.25–0.5. None of those invariants are explicitly enforced in the Flutter runtime.
- On Android, we bridge through `MainActivity.kt`, but there are no safeguards for tensor shapes, quantization mode, or asset drift ( `.pt` vs `.ptl` ).
- Painter visibility depends on `_cameraImageSize` and `LayoutBuilder` constraints; when inference silently returns zero keypoints, the overlay short-circuits with no diagnostic.

## Goals / Non-Goals
- **Goals**
  - Guarantee preprocessing parity with the Python scripts (letterboxing, normalization, orientation, mirroring, thresholds).
  - Surface actionable diagnostics when any pipeline stage (model load, inference, coordinate mapping, painter) fails.
  - Provide a deterministic verification path (recorded frame + expected keypoints) to test overlay rendering independent of the live camera.
  - Update documentation/specs so future model exports respect TorchScript Lite + PyTorch Mobile expectations.
- **Non-Goals**
  - Re-architect the camera stack beyond necessary instrumentation.
  - Replace YOLO11 with a different pose backbone.
  - Build a brand-new UI for pose visualization; we only fix the demo’s reliability.

## Decisions
- **Decision:** Mirror the preprocessing constants from `pose_train2.py` (imgsz 320, padding color 114, confidence gate 0.25) throughout `PoseModelManager` and `CustomPoseDetectionService`.  
  - *Reason:* pose_train2 is the ultra-fast config that matches the exported `.ptl`; enforcing its constants eliminates divergence.
- **Decision:** Add a `PoseDiagnostics` utility that logs inference inputs/outputs and exposes a debug stream to the UI.  
  - *Reason:* Without structured diagnostics the overlay can disappear silently; logs + UI badges make failures obvious.
- **Decision:** Introduce a baked-in verification frame (captured via `pose_test.py`) embedded as an asset.  
  - *Reason:* Allows end-to-end testing without live camera hardware.
- **Decision:** Require MainActivity.kt to validate tensor sizes and raise explicit Flutter errors when PyTorch modules fail to load.  
  - *Reason:* Current method channel swallows errors, leading to invisible overlays.

## Risks / Trade-offs
- Additional logging could affect frame timing; we mitigate via throttled and toggleable diagnostics.
- Enforcing preprocessing parity may break older assets exported with imgsz 416; mitigation: document how to regenerate `.ptl` for both 320 and 416 and gate by metadata.
- Adding verification assets increases APK size slightly (~100–200 KB), acceptable given stability gains.

## Migration Plan
1. Add diagnostics + verification helpers (non-breaking).
2. Align preprocessing and coordinate mapping logic.
3. Update Android method channel guards.
4. Embed verification frame + golden keypoints; wire into demo UI toggle.
5. Regenerate documentation and run `openspec validate`.

## Open Questions
- Do we need ExecuTorch or ONNX fallback for iOS/web parity? (Out of scope unless requested.)
- Should the verification frame be captured per device orientation (landscape vs portrait)?

