import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'assessment_result.dart';
import 'assessment_constants.dart';

/// Combined Gluteal and Hamstring ROM assessment module
/// 
/// Uses COCO format landmarks: ${side}Shoulder, ${side}Hip, ${side}Knee
/// where side is 'left' or 'right' (lowercase).
class GluteHamAssessment {
  /// Calculate gluteal angle between shoulder, hip, and knee
  /// 
  /// Uses COCO landmarks: ${side}Shoulder, ${side}Hip, ${side}Knee
  static double? calculateGlutealAngle(Map<String, Offset> landmarks, String side) {
    final sideLower = side.toLowerCase();
    final shoulder = landmarks['${sideLower}Shoulder'];
    final hip = landmarks['${sideLower}Hip'];
    final knee = landmarks['${sideLower}Knee'];

    if (shoulder == null || hip == null || knee == null) {
      return null;
    }

    return _calculateAngleBetweenPoints(shoulder, hip, knee);
  }

  /// Calculate hamstring angle between shoulder, hip, and knee
  /// 
  /// Uses COCO landmarks: ${side}Shoulder, ${side}Hip, ${side}Knee
  static double? calculateHamstringAngle(Map<String, Offset> landmarks, String side) {
    final sideLower = side.toLowerCase();
    final shoulder = landmarks['${sideLower}Shoulder'];
    final hip = landmarks['${sideLower}Hip'];
    final knee = landmarks['${sideLower}Knee'];

    if (shoulder == null || hip == null || knee == null) {
      return null;
    }

    return _calculateAngleBetweenPoints(shoulder, hip, knee);
  }

  /// Perform gluteal ROM assessment
  static AssessmentResult assessGluteals(Map<String, Offset> landmarks, String side) {
    final angle = calculateGlutealAngle(landmarks, side);
    
    if (angle == null) {
      return AssessmentResult.notVisible('Gluteals');
    }

    final romLevel = _evaluateGlutealROM(angle);
    final painScore = PainScaleMapping.mapToPainScale(romLevel);
    final categoricalPainLevel = PainScaleMapping.mapToCategoricalPainLevel(romLevel);
    final displayLabel = _getGlutealROMLabel(angle, romLevel);
    final displayColor = PainScaleMapping.getScoreColor(painScore);
    final clinicalContext = _getGlutealClinicalContext(romLevel);

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
        'muscleGroup': 'Gluteals',
      },
    );
  }

  /// Perform hamstring ROM assessment (enhanced version)
  static AssessmentResult assessHamstrings(Map<String, Offset> landmarks, String side) {
    final angle = calculateHamstringAngle(landmarks, side);
    
    if (angle == null) {
      return AssessmentResult.notVisible('Hamstrings');
    }

    final romLevel = _evaluateHamstringROM(angle);
    final painScore = PainScaleMapping.mapToPainScale(romLevel);
    final categoricalPainLevel = PainScaleMapping.mapToCategoricalPainLevel(romLevel);
    final displayLabel = _getHamstringROMLabel(angle, romLevel);
    final displayColor = PainScaleMapping.getScoreColor(painScore);
    final clinicalContext = _getHamstringClinicalContext(romLevel);

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
        'muscleGroup': 'Hamstrings',
      },
    );
  }

  /// Evaluate ROM level based on gluteal angle
  static String _evaluateGlutealROM(double angle) {
    // Gluteals: Shoulder-hip-knee angle
    // Higher angle = more extended = more pain
    // Lower angle = more flexed = less pain
    if (angle >= AssessmentConstants.glutealSevereThreshold) return 'severe';      // Angle >= 160° -> Severe (Extended)
    if (angle >= AssessmentConstants.glutealModerateThreshold) return 'moderate';  // 100° <= Angle < 160° -> Moderate
    return 'low';                                                                 // Angle < 100° -> Low pain (Flexed)
  }

  /// Evaluate ROM level based on hamstring angle
  static String _evaluateHamstringROM(double angle) {
    // Hamstrings: Shoulder-hip-knee angle
    // Angle < 190° -> Low (Poor flexion)
    // 190° <= angle < 210° -> Moderate (Partial flexion)
    // Angle >= 210° -> Severe (Leg extended, good flexion)
    if (angle < AssessmentConstants.hamstringEnhancedLowThreshold) return 'low';   // Angle < 190° -> Low
    if (angle < AssessmentConstants.hamstringEnhancedModerateThreshold) return 'moderate';  // 190° <= Angle < 210° -> Moderate
    return 'severe';                                                                           // Angle >= 210° -> Severe
  }

  /// Get ROM label for gluteal display
  static String _getGlutealROMLabel(double angle, String romLevel) {
    switch (romLevel) {
      case 'severe':
        return 'Gluteal ROM: Severe (>= ${AssessmentConstants.glutealSevereThreshold.toInt()}°)';
      case 'moderate':
        return 'Gluteal ROM: Moderate (${AssessmentConstants.glutealModerateThreshold.toInt()}-${AssessmentConstants.glutealSevereThreshold.toInt() - 1}°)';
      case 'low':
        return 'Gluteal ROM: Low (< ${AssessmentConstants.glutealModerateThreshold.toInt()}°)';
      default:
        return 'Gluteal ROM: Unknown';
    }
  }

  /// Get ROM label for hamstring display
  static String _getHamstringROMLabel(double angle, String romLevel) {
    switch (romLevel) {
      case 'low':
        return 'Hamstring ROM: Low (< ${AssessmentConstants.hamstringEnhancedLowThreshold.toInt()}°)';
      case 'moderate':
        return 'Hamstring ROM: Moderate (${AssessmentConstants.hamstringEnhancedLowThreshold.toInt()}-${AssessmentConstants.hamstringEnhancedModerateThreshold.toInt() - 1}°)';
      case 'severe':
        return 'Hamstring ROM: Severe (>= ${AssessmentConstants.hamstringEnhancedModerateThreshold.toInt()}°)';
      default:
        return 'Hamstring ROM: Unknown';
    }
  }

  /// Get clinical context for gluteal ROM level
  static String _getGlutealClinicalContext(String romLevel) {
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

  /// Get clinical context for hamstring ROM level
  static String _getHamstringClinicalContext(String romLevel) {
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
