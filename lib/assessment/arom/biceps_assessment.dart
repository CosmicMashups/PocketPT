import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'assessment_result.dart';
import 'assessment_constants.dart';

/// Biceps ROM assessment module
class BicepsAssessment {
  /// Calculate biceps angle between shoulder, elbow, and wrist
  static double? calculateAngle(Map<String, Offset> landmarks, String side) {
    final sideLower = side.toLowerCase();
    final shoulder = landmarks['${sideLower}Shoulder'];
    final elbow = landmarks['${sideLower}Elbow'];
    final wrist = landmarks['${sideLower}Wrist'];

    if (shoulder == null || elbow == null || wrist == null) {
      return null;
    }

    return _calculateAngleBetweenPoints(shoulder, elbow, wrist);
  }

  /// Perform biceps ROM assessment
  static AssessmentResult assess(Map<String, Offset> landmarks, String side) {
    final angle = calculateAngle(landmarks, side);
    
    if (angle == null) {
      return AssessmentResult.notVisible('Biceps');
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

  /// Evaluate ROM level based on biceps angle
  static String _evaluateROM(double angle) {
    // Biceps: Elbow flexion angle (shoulder-elbow-wrist)
    // Higher angle = more extended = more pain
    // Lower angle = more flexed = less pain
    if (angle > AssessmentConstants.bicepsSevereThreshold) return 'severe';      // Angle > 150° -> Severe (Extended)
    if (angle > AssessmentConstants.bicepsModerateThreshold) return 'moderate';  // 90° < Angle <= 150° -> Moderate
    return 'low';                                                                 // Angle <= 90° -> Low pain (Flexed)
  }

  /// Get ROM label for display
  static String _getROMLabel(double angle, String romLevel) {
    switch (romLevel) {
      case 'severe':
        return 'Biceps ROM: Severe (> ${AssessmentConstants.bicepsSevereThreshold.toInt()}°)';
      case 'moderate':
        return 'Biceps ROM: Moderate (${AssessmentConstants.bicepsModerateThreshold.toInt()}-${AssessmentConstants.bicepsSevereThreshold.toInt()}°)';
      case 'low':
        return 'Biceps ROM: Low (< ${AssessmentConstants.bicepsModerateThreshold.toInt()}°)';
      default:
        return 'Biceps ROM: Unknown';
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
