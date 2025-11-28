## Context
The current ROM assessment video system uses YouTube Shorts videos via the `youtube_player_iframe` package. This approach has proven unreliable due to:
- Persistent iframe loading issues causing "Video unavailable" errors
- Black screen rendering problems
- Network dependency requirements
- Potential embedding restrictions
- Code 4 HTML5 player errors

The application already has all necessary exercise demonstration videos stored locally in `assets/videos/`, making a migration to local video playback the optimal solution.

## Goals / Non-Goals

### Goals
- Replace YouTube video player with reliable local video playback
- Ensure offline functionality (no network dependency)
- Maintain muscle-specific video selection
- Provide smooth playback experience across Android and iOS
- Implement proper error handling for missing/corrupted files
- Preserve existing UI/UX patterns

### Non-Goals
- Creating new video content (using existing local videos)
- Implementing video editing or modification features
- Adding video download or streaming capabilities
- Changing the overall assessment flow or user journey
- Supporting multiple video formats (MP4 only)

## Decisions

### Decision: Use Existing video_player Package
**What**: Use the existing `video_player: ^2.7.0` package for local video playback
**Why**: Already in dependencies, well-maintained, supports asset playback, cross-platform compatible
**Alternatives considered**: 
- Custom video player implementation (unnecessary complexity)
- Different video player package (would require new dependency)

### Decision: Reuse or Enhance LocalVideoPlayer
**What**: Reuse existing `LocalVideoPlayer` widget from `lib/data/functions.dart` or create muscle-specific wrapper
**Why**: Existing widget already implements `VideoPlayerController.asset()` with proper initialization and error handling
**Alternatives considered**:
- Creating entirely new widget (code duplication)
- Modifying existing widget (may affect other usages)

### Decision: Muscle-to-File Mapping Strategy
**What**: Create mapping in `muscle_video_mapping.dart` that maps muscle names to local asset paths
**Why**: Centralized mapping logic, easy to maintain and extend, consistent with existing architecture
**Alternatives considered**:
- Hardcoded paths in widget (less maintainable)
- Configuration file (unnecessary complexity for static mapping)

### Decision: Fallback Strategy
**What**: Default to `deltoids_chest.mp4` when muscle-specific video is unavailable
**Why**: Ensures video always displays, provides reasonable default content
**Alternatives considered**:
- Show error message only (poor UX)
- Random video selection (inconsistent experience)

## Implementation Approach

1. **Phase 1: Remove YouTube Dependencies**
   - Remove `youtube_player_iframe` from pubspec.yaml
   - Remove YouTube-related imports and code
   - Clean up unused YouTube mapping logic

2. **Phase 2: Implement Local Mapping**
   - Update `muscle_video_mapping.dart` to return local asset paths
   - Create muscle-to-file mapping with fallback logic

3. **Phase 3: Create/Update Video Player**
   - Reuse or enhance `LocalVideoPlayer` widget
   - Ensure proper initialization, error handling, and disposal

4. **Phase 4: Update c_video.dart**
   - Replace YouTube player widget with local video player
   - Update video section to use local files
   - Remove YouTube-specific error handling

5. **Phase 5: Testing**
   - Test all muscle mappings
   - Verify error handling
   - Test on Android and iOS
   - Verify offline functionality

## Technical Considerations

### Video File Paths
All videos are stored in `assets/videos/` and declared in `pubspec.yaml`:
- `deltoids_chest.mp4`
- `triceps.mp4`
- `biceps.mp4`
- `quadriceps.mp4`
- `trunk.mp4`
- `hamstrings_gluteals.mp4`

### Asset Loading
Use `VideoPlayerController.asset()` for loading local videos:
```dart
VideoPlayerController.asset('assets/videos/deltoids_chest.mp4')
```

### Error Handling
- Catch initialization errors
- Display user-friendly error messages
- Fallback to default video if muscle-specific video fails
- Ensure UI remains functional even if video fails

### State Management
- Properly dispose video controllers on widget disposal
- Pause videos when navigating away
- Handle widget lifecycle correctly to prevent memory leaks

