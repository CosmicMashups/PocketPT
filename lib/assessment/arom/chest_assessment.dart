import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'assessment_result.dart';
import 'assessment_constants.dart';

/// Chest ROM assessment module
class ChestAssessment {
  /// Calculate chest forward elevation angle between hip, shoulder, and wrist
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
    final displayLabel = _getROMLabel(angle, romLevel);
    final displayColor = PainScaleMapping.getScoreColor(painScore);
    final clinicalContext = _getClinicalContext(romLevel);

    return AssessmentResult(
      romLevel: romLevel,
      painScore: painScore,
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
    return 'good';                      // Angle >= 90° -> Good
  }

  /// Get ROM label for display
  static String _getROMLabel(double angle, String romLevel) {
    switch (romLevel) {
      case 'severe':
        return 'Chest ROM: Severe (< 45°)';
      case 'moderate':
        return 'Chest ROM: Moderate (45-90°)';
      case 'good':
        return 'Chest ROM: Good (≥ 90°)';
      default:
        return 'Chest ROM: Unknown';
    }
  }

  /// Get clinical context for ROM level
  static String _getClinicalContext(String romLevel) {
    switch (romLevel) {
      case 'severe':
        return 'Severe chest ROM limitation - Requires immediate attention';
      case 'moderate':
        return 'Moderate chest ROM limitation - Monitor and consider intervention';
      case 'good':
        return 'Normal chest ROM - Maintain current activities';
      default:
        return 'Chest ROM assessment incomplete - Retry assessment';
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
