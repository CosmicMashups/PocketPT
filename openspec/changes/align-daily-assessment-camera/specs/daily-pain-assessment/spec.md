## ADDED Requirements

### Requirement: Pain Recognition Model Integration
The daily assessment camera page SHALL integrate facial pain recognition model (FacialPainRecognitionService) to automatically detect pain levels during camera assessment.

#### Scenario: Automatic Pain Detection
- **GIVEN** the user is on the daily assessment camera page
- **WHEN** the camera is active and processing frames
- **THEN** the facial pain recognition service processes frames at 5 FPS
- **AND** detected pain levels update `UserAssess.painScale` and `UserAssess.painLevel`
- **AND** pain level indicators are displayed in the UI overlay

#### Scenario: Pain Detection Failure
- **GIVEN** the facial pain recognition service fails to initialize
- **WHEN** the user accesses the daily assessment camera page
- **THEN** the camera assessment continues without pain detection
- **AND** the user can still manually input pain level on the next page

### Requirement: Pain Level Visual Feedback
The daily assessment camera page SHALL display real-time pain level indicators with color coding and animations.

#### Scenario: Pain Level Display
- **GIVEN** pain detection is active
- **WHEN** a pain level is detected
- **THEN** a pain level overlay appears in the top-right corner
- **AND** the overlay shows pain level (Low/Moderate/Severe) with appropriate color
- **AND** the overlay includes confidence percentage if available
- **AND** color transitions animate smoothly when pain level changes

#### Scenario: Pain Level Colors
- **GIVEN** different pain levels are detected
- **WHEN** Low pain is detected
- **THEN** the indicator uses green color
- **WHEN** Moderate pain is detected
- **THEN** the indicator uses orange color
- **WHEN** Severe pain is detected
- **THEN** the indicator uses red color

### Requirement: Skeleton Overlay Configuration
The daily assessment camera page SHALL provide configurable skeleton overlay matching the full assessment camera.

#### Scenario: Skeleton Overlay Toggle
- **GIVEN** the user is on the daily assessment camera page
- **WHEN** the user opens camera settings
- **THEN** a skeleton overlay toggle is available
- **AND** toggling it on/off shows/hides the skeleton overlay
- **AND** the skeleton overlay displays detected pose keypoints

#### Scenario: Skeleton Configuration
- **GIVEN** skeleton overlay is enabled
- **WHEN** the user opens skeleton settings
- **THEN** options are available for:
  - Stroke width (line thickness)
  - Point radius (keypoint size)
  - Show landmark labels
  - Show confidence values
- **AND** changes apply immediately to the overlay

## MODIFIED Requirements

### Requirement: Camera UI Layout
The daily assessment camera page SHALL adopt the UI layout and controls from the full assessment camera.

#### Scenario: Status Indicators
- **GIVEN** the user is on the daily assessment camera page
- **WHEN** the camera is active
- **THEN** status indicators are displayed at the top:
  - LIVE indicator (green)
  - SKELETON indicator (if enabled)
  - PAIN level indicator (color-coded)
- **AND** indicators match the style from full assessment camera

#### Scenario: Camera Controls
- **GIVEN** the user is on the daily assessment camera page
- **WHEN** the user taps the settings button
- **THEN** a menu appears with options:
  - Skeleton overlay toggle
  - Skeleton settings
  - Switch camera
  - Assessment help
- **AND** the menu structure matches the full assessment camera

### Requirement: Pose Estimation Model Integration
The daily assessment camera page SHALL integrate pose estimation model (CustomPoseDetectionService) for AROM assessment aligned with user's specificMuscle.

#### Scenario: Pose Estimation for AROM Assessment
- **GIVEN** the user is on the daily assessment camera page
- **WHEN** pose estimation model detects keypoints
- **THEN** keypoints are converted to landmarks format
- **AND** AROM assessment is performed using AssessmentService
- **AND** assessment algorithm is selected based on UserAssess.specificMuscle
- **AND** AROM assessment provides pain scores based on range of motion

#### Scenario: Muscle-Specific Assessment Alignment
- **GIVEN** the user has selected a specific muscle (UserAssess.specificMuscle)
- **WHEN** the camera assessment starts
- **THEN** the appropriate AROM assessment algorithm is selected via _getAssessmentMode()
- **AND** muscle-to-algorithm mapping correctly routes to AssessmentService
- **AND** assessment results are specific to the selected muscle group

### Requirement: Dual Model Pain Assessment
The daily assessment camera page SHALL combine pain scores from both AROM assessment and facial pain recognition for comprehensive pain assessment.

#### Scenario: Combined Pain Assessment
- **GIVEN** both pose estimation and pain recognition models are active
- **WHEN** assessment is performed
- **THEN** AROM assessment provides pain score based on range of motion
- **AND** facial pain recognition provides pain level from facial expressions
- **AND** both pain scores are combined or displayed together
- **AND** final pain level reflects comprehensive assessment from both models

#### Scenario: Navigation Flow
- **GIVEN** the user completes camera assessment
- **WHEN** the user proceeds to the next step
- **THEN** navigation goes directly to pain level input page
- **AND** no intermediate confirmation dialogs are shown
- **AND** detected pain values are pre-populated

## MODIFIED Requirements (continued)

### Requirement: Assessment Result Display
The daily assessment camera page SHALL display assessment results from both AROM assessment and facial pain recognition.

#### Scenario: Dual Model Results Display
- **GIVEN** both models are providing assessment data
- **WHEN** results are available
- **THEN** AROM assessment results are displayed (pain score, clinical context)
- **AND** facial pain recognition results are displayed (pain level, confidence)
- **AND** both results are shown in the assessment results panel
- **AND** UI clearly indicates which model provided which data


