import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import '../models/stretching_exercise.dart';
import '../models/stretching_routine.dart';

/// Service for loading and managing stretching exercise data
class StretchingDataService {
  static List<StretchingExercise>? _cachedExercises;
  static List<StretchingRoutine>? _cachedRoutines;

  /// Load all stretching exercises from CSV
  static Future<List<StretchingExercise>> loadStretchingExercises() async {
    if (_cachedExercises != null) {
      print('StretchingDataService: Using cached exercises (${_cachedExercises!.length} items)');
      return _cachedExercises!;
    }

    try {
      print('StretchingDataService: Loading stretching exercises from CSV...');
      final csvData = await rootBundle.loadString('assets/data/stretching_exercises.csv');
      final List<List<dynamic>> csvTable = const CsvToListConverter().convert(csvData);

      if (csvTable.isEmpty) {
        print('StretchingDataService: CSV file is empty');
        return [];
      }

      print('StretchingDataService: CSV loaded with ${csvTable.length} rows');

      // Skip header row and map to StretchingExercise objects
      final exercises = csvTable.skip(1).map((row) {
        if (row.length < 25) {
          print('StretchingDataService: Warning - row has insufficient columns: ${row.length}');
          return null;
        }
        
        try {
          return StretchingExercise.fromCSV(row);
        } catch (e) {
          print('StretchingDataService: Error parsing row: $e');
          return null;
        }
      }).where((exercise) => exercise != null).cast<StretchingExercise>().toList();

      _cachedExercises = exercises;
      print('StretchingDataService: Successfully loaded ${exercises.length} stretching exercises');
      return exercises;
    } catch (e, stackTrace) {
      print('StretchingDataService: ERROR loading stretching exercises - $e');
      print('StretchingDataService: Stack trace: $stackTrace');
      return [];
    }
  }

  /// Load stretching routines based on exercises
  static Future<List<StretchingRoutine>> loadStretchingRoutines() async {
    if (_cachedRoutines != null) {
      return _cachedRoutines!;
    }

    try {
      final exercises = await loadStretchingExercises();
      final routines = <StretchingRoutine>[];

      // Group exercises by muscle group and type
      final groupedExercises = <String, Map<String, List<StretchingExercise>>>{};
      
      for (final exercise in exercises) {
        if (!groupedExercises.containsKey(exercise.muscleGroup)) {
          groupedExercises[exercise.muscleGroup] = {};
        }
        if (!groupedExercises[exercise.muscleGroup]!.containsKey(exercise.exerciseType)) {
          groupedExercises[exercise.muscleGroup]![exercise.exerciseType] = [];
        }
        groupedExercises[exercise.muscleGroup]![exercise.exerciseType]!.add(exercise);
      }

      // Create routines for each muscle group and type combination
      for (final muscleGroup in groupedExercises.keys) {
        for (final exerciseType in groupedExercises[muscleGroup]!.keys) {
          final routineExercises = groupedExercises[muscleGroup]![exerciseType]!;
          if (routineExercises.isNotEmpty) {
            final totalDuration = routineExercises.fold(0, (sum, exercise) => sum + exercise.recommendedDuration);
            
            routines.add(StretchingRoutine(
              routineId: '${muscleGroup}_${exerciseType}',
              muscleGroup: muscleGroup,
              routineType: exerciseType,
              exercises: routineExercises,
              totalDuration: totalDuration,
              difficultyLevel: _getMostCommonDifficulty(routineExercises),
              description: '${exerciseType.capitalize()} routine for $muscleGroup',
              generalInstructions: _getGeneralInstructions(exerciseType),
            ));
          }
        }
      }

      _cachedRoutines = routines;
      print('StretchingDataService: Successfully loaded ${routines.length} stretching routines');
      return routines;
    } catch (e, stackTrace) {
      print('StretchingDataService: ERROR loading stretching routines - $e');
      print('StretchingDataService: Stack trace: $stackTrace');
      return [];
    }
  }

  /// Get routine for specific muscle group and type
  static Future<StretchingRoutine?> getRoutineForMuscle(String muscleGroup, String routineType) async {
    final routines = await loadStretchingRoutines();
    try {
      return routines.firstWhere((routine) => 
        routine.muscleGroup == muscleGroup && routine.routineType == routineType);
    } catch (e) {
      print('StretchingDataService: No routine found for $muscleGroup $routineType');
      return null;
    }
  }

  /// Get routine for specific muscle group, type, and pain level
  static Future<StretchingRoutine?> getRoutineForMuscleWithPainLevel(
    String muscleGroup, 
    String routineType, 
    int painScale
  ) async {
    try {
      print('StretchingDataService: Getting routine for $muscleGroup, $routineType, pain level $painScale');
      
      final exercises = await getExercisesForMuscleWithPainLevel(muscleGroup, routineType, painScale);
      print('StretchingDataService: Found ${exercises.length} exercises for routine');
      
      if (exercises.isEmpty) {
        print('StretchingDataService: No exercises found for $muscleGroup $routineType with pain level $painScale');
        return null;
      }

      final totalDuration = exercises.fold(0, (sum, exercise) => sum + exercise.recommendedDuration);
      
      final routine = StretchingRoutine(
        routineId: '${muscleGroup}_${routineType}_pain_${painScale}',
        muscleGroup: muscleGroup,
        routineType: routineType,
        exercises: exercises,
        totalDuration: totalDuration,
        difficultyLevel: _getMostCommonDifficulty(exercises),
        description: '${routineType.capitalize()} routine for $muscleGroup (pain level: $painScale)',
        generalInstructions: _getGeneralInstructions(routineType),
      );
      
      print('StretchingDataService: Created routine with ${exercises.length} exercises, ${totalDuration}s duration');
      return routine;
    } catch (e, stackTrace) {
      print('StretchingDataService: ERROR creating routine for $muscleGroup $routineType - $e');
      print('StretchingDataService: Stack trace: $stackTrace');
      return null;
    }
  }

  /// Get exercises for specific muscle group and type
  static Future<List<StretchingExercise>> getExercisesForMuscle(String muscleGroup, String routineType) async {
    final exercises = await loadStretchingExercises();
    return exercises.where((exercise) => 
      exercise.muscleGroup == muscleGroup && exercise.exerciseType == routineType).toList();
  }

  /// Get exercises for specific muscle group, type, and pain level
  static Future<List<StretchingExercise>> getExercisesForMuscleWithPainLevel(
    String muscleGroup, 
    String routineType, 
    int painScale
  ) async {
    try {
      print('StretchingDataService: Getting exercises for $muscleGroup, $routineType, pain level $painScale');
      
      final exercises = await loadStretchingExercises();
      print('StretchingDataService: Loaded ${exercises.length} total exercises');
      
      if (exercises.isEmpty) {
        print('StretchingDataService: No exercises loaded, returning empty list');
        return [];
      }
      
      // Filter exercises based on muscle group, type, and pain level
      final filteredExercises = exercises.where((exercise) {
        // Check muscle group and type match
        if (exercise.muscleGroup != muscleGroup || exercise.exerciseType != routineType) {
          return false;
        }
        
        // Check pain level compatibility
        return _isExerciseAppropriateForPainLevel(exercise, painScale);
      }).toList();
      
      print('StretchingDataService: Filtered to ${filteredExercises.length} exercises');
      
      // If no exercises found with pain level filtering, try without pain level filtering
      if (filteredExercises.isEmpty) {
        print('StretchingDataService: No exercises found with pain level filtering, trying without pain level');
        final exercisesWithoutPainFilter = exercises.where((exercise) {
          return exercise.muscleGroup == muscleGroup && exercise.exerciseType == routineType;
        }).toList();
        
        print('StretchingDataService: Found ${exercisesWithoutPainFilter.length} exercises without pain level filtering');
        return exercisesWithoutPainFilter;
      }
      
      return filteredExercises;
    } catch (e, stackTrace) {
      print('StretchingDataService: ERROR getting exercises for $muscleGroup $routineType - $e');
      print('StretchingDataService: Stack trace: $stackTrace');
      return [];
    }
  }

  /// Check if exercise is appropriate for given pain level
  static bool _isExerciseAppropriateForPainLevel(StretchingExercise exercise, int painScale) {
    // Get pain level classification from globals
    final painLevel = _getPainLevelClassification(painScale);
    
    // If severe pain is contraindicated for this exercise, exclude it for severe pain
    if (exercise.severePainContraindicated && painLevel == 'severe') {
      return false;
    }
    
    // Check if pain scale is within exercise's acceptable range
    if (exercise.minPainLevel != null && painScale < exercise.minPainLevel!) {
      return false;
    }
    
    if (exercise.maxPainLevel != null && painScale > exercise.maxPainLevel!) {
      return false;
    }
    
    return true;
  }

  /// Get pain level classification from pain scale
  static String _getPainLevelClassification(int painScale) {
    // Pain scale: 0-10 where 0 = no pain, 10 = severe pain
    if (painScale >= 0 && painScale <= 3) return 'good'; // Low pain
    if (painScale >= 4 && painScale <= 6) return 'low'; // Moderate pain
    if (painScale >= 7 && painScale <= 8) return 'moderate'; // High pain
    if (painScale >= 9 && painScale <= 10) return 'severe'; // Very high pain
    return 'moderate'; // Default fallback
  }

  /// Get the most common difficulty level from a list of exercises
  static String _getMostCommonDifficulty(List<StretchingExercise> exercises) {
    final difficultyCounts = <String, int>{};
    for (final exercise in exercises) {
      difficultyCounts[exercise.difficultyLevel] = (difficultyCounts[exercise.difficultyLevel] ?? 0) + 1;
    }
    return difficultyCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  /// Get general instructions based on exercise type
  static List<String> _getGeneralInstructions(String exerciseType) {
    if (exerciseType == 'warmup') {
      return [
        'Perform each exercise slowly and controlled',
        'Focus on proper form over intensity',
        'Breathe deeply throughout each movement',
        'Stop if you feel any sharp pain',
        'Hold each stretch for the recommended duration'
      ];
    } else {
      return [
        'Relax and breathe deeply during each stretch',
        'Hold each position for the full duration',
        'Focus on releasing tension from your muscles',
        'Stop if you feel any discomfort',
        'Take your time and don\'t rush through the routine'
      ];
    }
  }
}

/// Extension for string capitalization
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
