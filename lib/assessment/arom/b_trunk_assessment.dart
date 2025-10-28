import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'assessment_result.dart';
import 'assessment_constants.dart';

/// Unified trunk assessment module for abdominals, obliques, lower back, and multifidus
/// Uses trunk flexion and extension angles based on shoulder-hip-knee landmarks
class BTrunkAssessment {
  /// Calculate trunk angle using shoulder-hip-knee landmarks
  static double? calculateTrunkAngle(final Map<String, Offset> landmarks) {
    final leftShoulder = landmarks['leftShoulder'];
    final rightShoulder = landmarks['rightShoulder'];
    final leftHip = landmarks['leftHip'];
    final rightHip = landmarks['rightHip'];
    final leftKnee = landmarks['leftKnee'];
    final rightKnee = landmarks['rightKnee'];

    if (leftShoulder == null || rightShoulder == null || 
        leftHip == null || rightHip == null || 
        leftKnee == null || rightKnee == null) {
      return null;
    }

    // Calculate midpoint landmarks for trunk assessment
    final shoulderMid = Offset(
      (leftShoulder.dx + rightShoulder.dx) / 2,
      (leftShoulder.dy + rightShoulder.dy) / 2,
    );
    final hipMid = Offset(
      (leftHip.dx + rightHip.dx) / 2,
      (leftHip.dy + rightHip.dy) / 2,
    );
    final kneeMid = Offset(
      (leftKnee.dx + rightKnee.dx) / 2,
      (leftKnee.dy + rightKnee.dy) / 2,
    );

    // Calculate trunk angle: shoulder-hip-knee
    return _calculateAngleBetweenPoints(shoulderMid, hipMid, kneeMid);
  }

  /// Perform unified trunk assessment for all four muscle groups
  static AssessmentResult assess(final Map<String, Offset> landmarks, final String muscleType) {
    final angle = calculateTrunkAngle(landmarks);
    
    if (angle == null) {
      return AssessmentResult.notVisible(muscleType);
    }

    final romLevel = _evaluateTrunkROM(angle);
    final painScore = PainScaleMapping.mapToPainScale(romLevel);
    final categoricalPainLevel = PainScaleMapping.mapToCategoricalPainLevel(romLevel);
    final displayLabel = _getTrunkROMLabel(angle, romLevel, muscleType);
    final displayColor = PainScaleMapping.getScoreColor(painScore);
    final clinicalContext = _getTrunkClinicalContext(romLevel, muscleType);

    return AssessmentResult(
      romLevel: romLevel,
      painScore: painScore,
      categoricalPainLevel: categoricalPainLevel,
      displayLabel: displayLabel,
      displayColor: displayColor,
      clinicalContext: clinicalContext,
      additionalData: {
        'angle': angle,
        'muscleType': muscleType,
        'side': 'center', // Trunk assessment is center-based
      },
    );
  }

  /// Specific assessment methods for each muscle group
  static AssessmentResult assessAbdominals(final Map<String, Offset> landmarks) =>
      assess(landmarks, 'Abdominals');

  static AssessmentResult assessObliques(final Map<String, Offset> landmarks) =>
      assess(landmarks, 'Obliques');

  static AssessmentResult assessLowerBack(final Map<String, Offset> landmarks) =>
      assess(landmarks, 'Lower Back');

  static AssessmentResult assessMultifidus(final Map<String, Offset> landmarks) =>
      assess(landmarks, 'Multifidus');

  /// Evaluate trunk ROM level based on angle
  /// Trunk flexion/extension: 0° (fully flexed) -> 180° (upright/extended)
  static String _evaluateTrunkROM(final double angle) {
    // Standing straight or extended backward (160-180°) -> severe pain (high tension)
    if (angle >= AssessmentConstants.trunkSevereThreshold) {
      return 'severe';
    }
    // Mid-level bend (60-160°) -> moderate pain
    else if (angle >= AssessmentConstants.trunkModerateThreshold) {
      return 'moderate';
    }
    // Fully flexed forward (< 60°) -> low pain
    else {
      return 'low';
    }
  }

  /// Get ROM label for display based on muscle type
  static String _getTrunkROMLabel(final double angle, final String romLevel, final String muscleType) {
    switch (romLevel) {
      case 'severe':
        return '$muscleType ROM: Severe (>=160°)';
      case 'moderate':
        return '$muscleType ROM: Moderate (60-160°)';
      case 'low':
        return '$muscleType ROM: Low (<60°)';
      default:
        return '$muscleType ROM: Unknown';
    }
  }

  /// Get clinical context for trunk ROM level and muscle type
  static String _getTrunkClinicalContext(final String romLevel, final String muscleType) {
    switch (romLevel) {
      case 'severe':
        return 'Severe $muscleType limitation - Requires immediate attention';
      case 'moderate':
        return 'Moderate $muscleType limitation - Monitor and consider intervention';
      case 'low':
        return 'Mild $muscleType limitation - Continue monitoring';
      default:
        return '$muscleType assessment incomplete - Retry assessment';
    }
  }

  /// Calculate angle between three points (vertex is middle point)
  static double _calculateAngleBetweenPoints(final Offset pointA, final Offset vertex, final Offset pointB) {
    final v1 = pointA - vertex;
    final v2 = pointB - vertex;
    final dot = v1.dx * v2.dx + v1.dy * v2.dy;
    final mag1 = v1.distance;
    final mag2 = v2.distance;
    if (mag1 == 0 || mag2 == 0) return 0;
    final cosTheta = (dot / (mag1 * mag2)).clamp(-1.0, 1.0);
    final radians = math.acos(cosTheta);
    return radians * 180 / math.pi;
  }
}