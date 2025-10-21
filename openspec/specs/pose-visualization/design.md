# Pose Visualization Design

## Architecture

The pose visualization system consists of three main components:

1. **EnhancedPoseSkeletonPainter** - Custom painter for rendering pose landmarks
2. **SkeletonOverlayConfig** - Configuration class for appearance customization
3. **Camera Integration** - Integration with camera assessment UI

## Technical Decisions

### CustomPainter Implementation
- **Decision**: Use CustomPainter for skeleton rendering
- **Rationale**: Provides optimal performance and full control over rendering
- **Alternatives**: Canvas API, third-party visualization libraries

### Color-Coded Visualization
- **Decision**: Color-coded body parts for better visualization
- **Rationale**: Improves user experience and landmark identification
- **Alternatives**: Single color, confidence-based coloring

## Performance Characteristics

- **Target FPS**: ~8 FPS during pose detection
- **Memory Usage**: ~1KB per landmark set
- **Optimization**: shouldRepaint() prevents unnecessary repaints

## Integration Patterns

### Camera Assessment Integration
```dart
// State management
bool _showSkeleton = false;
Map<String, Offset>? _currentLandmarks;
SkeletonOverlayConfig _skeletonConfig = const SkeletonOverlayConfig();

// Rendering
CustomPaint(
  painter: EnhancedPoseSkeletonPainter(
    landmarks: _currentLandmarks!,
    showLandmarkLabels: _skeletonConfig.showLandmarkLabels,
    strokeWidth: _skeletonConfig.strokeWidth,
    pointRadius: _skeletonConfig.pointRadius,
  ),
  size: Size(constraints.maxWidth, constraints.maxHeight),
)
```

## Color Scheme

- **Head**: Blue violet (#8A2BE2)
- **Torso**: Bright blue (#00BFFF)
- **Arms**: Bright green (#00FF00)
- **Legs**: Bright orange (#FF8C00)
- **Points**: Bright red (#FF0000) with white outlines
