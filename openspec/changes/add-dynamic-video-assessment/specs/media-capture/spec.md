## ADDED Requirements

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

### Requirement: Video Performance Optimization
The system SHALL optimize video loading and playback performance for smooth user experience.

#### Scenario: Lazy video loading
- **WHEN** the video section becomes visible
- **THEN** the system initializes video loading
- **AND** defers loading until user interaction
- **AND** prevents unnecessary resource usage

#### Scenario: Memory management
- **WHEN** video players are no longer needed
- **THEN** the system properly disposes of player instances
- **AND** releases video resources
- **AND** prevents memory leaks

#### Scenario: Video caching
- **WHEN** videos are loaded multiple times
- **THEN** the system caches video metadata
- **AND** avoids repeated URL parsing
- **AND** improves loading performance
