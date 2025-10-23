## ADDED Requirements

### Requirement: Real-time Pain Recognition During AROM Assessment
The system SHALL detect facial pain in real-time during active range of motion assessment using the existing `FacialPainRecognitionService`.

#### Scenario: Pain detection during ROM assessment
- **WHEN** user performs ROM movement during camera assessment
- **THEN** system continuously monitors facial expressions for pain indicators
- **AND** processes pain detection at 5 FPS to maintain performance

#### Scenario: Pain detection service initialization
- **WHEN** AROM assessment camera initializes
- **THEN** system initializes `FacialPainRecognitionService`
- **AND** begins pain detection monitoring alongside pose detection

### Requirement: Pain Level Intervention System
The system SHALL provide immediate intervention based on detected pain levels during assessment.

#### Scenario: Low pain detection
- **WHEN** system detects low pain level (confidence > 0.7)
- **THEN** system ignores the detection and continues assessment
- **AND** no user intervention is triggered

#### Scenario: Moderate pain detection
- **WHEN** system detects moderate pain level (confidence > 0.7)
- **THEN** system displays confirmation dialog asking if detected pain level is accurate
- **AND** provides options to confirm or override the detected level

#### Scenario: Severe pain detection
- **WHEN** system detects severe pain level (confidence > 0.7)
- **THEN** system displays urgent confirmation dialog
- **AND** recommends rest and asks if user can continue assessment

### Requirement: Fallback Pain Detection
The system SHALL provide alternative pain detection when facial recognition fails during assessment.

#### Scenario: Face detection failure during assessment
- **WHEN** face cannot be detected during ROM movement
- **AND** user maintains position for 3 seconds after recording starts
- **THEN** system determines pain level based on ROM angle and pose analysis
- **AND** displays confirmation dialog with determined pain level

#### Scenario: Position-based pain determination
- **WHEN** face detection fails and user holds position for 3 seconds
- **THEN** system analyzes ROM angle and joint movement patterns
- **AND** estimates pain level based on movement quality and compensation patterns

### Requirement: Assessment Flow Modification
The system SHALL modify the AROM assessment flow to integrate pain detection and streamline user experience.

#### Scenario: Recording with pain detection
- **WHEN** user presses record button during assessment
- **THEN** system maintains both pose detection and pain recognition
- **AND** continues monitoring for pain indicators throughout recording

#### Scenario: Pain level confirmation dialog
- **WHEN** recording completes and pain level is detected
- **THEN** system displays dialog confirming detected pain level
- **AND** allows user to confirm or modify the pain level before proceeding

#### Scenario: Direct navigation to pain level input
- **WHEN** pain level confirmation is completed
- **THEN** system navigates directly to `c_painlevel.dart` with detected pain level
- **AND** bypasses video preview step (`c_videopreview.dart`)

## MODIFIED Requirements

### Requirement: AROM Assessment Camera Integration
The AROM assessment camera SHALL integrate pain recognition alongside existing pose detection functionality.

#### Scenario: Simultaneous detection during assessment
- **WHEN** user performs ROM movement during camera assessment
- **THEN** system processes both pose landmarks and facial pain indicators
- **AND** maintains performance through frame rate limiting (5 FPS for pain detection)

#### Scenario: Pain detection status display
- **WHEN** pain detection is active during assessment
- **THEN** system displays pain detection status indicator
- **AND** shows current pain level and confidence percentage

### Requirement: Assessment Recording Behavior
The assessment recording functionality SHALL maintain pain detection during video recording.

#### Scenario: Recording with continuous pain monitoring
- **WHEN** user starts video recording during assessment
- **THEN** system continues pain detection throughout recording
- **AND** captures pain level data alongside ROM measurements

#### Scenario: Pain level capture on recording completion
- **WHEN** video recording completes
- **THEN** system captures final pain level and confidence
- **AND** prepares pain level confirmation dialog

## REMOVED Requirements

### Requirement: Video Preview Step in Assessment Flow
**Reason**: Pain detection provides real-time feedback, making video review redundant
**Migration**: Users will see pain level confirmation dialog instead of video preview

#### Scenario: Bypass video preview
- **WHEN** assessment recording completes
- **THEN** system skips video preview step
- **AND** proceeds directly to pain level confirmation
