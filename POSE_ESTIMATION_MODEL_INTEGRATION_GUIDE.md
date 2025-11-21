# Pose Estimation Model Integration Guide

This guide documents the full pipeline for exporting, validating, and integrating the custom YOLO11 pose model inside PocketPT. Follow every step to guarantee parity between the Python training scripts and the on-device Flutter runtime.

## 1. Export Workflow (`pose_train1.py` / `pose_train2.py`)

1. Train or fine-tune the YOLO11 model using `assets/model/pose_train1.py` (YOLO11m, imgsz 416) or `assets/model/pose_train2.py` (YOLO11s, imgsz 320). Both scripts enable letterboxing to a square canvas padded with the value **114**.
2. Once training completes, export the best weights to TorchScript Lite (`.ptl`) for PyTorch Mobile:
   ```bash
   yolo export model=ultra_fast_training/yolo11s_pose_ultra_fast/weights/best.pt \
     format=torchscript optimize=true
   ```
3. Rename the artifact to `pose_model.ptl` and place it under `assets/model/`.
4. Regenerate the verification frame by running `assets/model/pose_test.py` with a canonical sample input:
   ```python
   python assets/model/pose_test.py --export-frame assets/data/pose_sample_frame.json
   ```
   This JSON captures the original image size, scale, padding, and the 17 COCO keypoints so the Flutter app can replay the exact inference.

## 2. Runtime Preconditions

- **Model format**: TorchScript Lite `.ptl` loaded through the `com.pocketpt/pytorch` channel in `MainActivity.kt`.
- **Input tensor**: Float32 `[1, 3, 320, 320]`, RGB, normalized to `[0,1]`, letterboxed with padding value 114, matching `pose_train2.py`.
- **Confidence thresholds**:
  - Detection confidence (YOLO head): `>= 0.25`
  - Painter confidence (per-keypoint): `>= 0.5`
- **Coordinate mapping**: Reverse padding + scale once, then clamp to the camera frame bounds; mirror for front camera feeds to keep overlay alignment consistent.

## 3. Diagnostics Pipeline

`lib/data/pose_diagnostics.dart` captures all runtime telemetry:

| Signal | Source | Description |
| --- | --- | --- |
| Model init | `PoseModelManager.initialize` | Emits success/error message. |
| Input tensor stats | `PoseModelManager._runPyTorchInference` | Tracks min/max/mean values for `[1,3,320,320]`. |
| Output summary | `PoseModelManager._runPyTorchInference` | Records keypoint count, sample coordinate, inference duration. |
| Frame failures | `CustomPoseDetectionService` | Marks streaks of empty / errored frames so the UI can warn the user. |

The UI (`PoseEstimationDemo`) reacts to `PoseDiagnostics.snapshot` and raises a warning chip after **18** consecutive empty frames, guiding the user to the verification toggle.

## 4. Verification Mode

- Toggle the bug icon in the demo to enter verification mode.
- The app stops the live camera stream, loads `assets/data/pose_sample_frame.json`, and renders the stored skeleton on top of a diagnostic gradient.
- Metadata validation ensures the recorded frame still matches the preprocessing constants (scale, padX, padY). If any value diverges, the UI surfaces a "Diagnostics Error" banner prompting a re-export.
- While verification is active, the diagnostics footer displays the `VERIFICATION` badge and live telemetry halts to avoid false warnings.

## 5. Troubleshooting Matrix

| Symptom | Likely Cause | Fix |
| --- | --- | --- |
| Verification sample fails to load | JSON missing or malformed | Re-run `pose_test.py --export-frame` and commit the new JSON. |
| Overlay invisible only on device | Input tensor mismatch (BGRA, wrong normalization) | Confirm padding value 114, `[0,1]` normalization, and the `[1,3,320,320]` shape in `PoseDiagnostics`. |
| Overlay mirrored for front camera | Missing mirroring flag | Ensure `CustomPoseSkeletonPainter.mirrorHorizontally` is true when `CameraLensDirection.front`. |
| Keypoints outside viewport | Padding reversal skipped twice | Validate `PoseDiagnostics` logs and use verification mode to confirm coordinates. |
| Native crashes after export | `.ptl` missing or incompatible ABI | Re-export for TorchScript Lite, verify asset listed in `pubspec.yaml`, and confirm the APK contains the file. |

## 6. Validation Checklist

- [ ] Run the app in **debug** and **release** builds, verify skeleton overlay appears within 5 seconds.
- [ ] Trigger verification mode and confirm the hard-coded skeleton renders and the warning banner disappears.
- [ ] Inspect `PoseDiagnostics` logs (Android logcat) to ensure min/max tensor values are within `[0,1]` and empty frame streak resets when detections resume.
- [ ] Validate Android `MainActivity.kt` logs no `INVALID_ARGUMENT` errors for tensor shapes.
- [ ] Attach screenshots/logs to the PR when modifying the model or preprocessing pipeline.

