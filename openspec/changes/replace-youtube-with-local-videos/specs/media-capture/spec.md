## MODIFIED Requirements

### Requirement: Local Video Playback
The system SHALL use local video files for exercise demonstration videos instead of YouTube videos.

#### Scenario: Local video playback
- **WHEN** a muscle-specific video is requested in the ROM assessment flow
- **THEN** the system loads the corresponding local MP4 file from `assets/videos/`
- **AND** initializes a local video player using `VideoPlayerController.asset()`
- **AND** displays the video with proper aspect ratio and controls
- **AND** works without network connectivity

#### Scenario: Muscle-to-video mapping
- **WHEN** a muscle group is selected for assessment
- **THEN** the system maps the muscle name to the corresponding local video file:
  - Deltoids, Chest → `assets/videos/deltoids_chest.mp4`
  - Triceps → `assets/videos/triceps.mp4`
  - Biceps → `assets/videos/biceps.mp4`
  - Quadriceps → `assets/videos/quadriceps.mp4`
  - Abdominals, Obliques, Lower Back, Multifidus → `assets/videos/trunk.mp4`
  - Gluteals, Hamstrings, Calf → `assets/videos/hamstrings_gluteals.mp4`
- **AND** falls back to `deltoids_chest.mp4` if muscle is not mapped

#### Scenario: Video player initialization
- **WHEN** initializing a local video player
- **THEN** the system uses `VideoPlayerController.asset()` with the mapped file path
- **AND** handles initialization errors gracefully
- **AND** displays loading state while video initializes
- **AND** maintains proper aspect ratio from video metadata

## REMOVED Requirements

### Requirement: YouTube Video Integration
The system SHALL NOT use YouTube video playback for exercise demonstration videos.

#### Scenario: YouTube video playback (REMOVED)
- ~~**WHEN** a muscle-specific video is selected~~
- ~~**THEN** the system initializes a YouTube player instance~~
- ~~**AND** loads the video from the mapped YouTube URL~~

#### Scenario: YouTube URL validation (REMOVED)
- ~~**WHEN** the system receives a YouTube video URL~~
- ~~**THEN** it validates the URL format~~
- ~~**AND** extracts the video ID for player initialization~~

#### Scenario: Network connectivity issues (REMOVED)
- ~~**WHEN** network connectivity is poor or unavailable~~
- ~~**THEN** the system displays appropriate error messaging~~
- ~~**AND** provides retry functionality~~

## ADDED Requirements

### Requirement: Local Video Error Handling
The system SHALL provide robust error handling for local video playback issues.

#### Scenario: Missing video file
- **WHEN** a local video file is missing or cannot be loaded
- **THEN** the system displays a user-friendly error message
- **AND** falls back to the default video (`deltoids_chest.mp4`)
- **AND** allows the user to continue the assessment

#### Scenario: Corrupted video file
- **WHEN** a local video file is corrupted or cannot be decoded
- **THEN** the system displays an error message
- **AND** attempts to load the fallback video
- **AND** logs the error for debugging

#### Scenario: Video initialization failure
- **WHEN** video player fails to initialize
- **THEN** the system displays error state with clear messaging
- **AND** provides fallback video option
- **AND** allows user to continue assessment without video

### Requirement: Offline Video Playback
The system SHALL support video playback without network connectivity.

#### Scenario: Offline video access
- **WHEN** the device has no network connectivity
- **THEN** local videos continue to play normally
- **AND** no network-related errors are displayed
- **AND** video playback is not affected by network status

### Requirement: Video State Management
The system SHALL properly manage video player state during navigation and widget lifecycle.

#### Scenario: Video disposal on navigation
- **WHEN** the user navigates away from the video page
- **THEN** the system properly disposes of the video controller
- **AND** releases video resources
- **AND** prevents memory leaks

#### Scenario: Video pause on background
- **WHEN** the app moves to background or video page is hidden
- **THEN** the system pauses video playback
- **AND** resumes playback when page becomes visible again (if applicable)

