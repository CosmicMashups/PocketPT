## Why
The current YouTube Shorts video player in the ROM assessment flow experiences persistent incompatibility and iframe loading issues, resulting in "Video unavailable" errors and black screens. These issues create a poor user experience and prevent reliable video playback. Additionally, YouTube dependency introduces network requirements and potential embedding restrictions. The application already has all necessary exercise demonstration videos stored locally in `assets/videos/`, making a fully local video playback solution the optimal approach for reliability and offline support.

## What Changes
- Remove all YouTube player dependencies, widgets, controllers, and initialization logic
- Replace YouTube video system with local video player using the existing `video_player` package
- Implement muscle-to-local-video file mapping system
- Update `c_video.dart` to use local video playback instead of YouTube
- Remove `youtube_player_iframe` package dependency
- Ensure proper error handling and fallback UI for missing or corrupted video files
- Maintain smooth video loading, correct aspect ratio, and stable state management

## Impact
- Affected specs: `media-capture` capability
- Affected code: 
  - `lib/assessment/c_video.dart` - Replace YouTube player with local video player
  - `lib/assessment/dynamic_video_player.dart` - Remove or replace with local video player
  - `lib/assessment/muscle_video_mapping.dart` - Replace URL mapping with local file path mapping
  - `pubspec.yaml` - Remove `youtube_player_iframe` dependency
- Dependencies: Remove `youtube_player_iframe` package (already have `video_player: ^2.7.0`)
- User Experience: Reliable, offline-capable video playback without network dependencies or embedding issues

