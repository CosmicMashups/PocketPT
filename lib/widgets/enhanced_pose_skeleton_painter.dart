import 'package:flutter/material.dart';

/// Enhanced pose skeleton painter with improved visualization and performance
/// 
/// This painter renders pose landmarks as a skeleton overlay with optimized
/// repaint logic and proper coordinate scaling. It expects normalized coordinates
/// (0.0-1.0) and scales them to the provided canvas size.
class EnhancedPoseSkeletonPainter extends CustomPainter {
  final Map<String, Offset> landmarks;
  final bool showLandmarkLabels;
  final double strokeWidth;
  final double pointRadius;
  final bool showConfidence;

  // Color scheme for different body parts
  static const Color _headColor = Color(0xFF8A2BE2); // Blue violet
  static const Color _torsoColor = Color(0xFF00BFFF); // Bright blue
  static const Color _armColor = Color(0xFF00FF00); // Bright green
  static const Color _legColor = Color(0xFFFF8C00); // Bright orange
  static const Color _pointColor = Color(0xFFFF0000); // Bright red
  static const Color _pointOutlineColor = Colors.white;
  static const Color _labelColor = Colors.white;
  static const Color _labelBackgroundColor = Color(0x80000000);

  EnhancedPoseSkeletonPainter({
    required this.landmarks,
    this.showLandmarkLabels = false,
    this.strokeWidth = 4.0,
    this.pointRadius = 6.0,
    this.showConfidence = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (landmarks.isEmpty) return;

    // Scale landmarks to fit the canvas size
    final scaledLandmarks = _scaleLandmarks(landmarks, size);

    // Create paint objects with improved styling
    final paints = _createPaints();

    // Draw skeleton connections first (so they appear behind points)
    _drawSkeletonConnections(canvas, paints, scaledLandmarks);

    // Draw landmark points with enhanced visibility
    _drawLandmarkPoints(canvas, paints, scaledLandmarks);

    // Draw labels if enabled
    if (showLandmarkLabels) {
      _drawLandmarkLabels(canvas, scaledLandmarks);
    }
  }

  Map<String, Offset> _scaleLandmarks(Map<String, Offset> landmarks, Size size) {
    final scaledLandmarks = <String, Offset>{};
    for (final entry in landmarks.entries) {
      scaledLandmarks[entry.key] = Offset(
        entry.value.dx * size.width,
        entry.value.dy * size.height,
      );
    }
    return scaledLandmarks;
  }

  Map<String, Paint> _createPaints() {
    return {
      'head': Paint()
        ..color = _headColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
      'torso': Paint()
        ..color = _torsoColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
      'arm': Paint()
        ..color = _armColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
      'leg': Paint()
        ..color = _legColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
      'point': Paint()
        ..color = _pointColor
        ..style = PaintingStyle.fill,
      'pointOutline': Paint()
        ..color = _pointOutlineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    };
  }

  void _drawSkeletonConnections(Canvas canvas, Map<String, Paint> paints, Map<String, Offset> landmarks) {
    // Head and neck connections
    _drawConnectionIfExists('nose', 'leftEye', canvas, paints['head']!, landmarks);
    _drawConnectionIfExists('nose', 'rightEye', canvas, paints['head']!, landmarks);
    _drawConnectionIfExists('leftEye', 'leftEar', canvas, paints['head']!, landmarks);
    _drawConnectionIfExists('rightEye', 'rightEar', canvas, paints['head']!, landmarks);
    _drawConnectionIfExists('leftEar', 'leftShoulder', canvas, paints['head']!, landmarks);
    _drawConnectionIfExists('rightEar', 'rightShoulder', canvas, paints['head']!, landmarks);

    // Torso connections
    _drawConnectionIfExists('leftShoulder', 'rightShoulder', canvas, paints['torso']!, landmarks);
    _drawConnectionIfExists('leftShoulder', 'leftHip', canvas, paints['torso']!, landmarks);
    _drawConnectionIfExists('rightShoulder', 'rightHip', canvas, paints['torso']!, landmarks);
    _drawConnectionIfExists('leftHip', 'rightHip', canvas, paints['torso']!, landmarks);

    // Left arm connections
    _drawConnectionIfExists('leftShoulder', 'leftElbow', canvas, paints['arm']!, landmarks);
    _drawConnectionIfExists('leftElbow', 'leftWrist', canvas, paints['arm']!, landmarks);
    _drawConnectionIfExists('leftWrist', 'leftThumb', canvas, paints['arm']!, landmarks);
    _drawConnectionIfExists('leftWrist', 'leftIndex', canvas, paints['arm']!, landmarks);
    _drawConnectionIfExists('leftWrist', 'leftPinky', canvas, paints['arm']!, landmarks);

    // Right arm connections
    _drawConnectionIfExists('rightShoulder', 'rightElbow', canvas, paints['arm']!, landmarks);
    _drawConnectionIfExists('rightElbow', 'rightWrist', canvas, paints['arm']!, landmarks);
    _drawConnectionIfExists('rightWrist', 'rightThumb', canvas, paints['arm']!, landmarks);
    _drawConnectionIfExists('rightWrist', 'rightIndex', canvas, paints['arm']!, landmarks);
    _drawConnectionIfExists('rightWrist', 'rightPinky', canvas, paints['arm']!, landmarks);

    // Left leg connections
    _drawConnectionIfExists('leftHip', 'leftKnee', canvas, paints['leg']!, landmarks);
    _drawConnectionIfExists('leftKnee', 'leftAnkle', canvas, paints['leg']!, landmarks);
    _drawConnectionIfExists('leftAnkle', 'leftHeel', canvas, paints['leg']!, landmarks);
    _drawConnectionIfExists('leftAnkle', 'leftFootIndex', canvas, paints['leg']!, landmarks);

    // Right leg connections
    _drawConnectionIfExists('rightHip', 'rightKnee', canvas, paints['leg']!, landmarks);
    _drawConnectionIfExists('rightKnee', 'rightAnkle', canvas, paints['leg']!, landmarks);
    _drawConnectionIfExists('rightAnkle', 'rightHeel', canvas, paints['leg']!, landmarks);
    _drawConnectionIfExists('rightAnkle', 'rightFootIndex', canvas, paints['leg']!, landmarks);
  }

  void _drawLandmarkPoints(Canvas canvas, Map<String, Paint> paints, Map<String, Offset> landmarks) {
    for (final landmark in landmarks.values) {
      // Draw white outline for better contrast
      canvas.drawCircle(landmark, pointRadius + 2, paints['pointOutline']!);
      // Draw colored point
      canvas.drawCircle(landmark, pointRadius, paints['point']!);
    }
  }

  void _drawLandmarkLabels(Canvas canvas, Map<String, Offset> landmarks) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (final entry in landmarks.entries) {
      final label = entry.key;
      final position = entry.value;

      // Create text span
      final textSpan = TextSpan(
        text: label,
        style: const TextStyle(
          color: _labelColor,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      );

      textPainter.text = textSpan;
      textPainter.layout();

      // Calculate label position (offset to avoid overlap with point)
      final labelPosition = Offset(
        position.dx - textPainter.width / 2,
        position.dy - pointRadius - textPainter.height - 4,
      );

      // Draw background rectangle
      final backgroundRect = Rect.fromLTWH(
        labelPosition.dx - 2,
        labelPosition.dy - 1,
        textPainter.width + 4,
        textPainter.height + 2,
      );

      final backgroundPaint = Paint()
        ..color = _labelBackgroundColor
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(backgroundRect, const Radius.circular(4)),
        backgroundPaint,
      );

      // Draw text
      textPainter.paint(canvas, labelPosition);
    }
  }

  void _drawConnectionIfExists(String fromKey, String toKey, Canvas canvas, Paint paint, Map<String, Offset> landmarks) {
    final from = landmarks[fromKey];
    final to = landmarks[toKey];
    
    if (from != null && to != null) {
      // Calculate distance to avoid drawing very short connections
      final distance = (from - to).distance;
      if (distance > 5) { // Minimum distance threshold
        canvas.drawLine(from, to, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant EnhancedPoseSkeletonPainter oldDelegate) {
    // Efficient comparison: only repaint if landmarks actually changed
    if (oldDelegate.landmarks.length != landmarks.length) {
      return true;
    }
    
    // Check if any landmark positions have changed (with small tolerance for floating point precision)
    for (final entry in landmarks.entries) {
      final oldPoint = oldDelegate.landmarks[entry.key];
      if (oldPoint == null) return true;
      
      // Use small tolerance to avoid unnecessary repaints from minor floating point differences
      const tolerance = 0.001;
      if ((entry.value.dx - oldPoint.dx).abs() > tolerance ||
          (entry.value.dy - oldPoint.dy).abs() > tolerance) {
        return true;
      }
    }
    
    // Check if visualization settings changed
    return oldDelegate.showLandmarkLabels != showLandmarkLabels ||
           (oldDelegate.strokeWidth - strokeWidth).abs() > 0.1 ||
           (oldDelegate.pointRadius - pointRadius).abs() > 0.1;
  }
}

/// Configuration class for skeleton overlay appearance
class SkeletonOverlayConfig {
  final bool showSkeleton;
  final bool showLandmarkLabels;
  final double strokeWidth;
  final double pointRadius;
  final bool showConfidence;
  final Color? customColor;

  const SkeletonOverlayConfig({
    this.showSkeleton = true,
    this.showLandmarkLabels = false,
    this.strokeWidth = 4.0,
    this.pointRadius = 6.0,
    this.showConfidence = false,
    this.customColor,
  });

  SkeletonOverlayConfig copyWith({
    bool? showSkeleton,
    bool? showLandmarkLabels,
    double? strokeWidth,
    double? pointRadius,
    bool? showConfidence,
    Color? customColor,
  }) {
    return SkeletonOverlayConfig(
      showSkeleton: showSkeleton ?? this.showSkeleton,
      showLandmarkLabels: showLandmarkLabels ?? this.showLandmarkLabels,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      pointRadius: pointRadius ?? this.pointRadius,
      showConfidence: showConfidence ?? this.showConfidence,
      customColor: customColor ?? this.customColor,
    );
  }
}

