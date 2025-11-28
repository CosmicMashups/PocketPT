# Tasks: Align Daily Assessment Camera

## 1. Preparation and Analysis

- [x] 1.1 Review `lib/assessment/c_camera.dart` implementation details
- [x] 1.2 Review `lib/dailyAssessment/cameraPose.dart` current implementation
- [x] 1.3 Identify UI/UX patterns to adopt from `c_camera.dart`
- [x] 1.4 Identify pain detection integration points
- [x] 1.5 Document differences between current and target implementation

## 2. Pain Recognition Model Integration

- [x] 2.1 Add `FacialPainRecognitionService` import to `cameraPose.dart`
- [x] 2.2 Initialize pain recognition service in `initState()`
- [x] 2.3 Add pain recognition state variables (pain level, confidence, etc.)
- [x] 2.4 Integrate pain recognition processing in image stream callback
- [x] 2.5 Add pain recognition throttling (5 FPS limit)
- [x] 2.6 Store facial pain recognition results separately from AROM assessment
- [x] 2.7 Add error handling for pain recognition failures
- [x] 2.8 Dispose pain recognition service in `dispose()`

## 3. Pose Estimation Model Integration

- [x] 3.1 Verify `CustomPoseDetectionService` is properly initialized
- [x] 3.2 Ensure pose estimation model processes frames for AROM assessment
- [x] 3.3 Verify keypoint-to-landmark conversion works correctly
- [x] 3.4 Ensure pose estimation runs at appropriate frame rate for AROM
- [x] 3.5 Add error handling for pose estimation failures
- [x] 3.6 Ensure pose estimation works alongside pain recognition without interference

## 4. AROM Assessment Alignment

- [x] 4.1 Verify `AssessmentService` import and usage is present
- [x] 4.2 Verify `_getAssessmentMode()` method correctly maps UserAssess.specificMuscle
- [x] 4.3 Ensure muscle-to-algorithm mapping aligns with AROM assessment service
- [x] 4.4 Verify AROM assessment is called with correct muscle group and side
- [x] 4.5 Store AROM assessment results (AssessmentResult) separately
- [x] 4.6 Ensure AROM assessment provides pain scores based on ROM
- [x] 4.7 Add error handling for AROM assessment failures
- [x] 4.8 Update comments to reflect dual-model assessment approach

## 5. Dual Model Coordination

- [x] 5.1 Implement logic to combine AROM pain scores with facial pain recognition
- [x] 5.2 Determine strategy for combining pain scores (average, max, weighted)
- [x] 5.3 Update `UserAssess.painScale` and `UserAssess.painLevel` from combined results
- [x] 5.4 Ensure both models can work independently if one fails
- [x] 5.5 Add UI indicators showing which model provided which data
- [ ] 5.6 Test coordination between both models

## 6. UI/UX Alignment

- [x] 6.1 Adopt camera preview layout from `c_camera.dart`
- [x] 6.2 Add pain detection status overlay (top-left)
- [x] 6.3 Add instructions button (top-right)
- [x] 6.4 Add status indicators (LIVE, SKELETON, PAIN level)
- [x] 6.5 Add assessment results panel (simplified for pain only)
- [x] 6.6 Improve camera controls menu structure
- [x] 6.7 Add camera switching functionality
- [x] 6.8 Add side selection (Left/Right) if applicable

## 7. Skeleton Overlay Enhancement

- [x] 7.1 Add `SkeletonOverlayConfig` state management
- [x] 7.2 Integrate `CustomPoseSkeletonPainter` with configuration
- [x] 7.3 Add skeleton toggle in camera settings menu
- [x] 7.4 Add skeleton configuration dialog
- [x] 7.5 Add skeleton settings (stroke width, point radius, labels)
- [x] 7.6 Ensure skeleton overlay works with camera switching

## 8. Pain Level Feedback

- [x] 8.1 Add pain level overlay with color coding
- [x] 8.2 Add pain level animations (fade, scale transitions)
- [x] 8.3 Add pain color helper methods
- [x] 8.4 Add pain icon helper methods
- [x] 8.5 Add moderate pain banner (optional, user-configurable)
- [x] 8.6 Add severe pain dialog (optional, user-configurable)
- [x] 8.7 Add user preferences for pain feedback

## 9. Animation Integration

- [x] 9.1 Add animation controllers for pain feedback
- [x] 9.2 Add fade animations for pain overlay
- [x] 9.3 Add scale animations for pain level changes
- [x] 9.4 Add color transition animations
- [x] 9.5 Integrate with `PocketPTAnimations` utilities
- [x] 9.6 Ensure animations respect user preferences

## 10. Camera Controls Enhancement

- [x] 10.1 Improve camera settings menu structure
- [x] 10.2 Add skeleton overlay toggle
- [x] 10.3 Add skeleton configuration option
- [x] 10.4 Add camera switching option
- [x] 10.5 Add side selection option (if applicable)
- [x] 10.6 Add help/instructions option
- [x] 10.7 Ensure menu matches `c_camera.dart` style

## 11. Code Cleanup and Optimization

- [x] 11.1 Remove unused ROM assessment code
- [x] 11.2 Remove unused angle calculation methods
- [x] 11.3 Optimize image stream processing
- [x] 11.4 Add proper error handling throughout
- [x] 11.5 Add debug logging for troubleshooting
- [x] 11.6 Ensure proper resource disposal
- [x] 11.7 Update code comments and documentation

## 12. Testing and Validation

- [ ] 12.1 Test pain recognition model integration
- [ ] 12.2 Test pose estimation model integration
- [ ] 12.3 Test AROM assessment alignment with specificMuscle
- [ ] 12.4 Test dual model coordination and combination logic
- [ ] 12.5 Test skeleton overlay functionality
- [ ] 12.6 Test camera switching
- [ ] 12.7 Test pain level updates from both models
- [ ] 12.8 Test navigation flow (Instruction → Camera → Pain Level)
- [ ] 12.9 Test error handling scenarios (one model fails, both fail)
- [ ] 12.10 Test performance on low-end devices with dual models
- [ ] 12.11 Verify UI matches `c_camera.dart` patterns
- [ ] 12.12 Test with different pain levels from both models
- [ ] 12.13 Validate pain data persistence
- [ ] 12.14 Test muscle-specific assessment alignment

## 13. Documentation

- [ ] 13.1 Update code comments in `cameraPose.dart`
- [ ] 13.2 Document pain recognition model integration
- [ ] 13.3 Document pose estimation model integration
- [ ] 13.4 Document AROM assessment alignment with specificMuscle
- [ ] 13.5 Document dual model coordination and combination strategy
- [ ] 13.6 Document skeleton overlay configuration
- [ ] 13.7 Update any relevant README files
- [ ] 13.8 Document user preferences for pain feedback

