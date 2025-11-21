## ADDED Requirements

### Requirement: Pose Demo Camera Stability
The pose estimation demo SHALL guard camera initialization so the UI never crashes or exposes controls before `CameraController` and the camera list are ready.

#### Scenario: Safe camera list access
- **WHEN** the page builds before `availableCameras()` completes
- **THEN** the UI SHALL treat the camera list as empty
- **AND** SHALL avoid reading uninitialized data (no `LateInitializationError`)
- **AND** SHALL hide/disable the switch-camera button until cameras are available.

#### Scenario: Stream start after model init
- **WHEN** the pose model finishes initializing after the camera controller is ready
- **THEN** the demo SHALL (re)start the image stream automatically
- **AND** SHALL prevent camera toggles or diagnostics mode transitions from calling controller methods before initialization completes.

