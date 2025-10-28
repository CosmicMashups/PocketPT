import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'assessment_result.dart';
import 'assessment_constants.dart';

/// Hamstrings ROM assessment module
class HamstringsAssessment {
  /// Calculate hamstring angle (angle between hip-ankle and vertical axis)
  static double? calculateAngle(Map<String, Offset> landmarks, String side) {
    final sideLower = side.toLowerCase();
    final hip = landmarks['${sideLower}Hip'];
    final ankle = landmarks['${sideLower}Ankle'];

    if (hip == null || ankle == null) {
      return null;
    }

    return _calculateVerticalAngle(hip, ankle);
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
    if (angle < AssessmentConstants.hamstringSevereThreshold) return 'severe';   // Angle < 60° -> Severe
    if (angle < AssessmentConstants.hamstringModerateThreshold) return 'moderate'; // 60° <= Angle < 80° -> Moderate
    return 'good';                      // Angle >= 80° -> Good
  }

  /// Get ROM label for display
  static String _getROMLabel(double angle, String romLevel) {
    switch (romLevel) {
      case 'severe':
        return 'Hamstring ROM: Severe (< ${AssessmentConstants.hamstringSevereThreshold.toInt()}°)';
      case 'moderate':
        return 'Hamstring ROM: Moderate (${AssessmentConstants.hamstringSevereThreshold.toInt()}-${AssessmentConstants.hamstringModerateThreshold.toInt()}°)';
      case 'good':
        return 'Hamstring ROM: Good (> ${AssessmentConstants.hamstringModerateThreshold.toInt()}°)';
      default:
        return 'Hamstring ROM: Unknown';
    }
  }

  /// Get clinical context for ROM level
  static String _getClinicalContext(String romLevel) {
    switch (romLevel) {
      case 'severe':
        return 'Severe ROM limitation - Requires immediate attention';
      case 'moderate':
        return 'Moderate ROM limitation - Monitor and consider intervention';
      case 'good':
        return 'Normal ROM - Maintain current activities';
      default:
        return 'ROM assessment incomplete - Retry assessment';
    }
  }

  /// Calculate vertical angle
  static double _calculateVerticalAngle(Offset point1, Offset point2) {
    // Vector from point1 to point2
    final vector = point2 - point1;
    
    // Vertical vector pointing upwards (negative Y in Flutter)
    final verticalVector = const Offset(0, -1);
    
    final normVector = vector.distance;
    final normVertical = verticalVector.distance;
    
    if (normVector == 0 || normVertical == 0) {
      return 0.0;
    }
    
    // Calculate cosine of the angle
    final cosineAngle = (vector.dx * verticalVector.dx + vector.dy * verticalVector.dy) / (normVector * normVertical);
    
    // Clamp to prevent floating point errors
    final clampedCosine = cosineAngle.clamp(-1.0, 1.0);
    
    // Calculate angle in radians and convert to degrees
    final angleRadians = math.acos(clampedCosine);
    final angleDegrees = (angleRadians * 180) / math.pi;
    
    return angleDegrees;
  }
}
