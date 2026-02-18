import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'assessment_result.dart';
import 'assessment_constants.dart';

/// Triceps ROM assessment module
/// 
/// Measurement:
///   - Shoulder–Elbow–Wrist angle (vertex at the elbow)
/// 
/// Uses COCO format landmarks (side is 'left' or 'right', lowercase):
///   - ${side}Shoulder
///   - ${side}Elbow
///   - ${side}Wrist
class TricepsAssessment {
  /// Calculate triceps angle between hip, shoulder, and elbow
  /// 
  /// Uses COCO landmarks: ${side}Hip, ${side}Shoulder, ${side}Elbow
  static double? calculateAngle(Map<String, Offset> landmarks, String side) {
    final sideLower = side.toLowerCase();
    final shoulder = landmarks['${sideLower}Shoulder'];
    final elbow = landmarks['${sideLower}Elbow'];
    final wrist = landmarks['${sideLower}Wrist'];

    if (shoulder == null || elbow == null || wrist == null) {
      return null;
    }

    // Shoulder–Elbow–Wrist angle, with the elbow as the vertex
    return _calculateAngleBetweenPoints(shoulder, elbow, wrist);
  }

  /// Perform triceps ROM assessment
  static AssessmentResult assess(Map<String, Offset> landmarks, String side) {
    final angle = calculateAngle(landmarks, side);
    
    if (angle == null) {
      return AssessmentResult.notVisible('Triceps');
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

  /// Evaluate ROM level based on triceps angle
  static String _evaluateROM(double angle) {
    // Triceps: 0° (heavily flexed) -> 180° (fully extended)
    //
    // Severe (Bent):   angle < 90°   -> Poor extension, arm heavily bent
    // Moderate:        90°–134°      -> Partial extension
    // Low:             angle ≥ 135°  -> Good extension, arm nearly straight
    if (angle < 90.0) return 'severe';
    if (angle < 135.0) return 'moderate';
    return 'low';
  }

  /// Get ROM label for display
  static String _getROMLabel(double angle, String romLevel) {
    switch (romLevel) {
      case 'severe':
        return 'Triceps ROM: Severe (<90° - poor extension, arm heavily bent)';
      case 'moderate':
        return 'Triceps ROM: Moderate (90-134° - partial extension)';
      case 'low':
        return 'Triceps ROM: Low (>=135° - good extension, arm nearly straight)';
      default:
        return 'Triceps ROM: Unknown';
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
