## ADDED Requirements

### Requirement: Dynamic Video Assessment
The system SHALL provide muscle-specific instructional videos that dynamically change based on the user's selected muscle during ROM assessment.

#### Scenario: Upper body muscle video selection
- **WHEN** user selects "Deltoids" in the upper body assessment
- **THEN** the video section displays the Deltoids-specific instructional video
- **AND** the video loads from the appropriate YouTube URL
- **AND** the video provides ROM assessment instructions for shoulder muscles

#### Scenario: Lower body muscle video selection
- **WHEN** user selects "Quadriceps" in the lower body assessment
- **THEN** the video section displays the Quadriceps-specific instructional video
- **AND** the video loads from the appropriate YouTube URL
- **AND** the video provides ROM assessment instructions for thigh muscles

#### Scenario: Core muscle video selection
- **WHEN** user selects "Abdominals" in the core assessment
- **THEN** the video section displays the Abdominals-specific instructional video
- **AND** the video loads from the appropriate YouTube URL
- **AND** the video provides ROM assessment instructions for core muscles

#### Scenario: Video loading with fallback
- **WHEN** user selects a muscle that doesn't have a specific video assigned
- **THEN** the system displays the default instructional video
- **AND** provides appropriate fallback messaging
- **AND** maintains video functionality

### Requirement: Muscle-Video Mapping System
The system SHALL maintain a comprehensive mapping between muscle names and their corresponding instructional video URLs.

#### Scenario: Muscle mapping lookup
- **WHEN** the system needs to display a video for a selected muscle
- **THEN** it looks up the muscle name in the mapping system
- **AND** retrieves the appropriate YouTube video URL
- **AND** handles case-insensitive muscle name matching

#### Scenario: Missing muscle mapping
- **WHEN** a muscle name is not found in the mapping system
- **THEN** the system uses the default video URL
- **AND** logs the missing mapping for future updates
- **AND** continues with video playback

### Requirement: Video Player State Management
The system SHALL properly manage video player states including loading, error handling, and disposal.

#### Scenario: Video loading state
- **WHEN** a video is being loaded
- **THEN** the system displays a loading indicator
- **AND** shows appropriate loading messaging
- **AND** prevents user interaction until loading completes

#### Scenario: Video error handling
- **WHEN** a video fails to load due to network issues or invalid URLs
- **THEN** the system displays an error message with retry option
- **AND** provides fallback to default video
- **AND** maintains user experience continuity

#### Scenario: Video player disposal
- **WHEN** the user navigates away from the video section
- **THEN** the system properly disposes of video resources
- **AND** prevents memory leaks
- **AND** cleans up YouTube player instances
