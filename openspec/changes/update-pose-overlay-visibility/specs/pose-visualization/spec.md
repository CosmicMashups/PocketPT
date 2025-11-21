## ADDED Requirements

### Requirement: Pose Overlay Runtime Parity
The system SHALL ensure the mobile pose overlay uses the exact preprocessing, normalization, and coordinate reconstruction parameters defined in `assets/model/pose_train1.py`, `pose_train2.py`, and validated by `assets/model/pose_test.py`.

#### Scenario: Matching preprocessing constants
- **WHEN** camera frames are converted for inference
- **THEN** the pipeline SHALL apply the same letterboxing size, padding color, normalization range, and channel order used during training
- **AND** SHALL document the constants (imgsz, padding value 114, thresholds 0.25/0.5) alongside the export instructions.

#### Scenario: Coordinate reconstruction parity
- **WHEN** YOLO keypoints are mapped back to camera space
- **THEN** the runtime SHALL undo padding/scale once, clamp coordinates within bounds, and mirror/rotate consistently with the camera sensor orientation
- **AND** the behavior SHALL be validated against a sample inference exported via `pose_test.py`.

### Requirement: Pose Overlay Diagnostics and Fallback
The system SHALL provide diagnostics, verification data, and UI safeguards so a missing skeleton overlay is immediately observable and debuggable.

#### Scenario: Inference diagnostics
- **WHEN** the PyTorch/ONNX backend initializes or runs inference
- **THEN** the app SHALL log tensor shapes, value ranges, and sample confidences (with throttling)
- **AND** SHALL raise a visible UI warning if N consecutive frames return zero keypoints.

#### Scenario: Painter verification mode
- **WHEN** diagnostics mode is enabled in `pose_estimation_demo.dart`
- **THEN** the app SHALL render a hard-coded skeleton (or stored inference frame) on top of the camera preview to prove the painter stack works independent of live inference.

#### Scenario: Asset verification
- **WHEN** a new model export is added to `assets/model/`
- **THEN** the repo SHALL include reproduction steps (TorchScript Lite conversion, quantization choice, tensor metadata) so future integrations cannot silently diverge from the training scripts.

