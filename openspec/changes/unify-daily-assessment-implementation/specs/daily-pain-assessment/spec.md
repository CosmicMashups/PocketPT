## MODIFIED Requirements

### Requirement: Daily Assessment Camera Implementation
The daily assessment camera page (`lib/dailyAssessment/cameraPose.dart`) SHALL have identical implementation to the assessment camera page (`lib/assessment/c_camera.dart`), with only navigation target differences to maintain the simplified daily assessment flow.

#### Scenario: Identical camera initialization
- **GIVEN** both assessment and daily assessment camera pages
- **WHEN** initializing the camera
- **THEN** both use identical camera initialization logic
- **AND** both use identical error handling
- **AND** both use identical camera switching logic

#### Scenario: Identical pose detection integration
- **GIVEN** both assessment and daily assessment camera pages
- **WHEN** processing camera frames for pose detection
- **THEN** both use identical pose detection service integration
- **AND** both use identical keypoint-to-landmark conversion
- **AND** both use identical throttling and frame rate limiting

#### Scenario: Identical pain recognition integration
- **GIVEN** both assessment and daily assessment camera pages
- **WHEN** processing camera frames for pain recognition
- **THEN** both use identical pain recognition service integration
- **AND** both use identical pain level detection logic
- **AND** both use identical pain feedback mechanisms

#### Scenario: Identical AROM assessment integration
- **GIVEN** both assessment and daily assessment camera pages
- **WHEN** performing AROM assessment
- **THEN** both use identical AROM assessment service integration
- **AND** both use identical muscle-to-algorithm mapping
- **AND** both use identical assessment result handling

#### Scenario: Identical UI/UX implementation
- **GIVEN** both assessment and daily assessment camera pages
- **WHEN** rendering the camera interface
- **THEN** both use identical UI layout and styling
- **AND** both use identical status indicators
- **AND** both use identical camera controls
- **AND** both use identical skeleton overlay implementation

#### Scenario: Identical helper code usage
- **GIVEN** both assessment and daily assessment camera pages
- **WHEN** using helper code from `lib/assessment/arom/`
- **THEN** both use identical imports and service calls
- **AND** both use identical error handling patterns
- **AND** both use identical state management patterns

### Requirement: Daily Assessment Instruction Video Implementation
The daily assessment instruction video page (`lib/dailyAssessment/instructionVideo.dart`) SHALL have identical implementation to the assessment instruction video page (`lib/assessment/c_video.dart`), with only navigation target differences to maintain the simplified daily assessment flow.

#### Scenario: Identical video player integration
- **GIVEN** both assessment and daily assessment instruction video pages
- **WHEN** displaying instructional videos
- **THEN** both use identical `LocalMuscleVideoPlayer` integration
- **AND** both use identical `MuscleVideoMapping` usage
- **AND** both use identical video loading and error handling

#### Scenario: Identical muscle selection logic
- **GIVEN** both assessment and daily assessment instruction video pages
- **WHEN** selecting the muscle for video display
- **THEN** both use identical `_getSelectedMuscle()` implementation
- **AND** both use identical fallback logic
- **AND** both use identical data source priority (UserAssess → AssessmentData → default)

#### Scenario: Identical UI/UX implementation
- **GIVEN** both assessment and daily assessment instruction video pages
- **WHEN** rendering the instruction video interface
- **THEN** both use identical UI layout and styling
- **AND** both use identical progress section
- **AND** both use identical question section
- **AND** both use identical video section
- **AND** both use identical action buttons

#### Scenario: Identical helper code usage
- **GIVEN** both assessment and daily assessment instruction video pages
- **WHEN** using helper code from `lib/assessment/`
- **THEN** both use identical imports for video mapping and player
- **AND** both use identical error handling patterns
- **AND** both use identical state management patterns

### Requirement: Helper Code Integration
The daily assessment flow SHALL use the same helper code from `lib/assessment/arom/`, `lib/assessment/muscle_video_mapping.dart`, and `lib/assessment/local_muscle_video_player.dart` as the assessment flow, ensuring consistent behavior and single source of truth.

#### Scenario: AROM assessment service usage
- **GIVEN** both assessment and daily assessment flows
- **WHEN** performing AROM assessment
- **THEN** both use `lib/assessment/arom/assessment_service.dart` identically
- **AND** both use `lib/assessment/arom/assessment_result.dart` identically
- **AND** both have access to all AROM assessment algorithms

#### Scenario: Video mapping service usage
- **GIVEN** both assessment and daily assessment flows
- **WHEN** selecting instructional videos
- **THEN** both use `lib/assessment/muscle_video_mapping.dart` identically
- **AND** both use the same muscle-to-video mapping
- **AND** both use the same fallback logic

#### Scenario: Video player component usage
- **GIVEN** both assessment and daily assessment flows
- **WHEN** displaying instructional videos
- **THEN** both use `lib/assessment/local_muscle_video_player.dart` identically
- **AND** both use the same video player configuration
- **AND** both use the same error handling and loading states

