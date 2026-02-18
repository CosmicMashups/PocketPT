import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'assessment_result.dart';
import 'assessment_constants.dart';

/// Quadriceps ROM assessment module
/// 
/// Measurement:
///   - Hip–Knee–Ankle angle (vertex at the knee)
/// 
/// Uses COCO format landmarks (side is 'left' or 'right', lowercase):
///   - ${side}Hip
///   - ${side}Knee
///   - ${side}Ankle
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
    // Quadriceps: Knee flexion angle (hip–knee–ankle)
    //
    // Severe:   angle <= 90°   -> Leg bent (good flexion)
    // Moderate: 90° < angle < 115° -> Partial flexion
    // Low:      angle >= 135°  -> Leg nearly straight
    if (angle <= 90.0) return 'severe';
    if (angle < 115.0) return 'moderate';
    if (angle >= 135.0) return 'low';
    // For the intermediate band (115°–134°), treat as low flexion clinically.
    return 'low';
  }

  /// Get ROM label for display
  static String _getROMLabel(double angle, String romLevel) {
    switch (romLevel) {
      case 'severe':
        return 'Quadriceps ROM: Severe (≤90° - leg bent)';
      case 'moderate':
        return 'Quadriceps ROM: Moderate (91-114° - partial flexion)';
      case 'low':
        return 'Quadriceps ROM: Low (≥135° - leg nearly straight)';
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
