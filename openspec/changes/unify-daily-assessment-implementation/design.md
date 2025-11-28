# Design: Unify Daily Assessment Implementation

## Context

The daily assessment flow (`lib/dailyAssessment/`) and the main assessment flow (`lib/assessment/`) currently have separate implementations for camera assessment and instruction video pages. While they share similar functionality, there are implementation differences that create inconsistencies in user experience and increase maintenance burden.

## Goals

- Ensure `cameraPose.dart` has identical implementation to `c_camera.dart`
- Ensure `instructionVideo.dart` has identical implementation to `c_video.dart`
- Ensure helper codes from `arom/`, `muscle_video_mapping.dart`, and `local_muscle_video_player.dart` are properly incorporated
- Maintain appropriate navigation flow differences (daily assessment is simplified: Instruction → Camera → Pain Level)

## Non-Goals

- Changing the navigation flow structure (daily assessment remains simplified)
- Removing legitimate context-specific differences (e.g., different navigation targets)
- Creating shared base classes (keep implementations identical but separate)

## Decisions

### Decision: Identical Implementation Approach
**What**: Make `cameraPose.dart` and `instructionVideo.dart` have identical implementations to their assessment counterparts, with only navigation target differences.

**Why**: 
- Ensures feature parity automatically
- Reduces maintenance burden
- Provides consistent user experience
- Makes it easier to apply improvements to both flows

**Alternatives Considered**:
- Shared base classes: Rejected because it adds complexity and may not be necessary if implementations are truly identical
- Keeping differences: Rejected because it creates maintenance burden and inconsistent UX

### Decision: Helper Code Sharing
**What**: Both flows use the same helper code from `lib/assessment/arom/`, `lib/assessment/muscle_video_mapping.dart`, and `lib/assessment/local_muscle_video_player.dart`.

**Why**:
- Single source of truth for assessment logic
- Consistent behavior across flows
- Easier to maintain and update

**Alternatives Considered**:
- Duplicating helper code: Rejected because it creates maintenance burden
- Creating separate helper code: Rejected because functionality is identical

### Decision: Navigation Flow Preservation
**What**: Preserve the simplified daily assessment navigation flow (Instruction → Camera → Pain Level) while ensuring implementation details are identical.

**Why**:
- Daily assessment is intentionally simplified
- Navigation flow differences are legitimate context-specific differences
- Implementation details (UI, logic, error handling) should be identical

**Alternatives Considered**:
- Unifying navigation flows: Rejected because daily assessment is intentionally simplified
- Changing navigation targets: Rejected because each flow has appropriate targets

## Implementation Strategy

1. **Comparison Phase**: Line-by-line comparison to identify all differences
2. **Alignment Phase**: Update daily assessment files to match assessment files exactly
3. **Navigation Adjustment**: Adjust navigation targets to maintain daily assessment flow
4. **Helper Code Verification**: Ensure helper code usage is identical
5. **Testing Phase**: Comprehensive testing to ensure parity

## Risks / Trade-offs

- **Risk**: Navigation flow differences might be lost
  - **Mitigation**: Explicitly document and preserve navigation target differences

- **Risk**: Breaking changes if implementations are too different
  - **Mitigation**: Careful comparison and incremental alignment

- **Risk**: Performance impact from identical implementations
  - **Mitigation**: Both implementations are already similar, minimal risk

## Migration Plan

1. Complete analysis and comparison
2. Align `instructionVideo.dart` with `c_video.dart`
3. Align `cameraPose.dart` with `c_camera.dart`
4. Verify helper code integration
5. Test both flows thoroughly
6. Update documentation

## Open Questions

- Are there any legitimate differences that should be preserved beyond navigation targets?
- Should we create shared constants or utilities if patterns emerge?

