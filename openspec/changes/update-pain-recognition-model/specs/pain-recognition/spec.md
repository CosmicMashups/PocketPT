## ADDED Requirements

### Requirement: ONNX-backed pain recognition model
The system SHALL load the re-trained ONNX export derived from `pain_recognition_model.pth` whenever the facial pain recognition service is initialized so that all detections run against the newest weights.

#### Scenario: Pain detection service starts with the updated ONNX asset
- **WHEN** the assessment camera or exercise recording view initializes and calls `FacialPainRecognitionService.initialize()`
- **THEN** the service copies `assets/model/pain_recognition_model.onnx` into a temporary location
- **AND** the native ONNX runtime channel is instructed to load that file before any camera frames are processed
- **AND** a warm-up inference is executed so the streaming pipelines can rely on the new model immediately.

#### Scenario: ONNX runtime initialization fails
- **WHEN** the ONNX runtime method channel cannot be initialized (e.g., device lacks native support)
- **THEN** the service logs the failure and falls back to the simulation mode without crashing the assessment or recording flows
- **AND** the UI continues running so the user can complete the interaction with degraded pain detection feedback.

### Requirement: Model metadata surfaced in assessment and recording overlays
The system SHALL surface the name of the active ONNX pain model inside both the AROM camera overlay and the exercise recording overlay so users and telemetry can confirm the new weights are in use.

#### Scenario: Camera overlay displays the ONNX model name
- **WHEN** `c_camera.dart` is displaying the live preview with pain detection enabled
- **THEN** its pain detection status indicator includes text such as `Model: pain_recognition_model.onnx`
- **AND** the indicator continues to update the current pain level/confidence alongside the model metadata.

#### Scenario: Exercise recording overlay highlights the ONNX model
- **WHEN** `record_exercise.dart` is recording and pain detection is active
- **THEN** the overlay banner contains the same model identifier text so the user sees the new ONNX runtime in both flows
- **AND** any ONNX initialization issues are surfaced as a warning badge without blocking the recording experience.

