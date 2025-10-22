## Why
The current ROM assessment video system uses static local videos that don't adapt to the user's selected muscle. This limits the instructional value and creates a generic experience that doesn't provide muscle-specific guidance. Users need dynamic, muscle-specific instructional videos that change based on their assessment focus to provide relevant ROM assessment instructions.

## What Changes
- Replace static local video player with dynamic YouTube video system
- Add muscle-to-video mapping system for all assessment muscles
- Implement YouTube video player with loading states and error handling
- Add fallback mechanisms for missing videos or network issues
- Integrate dynamic video selection with existing assessment data flow

## Impact
- Affected specs: assessment-flow, media-capture capabilities
- Affected code: lib/assessment/c_video.dart, new muscle_video_mapping.dart, new dynamic_video_player.dart
- Dependencies: Add youtube_player_iframe package to pubspec.yaml
- User Experience: Muscle-specific instructional videos improve assessment guidance
