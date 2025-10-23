## Context

The AROM assessment camera flow currently performs pose detection and ROM measurement but lacks real-time pain recognition. The existing `FacialPainRecognitionService` is available but not integrated into the assessment workflow. Users must manually report pain levels in a separate step, which may not accurately reflect pain experienced during ROM movements.

The assessment flow currently follows: Camera → Video Recording → Video Preview → Pain Level Input. This proposal modifies the flow to: Camera (with pain detection) → Pain Level Confirmation → Pain Level Input.

## Goals / Non-Goals

### Goals
- Integrate real-time pain recognition during AROM assessment
- Provide immediate pain intervention for moderate/severe pain detection
- Maintain pose detection and pain recognition simultaneously during recording
- Streamline assessment flow by eliminating video preview step
- Ensure accurate pain level capture during actual ROM movement

### Non-Goals
- Replacing manual pain level input (still needed for validation)
- Modifying the underlying pain recognition model architecture
- Changing the pose detection algorithms or ROM measurement logic
- Implementing new pain recognition models (use existing service)

## Decisions

### Decision: Integrate existing FacialPainRecognitionService
- **Rationale**: Service already exists and is tested in exercise recording context
- **Alternatives considered**: Creating new assessment-specific pain service
- **Trade-off**: Reuse existing service vs. creating assessment-optimized service

### Decision: Maintain simultaneous pose and pain detection
- **Rationale**: Both are needed for comprehensive assessment
- **Alternatives considered**: Sequential detection (pose first, then pain)
- **Trade-off**: Performance impact vs. assessment completeness

### Decision: Bypass video preview step
- **Rationale**: Pain detection provides real-time feedback, making video review redundant
- **Alternatives considered**: Keep video preview with pain detection overlay
- **Trade-off**: User experience vs. assessment efficiency

### Decision: 3-second position hold for fallback pain detection
- **Rationale**: Provides alternative when face detection fails
- **Alternatives considered**: Skip pain detection entirely, manual input only
- **Trade-off**: Assessment accuracy vs. user experience

## Risks / Trade-offs

### Performance Impact
- **Risk**: Simultaneous pose + pain detection may impact camera performance
- **Mitigation**: Frame rate limiting (5 FPS for pain detection), performance monitoring

### Face Detection Reliability
- **Risk**: Pain detection may fail if face not visible during ROM movement
- **Mitigation**: Fallback to position-based pain determination, manual override option

### User Experience
- **Risk**: Additional dialogs may interrupt assessment flow
- **Mitigation**: Non-intrusive pain indicators, optional pain detection toggle

### Assessment Accuracy
- **Risk**: Automated pain detection may not match user's subjective experience
- **Mitigation**: Confirmation dialog allows user to override detected pain level

## Migration Plan

### Phase 1: Service Integration
1. Import `FacialPainRecognitionService` into `c_camera.dart`
2. Add pain detection state management
3. Integrate with existing camera image stream

### Phase 2: UI Implementation
1. Add pain detection status indicators
2. Implement pain confirmation dialogs
3. Create pain level display components

### Phase 3: Flow Modification
1. Modify recording behavior to maintain pain detection
2. Implement pain level confirmation dialog
3. Update navigation to bypass video preview

### Phase 4: Testing and Validation
1. Unit tests for service integration
2. Integration tests for assessment flow
3. User acceptance testing

## Open Questions

- Should pain detection be enabled by default or opt-in?
- How should we handle pain detection failures during critical ROM movements?
- Should we store pain detection confidence scores for assessment analytics?
- How to handle users who prefer manual pain reporting over automated detection?
