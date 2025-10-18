## MODIFIED Requirements
### Requirement: Assessment Navigation Flow
The assessment module SHALL follow a logical sequence where pain type assessment precedes pain duration assessment, and media upload is only accessible when video recording is selected.

#### Scenario: Correct navigation from pain type to pain duration
- **WHEN** user completes pain type selection in `c_paintype.dart`
- **THEN** the app navigates to `c_painduration.dart`
- **AND** the navigation preserves all selected pain type data

#### Scenario: Media upload accessibility
- **WHEN** user reaches the media upload step
- **THEN** `c_upload.dart` is only accessible after all `b_*.dart` files except `b_focus1.dart`
- **AND** `c_video.dart` is only accessible when "Record Video" option is toggled

#### Scenario: Assessment flow sequence
- **WHEN** user progresses through the assessment
- **THEN** the sequence follows: `b_focus1.dart` → `b_*.dart` files → `c_paintype.dart` → `c_painduration.dart` → `c_upload.dart` (if video selected) → `c_video.dart`

## ADDED Requirements
### Requirement: Functional Media Capture
The system SHALL provide fully functional photo and video capture capabilities with proper device integration.

#### Scenario: Take photo functionality
- **WHEN** user taps "Take Photo" button in `c_upload.dart`
- **THEN** the device camera opens
- **AND** user can capture a photo
- **AND** the photo is saved to the appropriate path or variable
- **AND** AI model preparation is triggered for the captured photo

#### Scenario: Upload from gallery functionality
- **WHEN** user taps "Upload from Gallery" button in `c_upload.dart`
- **THEN** the device gallery opens
- **AND** user can select existing photos or videos
- **AND** the selected media is loaded into the appropriate path or variable
- **AND** AI model preparation is triggered for the selected media

#### Scenario: Video recording toggle
- **WHEN** user toggles "Record Video" option
- **THEN** `c_video.dart` becomes accessible
- **AND** the video recording flow is properly initialized
