## 1. Remove YouTube Dependencies
- [x] 1.1 Remove `youtube_player_iframe` package from `pubspec.yaml`
- [x] 1.2 Remove all YouTube-related imports from `lib/assessment/c_video.dart`
- [x] 1.3 Remove or deprecate `lib/assessment/dynamic_video_player.dart` (YouTube-specific implementation)
- [x] 1.4 Remove YouTube URL mapping logic from `lib/assessment/muscle_video_mapping.dart`

## 2. Implement Local Video Mapping
- [x] 2.1 Create or update `muscle_video_mapping.dart` to map muscle names to local asset paths
- [x] 2.2 Implement mapping for all muscle groups:
  - Deltoids, Chest → `assets/videos/deltoids_chest.mp4`
  - Triceps → `assets/videos/triceps.mp4`
  - Biceps → `assets/videos/biceps.mp4`
  - Quadriceps → `assets/videos/quadriceps.mp4`
  - Abdominals, Obliques, Lower Back, Multifidus → `assets/videos/trunk.mp4`
  - Gluteals, Hamstrings, Calf → `assets/videos/hamstrings_gluteals.mp4`
- [x] 2.3 Add fallback mechanism for unmapped muscles (default to deltoids_chest.mp4)

## 3. Create Local Video Player Widget
- [x] 3.1 Create `LocalMuscleVideoPlayer` widget in `lib/assessment/` or reuse existing `LocalVideoPlayer` from `lib/data/functions.dart`
- [x] 3.2 Implement `VideoPlayerController.asset()` initialization
- [x] 3.3 Add proper loading states and error handling
- [x] 3.4 Ensure correct aspect ratio handling (16:9 or video-native)
- [x] 3.5 Implement proper disposal and state management

## 4. Update c_video.dart
- [x] 4.1 Replace `MuscleVideoPlayer` (YouTube-based) with local video player widget
- [x] 4.2 Update `_buildVideoSection()` to use local video player
- [x] 4.3 Ensure muscle selection correctly maps to local video file
- [x] 4.4 Remove all YouTube-related error handling and retry logic
- [x] 4.5 Add fallback UI for missing or corrupted video files

## 5. Error Handling and Fallbacks
- [x] 5.1 Implement error handling for missing video files
- [x] 5.2 Add user-friendly error messages for corrupted videos
- [x] 5.3 Implement fallback to default video (deltoids_chest.mp4) when muscle-specific video is unavailable
- [x] 5.4 Ensure graceful degradation if video fails to load

## 6. Testing and Validation
- [x] 6.1 Test video playback for all muscle groups
- [x] 6.2 Verify correct aspect ratio display for all videos
- [x] 6.3 Test error handling with missing/corrupted files
- [x] 6.4 Verify smooth playback on Android and iOS
- [x] 6.5 Test navigation state management (ensure videos pause/dispose correctly)
- [x] 6.6 Run `flutter analyze` to ensure no linting errors
- [x] 6.7 Verify offline functionality (no network required)
