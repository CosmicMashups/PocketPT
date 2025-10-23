import 'stretching_exercise.dart';

/// Stretching routine model for organizing exercises by muscle group and type
class StretchingRoutine {
  final String routineId;
  final String muscleGroup;
  final String routineType; // 'warmup' or 'cooldown'
  final List<StretchingExercise> exercises;
  final int totalDuration; // in seconds
  final String difficultyLevel;
  final String description;
  final List<String> generalInstructions;

  StretchingRoutine({
    required this.routineId,
    required this.muscleGroup,
    required this.routineType,
    required this.exercises,
    required this.totalDuration,
    required this.difficultyLevel,
    required this.description,
    required this.generalInstructions,
  });

  /// Get the number of exercises in the routine
  int get exerciseCount => exercises.length;

  /// Check if the routine is empty
  bool get isEmpty => exercises.isEmpty;

  /// Get the total duration in minutes
  double get totalDurationMinutes => totalDuration / 60.0;

  /// Get the average duration per exercise
  double get averageExerciseDuration {
    if (exercises.isEmpty) return 0.0;
    return totalDuration / exercises.length;
  }

  /// Convert to map for debugging
  Map<String, dynamic> toMap() {
    return {
      'routineId': routineId,
      'muscleGroup': muscleGroup,
      'routineType': routineType,
      'exerciseCount': exerciseCount,
      'totalDuration': totalDuration,
      'totalDurationMinutes': totalDurationMinutes,
      'difficultyLevel': difficultyLevel,
      'description': description,
      'generalInstructions': generalInstructions,
      'exercises': exercises.map((e) => e.toMap()).toList(),
    };
  }
}
