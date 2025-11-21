import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'assessment_result.dart';
import 'assessment_constants.dart';

/// Quadriceps ROM assessment module
/// 
/// Uses COCO format landmarks: ${side}Hip, ${side}Knee, ${side}Ankle
/// where side is 'left' or 'right' (lowercase).
class QuadricepsAssessment {
  /// Calculate quadriceps angle between hip, knee, and ankle
  /// 
  /// Uses COCO landmarks: ${side}Hip, ${side}Knee, ${side}Ankle
  static double? calculateAngle(Map<String, Offset> landmarks, String side) {
    final sideLower = side.toLowerCase();
    final hip = landmarks['${sideLower}Hip'];
    final knee = landmarks['${sideLower}Knee'];
    final ankle = landmarks['${sideLower}Ankle'];

    if (hip == null || knee == null || ankle == null) {
      return null;
    }

    return _calculateAngleBetweenPoints(hip, knee, ankle);
  }

  /// Perform quadriceps ROM assessment
  static AssessmentResult assess(Map<String, Offset> landmarks, String side) {
    final angle = calculateAngle(landmarks, side);
    
    if (angle == null) {
      return AssessmentResult.notVisible('Quadriceps');
    }

    final romLevel = _evaluateROM(angle);
    final painScore = PainScaleMapping.mapToPainScale(romLevel);
    final categoricalPainLevel = PainScaleMapping.mapToCategoricalPainLevel(romLevel);
    final displayLabel = _getROMLabel(angle, romLevel);
    final displayColor = PainScaleMapping.getScoreColor(painScore);
    final clinicalContext = _getClinicalContext(romLevel);

    return AssessmentResult(
      romLevel: romLevel,
      painScore: painScore,
      categoricalPainLevel: categoricalPainLevel,
      displayLabel: displayLabel,
      displayColor: displayColor,
      clinicalContext: clinicalContext,
      additionalData: {
        'angle': angle,
        'side': side,
      },
    );
  }

  /// Evaluate ROM level based on quadriceps angle
  static String _evaluateROM(double angle) {
    // Quadriceps: Knee flexion angle (hip-knee-ankle)
    // Angle < 120° -> Severe (Good flexion, leg well bent)
    // 120° <= angle < 140° -> Moderate (Partial flexion)
    // Angle >= 140° -> Low (Leg nearly straight, poor flexion)
    if (angle < AssessmentConstants.quadricepsSevereThreshold) return 'severe';      // Angle < 120° -> Severe
    if (angle < AssessmentConstants.quadricepsModerateThreshold) return 'moderate';  // 120° <= Angle < 140° -> Moderate
    return 'low';                                                                   // Angle >= 140° -> Low
  }

  /// Get ROM label for display
  static String _getROMLabel(double angle, String romLevel) {
    switch (romLevel) {
      case 'severe':
        return 'Quadriceps ROM: Severe (< ${AssessmentConstants.quadricepsSevereThreshold.toInt()}°)';
      case 'moderate':
        return 'Quadriceps ROM: Moderate (${AssessmentConstants.quadricepsSevereThreshold.toInt()}-${AssessmentConstants.quadricepsModerateThreshold.toInt() - 1}°)';
      case 'low':
        return 'Quadriceps ROM: Low (>= ${AssessmentConstants.quadricepsModerateThreshold.toInt()}°)';
      default:
        return 'Quadriceps ROM: Unknown';
    }
  }

  /// Get clinical context for ROM level
  static String _getClinicalContext(String romLevel) {
    switch (romLevel) {
      case 'severe':
        return 'Severe';
      case 'moderate':
        return 'Moderate';
      case 'low':
        return 'Low';
      default:
        return 'Low';
    }
  }

  /// Calculate angle between three points (vertex is middle point)
  static double _calculateAngleBetweenPoints(Offset pointA, Offset vertex, Offset pointB) {
    final v1 = pointA - vertex;
    final v2 = pointB - vertex;
    final dot = v1.dx * v2.dx + v1.dy * v2.dy;
    final mag1 = v1.distance;
    final mag2 = v2.distance;
    if (mag1 == 0 || mag2 == 0) return 0.0;
    double cosTheta = (dot / (mag1 * mag2)).clamp(-1.0, 1.0);
    final radians = math.acos(cosTheta);
    return radians * 180.0 / math.pi;
  }
}
