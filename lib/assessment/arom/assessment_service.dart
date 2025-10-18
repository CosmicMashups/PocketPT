import 'package:flutter/material.dart';
import 'triceps_assessment.dart';
import 'shoulders_assessment.dart';
import 'hamstrings_assessment.dart';
import 'calves_assessment.dart';
import 'chest_assessment.dart';
import 'biceps_assessment.dart';
import 'assessment_result.dart';

/// Unified assessment service that provides a consistent API for all muscle group assessments
class AssessmentService {
  /// Perform assessment for the specified muscle group and side
  static AssessmentResult assess(String muscleGroup, Map<String, Offset> landmarks, String side) {
    switch (muscleGroup.toLowerCase()) {
      case 'triceps':
        return TricepsAssessment.assess(landmarks, side);
      case 'shoulders':
        return ShouldersAssessment.assess(landmarks, side);
      case 'hamstrings':
        return HamstringsAssessment.assess(landmarks, side);
      case 'calf':
      case 'calves':
        return CalvesAssessment.assess(landmarks, side);
      case 'chest':
        return ChestAssessment.assess(landmarks, side);
      case 'biceps':
        return BicepsAssessment.assess(landmarks, side);
      default:
        return AssessmentResult.error(muscleGroup);
    }
  }

  /// Get available muscle groups for assessment
  static List<String> getAvailableMuscleGroups() {
    return ['Triceps', 'Shoulders', 'Hamstrings', 'Calf', 'Chest', 'Biceps'];
  }

  /// Get available sides for assessment
  static List<String> getAvailableSides() {
    return ['Left', 'Right'];
  }

  /// Check if a muscle group is supported
  static bool isSupportedMuscleGroup(String muscleGroup) {
    return getAvailableMuscleGroups().any((group) => 
      group.toLowerCase() == muscleGroup.toLowerCase());
  }

  /// Get assessment instructions for a muscle group
  static String getInstructions(String muscleGroup, String side) {
    final sideLower = side.toLowerCase();
    
    switch (muscleGroup.toLowerCase()) {
      case 'triceps':
        return "Extend your $sideLower arm fully (elbow straight) for triceps assessment";
      case 'shoulders':
        return "Raise your $sideLower arm overhead or to T-pose for shoulder assessment";
      case 'calf':
      case 'calves':
        return "Stand side-on to camera, perform knee-to-wall motion with your $sideLower leg for calf assessment";
      case 'hamstrings':
        return "Lie on back, side-on to camera, raise your $sideLower leg straight for hamstring assessment";
      case 'chest':
        return "Raise your $sideLower arm forward and upward for chest ROM assessment";
      case 'biceps':
        return "Flex your $sideLower arm at the elbow for biceps assessment";
      default:
        return "Follow the on-screen instructions";
    }
  }
}
