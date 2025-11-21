## Why
The new YOLO11-based pose overlay demo (`lib/demo/pose_estimation_demo.dart`) shows a blank skeleton layer even though the same model works inside the Python training/test harness (`assets/model/pose_train1.py`, `pose_train2.py`, `pose_test.py`). Integration logs reveal that no keypoints arrive at the painter, meaning the failure can originate anywhere between model export and Flutter rendering. We need a disciplined change proposal that enumerates every failure mode, realigns runtime preprocessing with the training scripts, adds diagnostics for the camera/UI layers, and guarantees that the skeleton overlay is impossible to “silently” disappear again.

### Failure Catalogue (integration + runtime)

| Area | Issues we must eliminate |
| --- | --- |
| **Model conversion / packaging** | Wrong export flavor (`.pt` vs `.ptl`), missing Opset, unsupported PyTorch ops (`grid_sample`, `einsum`), traced instead of scripted graphs, dynamic shapes, quantization format mismatch, truncated assets, ABI/channel mismatch in `MainActivity.kt`. |
| **Runtime backends** | PyTorch Mobile method channel not initialized, ONNX fallback never triggered, incorrect float tensor shapes (CHW vs HWC), NaNs/zeros from inference, timeout/OOM on device, CPU-only stalls, release builds stripping native libs. |
| **Camera → tensor preprocessing** | YUV→RGB conversion errors, missing normalization to match `pose_train*.py`, improper 114-padding/letterboxing, wrong resize (center-crop/stretch), channel order mismatch, rotation/mirroring ignored, stale throttling clearing keypoints. |
| **Output decoding** | YOLO head indexing wrong (2100 anchors), ignoring multi-stage outputs, threshold too high, not applying softmax/sigmoid, coordinate rescaling not reversing padding, CHW/HWC mismatches when passing to painter. |
| **Overlay drawing** | `_cameraImageSize` null/incorrect, `CustomPoseSkeletonPainter` receiving empty `previewSize`, Stack order hiding overlay, opacity zero, z-order behind camera, `setState` never called, painter returning early on aspect mismatch, `shouldRepaint` false positives, DP vs PX scaling, rotation/mirroring mismatch. |
| **Dataflow & lifecycle** | `_showSkeleton` toggled false, camera stream paused/resumed without restarting inference, isolate messages dropped, race resetting `_currentKeypoints`, camera permission/capability differences per platform. |
| **Training/testing parity** | `pose_train1.py` uses YOLO letterboxing (imgsz 416) while mobile inference hardcodes 320 letterbox—must document/respect whichever version is exported; `pose_test.py` expects `.pt` weights while Flutter loads `.ptl`—need deterministic conversion guidance; quantization/normalization parity not captured in docs. |

## What Changes
- Author a cross-layer spec delta for `pose-visualization` that mandates: (1) training/inference preprocessing parity (normalization, padding, resizing, orientation), (2) instrumentation of PyTorch/ONNX outputs with sanity logs + fallback, and (3) UI safeguards that guarantee overlay visibility (stack diagnostics, hard-coded debug skeleton toggle, coordinate clamps).
- Ship a diagnostics-first implementation plan that adds logging hooks in `CustomPoseDetectionService`, `PoseModelManager`, and `pose_estimation_demo.dart` to trace tensor ranges, confidences, and painter invocation counts.
- Add a Flutter-side “verification frame” path that replays a known working inference sample (exported from `pose_test.py`) so overlay rendering can be tested without a live camera.
- Harden Android method-channel glue so PyTorch tensor shapes/byte orders are validated before inference, with clearer errors when opset/libs are missing.
- Document an AI remediation prompt (next section) that future agents can reuse to execute the entire recovery flow end-to-end.

## Impact
- **Specs:** `pose-visualization`
- **Code:** `lib/demo/pose_estimation_demo.dart`, `lib/data/custom_pose_detection_service.dart`, `lib/data/pose_model_manager.dart`, `android/app/src/main/kotlin/.../MainActivity.kt`, `assets/model/pose_train1.py`, `pose_train2.py`, `pose_test.py`
- **Tooling:** PyTorch Mobile/ONNX runtime initialization, camera permissions, CI smoke tests for model assets

## AI Remediation Prompt
> **Prompt Title:** “Diagnose and repair invisible pose skeleton overlay in PocketPT”
>
> **System context:** You are integrating a YOLO11 pose model trained via `assets/model/pose_train1.py` / `pose_train2.py`, validated by `assets/model/pose_test.py`, into the Flutter demo at `lib/demo/pose_estimation_demo.dart`. PyTorch Mobile runs through the method channel `com.pocketpt/pytorch` configured in `android/app/src/main/kotlin/com/example/pocketpt/MainActivity.kt`.
>
> **Objectives:**  
> 1. Verify model asset correctness (`.pt` vs `.ptl`, opset, quantization) and confirm PyTorch Mobile initializes with consistent tensor shapes (NCHW float32, 320×320 w/114 padding).  
> 2. Align runtime preprocessing with training: replicate YUV→RGB, letterboxing, normalization, mirroring, orientation, and confidence thresholds used in the training scripts; document every constant (imgsz, padding color, threshold).  
> 3. Instrument inference outputs (min/max, non-zero counts, keypoint sample) and fail loudly if tensors are empty/NaN.  
> 4. Validate coordinate rescaling + overlay rendering: ensure `_cameraImageSize` and painter `previewSize` never null, clamp coordinates inside the viewport, and add a debug overlay with hard-coded sample keypoints to prove the painter works even when inference fails.  
> 5. Add regression tests (unit or golden logs) ensuring `CustomPoseDetectionService` returns >0 keypoints for a stored frame exported by `pose_test.py`.  
> 6. Update documentation so future exports from `pose_train*.py` spell out conversion steps for mobile (TorchScript Lite, ExecuTorch, quantization choices) and highlight the troubleshooting matrix above.
>
> **Deliverables:** Updated Dart/Kotlin/Python files with inline logging, a diagnostic toggle in the demo UI, reproducible instructions to regenerate the `.ptl` asset, and validation notes confirming skeleton overlay renders over the camera on both debug and release Android builds. Use small, incremental commits and keep the solution under 100 lines per file unless absolutely necessary.

## Prompt Execution Status
This proposal, its tasks, and the accompanying spec deltas execute the remediation prompt by defining the requirements (preprocessing parity, diagnostics, fallback overlay) and scheduling concrete work items to implement them.

