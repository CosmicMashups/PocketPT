## MODIFIED Requirements

### Requirement: Pose Detection for Uploaded Media
The system SHALL provide comprehensive pose detection and muscle angle analysis for uploaded images and videos using Google ML Kit Pose Detection, with proper preprocessing, error handling, and integration with the pain level assessment workflow.

#### Scenario: Successful image pose detection and assessment
- **WHEN** user uploads a clear image of a person in a pose
- **THEN** the system detects pose landmarks using ML Kit
- **AND** analyzes muscle angles based on the selected muscle group
- **AND** calculates pain level based on ROM assessment
- **AND** displays results with pose landmarks overlaid on the image
- **AND** provides a "Proceed" button to apply results to pain level assessment

#### Scenario: Successful video pose detection and assessment
- **WHEN** user uploads a video showing range of motion
- **THEN** the system processes key frames using ML Kit pose detection
- **AND** analyzes muscle angles across the movement range
- **AND** calculates overall pain level based on ROM assessment
- **AND** displays results with pose landmarks overlaid on video frames
- **AND** provides a "Proceed" button to apply results to pain level assessment

#### Scenario: Pose detection failure handling
- **WHEN** uploaded media fails pose detection (no person visible, poor quality, etc.)
- **THEN** the system displays clear error message with guidance
- **AND** provides retry option to upload different media
- **AND** allows user to skip pose detection and continue with manual pain assessment

#### Scenario: Integration with pain level assessment
- **WHEN** pose detection completes successfully
- **THEN** the "Proceed" button automatically applies detected pain level to the slider in c_painlevel.dart
- **AND** updates UserAssess.painScale and UserAssess.painLevel
- **AND** maintains consistency with existing assessment data flow

## ADDED Requirements

### Requirement: Enhanced Image Preprocessing
The system SHALL preprocess uploaded images before pose detection to ensure optimal ML Kit performance.

#### Scenario: Image quality validation
- **WHEN** user uploads an image for pose detection
- **THEN** the system validates image quality (resolution, lighting, person visibility)
- **AND** provides feedback if image quality is insufficient
- **AND** suggests improvements (better lighting, clearer pose, etc.)

#### Scenario: Image preprocessing optimization
- **WHEN** processing uploaded images for pose detection
- **THEN** the system applies appropriate preprocessing (resizing, format conversion)
- **AND** ensures compatibility with ML Kit input requirements
- **AND** maintains image quality for accurate pose detection

### Requirement: Video Processing Support
The system SHALL process uploaded videos for pose detection using ML Kit, with frame sampling and comprehensive analysis.

#### Scenario: Video frame sampling
- **WHEN** user uploads a video for pose detection
- **THEN** the system samples key frames at appropriate intervals
- **AND** processes each frame using ML Kit pose detection
- **AND** analyzes pose changes across the movement range

#### Scenario: Video assessment integration
- **WHEN** video pose detection completes
- **THEN** the system provides comprehensive ROM assessment across the movement
- **AND** calculates overall pain level based on range of motion analysis
- **AND** displays results with pose landmarks overlaid on video frames

### Requirement: Muscle Angle Analysis Enhancement
The system SHALL provide comprehensive muscle angle analysis based on detected pose landmarks, matching the accuracy of camera-based assessment.

#### Scenario: Accurate muscle angle calculation
- **WHEN** pose landmarks are detected for uploaded media
- **THEN** the system calculates muscle angles using the same logic as camera assessment
- **AND** applies appropriate muscle group-specific analysis
- **AND** provides ROM assessment consistent with camera-based results

#### Scenario: Multi-muscle group support
- **WHEN** user selects different muscle groups for assessment
- **THEN** the system applies appropriate angle analysis for each muscle group
- **AND** provides muscle-specific ROM assessment and pain level calculation
- **AND** maintains consistency with existing muscle group mappings

