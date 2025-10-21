## Why

The pose skeleton overlay in `c_camera.dart` currently experiences alignment issues, scaling errors, and performance problems that affect the accuracy and usability of ROM assessments. The overlay either displays misaligned skeletons, lags during real-time updates, or fails to render landmarks correctly due to improper coordinate normalization and inefficient state management.

## What Changes

- **BREAKING**: Fix coordinate normalization between camera preview and skeleton overlay
- **BREAKING**: Improve landmark synchronization and state management
- **BREAKING**: Optimize CustomPainter performance and repaint logic
- **BREAKING**: Fix overlay positioning and aspect ratio handling
- **BREAKING**: Enhance error handling and null safety for landmark data
- **BREAKING**: Improve toggle behavior and skeleton visibility controls

## Impact

- Affected specs: pose-visualization
- Affected code: lib/assessment/c_camera.dart, lib/widgets/enhanced_pose_skeleton_painter.dart, lib/data/pose_detection_service.dart
- Improves overlay accuracy and rendering stability
- Ensures proper scaling across devices and orientations
- Aligns camera data flow with pose painter expectations
- Fixes toggling and landmark visibility issues
