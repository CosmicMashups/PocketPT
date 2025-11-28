# Unify Daily Assessment Implementation with Assessment Flow

## Why

The daily assessment flow (`lib/dailyAssessment/`) currently has separate implementations that differ from the main assessment flow (`lib/assessment/`), creating inconsistencies in user experience, code maintenance burden, and potential feature gaps. By ensuring complete implementation parity between `cameraPose.dart` and `c_camera.dart`, and between `instructionVideo.dart` and `c_video.dart`, we ensure:

1. **Consistent User Experience**: Users receive identical functionality and UI/UX in both assessment flows
2. **Code Maintainability**: Single source of truth reduces duplication and maintenance overhead
3. **Feature Parity**: Daily assessment benefits from all improvements made to the main assessment flow
4. **Shared Helper Code**: AROM assessment services, video mapping, and video player are properly incorporated in both flows
5. **Reduced Bugs**: Identical implementations reduce the chance of bugs appearing in one flow but not the other

## What Changes

- **BREAKING**: Ensure `lib/dailyAssessment/cameraPose.dart` has identical implementation to `lib/assessment/c_camera.dart`
- **BREAKING**: Ensure `lib/dailyAssessment/instructionVideo.dart` has identical implementation to `lib/assessment/c_video.dart`
- Ensure all helper codes from `lib/assessment/arom/` are properly incorporated in daily assessment
- Ensure `lib/assessment/muscle_video_mapping.dart` and `lib/assessment/local_muscle_video_player.dart` are used consistently in both flows
- Align navigation flows, error handling, state management, and UI components
- Ensure both flows use the same AROM assessment service integration patterns
- Ensure both flows use the same video player and mapping systems

## Impact

- Affected specs: daily-pain-assessment, assessment-flow, media-capture capabilities
- Affected code: 
  - `lib/dailyAssessment/cameraPose.dart` (align with `lib/assessment/c_camera.dart`)
  - `lib/dailyAssessment/instructionVideo.dart` (align with `lib/assessment/c_video.dart`)
  - Helper code sharing: `lib/assessment/arom/`, `lib/assessment/muscle_video_mapping.dart`, `lib/assessment/local_muscle_video_player.dart`
- Dependencies: No new dependencies required
- User Experience: Consistent experience across assessment and daily assessment flows
- Maintenance: Reduced code duplication and maintenance burden

