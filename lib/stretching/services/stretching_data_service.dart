import '../models/stretching_exercise.dart';
import '../models/stretching_routine.dart';
import '../../data/rehabilitation_plan.dart'; // For loadCSVFromAsset

/// Service for loading and managing stretching exercise data
class StretchingDataService {
  static List<StretchingExercise>? _cachedExercises;
  static List<StretchingRoutine>? _cachedRoutines;
  static final Map<String, String> _displayNameByKey = {};

  /// Normalize strings for robust matching (case-insensitive, trimmed)
  static String _norm(String value) => value.trim().toLowerCase();

  /// Map assessment muscle names to stretching CSV muscle group names
  /// This ensures compatibility between assessment data and stretching exercise data
  static String _mapMuscleGroup(String muscleName) {
    final normalized = _norm(muscleName);
    
    // Direct mapping from assessment muscle names to CSV muscle group names
    final muscleMap = {
      // Core muscles
      'abdominals': 'abdominals',
      'obliques': 'obliques',
      'lower back': 'lower back',
      'multifidus': 'multifidus',
      
      // Lower body
      'quadriceps': 'quadriceps',
      'hamstrings': 'hamstrings',
      'calf': 'calf',
      'calves': 'calf',
      'gluteals': 'gluteals',
      'glutes': 'gluteals',
      'ankle': 'ankle',
      'ankles': 'ankle',
      
      // Upper body
      'deltoids': 'deltoids',
      'shoulders': 'deltoids',
      'triceps': 'triceps',
      'biceps': 'biceps',
      'chest': 'chest',
      'cervical muscle': 'cervical muscle',
      'neck': 'cervical muscle',
      
      // Additional stretching CSV groups
      'upper back': 'upper back',
      'lats': 'lats',
      'latissimus': 'lats',
      'hips': 'hips',
      'hip': 'hips',
      'it band': 'it band',
      'iliotibial band': 'it band',
      'shins': 'shins',
      'shin': 'shins',
      'wrists': 'wrists',
      'wrist': 'wrists',
      'hands': 'hands',
      'hand': 'hands',
    };
    
    // Return mapped muscle name or original if no mapping found
    return muscleMap[normalized] ?? normalized;
  }

  /// Load all stretching exercises from CSV
  static Future<List<StretchingExercise>> loadStretchingExercises() async {
    if (_cachedExercises != null) {
      print('StretchingDataService: Using cached exercises (${_cachedExercises!.length} items)');
      return _cachedExercises!;
    }

    try {
      print('StretchingDataService: Loading stretching exercises from CSV...');
      final csvData = await loadCSVFromAsset('assets/data/stretching_exercises.csv');
      
      if (csvData.isEmpty) {
        print('StretchingDataService: CSV file is empty');
        return [];
      }
      
      // Expected column count for stretching exercises CSV
      const expectedColumnCount = 28;
      
      // Fix malformed header: if first row has too many columns, truncate to expected count
      List<dynamic> header = csvData.first;
      if (header.length > expectedColumnCount) {
        print('StretchingDataService: [STRETCH FIX] Header row has ${header.length} columns (expected $expectedColumnCount), truncating...');
        header = header.sublist(0, expectedColumnCount);
      }
      
      final data = csvData.sublist(1);
      
      // Build normalized header map for debug
      String _norm(String s) {
        if (s.isEmpty) return s;
        var t = s.replaceAll('\r', '').trim();
        if (t.isNotEmpty && t.codeUnitAt(0) == 0xFEFF) t = t.substring(1);
        if (t.startsWith('"') && t.endsWith('"') && t.length >= 2) {
          t = t.substring(1, t.length - 1);
        }
        t = t.toLowerCase().replaceAll(' ', '_');
        return t;
      }
      final Map<String, int> headerMap = <String, int>{};
      for (int i = 0; i < header.length && i < expectedColumnCount; i++) {
        final normalizedKey = _norm(header[i].toString());
        headerMap[normalizedKey] = i;
      }
      
      // Debug: print stretching CSV header info
      print('StretchingDataService: [STRETCH HEADER] Raw header row has ${header.length} columns (using first $expectedColumnCount)');
      print('StretchingDataService: [STRETCH HEADER] Raw header (first $expectedColumnCount): ${header.take(expectedColumnCount).toList()}');
      final normalizedColumns = headerMap.keys.toList()..sort();
      print('StretchingDataService: [STRETCH HEADER] Normalized column names (${normalizedColumns.length}): ${normalizedColumns.join(', ')}');
      print('StretchingDataService: [STRETCH HEADER] Full header map entries (${headerMap.length}): ${headerMap.entries.map((e) => '${e.key}->${e.value}').join(', ')}');
      print('StretchingDataService: [STRETCH DATA] ${data.length} stretching exercise rows');
      print('StretchingDataService: CSV loaded with ${csvData.length} total rows (header + ${data.length} data rows)');
      
      // Print first few rows for debugging (all columns)
      if (data.isNotEmpty) {
        print('StretchingDataService: [STRETCH DATA] First row (${data.first.length} columns):');
        for (int i = 0; i < data.first.length && i < expectedColumnCount; i++) {
          final value = data.first[i].toString();
          final truncated = value.length > 100 ? value.substring(0, 100) + '...' : value;
          print('StretchingDataService: [STRETCH DATA]   [$i] ${header[i]}: $truncated');
        }
        if (data.length > 1) {
          print('StretchingDataService: [STRETCH DATA] Second row (${data[1].length} columns):');
          for (int i = 0; i < data[1].length && i < expectedColumnCount; i++) {
            final value = data[1][i].toString();
            final truncated = value.length > 100 ? value.substring(0, 100) + '...' : value;
            print('StretchingDataService: [STRETCH DATA]   [$i] ${header[i]}: $truncated');
          }
        }
        if (data.length > 2) {
          print('StretchingDataService: [STRETCH DATA] Third row (${data[2].length} columns):');
          for (int i = 0; i < data[2].length && i < expectedColumnCount; i++) {
            final value = data[2][i].toString();
            final truncated = value.length > 100 ? value.substring(0, 100) + '...' : value;
            print('StretchingDataService: [STRETCH DATA]   [$i] ${header[i]}: $truncated');
          }
        }
      } else {
        print('StretchingDataService: [STRETCH DATA] WARNING: No data rows found in CSV!');
      }

      // Skip header row and map to StretchingExercise objects
      int exerciseIndex = 0;
      final exercises = data.map((row) {
        exerciseIndex++;
        if (row.length < 25) {
          print('StretchingDataService: Warning - row $exerciseIndex has insufficient columns: ${row.length} (expected at least 25)');
          print('StretchingDataService: Row data (first 10): ${row.take(10).toList()}');
          return null;
        }
        
        try {
          final exercise = StretchingExercise.fromCSV(row);
          // Debug first few exercises
          if (exerciseIndex <= 3) {
            print('StretchingDataService: Parsed exercise $exerciseIndex: ${exercise.exerciseName} (${exercise.muscleGroup}, ${exercise.exerciseType})');
          }
          return exercise;
        } catch (e, stackTrace) {
          print('StretchingDataService: Error parsing row $exerciseIndex: $e');
          print('StretchingDataService: Row data (first 10): ${row.take(10).toList()}');
          print('StretchingDataService: Stack trace: $stackTrace');
          return null;
        }
      }).where((exercise) => exercise != null).cast<StretchingExercise>().toList();

      _cachedExercises = exercises;
      print('StretchingDataService: Successfully loaded ${exercises.length} stretching exercises');
      
      // Summary debug output
      if (exercises.isNotEmpty) {
        final typeCounts = <String, int>{};
        final muscleCounts = <String, int>{};
        for (final ex in exercises) {
          typeCounts[ex.exerciseType] = (typeCounts[ex.exerciseType] ?? 0) + 1;
          muscleCounts[ex.muscleGroup] = (muscleCounts[ex.muscleGroup] ?? 0) + 1;
        }
        print('StretchingDataService: Exercise type distribution: $typeCounts');
        print('StretchingDataService: Muscle group distribution: ${muscleCounts.keys.toList()}');
        print('StretchingDataService: Deltoids exercises: ${exercises.where((e) => _norm(e.muscleGroup) == 'deltoids').length} (warmup: ${exercises.where((e) => _norm(e.muscleGroup) == 'deltoids' && _norm(e.exerciseType) == 'warmup').length}, cooldown: ${exercises.where((e) => _norm(e.muscleGroup) == 'deltoids' && _norm(e.exerciseType) == 'cooldown').length})');
      }
      
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

      // Group exercises by muscle group and type (using normalized keys with preserved display names)
      final groupedExercises = <String, Map<String, List<StretchingExercise>>>{};
      
      for (final exercise in exercises) {
        final muscleKey = _norm(exercise.muscleGroup);
        final typeKey = _norm(exercise.exerciseType);
        _displayNameByKey.putIfAbsent(muscleKey, () => exercise.muscleGroup);

        groupedExercises.putIfAbsent(muscleKey, () => {});
        groupedExercises[muscleKey]!.putIfAbsent(typeKey, () => []);
        groupedExercises[muscleKey]![typeKey]!.add(exercise);
      }

      // Create routines for each muscle group and type combination
      for (final muscleKey in groupedExercises.keys) {
        for (final typeKey in groupedExercises[muscleKey]!.keys) {
          final routineExercises = groupedExercises[muscleKey]![typeKey]!;
          if (routineExercises.isNotEmpty) {
            final totalDuration = routineExercises.fold(0, (sum, exercise) => sum + exercise.recommendedDuration);
            
            routines.add(StretchingRoutine(
              routineId: '${_displayNameByKey[muscleKey] ?? muscleKey}_${typeKey}',
              muscleGroup: _displayNameByKey[muscleKey] ?? muscleKey,
              routineType: typeKey,
              exercises: routineExercises,
              totalDuration: totalDuration,
              difficultyLevel: _getMostCommonDifficulty(routineExercises),
              description: '${typeKey.capitalize()} routine for ${_displayNameByKey[muscleKey] ?? muscleKey}',
              generalInstructions: _getGeneralInstructions(typeKey),
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
      // Map muscle group to CSV format
      final mappedMuscle = _mapMuscleGroup(muscleGroup);
      final mKey = _norm(mappedMuscle);
      final tKey = _norm(routineType);
      
      print('StretchingDataService: Looking for routine - original: "$muscleGroup", mapped: "$mappedMuscle", normalized: "$mKey"');
      print('StretchingDataService: Available routines: ${routines.map((r) => "${r.muscleGroup}_${r.routineType}").toList()}');
      
      final match = routines.firstWhere((routine) => 
        _norm(routine.muscleGroup) == mKey && _norm(routine.routineType) == tKey);
      return match;
    } catch (e) {
      print('StretchingDataService: No routine found for $muscleGroup $routineType (mapped: ${_mapMuscleGroup(muscleGroup)})');
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
    // Map muscle group to CSV format
    final mappedMuscle = _mapMuscleGroup(muscleGroup);
    final mKey = _norm(mappedMuscle);
    final tKey = _norm(routineType);
    
    print('StretchingDataService: getExercisesForMuscle - original: "$muscleGroup", mapped: "$mappedMuscle", normalized: "$mKey"');
    print('StretchingDataService: Looking for routineType: "$routineType", normalized: "$tKey"');
    print('StretchingDataService: Total exercises loaded: ${exercises.length}');
    
    // Debug: Show available exercise types and muscle groups
    final availableTypes = exercises.map((e) => e.exerciseType).toSet().toList();
    final availableMuscles = exercises.map((e) => e.muscleGroup).toSet().toList();
    print('StretchingDataService: Available exercise types: $availableTypes');
    print('StretchingDataService: Available muscle groups: $availableMuscles');
    
    // Debug: Show exercises matching muscle group (before type filter)
    final muscleMatches = exercises.where((e) => _norm(e.muscleGroup) == mKey).toList();
    print('StretchingDataService: Exercises matching muscle group "$mKey": ${muscleMatches.length}');
    if (muscleMatches.isNotEmpty) {
      print('StretchingDataService: Matching exercises by type: ${muscleMatches.map((e) => '${e.exerciseName} (${e.exerciseType})').take(5).toList()}');
    }
    
    final filtered = exercises.where((exercise) {
      final muscleMatch = _norm(exercise.muscleGroup) == mKey;
      final typeMatch = _norm(exercise.exerciseType) == tKey;
      return muscleMatch && typeMatch;
    }).toList();
    
    print('StretchingDataService: getExercisesForMuscle($muscleGroup,$routineType) -> ${filtered.length} matches');
    if (filtered.isNotEmpty) {
      print('StretchingDataService: Matched exercises: ${filtered.map((e) => e.exerciseName).toList()}');
    }
    return filtered;
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
      
      // Map muscle group to CSV format
      final mappedMuscle = _mapMuscleGroup(muscleGroup);
      final mKey = _norm(mappedMuscle);
      final tKey = _norm(routineType);
      
      print('StretchingDataService: getExercisesForMuscleWithPainLevel - original: "$muscleGroup", mapped: "$mappedMuscle", normalized: "$mKey"');
      print('StretchingDataService: Looking for routineType: "$routineType", normalized: "$tKey"');
      
      // Debug: Show available exercise types and muscle groups
      final availableTypes = exercises.map((e) => e.exerciseType).toSet().toList();
      final availableMuscles = exercises.map((e) => e.muscleGroup).toSet().toList();
      print('StretchingDataService: Available exercise types: $availableTypes');
      print('StretchingDataService: Available muscle groups: $availableMuscles');
      
      // Debug: Show exercises matching muscle group (before type filter)
      final muscleMatches = exercises.where((e) => _norm(e.muscleGroup) == mKey).toList();
      print('StretchingDataService: Exercises matching muscle group "$mKey": ${muscleMatches.length}');
      if (muscleMatches.isNotEmpty) {
        print('StretchingDataService: Matching exercises by type: ${muscleMatches.map((e) => '${e.exerciseName} (${e.exerciseType})').take(5).toList()}');
      }
      
      // Filter exercises based on muscle group, type, and pain level
      final filteredExercises = exercises.where((exercise) {
        // Check muscle group and type match
        final muscleMatch = _norm(exercise.muscleGroup) == mKey;
        final typeMatch = _norm(exercise.exerciseType) == tKey;
        
        if (!muscleMatch || !typeMatch) {
          return false;
        }
        
        // Check pain level compatibility
        final painMatch = _isExerciseAppropriateForPainLevel(exercise, painScale);
        if (!painMatch) {
          print('StretchingDataService: Exercise "${exercise.exerciseName}" excluded by pain level (min: ${exercise.minPainLevel}, max: ${exercise.maxPainLevel}, severe contraindicated: ${exercise.severePainContraindicated}, painScale: $painScale)');
        }
        return painMatch;
      }).toList();
      
      print('StretchingDataService: Filtered to ${filteredExercises.length} exercises (after muscle, type, and pain level filtering)');
      if (filteredExercises.isNotEmpty) {
        print('StretchingDataService: Filtered exercises: ${filteredExercises.map((e) => e.exerciseName).toList()}');
      }
      
      // If no exercises found with pain level filtering, try without pain level filtering
      if (filteredExercises.isEmpty) {
        print('StretchingDataService: No exercises found with pain level filtering, trying without pain level');
        final exercisesWithoutPainFilter = exercises.where((exercise) {
          return _norm(exercise.muscleGroup) == mKey && _norm(exercise.exerciseType) == tKey;
        }).toList();
        
        print('StretchingDataService: Found ${exercisesWithoutPainFilter.length} exercises without pain level filtering');
        if (exercisesWithoutPainFilter.isNotEmpty) {
          return exercisesWithoutPainFilter;
        }
        // Final fallback: if generic or unknown muscle group, try to find similar muscle groups
        if (mKey.isEmpty || mKey == 'general') {
          // Try to find exercises with similar muscle group names
          final similarGroups = exercises.where((exercise) {
            final exerciseMuscle = _norm(exercise.muscleGroup);
            return exerciseMuscle.contains(mKey) || mKey.contains(exerciseMuscle);
          }).where((exercise) => _norm(exercise.exerciseType) == tKey).toList();
          
          if (similarGroups.isNotEmpty) {
            print('StretchingDataService: Similar muscle group fallback yielded ${similarGroups.length} exercises');
            return similarGroups;
          }
          
          // Last resort: any muscle group for the routine type
          final anyGroup = exercises.where((exercise) => _norm(exercise.exerciseType) == tKey).toList();
          print('StretchingDataService: Generic muscle group fallback yielded ${anyGroup.length} exercises');
          return anyGroup;
        }
        return [];
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
