## Context

The exercise recording flow currently uses a camera service to record exercises but lacks pain detection capabilities. The app has a trained 3-class pain recognition model that can detect Low/Moderate/Severe pain levels, but it's not integrated into the recording workflow. This creates a safety gap where users may experience pain during exercises without the app detecting or responding to it.

## Goals / Non-Goals

### Goals
- Integrate real-time pain detection into exercise recording
- Provide appropriate user feedback based on pain levels
- Maintain smooth exercise flow while ensuring user safety
- Use existing camera infrastructure for pain detection
- Implement progressive intervention (info → warning → dialog)

### Non-Goals
- Replace existing exercise recording functionality
- Implement complex pain analysis beyond the 3-class model
- Add pain detection to other app flows (assessment, etc.)
- Modify the underlying pain recognition model

## Decisions

### Decision: Pain Detection Integration Architecture
- **What**: Integrate pain detection as a background service during exercise recording
- **Why**: Maintains existing recording flow while adding safety layer
- **Alternatives considered**: 
  - Separate pain detection mode (rejected - adds complexity)
  - Post-exercise pain analysis (rejected - too late for safety)

### Decision: Progressive Intervention System
- **What**: Three-tier response system based on pain levels
- **Why**: Provides appropriate escalation without being overly intrusive
- **Implementation**:
  - Low pain: Ignore (no intervention needed)
  - Moderate pain: Show info banner with rest recommendation
  - Severe pain: Show dialog with continue/rest options

### Decision: Camera Service Integration
- **What**: Extend existing camera service to support pain detection
- **Why**: Leverages existing camera infrastructure and maintains consistency
- **Alternatives considered**: 
  - Separate pain detection camera (rejected - resource intensive)
  - Post-processing analysis (rejected - not real-time)

## Risks / Trade-offs

### Risk: Performance Impact
- **Mitigation**: Implement frame rate limiting and background processing
- **Trade-off**: Slight performance cost for significant safety benefit

### Risk: False Positives
- **Mitigation**: Confidence thresholds and user override options
- **Trade-off**: Some false alarms vs. missing real pain

### Risk: User Experience Disruption
- **Mitigation**: Non-blocking notifications and user control
- **Trade-off**: Occasional interruption vs. safety protection

## Migration Plan

1. **Phase 1**: Integrate pain detection service with camera
2. **Phase 2**: Add UI components for pain feedback
3. **Phase 3**: Implement intervention logic
4. **Phase 4**: Testing and refinement
5. **Phase 5**: Deployment with feature flags

## Open Questions

- Should pain detection be optional or always-on during recording?
- What confidence threshold should trigger interventions?
- How should pain detection integrate with existing exercise validation?
