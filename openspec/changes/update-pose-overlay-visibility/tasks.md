## 1. Diagnostics & Asset Verification
- [x] 1.1 Confirm latest `.pt` → `.ptl` export path matches `pose_train2.py` config (imgsz 320, padding 114, confidence >=0.25) and document the conversion workflow alongside `pose_test.py`.
- [x] 1.2 Add a `PoseDiagnostics` helper (Dart) that logs PyTorch initialization, tensor ranges, and sample keypoints with throttling.
- [x] 1.3 Extend `MainActivity.kt` method channel guards to validate tensor shapes/byte orders and surface explicit Flutter errors when initialization or inference fails.

## 2. Preprocessing & Inference Parity
- [x] 2.1 Refactor `CustomPoseDetectionService._cameraImageToImage` to reuse a shared normalization pipeline (letterbox to 320, padding color 114, RGB order) that mirrors the Python trainers.
- [x] 2.2 Ensure `PoseModelManager._parseYOLOOutput` reverses padding/scale exactly once and clamps coordinates within the original camera bounds.
- [x] 2.3 Add unit-style tests or assertions comparing Dart preprocessing against a sample exported tensor from `pose_test.py`.

## 3. UI & Painter Safeguards
- [x] 3.1 Teach `PoseEstimationDemo` to surface diagnostics (badges/snackbar) when no keypoints arrive for N frames, and expose a toggle to draw a hard-coded skeleton for validation.
- [x] 3.2 Update `CustomPoseSkeletonPainter` to guard against null/zero preview sizes, clamp coordinates, and optionally mirror for front camera parity.
- [x] 3.3 Add a verification mode that replays a stored inference frame so QA can validate overlay rendering without camera hardware.

## 4. Validation & Documentation
- [x] 4.1 Record results of the verification frame (expected vs actual keypoints) and attach to docs.
- [x] 4.2 Update `POSE_ESTIMATION_MODEL_INTEGRATION_GUIDE.md` (or new doc) with the troubleshooting matrix + remediation prompt.
- [ ] 4.3 Run on-device tests (debug + release) to confirm overlay visibility and archive logs in the repo.

