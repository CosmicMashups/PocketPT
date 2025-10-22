## Context
The current ROM assessment system uses static local videos that don't adapt to user selections, limiting instructional value. Users need muscle-specific instructional videos that provide relevant guidance for their selected assessment focus. This change introduces dynamic YouTube video integration to replace static content with adaptive, muscle-specific instructional videos.

## Goals / Non-Goals

### Goals
- Replace static video system with dynamic muscle-specific videos
- Provide seamless YouTube video integration with proper error handling
- Maintain existing UI/UX patterns and user experience
- Ensure robust fallback mechanisms for missing videos
- Optimize performance with lazy loading and proper resource management

### Non-Goals
- Creating custom video content (using existing YouTube videos)
- Implementing video editing or modification features
- Adding video download or offline capabilities
- Changing the overall assessment flow or user journey

## Decisions

### Decision: YouTube Video Integration
**What**: Use youtube_player_iframe package for YouTube video playback
**Why**: Provides native YouTube integration with proper controls, error handling, and performance optimization
**Alternatives considered**: 
- Custom video player (complex implementation)
- WebView-based solution (limited control)
- Local video storage (storage limitations)

### Decision: Muscle-Video Mapping System
**What**: Create comprehensive mapping system with fallback mechanisms
**Why**: Ensures all muscles have appropriate videos while providing graceful degradation
**Alternatives considered**:
- Single generic video (reduces instructional value)
- Dynamic video selection (complex implementation)
- User-selected videos (increases complexity)

### Decision: Error Handling Strategy
**What**: Multi-level fallback system (UserAssess → AssessmentData → Default)
**Why**: Ensures video display even with missing or invalid data
**Alternatives considered**:
- Fail-fast approach (poor user experience)
- Complex retry logic (over-engineering)
- Silent fallbacks (lacks transparency)

## Risks / Trade-offs

### Risk: Network Dependency
**Mitigation**: Implement robust error handling, retry mechanisms, and offline guidance

### Risk: YouTube API Changes
**Mitigation**: Use stable youtube_player_iframe package with community support

### Risk: Performance Impact
**Mitigation**: Implement lazy loading, proper disposal, and memory management

### Risk: Video Availability
**Mitigation**: Comprehensive mapping system with fallback to default videos

## Migration Plan

### Phase 1: Package Integration
1. Add youtube_player_iframe dependency
2. Create muscle-video mapping system
3. Implement basic dynamic video player

### Phase 2: Integration
1. Replace static video in c_video.dart
2. Implement fallback logic
3. Add error handling mechanisms

### Phase 3: Optimization
1. Add performance optimizations
2. Implement proper resource management
3. Test across different devices and networks

### Phase 4: Validation
1. Test all muscle mappings
2. Verify error handling scenarios
3. Validate user experience

## Open Questions

### Video Content Gaps
- **Question**: Some muscles (Cervical Muscle, Calf, Ankle) currently use default videos
- **Resolution**: Monitor usage and create specific videos if needed, or use generic ROM assessment videos

### Network Requirements
- **Question**: How to handle users with limited network connectivity?
- **Resolution**: Implement graceful degradation with clear messaging and alternative guidance

### Video Quality Standards
- **Question**: Should we standardize video quality or aspect ratios?
- **Resolution**: Use responsive design to maintain aspect ratio across devices

### Future Video Updates
- **Question**: How to handle updates to video URLs or new muscle additions?
- **Resolution**: Design mapping system to be easily maintainable and updatable
