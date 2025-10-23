import 'package:flutter/material.dart';

/// Custom painter for drawing pose skeleton overlay
/// 
/// This painter draws the pose skeleton on top of the camera preview,
/// similar to the ML Kit pose detection visualization but using
/// the custom pose estimation model data.
class CustomPoseSkeletonPainter extends CustomPainter {
  final List<Map<String, dynamic>> keypoints;
  final bool showLandmarkLabels;
  final double strokeWidth;
  final double pointRadius;
  final bool showConfidence;
  
  const CustomPoseSkeletonPainter({
    required this.keypoints,
    this.showLandmarkLabels = false,
    this.strokeWidth = 3.0,
    this.pointRadius = 6.0,
    this.showConfidence = false,
  });
  
  // COCO pose keypoint connections for skeleton drawing
  static const List<List<int>> _skeletonConnections = [
    [0, 1], [0, 2], [1, 3], [2, 4],  // head
    [5, 6], [5, 7], [7, 9], [6, 8], [8, 10],  // arms
    [5, 11], [6, 12], [11, 12],  // torso
    [11, 13], [13, 15], [12, 14], [14, 16]  // legs
  ];
  
  // Keypoint names for labels
  static const List<String> _keypointNames = [
    'nose', 'leftEye', 'rightEye', 'leftEar', 'rightEar',
    'leftShoulder', 'rightShoulder', 'leftElbow', 'rightElbow',
    'leftWrist', 'rightWrist', 'leftHip', 'rightHip',
    'leftKnee', 'rightKnee', 'leftAnkle', 'rightAnkle'
  ];
  
  // Colors for different keypoint types
  static const List<Color> _keypointColors = [
    Color(0xFF8B2E2E), // nose - main color
    Color(0xFF3B82F6), // eyes - blue
    Color(0xFF3B82F6), // eyes - blue
    Color(0xFF10B981), // ears - green
    Color(0xFF10B981), // ears - green
    Color(0xFFF59E0B), // shoulders - orange
    Color(0xFFF59E0B), // shoulders - orange
    Color(0xFFEF4444), // elbows - red
    Color(0xFFEF4444), // elbows - red
    Color(0xFF8B5CF6), // wrists - purple
    Color(0xFF8B5CF6), // wrists - purple
    Color(0xFF06B6D4), // hips - cyan
    Color(0xFF06B6D4), // hips - cyan
    Color(0xFF84CC16), // knees - lime
    Color(0xFF84CC16), // knees - lime
    Color(0xFFF97316), // ankles - orange
    Color(0xFFF97316), // ankles - orange
  ];
  
  @override
  void paint(Canvas canvas, Size size) {
    if (keypoints.isEmpty) return;
    
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    
    final pointPaint = Paint()
      ..style = PaintingStyle.fill;
    
    // Draw skeleton connections
    for (final connection in _skeletonConnections) {
      final pt1Idx = connection[0];
      final pt2Idx = connection[1];
      
      if (pt1Idx < keypoints.length && pt2Idx < keypoints.length) {
        final pt1 = keypoints[pt1Idx];
        final pt2 = keypoints[pt2Idx];
        
        if (pt1['confidence'] > 0.5 && pt2['confidence'] > 0.5) {
          paint.color = _getConnectionColor(pt1Idx, pt2Idx);
          
          canvas.drawLine(
            Offset(pt1['x'], pt1['y']),
            Offset(pt2['x'], pt2['y']),
            paint,
          );
        }
      }
    }
    
    // Draw keypoints
    for (int i = 0; i < keypoints.length; i++) {
      final kp = keypoints[i];
      final confidence = kp['confidence'] as double;
      
      if (confidence > 0.5) {
        final point = Offset(kp['x'], kp['y']);
        
        // Draw keypoint circle
        pointPaint.color = _keypointColors[i % _keypointColors.length];
        canvas.drawCircle(point, pointRadius, pointPaint);
        
        // Draw confidence ring
        if (showConfidence) {
          final confidencePaint = Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0
            ..color = _getConfidenceColor(confidence);
          
          final ringRadius = pointRadius + 3;
          canvas.drawCircle(point, ringRadius, confidencePaint);
        }
        
        // Draw landmark labels
        if (showLandmarkLabels && i < _keypointNames.length) {
          _drawLabel(canvas, point, _keypointNames[i], confidence);
        }
      }
    }
  }
  
  /// Get connection color based on keypoint types
  Color _getConnectionColor(int pt1Idx, int pt2Idx) {
    // Head connections
    if (pt1Idx <= 4 && pt2Idx <= 4) {
      return const Color(0xFF8B2E2E);
    }
    // Arm connections
    if ((pt1Idx >= 5 && pt1Idx <= 10) && (pt2Idx >= 5 && pt2Idx <= 10)) {
      return const Color(0xFF3B82F6);
    }
    // Torso connections
    if ((pt1Idx >= 5 && pt1Idx <= 12) && (pt2Idx >= 5 && pt2Idx <= 12)) {
      return const Color(0xFF10B981);
    }
    // Leg connections
    if ((pt1Idx >= 11 && pt1Idx <= 16) && (pt2Idx >= 11 && pt2Idx <= 16)) {
      return const Color(0xFFF59E0B);
    }
    
    return const Color(0xFF6B7280); // Default gray
  }
  
  /// Get confidence color based on confidence value
  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.red;
  }
  
  /// Draw keypoint label
  void _drawLabel(Canvas canvas, Offset point, String label, double confidence) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: '$label (${(confidence * 100).toInt()}%)',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    
    // Position label above the keypoint
    final labelOffset = Offset(
      point.dx - textPainter.width / 2,
      point.dy - pointRadius - textPainter.height - 5,
    );
    
    // Draw background rectangle
    final backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.7)
      ..style = PaintingStyle.fill;
    
    final backgroundRect = Rect.fromLTWH(
      labelOffset.dx - 4,
      labelOffset.dy - 2,
      textPainter.width + 8,
      textPainter.height + 4,
    );
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(backgroundRect, const Radius.circular(4)),
      backgroundPaint,
    );
    
    // Draw text
    textPainter.paint(canvas, labelOffset);
  }
  
  @override
  bool shouldRepaint(CustomPoseSkeletonPainter oldDelegate) {
    return keypoints != oldDelegate.keypoints ||
           showLandmarkLabels != oldDelegate.showLandmarkLabels ||
           strokeWidth != oldDelegate.strokeWidth ||
           pointRadius != oldDelegate.pointRadius ||
           showConfidence != oldDelegate.showConfidence;
  }
}
