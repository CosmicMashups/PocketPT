# Pose Skeleton Overlay Documentation

## Overview

The pose skeleton overlay system provides real-time visualization of human pose landmarks using Google ML Kit Pose Detection. This system is integrated into the PocketPT assessment and exercise tracking features, enabling visual feedback during ROM assessments and form analysis.

## Architecture

### Core Components

1. **EnhancedPoseSkeletonPainter** (`lib/widgets/enhanced_pose_skeleton_painter.dart`)
   - Custom painter that renders 33 body landmarks with color-coded connections
   - Extends `CustomPainter` for optimal performance
   - Handles coordinate scaling and transformation

2. **SkeletonOverlayConfig** (`lib/widgets/enhanced_pose_skeleton_painter.dart`)
   - Configuration class for customizing appearance
   - Controls visibility, colors, stroke width, and point radius

3. **Camera Integration** (`lib/assessment/c_camera.dart`)
   - Integrates skeleton overlay with camera preview
   - Manages state and toggle functionality
   - Handles landmark data flow from pose detection service

## API Reference

### EnhancedPoseSkeletonPainter

#### Constructor
```dart
EnhancedPoseSkeletonPainter({
  required Map<String, Offset> landmarks,
  bool showLandmarkLabels = false,
  double strokeWidth = 4.0,
  double pointRadius = 6.0,
  bool showConfidence = false,
})
```

#### Parameters
- `landmarks`: Map of landmark names to normalized coordinates (0.0-1.0)
- `showLandmarkLabels`: Whether to display landmark names
- `strokeWidth`: Width of skeleton connection lines
- `pointRadius`: Radius of landmark points
- `showConfidence`: Whether to show confidence indicators (not implemented)

#### Key Methods
- `paint(Canvas canvas, Size size)`: Main rendering method
- `shouldRepaint(CustomPainter oldDelegate)`: Optimization for repaint decisions
- `_scaleLandmarks()`: Converts normalized coordinates to canvas coordinates
- `_drawSkeletonConnections()`: Renders body part connections
- `_drawLandmarkPoints()`: Renders individual landmarks

### SkeletonOverlayConfig

#### Constructor
```dart
SkeletonOverlayConfig({
  bool showSkeleton = true,
  bool showLandmarkLabels = false,
  double strokeWidth = 4.0,
  double pointRadius = 6.0,
  bool showConfidence = false,
  Color? customColor,
})
```

#### Methods
- `copyWith()`: Creates a copy with modified parameters

## Color Scheme

The skeleton overlay uses a color-coded system for different body parts:

- **Head**: Blue violet (#8A2BE2)
- **Torso**: Bright blue (#00BFFF)
- **Arms**: Bright green (#00FF00)
- **Legs**: Bright orange (#FF8C00)
- **Points**: Bright red (#FF0000) with white outlines

## Landmark Mapping

The system renders 33 body landmarks from Google ML Kit:

### Head and Face
- `nose`, `leftEye`, `rightEye`, `leftEar`, `rightEar`

### Upper Body
- `leftShoulder`, `rightShoulder`
- `leftElbow`, `rightElbow`
- `leftWrist`, `rightWrist`
- `leftThumb`, `rightThumb`
- `leftIndex`, `rightIndex`
- `leftPinky`, `rightPinky`

### Lower Body
- `leftHip`, `rightHip`
- `leftKnee`, `rightKnee`
- `leftAnkle`, `rightAnkle`
- `leftHeel`, `rightHeel`
- `leftFootIndex`, `rightFootIndex`

## Integration Pattern

### Camera Assessment Integration

```dart
// State management
bool _showSkeleton = false;
Map<String, Offset>? _currentLandmarks;
SkeletonOverlayConfig _skeletonConfig = const SkeletonOverlayConfig();

// Toggle mechanism
Switch(
  value: _showSkeleton,
  onChanged: (val) => setState(() {
    _showSkeleton = val;
    if (!val) _currentLandmarks = null;
  }),
)

// Rendering
if (_showSkeleton && _currentLandmarks != null)
  Positioned.fill(
    child: IgnorePointer(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return CustomPaint(
                painter: EnhancedPoseSkeletonPainter(
                  landmarks: _currentLandmarks!,
                  showLandmarkLabels: _skeletonConfig.showLandmarkLabels,
                  strokeWidth: _skeletonConfig.strokeWidth,
                  pointRadius: _skeletonConfig.pointRadius,
                  showConfidence: _skeletonConfig.showConfidence,
                ),
                size: Size(constraints.maxWidth, constraints.maxHeight),
              );
            },
          ),
        ),
      ),
    ),
  )
```

### Data Flow

1. **Pose Detection**: `PoseDetectionService` processes camera frames
2. **Landmark Extraction**: Service extracts 33 landmarks as normalized coordinates
3. **State Update**: Landmarks stored in `_currentLandmarks` state variable
4. **Rendering**: `EnhancedPoseSkeletonPainter` renders overlay on camera preview

## Performance Characteristics

### Rendering Performance
- **Target FPS**: ~8 FPS during pose detection
- **Optimization**: `shouldRepaint()` method prevents unnecessary repaints
- **Memory**: Minimal memory footprint for landmark storage

### Optimization Strategies
- Use `IgnorePointer` to prevent touch interference
- Implement proper `shouldRepaint()` logic
- Scale landmarks efficiently using multiplication
- Cache paint objects for consistent styling

## Usage Examples

### Basic Implementation

```dart
CustomPaint(
  painter: EnhancedPoseSkeletonPainter(
    landmarks: poseLandmarks,
  ),
  size: Size(width, height),
)
```

### Advanced Configuration

```dart
CustomPaint(
  painter: EnhancedPoseSkeletonPainter(
    landmarks: poseLandmarks,
    showLandmarkLabels: true,
    strokeWidth: 3.0,
    pointRadius: 8.0,
  ),
  size: Size(width, height),
)
```

### Custom Configuration

```dart
final config = SkeletonOverlayConfig(
  showSkeleton: true,
  showLandmarkLabels: false,
  strokeWidth: 5.0,
  pointRadius: 7.0,
);

CustomPaint(
  painter: EnhancedPoseSkeletonPainter(
    landmarks: poseLandmarks,
    showLandmarkLabels: config.showLandmarkLabels,
    strokeWidth: config.strokeWidth,
    pointRadius: config.pointRadius,
  ),
  size: Size(width, height),
)
```

## Troubleshooting

### Common Issues

1. **Skeleton not displaying**
   - Check if `_showSkeleton` is true
   - Verify `_currentLandmarks` is not null
   - Ensure pose detection is working

2. **Misaligned landmarks**
   - Verify coordinate normalization (0.0-1.0 range)
   - Check camera preview size matches overlay size
   - Ensure proper scaling in `_scaleLandmarks()`

3. **Performance issues**
   - Reduce `strokeWidth` and `pointRadius`
   - Disable `showLandmarkLabels` if not needed
   - Check `shouldRepaint()` implementation

4. **Missing landmarks**
   - Verify pose detection service is running
   - Check landmark extraction in `PoseDetectionService`
   - Ensure proper landmark key mapping

### Debugging Techniques

1. **Enable landmark labels** for visual debugging
2. **Add debug prints** for landmark coordinates
3. **Test with static pose** to isolate issues
4. **Verify camera permissions** and initialization

## Best Practices

1. **State Management**: Always check for null landmarks before rendering
2. **Performance**: Use `shouldRepaint()` to optimize rendering
3. **Responsive Design**: Use `LayoutBuilder` for dynamic sizing
4. **Error Handling**: Gracefully handle missing landmarks
5. **Memory Management**: Clear landmarks when not needed

## Future Enhancements

1. **Confidence-based visualization**: Color-code landmarks by detection confidence
2. **Landmark filtering**: Smooth landmark positions over time
3. **Custom color schemes**: Allow runtime color customization
4. **Animation support**: Smooth transitions between poses
5. **Accessibility**: Add support for screen readers and high contrast

## Related Files

- `lib/widgets/enhanced_pose_skeleton_painter.dart` - Core painter implementation
- `lib/assessment/c_camera.dart` - Camera assessment integration
- `lib/data/pose_detection_service.dart` - Pose detection service
- `lib/dailyAssessment/cameraPose.dart` - Daily assessment integration
- `lib/demo/cameraPosePain.dart` - Demo implementation
