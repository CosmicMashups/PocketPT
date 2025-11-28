# Align Daily Assessment Camera with Assessment Camera

## Summary

Align the daily assessment camera implementation (`lib/dailyAssessment/cameraPose.dart`) with the full assessment camera (`lib/assessment/c_camera.dart`), integrating both pain recognition and pose estimation models while maintaining alignment with the user's specificMuscle and AROM assessment system.

## Why

The daily assessment camera currently has a simpler, less polished implementation compared to the full assessment camera. This creates an inconsistent user experience and misses opportunities to leverage improved UI/UX patterns and pain detection capabilities. By aligning the implementations while keeping the daily assessment focused on its core purpose (pain level assessment), we provide:

1. **Consistent User Experience**: Users get the same polished interface and controls in both assessment flows
2. **Enhanced Pain Detection**: Automatic facial pain recognition improves assessment accuracy
3. **Comprehensive Assessment**: Both pose estimation (AROM) and facial pain recognition work together for comprehensive pain assessment
4. **Muscle-Specific Alignment**: Assessment aligns with user's specificMuscle via AROM assessment service
5. **Better Visual Feedback**: Improved status indicators and pain level displays enhance user awareness
6. **Maintainability**: Shared patterns reduce code duplication and maintenance burden

## Motivation

Currently, the daily assessment camera page has a simpler implementation compared to the full assessment camera. To provide a consistent user experience and leverage the improved UI/UX patterns from the full assessment camera, we should align the daily assessment flow while keeping it focused on its core purpose: pain level assessment.

## Scope

### In Scope
- Align UI/UX patterns from `c_camera.dart` to `cameraPose.dart`
- Integrate facial pain recognition service (FacialPainRecognitionService)
- Maintain pose estimation model (CustomPoseDetectionService) for AROM assessment
- Keep AROM assessment alignment with user's specificMuscle via AssessmentService
- Combine AROM-based pain scores with facial pain recognition for comprehensive assessment
- Keep instruction video page functionality
- Preserve pain level assessment focus
- Add skeleton overlay with configuration options
- Improve camera controls and settings
- Add pain detection status indicators
- Maintain real-time pain level updates

### Out of Scope
- Video recording functionality
- Complex assessment result panels with detailed ROM metrics
- Assessment result confirmation dialogs (keep simple pain level flow)

## Key Changes

1. **UI/UX Alignment**: Adopt the improved layout, status indicators, and controls from `c_camera.dart`
2. **Pain Recognition Model Integration**: Add facial pain recognition service (FacialPainRecognitionService)
3. **Pose Estimation Model Integration**: Ensure pose estimation model (CustomPoseDetectionService) is properly integrated
4. **AROM Assessment Alignment**: Maintain AROM assessment via AssessmentService aligned with user's specificMuscle
5. **Dual Model Assessment**: Combine AROM-based pain scores with facial pain recognition for comprehensive pain assessment
6. **Skeleton Overlay**: Add configurable skeleton overlay matching `c_camera.dart`
7. **Camera Controls**: Improve camera switching and settings menu
8. **Pain Feedback**: Add visual pain level indicators and animations

## Success Criteria

- Daily assessment camera page matches `c_camera.dart` UI/UX patterns
- Facial pain recognition model works in daily assessment flow
- Pose estimation model works for AROM assessment aligned with specificMuscle
- AROM assessment service correctly maps user's specificMuscle to appropriate assessment algorithm
- Pain level is accurately detected and displayed from both models
- AROM-based pain scores and facial pain recognition are combined for comprehensive assessment
- Skeleton overlay is functional and configurable
- Instruction video page remains functional
- Flow focuses on pain assessment with dual-model support

## Dependencies

- `lib/data/facial_pain_recognition_service.dart` - Facial pain detection model
- `lib/data/custom_pose_detection_service.dart` - Pose estimation model
- `lib/assessment/arom/assessment_service.dart` - AROM assessment service for muscle-specific assessment
- `lib/assessment/arom/assessment_result.dart` - Assessment result structure
- `lib/widgets/custom_pose_skeleton_painter.dart` - Skeleton visualization
- `lib/core/animations.dart` - Animation utilities
- `lib/dailyAssessment/instructionVideo.dart` - Instruction page

## Risks

- Performance impact from dual model processing (pose estimation + pain recognition)
- UI complexity may increase (mitigated by keeping flow simple)
- Need to ensure both models work harmoniously without interference
- Need to properly combine AROM-based pain scores with facial pain recognition
- Ensure AROM assessment correctly aligns with user's specificMuscle selection

## Related Work

- Full assessment camera implementation (`lib/assessment/c_camera.dart`)
- Daily assessment flow (`lib/dailyAssessment/`)
- Pain recognition integration in assessment flow

