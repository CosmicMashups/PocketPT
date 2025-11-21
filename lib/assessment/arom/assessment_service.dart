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
/// 
/// All assessments expect landmarks in COCO format (17 keypoints) normalized to 0.0-1.0 range:
/// - nose, leftEye, rightEye, leftEar, rightEar
/// - leftShoulder, rightShoulder, leftElbow, rightElbow
/// - leftWrist, rightWrist, leftHip, rightHip
/// - leftKnee, rightKnee, leftAnkle, rightAnkle
/// 
/// These landmarks are provided by the custom YOLO11s-pose model via CustomPoseDetectionService.
class AssessmentService {
  /// Perform assessment for the specified muscle group and side
  /// 
  /// [landmarks] must be in COCO format with normalized coordinates (0.0-1.0)
  /// [side] must be 'Left' or 'Right' (case-insensitive)
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

  /// Get detailed assessment instructions for a muscle group
  static String getInstructions(String muscleGroup, String side) {
    final sideLower = side.toLowerCase();
    
    switch (muscleGroup.toLowerCase()) {
      case 'triceps':
        return "Raise your $sideLower arm overhead, then slowly bend your elbow behind your head. Hold for 3 seconds, then straighten your arm. Move slowly and controlled.";
      case 'shoulders':
        return "Slowly raise your $sideLower arm to the side, lifting as high as possible. Keep your arm straight and don't shrug your shoulder. Hold at the top for 3 seconds.";
      case 'calf':
      case 'calves':
        return "Stand side-on to camera. Step forward with your $sideLower foot, keeping your heel down. Lean forward from your ankle until you feel a stretch. Hold for 3 seconds.";
      case 'hamstrings':
        return "Lift your $sideLower leg to 90° at the hip, then slowly straighten your knee as much as possible. Keep your back straight and hold for 3 seconds.";
      case 'gluteals':
        return "Extend your $sideLower leg straight back behind you, keeping your knee straight. Lift as high as comfortable while maintaining good posture. Hold for 3 seconds.";
      case 'chest':
        return "Raise your $sideLower arm forward and upward, lifting as high as possible. Keep your arm straight and don't lean backward. Hold at the top for 3 seconds.";
      case 'biceps':
        return "Slowly bend your $sideLower elbow, bringing your hand toward your shoulder. Keep your upper arm still and move in a controlled manner. Hold for 3 seconds.";
      case 'quadriceps':
        return "Lift your $sideLower thigh to 90° at the hip, then slowly extend your knee as much as possible. Keep your back straight and hold for 3 seconds.";
      case 'abdominals':
        return "Place your hands on your hips and slowly bend forward from your waist. Reach toward the ground while keeping your knees straight. Hold for 3 seconds.";
      case 'obliques':
        return "Place your hands on your hips and slowly bend to the $side. Keep your shoulders aligned and don't rotate your torso. Hold for 3 seconds.";
      case 'lower back':
        return "Place your hands on your lower back and slowly bend backward, arching your back gently. Don't force the movement. Hold for 3 seconds.";
      case 'multifidus':
        return "Place your hands on your hips and slowly rotate your torso to the $side. Keep your hips facing forward and don't force the rotation. Hold for 3 seconds.";
      default:
        return "Follow the detailed instructions in the help dialog for proper positioning and movement technique.";
    }
  }
}
