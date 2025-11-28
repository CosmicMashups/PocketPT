# Tasks: Unify Daily Assessment Implementation

## 1. Analysis and Comparison

- [x] 1.1 Compare `lib/dailyAssessment/cameraPose.dart` with `lib/assessment/c_camera.dart` line-by-line
- [x] 1.2 Compare `lib/dailyAssessment/instructionVideo.dart` with `lib/assessment/c_video.dart` line-by-line
- [x] 1.3 Document all differences in implementation, UI/UX, error handling, state management
- [x] 1.4 Verify helper code usage: check if `arom/` services are used identically in both flows
- [x] 1.5 Verify video player usage: check if `muscle_video_mapping.dart` and `local_muscle_video_player.dart` are used identically
- [x] 1.6 Identify navigation flow differences between assessment and daily assessment
- [x] 1.7 Document any legitimate differences that should be preserved (e.g., different navigation targets)

## 2. Camera Implementation Unification

- [x] 2.1 Align imports between `cameraPose.dart` and `c_camera.dart`
- [x] 2.2 Align state variables and initialization logic
- [x] 2.3 Align camera initialization and error handling
- [x] 2.4 Align image stream processing and throttling
- [x] 2.5 Align pose detection service integration
- [x] 2.6 Align pain recognition service integration
- [x] 2.7 Align AROM assessment service integration
- [x] 2.8 Align skeleton overlay implementation and configuration
- [ ] 2.9 Align UI layout, status indicators, and controls (build method - requires full review)
- [x] 2.10 Align camera switching and settings menu
- [x] 2.11 Align pain level feedback and animations
- [x] 2.12 Align disposal and cleanup logic
- [x] 2.13 Ensure navigation targets are appropriate for daily assessment context

## 3. Instruction Video Implementation Unification

- [x] 3.1 Align imports between `instructionVideo.dart` and `c_video.dart`
- [x] 3.2 Align state variables and initialization logic
- [x] 3.3 Align UI layout and styling
- [x] 3.4 Align video player integration (`LocalMuscleVideoPlayer`)
- [x] 3.5 Align muscle selection and fallback logic (`_getSelectedMuscle()`)
- [x] 3.6 Align video mapping usage (`MuscleVideoMapping`)
- [x] 3.7 Align progress section implementation
- [x] 3.8 Align question section implementation
- [x] 3.9 Align video section implementation
- [x] 3.10 Align action buttons and navigation
- [x] 3.11 Align skip button implementation
- [x] 3.12 Ensure navigation targets are appropriate for daily assessment context

## 4. Helper Code Integration Verification

- [x] 4.1 Verify `lib/assessment/arom/assessment_service.dart` is used identically in both flows
- [x] 4.2 Verify `lib/assessment/arom/assessment_result.dart` is used identically in both flows
- [x] 4.3 Verify all AROM assessment algorithms are accessible from daily assessment
- [x] 4.4 Verify `lib/assessment/muscle_video_mapping.dart` is used identically in both flows
- [x] 4.5 Verify `lib/assessment/local_muscle_video_player.dart` is used identically in both flows
- [x] 4.6 Ensure helper code imports are consistent
- [x] 4.7 Verify helper code error handling is consistent

## 5. Navigation Flow Alignment

- [x] 5.1 Document navigation flow differences between assessment and daily assessment
- [x] 5.2 Ensure daily assessment navigation maintains its simplified flow (Instruction → Camera → Pain Level)
- [x] 5.3 Ensure assessment navigation maintains its full flow
- [x] 5.4 Verify back button behavior is appropriate for each context
- [x] 5.5 Verify skip button behavior is appropriate for each context

**Note**: Daily assessment uses different navigation targets (InstructionVideoPage/PainLevelPage) vs assessment (AssessPainVideo/AssessPainLevel), which is a legitimate difference preserved.

## 6. Testing and Validation

- [ ] 6.1 Test daily assessment camera page matches assessment camera page functionality
- [ ] 6.2 Test daily assessment instruction video page matches assessment instruction video page
- [ ] 6.3 Test AROM assessment works identically in both flows
- [ ] 6.4 Test video player works identically in both flows
- [ ] 6.5 Test navigation flows work correctly in both contexts
- [ ] 6.6 Test error handling is consistent
- [ ] 6.7 Test state management is consistent
- [ ] 6.8 Test UI/UX is visually consistent
- [ ] 6.9 Test performance is similar in both flows
- [ ] 6.10 Test with different muscle selections
- [ ] 6.11 Test with different camera configurations
- [ ] 6.12 Test edge cases and error scenarios

## 7. Code Review and Cleanup

- [x] 7.1 Remove any duplicate code that can be shared (removed _combinePainScores, aligned with c_camera.dart approach)
- [x] 7.2 Ensure consistent code style and formatting
- [x] 7.3 Update comments and documentation
- [x] 7.4 Verify all imports are necessary and consistent (aligned imports, some unused warnings expected for code parity)
- [x] 7.5 Ensure proper error handling throughout
- [x] 7.6 Verify resource disposal is consistent

**Note**: Some linter warnings about unused imports/fields are expected - these are kept for code parity with c_camera.dart (dart:io, main.dart, video recording fields used in c_camera.dart's build method).

## 8. Documentation

- [x] 8.1 Document the unified implementation approach
- [x] 8.2 Document any legitimate differences that are preserved
- [x] 8.3 Update code comments to reflect unified implementation
- [x] 8.4 Document helper code usage patterns
- [ ] 8.5 Update any relevant README files (if needed)

**Implementation Summary**:
- Core functionality aligned: imports, camera initialization, image stream processing, AROM assessment, pain recognition, help dialog
- Helper code integration verified: both flows use `arom/` services, `muscle_video_mapping.dart`, and `local_muscle_video_player.dart` identically
- Navigation differences preserved: daily assessment uses InstructionVideoPage/PainLevelPage, assessment uses AssessPainVideo/AssessPainLevel
- Some linter warnings expected: unused imports/fields kept for code parity with c_camera.dart (used in build method for video recording UI)

