import 'package:flutter/material.dart';
import 'assessment_result.dart';
import 'assessment_constants.dart';

/// Calves dorsiflexion assessment module
/// 
/// Uses COCO format landmarks: ${side}Hip, ${side}Knee, ${side}Ankle
/// where side is 'left' or 'right' (lowercase).
class CalvesAssessment {
  /// Calculate normalized displacement for calf dorsiflexion
  /// 
  /// Uses COCO landmarks: ${side}Hip, ${side}Knee, ${side}Ankle
  static double? calculateNormalizedDisplacement(Map<String, Offset> landmarks, String side) {
    final sideLower = side.toLowerCase();
    final hip = landmarks['${sideLower}Hip'];
    final knee = landmarks['${sideLower}Knee'];
    final ankle = landmarks['${sideLower}Ankle'];

    if (hip == null || knee == null || ankle == null) {
      return null;
    }

    // Calculate horizontal displacement between knee and ankle
    final horizontalDisplacement = knee.dx - ankle.dx;
    
    // Calculate vertical distance between hip and ankle as body height proxy
    final bodySegmentHeight = (hip.dy - ankle.dy).abs();
    
    if (bodySegmentHeight < 10) {
      return null; // Position adjustment needed
    }

    // Normalize horizontal displacement by body segment height
    return horizontalDisplacement / bodySegmentHeight;
  }

  /// Check knee-over-ankle alignment
  static String checkAlignment(Map<String, Offset> landmarks, String side) {
    final sideLower = side.toLowerCase();
    final knee = landmarks['${sideLower}Knee'];
    final ankle = landmarks['${sideLower}Ankle'];

    if (knee == null || ankle == null) {
      return "Alignment: N/A";
    }

    if (knee.dx > ankle.dx) {
      return "Alignment: Knee Forward";
    } else {
      return "Alignment: Knee Behind/Inline";
    }
  }

  /// Perform calves ROM assessment
  static AssessmentResult assess(Map<String, Offset> landmarks, String side) {
    final normalizedDisplacement = calculateNormalizedDisplacement(landmarks, side);
    
    if (normalizedDisplacement == null) {
      // Check if it's a position issue or missing landmarks
      final sideLower = side.toLowerCase();
      final hip = landmarks['${sideLower}Hip'];
      final knee = landmarks['${sideLower}Knee'];
      final ankle = landmarks['${sideLower}Ankle'];
      
      if (hip == null || knee == null || ankle == null) {
        return AssessmentResult.notVisible('Calf');
      } else {
        return AssessmentResult.adjustPosition('Calf');
      }
    }

    final absNormDisplacement = normalizedDisplacement.abs();
    final romLevel = _evaluateROM(absNormDisplacement);
    final painScore = PainScaleMapping.mapToPainScale(romLevel);
    final categoricalPainLevel = PainScaleMapping.mapToCategoricalPainLevel(romLevel);
    final displayLabel = _getROMLabel(absNormDisplacement, romLevel);
    final displayColor = PainScaleMapping.getScoreColor(painScore);
    final clinicalContext = _getClinicalContext(romLevel);
    final alignment = checkAlignment(landmarks, side);

    return AssessmentResult(
      romLevel: romLevel,
      painScore: painScore,
      categoricalPainLevel: categoricalPainLevel,
      displayLabel: displayLabel,
      displayColor: displayColor,
      clinicalContext: clinicalContext,
      additionalData: {
        'normalizedDisplacement': normalizedDisplacement,
        'absNormalizedDisplacement': absNormDisplacement,
        'side': side,
      },
      alignment: alignment,
    );
  }

  /// Evaluate ROM level based on normalized displacement
  static String _evaluateROM(double absNormDisplacement) {
    if (absNormDisplacement < AssessmentConstants.calfSevereThreshold) return 'severe';      // < 0.15 -> Severe
    if (absNormDisplacement < AssessmentConstants.calfModerateThreshold) return 'moderate';  // 0.15-0.30 -> Moderate
    return 'low';                                                                           // >= 0.30 -> Low
  }

  /// Get ROM label for display
  static String _getROMLabel(double absNormDisplacement, String romLevel) {
    switch (romLevel) {
      case 'severe':
        return 'Calf ROM: Severe (< ${AssessmentConstants.calfSevereThreshold.toStringAsFixed(2)})';
      case 'moderate':
        return 'Calf ROM: Moderate (${AssessmentConstants.calfSevereThreshold.toStringAsFixed(2)}-${AssessmentConstants.calfModerateThreshold.toStringAsFixed(2)})';
      case 'low':
        return 'Calf ROM: Low (> ${AssessmentConstants.calfModerateThreshold.toStringAsFixed(2)})';
      default:
        return 'Calf ROM: Unknown';
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
}
