import 'package:flutter/material.dart';

/// Clinical thresholds for ROM assessments
/// 
/// All assessments use COCO format pose landmarks (17 keypoints):
/// - nose, leftEye, rightEye, leftEar, rightEar
/// - leftShoulder, rightShoulder, leftElbow, rightElbow
/// - leftWrist, rightWrist, leftHip, rightHip
/// - leftKnee, rightKnee, leftAnkle, rightAnkle
/// 
/// These landmarks are provided by the custom YOLO11s-pose model
/// and normalized to 0.0-1.0 range for assessment calculations.
class AssessmentConstants {
  // Calf dorsiflexion thresholds
  static const double calfSevereThreshold = 0.15;  // Normalized displacement < 0.15 -> Severe
  static const double calfModerateThreshold = 0.30;  // 0.15 <= displacement < 0.30 -> Moderate
  
  // Pelvic compensation threshold
  static const double pelvicCompensationThresholdNorm = 0.05; // Vertical difference > 5% of body height proxy -> Warning
  
  // Triceps ROM thresholds
  static const double tricepsSevereThreshold = 90.0;  // Angle < 90° -> Severe
  static const double tricepsModerateThreshold = 135.0;  // 90° <= Angle < 135° -> Moderate
  
  // Shoulder ROM thresholds
  static const double shoulderSevereThreshold = 90.0;  // Angle < 90° -> Severe
  static const double shoulderModerateThreshold = 110.0;  // 90° <= Angle <= 110° -> Moderate
  static const double shoulderLowThreshold = 150.0;  // 111° <= Angle <= 150° -> Low pain
  
  // Chest ROM thresholds
  static const double chestSevereThreshold = 45.0;  // Angle < 45° -> Severe limitation
  static const double chestModerateThreshold = 90.0; // 45° <= Angle < 90° -> Moderate limitation
  
  // Biceps ROM thresholds
  static const double bicepsSevereThreshold = 150.0;  // Angle > 150° -> Severe (Extended)
  static const double bicepsModerateThreshold = 90.0; // 90° < Angle <= 150° -> Moderate
  
  // Quadriceps ROM thresholds
  static const double quadricepsSevereThreshold = 120.0;  // Angle < 120° -> Severe (Good flexion, leg well bent)
  static const double quadricepsModerateThreshold = 140.0; // 120° <= Angle < 140° -> Moderate (Partial flexion)
  
  // Gluteal ROM thresholds
  static const double glutealSevereThreshold = 180.0;  // Angle >= 180° -> Severe (Extended)
  static const double glutealModerateThreshold = 140.0; // 140° <= Angle < 160° -> Moderate
  static const double glutealModerateUpperThreshold = 160.0; // Angle < 160° continues moderate range
  
  // Hamstring ROM thresholds
  static const double hamstringLowThreshold = 140.0;  // Angle < 140° -> Low (Flexed)
  static const double hamstringModerateUpperThreshold = 160.0;  // 140° <= Angle < 160° -> Moderate
  static const double hamstringSevereThreshold = 180.0;  // Angle >= 180° -> Severe (Extended)
  
  // Trunk ROM thresholds (for unified trunk muscle assessment)
  static const double trunkSevereThreshold = 150.0;  // Angle >= 150° -> Severe (Extended/Upright)
  static const double trunkModerateThreshold = 80.0; // 80° <= Angle < 150° -> Moderate
}

/// Standardized pain scale mapping
class PainScaleMapping {
  static int mapToPainScale(String romLevel) {
    switch (romLevel) {
      case 'severe':
        return 9; // 8-10: Severe limitation/pain (significant functional impact)
      case 'moderate':
        return 6; // 5-7: Moderate limitation/pain (noticeable functional impact)
      case 'low':
        return 3; // 2-4: Low limitation/pain (minimal functional impact)
      default:
        return 5; // Default moderate pain when ROM level is unknown
    }
  }
  
  /// Map ROM level to categorical pain level (Low/Moderate/Severe)
  /// Uses the same logic as c_painlevel.dart for consistency
  static String mapToCategoricalPainLevel(String romLevel) {
    switch (romLevel) {
      case 'severe':
        return 'Severe'; // Severe limitation/pain
      case 'moderate':
        return 'Moderate'; // Moderate limitation/pain
      case 'low':
        return 'Low'; // Low limitation/pain
      default:
        return 'Moderate'; // Default moderate when ROM level is unknown
    }
  }
  
  static Color getScoreColor(int score) {
    if (score <= 3) return Colors.green;      // Good (0-3)
    if (score <= 7) return Colors.orange;     // Moderate (4-7)
    return Colors.red;                         // Severe (8-10)
  }
  
  static String getPainDescription(int painScale) {
    if (painScale >= 8) {
      return "Severe Pain - Significant functional limitation";
    } else if (painScale >= 5) {
      return "Moderate Pain - Noticeable functional impact";
    } else if (painScale >= 2) {
      return "Low Pain - Minimal functional impact";
    } else {
      return "No/Minimal Pain - Normal function";
    }
  }
}
