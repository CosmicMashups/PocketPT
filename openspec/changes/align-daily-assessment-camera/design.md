# Design: Align Daily Assessment Camera

## Architecture Overview

The daily assessment camera will adopt the UI/UX patterns and pain detection capabilities from `c_camera.dart` while maintaining a simplified flow focused on pain level assessment.

## Key Design Decisions

### 1. Pain Detection Integration

**Decision**: Integrate `FacialPainRecognitionService` into daily assessment camera.

**Rationale**: 
- Provides automatic pain level detection during camera assessment
- Aligns with full assessment camera capabilities
- Enhances user experience with real-time feedback

**Implementation**:
- Initialize pain detection service in `initState()`
- Process pain detection in image stream callback (throttled to 5 FPS)
- Display pain level indicators in UI overlay
- Update `UserAssess.painScale` and `UserAssess.painLevel` based on detection

### 2. AROM Assessment Integration

**Decision**: Keep `AssessmentService.assess()` calls aligned with user's specificMuscle.

**Rationale**:
- Daily assessment should align with user's selected muscle group
- AROM assessment provides pain scores based on range of motion
- Combines with facial pain recognition for comprehensive assessment
- Maintains consistency with full assessment flow

**Implementation**:
- Keep `AssessmentService` imports and usage
- Keep `_getAssessmentMode()` method to map UserAssess.specificMuscle to AROM algorithm
- Use pose estimation model (CustomPoseDetectionService) for AROM assessment
- Combine AROM-based pain scores with facial pain recognition results
- Display both assessment results in UI

### 3. UI/UX Alignment

**Decision**: Adopt layout, controls, and status indicators from `c_camera.dart`.

**Rationale**:
- Provides consistent user experience across assessment flows
- Leverages proven UI patterns
- Improves visual feedback and user guidance

**Implementation**:
- Adopt camera preview layout with status indicators
- Add pain detection overlay (top-left)
- Add instructions button (top-right)
- Add skeleton overlay with configuration
- Add assessment results panel (simplified for pain only)
- Improve camera controls menu

### 4. Skeleton Overlay Configuration

**Decision**: Add configurable skeleton overlay matching `c_camera.dart`.

**Rationale**:
- Provides visual feedback for pose detection
- Allows user customization
- Maintains consistency with full assessment

**Implementation**:
- Add `SkeletonOverlayConfig` state
- Add settings dialog for skeleton configuration
- Integrate `CustomPoseSkeletonPainter` with configuration
- Add toggle in camera settings menu

### 5. Pain Level Feedback

**Decision**: Add visual indicators and animations for detected pain levels.

**Rationale**:
- Provides immediate feedback to user
- Enhances user awareness of detected pain
- Aligns with full assessment camera patterns

**Implementation**:
- Add pain level overlay with color coding
- Add pain level animations (fade, scale)
- Add moderate pain banner (optional, user-configurable)
- Add severe pain dialog (optional, user-configurable)

### 6. Simplified Navigation Flow

**Decision**: Maintain simple flow: Instruction Video → Camera → Pain Level.

**Rationale**:
- Daily assessment should be quick and focused
- No need for complex confirmation dialogs
- Direct progression to pain level input

**Implementation**:
- Keep navigation to `PainLevelPage` after camera assessment
- Remove pain level confirmation dialog
- Direct update of pain values without intermediate dialogs

## Component Structure

```
lib/dailyAssessment/
├── instructionVideo.dart (unchanged)
├── cameraPose.dart (refactored)
│   ├── Camera initialization
│   ├── Pose estimation model (CustomPoseDetectionService)
│   │   ├── Keypoint detection
│   │   ├── Landmark conversion
│   │   └── AROM assessment via AssessmentService
│   ├── Pain recognition model (FacialPainRecognitionService)
│   │   ├── Facial pain detection
│   │   └── Pain level classification
│   ├── Dual model coordination
│   │   ├── Combine AROM and facial pain scores
│   │   └── Update UserAssess values
│   ├── Skeleton overlay (from pose estimation)
│   ├── Pain level indicators (from both models)
│   └── Camera controls
├── painLevel.dart (unchanged)
└── dailySummary.dart (unchanged)
```

## Data Flow

1. **Instruction Video Page**: User views instructions
2. **Camera Page**: 
   - Camera initializes
   - Pose estimation model starts (for AROM assessment and skeleton visualization)
   - Pain recognition model starts (for facial pain detection)
   - AROM assessment runs based on user's specificMuscle
   - Both models provide pain level data
   - Pain values are combined/computed from both sources
   - User sees real-time feedback
   - Pain values update continuously
3. **Pain Level Page**: User confirms or adjusts pain level
4. **Daily Summary**: Assessment complete

## Performance Considerations

- **Throttling**: Pain recognition limited to 5 FPS, pose estimation runs at higher rate for AROM
- **Frame Processing**: Pose estimation and pain recognition run in parallel
- **Model Coordination**: AROM assessment uses pose estimation results, pain recognition runs independently
- **UI Updates**: Batch state updates to minimize rebuilds
- **Memory Management**: Proper disposal of both model services and controllers

## Error Handling

- **Camera Initialization**: Graceful fallback if camera unavailable
- **Pain Recognition Model**: Continue without facial pain detection if service fails
- **Pose Estimation Model**: Continue without AROM assessment if pose detection fails
- **AROM Assessment**: Fallback to default pain score if assessment fails
- **Model Coordination**: If one model fails, continue with the other
- **User Feedback**: Clear error messages and recovery options

## Testing Strategy

- **Unit Tests**: Pain recognition service integration, pose estimation service integration
- **Integration Tests**: AROM assessment alignment with specificMuscle
- **Model Coordination Tests**: Both models working together
- **Widget Tests**: Camera page UI components
- **Integration Tests**: Full daily assessment flow
- **Performance Tests**: Dual model frame processing and UI responsiveness

