## Context

The pose skeleton overlay in PocketPT's camera assessment system currently has several critical issues that affect the accuracy and usability of ROM assessments. The overlay system consists of three main components: PoseDetectionService (landmark detection), EnhancedPoseSkeletonPainter (visualization), and c_camera.dart (integration and state management).

## Goals / Non-Goals

### Goals
- Fix coordinate normalization between camera preview and skeleton overlay
- Ensure real-time synchronization of landmark data
- Optimize rendering performance to maintain 8-12 FPS target
- Improve error handling and null safety
- Maintain consistent behavior across front and rear cameras

### Non-Goals
- Changing the core pose detection algorithm
- Modifying the assessment logic or pain scoring
- Adding new visualization features beyond fixing existing issues
- Changing the overall UI layout or camera assessment flow

## Decisions

### Decision: Fix coordinate normalization in PoseDetectionService
- **What**: Ensure landmarks are properly normalized to 0.0-1.0 range and mirrored for front camera
- **Why**: Current implementation has inconsistent coordinate mapping causing misalignment
- **Alternatives considered**: Fixing in painter (rejected - violates separation of concerns)

### Decision: Optimize shouldRepaint logic in EnhancedPoseSkeletonPainter
- **What**: Implement efficient comparison of landmark data to prevent unnecessary repaints
- **Why**: Current implementation causes performance issues and UI lag
- **Alternatives considered**: Using ValueNotifier (rejected - adds complexity without clear benefit)

### Decision: Improve landmark synchronization in c_camera.dart
- **What**: Update landmarks regardless of skeleton toggle state and implement proper state management
- **Why**: Current implementation only updates landmarks when skeleton is visible, causing stale data
- **Alternatives considered**: Separate landmark state (rejected - adds unnecessary complexity)

## Risks / Trade-offs

- **Risk**: Performance degradation from more frequent landmark updates
  - **Mitigation**: Implement proper throttling and efficient shouldRepaint logic
- **Risk**: Breaking existing assessment functionality
  - **Mitigation**: Maintain backward compatibility and thorough testing
- **Risk**: Increased memory usage from landmark caching
  - **Mitigation**: Use efficient data structures and proper cleanup

## Migration Plan

1. Update PoseDetectionService coordinate normalization
2. Fix landmark synchronization in c_camera.dart
3. Optimize EnhancedPoseSkeletonPainter performance
4. Test across different devices and orientations
5. Validate assessment accuracy remains unchanged

## Open Questions

- Should we implement landmark confidence filtering to improve accuracy?
- Is there a need for different visualization modes beyond the current skeleton overlay?
