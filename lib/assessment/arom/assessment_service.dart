import 'package:flutter/material.dart';
import 'triceps_assessment.dart';
import 'shoulders_assessment.dart';
import 'calves_assessment.dart';
import 'chest_assessment.dart';
import 'biceps_assessment.dart';
import 'quadriceps_assessment.dart';
import 'glute_ham_assessment.dart';
import 'b_trunk_assessment.dart';
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
        return GluteHamAssessment.assessHamstrings(landmarks, side);
      case 'gluteals':
        return GluteHamAssessment.assessGluteals(landmarks, side);
      case 'calf':
      case 'calves':
        return CalvesAssessment.assess(landmarks, side);
      case 'chest':
        return ChestAssessment.assess(landmarks, side);
      case 'biceps':
        return BicepsAssessment.assess(landmarks, side);
      case 'quadriceps':
        return QuadricepsAssessment.assess(landmarks, side);
      case 'abdominals':
        return BTrunkAssessment.assessAbdominals(landmarks);
      case 'obliques':
        return BTrunkAssessment.assessObliques(landmarks);
      case 'lower back':
        return BTrunkAssessment.assessLowerBack(landmarks);
      case 'multifidus':
        return BTrunkAssessment.assessMultifidus(landmarks);
      default:
        return AssessmentResult.error(muscleGroup);
    }
  }

  /// Get available muscle groups for assessment
  static List<String> getAvailableMuscleGroups() {
    return ['Triceps', 'Shoulders', 'Hamstrings', 'Gluteals', 'Calf', 'Chest', 'Biceps', 'Quadriceps', 'Abdominals', 'Obliques', 'Lower Back', 'Multifidus'];
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
        return "Raise your $sideLower thigh to 90° then extend your leg for hamstring assessment";
      case 'gluteals':
        return "Extend your $sideLower leg backward for gluteal assessment";
      case 'chest':
        return "Raise your $sideLower arm forward and upward for chest ROM assessment";
      case 'biceps':
        return "Flex your $sideLower arm at the elbow for biceps assessment";
      case 'quadriceps':
        return "Raise your $sideLower thigh to 90° then extend your leg for quadriceps assessment";
      case 'abdominals':
        return "Perform trunk flexion and extension movements for abdominal assessment";
      case 'obliques':
        return "Perform lateral trunk movements for oblique assessment";
      case 'lower back':
        return "Perform trunk extension movements for lower back assessment";
      case 'multifidus':
        return "Perform controlled trunk movements for multifidus assessment";
      default:
        return "Follow the on-screen instructions";
    }
  }
}
