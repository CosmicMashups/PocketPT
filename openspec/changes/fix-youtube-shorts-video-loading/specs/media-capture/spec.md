## MODIFIED Requirements

### Requirement: YouTube Video Integration
The system SHALL integrate YouTube video playback for instructional content using the youtube_player_iframe package.

#### Scenario: YouTube video playback
- **WHEN** a muscle-specific video is selected
- **THEN** the system initializes a YouTube player instance
- **AND** loads the video from the mapped YouTube URL
- **AND** provides standard YouTube player controls
- **AND** maintains proper aspect ratio

#### Scenario: YouTube URL validation
- **WHEN** the system receives a YouTube video URL
- **THEN** it validates the URL format
- **AND** extracts the video ID for player initialization
- **AND** handles various YouTube URL formats (youtu.be, youtube.com, shorts)

#### Scenario: YouTube player configuration
- **WHEN** initializing a YouTube player
- **THEN** the system configures appropriate player parameters
- **AND** sets autoplay to false by default
- **AND** enables user controls and captions
- **AND** maintains responsive design

#### Scenario: YouTube Shorts playback
- **WHEN** the system is provided a `youtube.com/shorts/...` link for a muscle video
- **THEN** it normalizes the link to a watch URL, extracts the video ID, and sizes the player for the portrait aspect ratio
- **AND** it does not treat the initial `PlayerState.unknown` signal as a failure unless a `YoutubeError` occurs

### Requirement: Video Error Recovery
The system SHALL provide robust error handling and recovery mechanisms for video playback issues.

#### Scenario: Network connectivity issues
- **WHEN** network connectivity is poor or unavailable
- **THEN** the system displays appropriate error messaging
- **AND** provides retry functionality
- **AND** offers offline alternatives or guidance

#### Scenario: Invalid video URLs
- **WHEN** a video URL is invalid or inaccessible
- **THEN** the system falls back to default video
- **AND** logs the error for debugging
- **AND** maintains user experience continuity

#### Scenario: Video player initialization failure
- **WHEN** YouTube player fails to initialize
- **THEN** the system displays error state with retry button
- **AND** provides clear error messaging
- **AND** allows user to continue assessment without video

#### Scenario: Accurate Shorts error reporting
- **WHEN** a YouTube Shorts video is being loaded
- **AND** the player reports `PlayerState.unknown` without emitting a `YoutubeError`
- **THEN** the system waits for a real `YoutubeError` before showing the “Video not available” messaging
- **AND** actually displays the error state only when `YoutubeError` indicates a playback failure or embedding restriction

