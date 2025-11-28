import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'assessment_result.dart';
import 'assessment_constants.dart';

/// Chest ROM assessment module
/// 
/// Uses COCO format landmarks: ${side}Hip, ${side}Shoulder, ${side}Wrist
/// where side is 'left' or 'right' (lowercase).
class ChestAssessment {
  /// Calculate chest forward elevation angle between hip, shoulder, and wrist
  /// 
  /// Uses COCO landmarks: ${side}Hip, ${side}Shoulder, ${side}Wrist
  static double? calculateAngle(Map<String, Offset> landmarks, String side) {
    final sideLower = side.toLowerCase();
    final hip = landmarks['${sideLower}Hip'];
    final shoulder = landmarks['${sideLower}Shoulder'];
    final wrist = landmarks['${sideLower}Wrist'];

    if (hip == null || shoulder == null || wrist == null) {
      return null;
    }

    return _calculateAngleBetweenPoints(hip, shoulder, wrist);
  }

  /// Perform chest ROM assessment
  static AssessmentResult assess(Map<String, Offset> landmarks, String side) {
    final angle = calculateAngle(landmarks, side);
    
    if (angle == null) {
      return AssessmentResult.notVisible('Chest');
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

  /// Evaluate ROM level based on chest forward elevation angle
  static String _evaluateROM(double angle) {
    // Chest: Forward elevation angle (hip-shoulder-wrist)
    // Higher angle = better forward elevation
    if (angle < AssessmentConstants.chestSevereThreshold) return 'severe';      // Angle < 45° -> Severe
    if (angle < AssessmentConstants.chestModerateThreshold) return 'moderate';  // 45° <= Angle < 90° -> Moderate
    return 'low';                      // Angle >= 90° -> Low
  }

  /// Get ROM label for display
  static String _getROMLabel(double angle, String romLevel) {
    switch (romLevel) {
      case 'severe':
        return 'Chest ROM: Severe (< 45°)';
      case 'moderate':
        return 'Chest ROM: Moderate (45-90°)';
      case 'low':
        return 'Chest ROM: Low (≥ 90°)';
      default:
        return 'Chest ROM: Unknown';
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
