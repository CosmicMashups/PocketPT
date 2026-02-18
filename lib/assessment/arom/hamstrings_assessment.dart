import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'assessment_result.dart';
import 'assessment_constants.dart';

/// Hamstrings ROM assessment module
/// 
/// Uses COCO format landmarks: ${side}Shoulder, ${side}Hip, ${side}Knee
/// where side is 'left' or 'right' (lowercase).
/// Also uses leftHip, rightHip, leftShoulder, rightShoulder for compensation checks.
class HamstringsAssessment {
  /// Calculate hamstring angle between shoulder, hip, and knee
  /// 
  /// Uses COCO landmarks: ${side}Shoulder, ${side}Hip, ${side}Knee
  static double? calculateAngle(Map<String, Offset> landmarks, String side) {
    final sideLower = side.toLowerCase();
    final shoulder = landmarks['${sideLower}Shoulder'];
    final hip = landmarks['${sideLower}Hip'];
    final knee = landmarks['${sideLower}Knee'];

    if (shoulder == null || hip == null || knee == null) {
      return null;
    }

    return _calculateAngleBetweenPoints(shoulder, hip, knee);
  }

  /// Check for pelvic compensation
  static String checkPelvicCompensation(Map<String, Offset> landmarks) {
    final hipL = landmarks['leftHip'];
    final hipR = landmarks['rightHip'];
    final shoulderR = landmarks['rightShoulder'];
    final shoulderL = landmarks['leftShoulder'];

    if (hipL == null || hipR == null || shoulderR == null || shoulderL == null) {
      return "Compensation: N/A";
    }

    // Check for pelvic compensation
    final verticalHipDifference = (hipR.dy - hipL.dy).abs();
    final avgShoulderY = (shoulderR.dy + shoulderL.dy) / 2;
    final avgHipY = (hipR.dy + hipL.dy) / 2;
    final torsoHeightProxy = (avgShoulderY - avgHipY).abs();

    if (torsoHeightProxy > 5) {
      final normVerticalHipDifference = verticalHipDifference / torsoHeightProxy;
      
      if (normVerticalHipDifference > AssessmentConstants.pelvicCompensationThresholdNorm) {
        return "Compensation: Pelvic Tilt (${normVerticalHipDifference.toStringAsFixed(2)})";
      } else {
        return "Compensation: Stable";
      }
    } else {
      return "Compensation: Cannot assess (Torso too flat)";
    }
  }

  /// Perform hamstrings ROM assessment
  static AssessmentResult assess(Map<String, Offset> landmarks, String side) {
    final angle = calculateAngle(landmarks, side);
    
    if (angle == null) {
      return AssessmentResult.notVisible('Hamstring');
    }

    final romLevel = _evaluateROM(angle);
    final painScore = PainScaleMapping.mapToPainScale(romLevel);
    final categoricalPainLevel = PainScaleMapping.mapToCategoricalPainLevel(romLevel);
    final displayLabel = _getROMLabel(angle, romLevel);
    final displayColor = PainScaleMapping.getScoreColor(painScore);
    final clinicalContext = _getClinicalContext(romLevel);
    final compensation = checkPelvicCompensation(landmarks);

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
      compensation: compensation,
    );
  }

  /// Evaluate ROM level based on hamstring angle
  static String _evaluateROM(double angle) {
    // Hamstrings: Shoulder-Hip-Knee angle
    //
    // Low:      angle <= 130°          -> Leg extended, good flexion
    // Moderate: 145° <= angle < 160°   -> Partial flexion
    // Severe:   angle < 190°           -> Poor flexion (default for other angles)
    if (angle <= 130.0) return 'low';
    if (angle >= 145.0 && angle < 160.0) return 'moderate';
    // For all remaining angles (including 131°–144° and 160°–189°), treat as severe (poor flexion)
    if (angle < 190.0) return 'severe';
    // Fallback (should rarely be hit with typical human ROM ranges)
    return 'severe';
  }

  /// Get ROM label for display
  static String _getROMLabel(double angle, String romLevel) {
    switch (romLevel) {
      case 'low':
        return 'Hamstring ROM: Low (≤130° - leg extended, good flexion)';
      case 'moderate':
        return 'Hamstring ROM: Moderate (145-159° - partial flexion)';
      case 'severe':
        return 'Hamstring ROM: Severe (<190° - poor flexion)';
      default:
        return 'Hamstring ROM: Unknown';
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
