import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'assessment_result.dart';
import 'assessment_constants.dart';

/// Shoulders ROM assessment module
class ShouldersAssessment {
  /// Calculate shoulder angle between hip, shoulder, and elbow
  static double? calculateAngle(Map<String, Offset> landmarks, String side) {
    final sideLower = side.toLowerCase();
    final hip = landmarks['${sideLower}Hip'];
    final shoulder = landmarks['${sideLower}Shoulder'];
    final elbow = landmarks['${sideLower}Elbow'];

    if (hip == null || shoulder == null || elbow == null) {
      return null;
    }

    return _calculateAngleBetweenPoints(hip, shoulder, elbow);
  }

  /// Perform shoulders ROM assessment
  static AssessmentResult assess(Map<String, Offset> landmarks, String side) {
    final angle = calculateAngle(landmarks, side);
    
    if (angle == null) {
      return AssessmentResult.notVisible('Shoulders');
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

  /// Evaluate ROM level based on shoulder angle
  static String _evaluateROM(double angle) {
    // Shoulders: 180° (arm down) -> 90° (T-pose) -> <90° (overhead)
    if (angle < AssessmentConstants.shoulderSevereThreshold) return 'severe';   // Angle < 90° -> Severe Pain
    if (angle <= AssessmentConstants.shoulderModerateThreshold) return 'moderate'; // 90° <= Angle <= 110° -> Moderate Pain
    if (angle <= AssessmentConstants.shoulderLowThreshold) return 'low';     // 111° <= Angle <= 150° -> Low Pain
    return 'good';                      // Angle > 150° -> Good Mobility/Low Pain
  }

  /// Get ROM label for display
  static String _getROMLabel(double angle, String romLevel) {
    switch (romLevel) {
      case 'severe':
        return 'Shoulder Pain: Severe (<90°)';
      case 'moderate':
        return 'Shoulder Pain: Moderate (90-110°)';
      case 'low':
        return 'Shoulder Pain: Low (111-150°)';
      case 'good':
        return 'Shoulder Mobility: Good (>=151°)';
      default:
        return 'Shoulder ROM: Unknown';
    }
  }

  /// Get clinical context for ROM level
  static String _getClinicalContext(String romLevel) {
    switch (romLevel) {
      case 'severe':
        return 'Severe ROM limitation - Requires immediate attention';
      case 'moderate':
        return 'Moderate ROM limitation - Monitor and consider intervention';
      case 'low':
        return 'Mild ROM limitation - Continue monitoring';
      case 'good':
        return 'Normal ROM - Maintain current activities';
      default:
        return 'ROM assessment incomplete - Retry assessment';
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
