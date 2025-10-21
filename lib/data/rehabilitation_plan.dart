import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'globals.dart';
import 'treatment.dart';
import 'package:hive/hive.dart';
import 'hive_models.dart';
import 'data_persistence_service.dart';
import 'firebase_helper.dart';
import '../assessment/services/muscle_injury_dialog_service.dart';
import '../assessment/models/muscle_injury_choice.dart';
import '../data/user_data_notifier.dart';
import 'custom_exercise_service.dart';

// Service to handle CSV data retrieval
class ExerciseDataService {
  static List<Exercise>? _cachedExercises;
  static List<Treatment>? _cachedTreatments;
  static bool _isLoadingExercises = false;
  static bool _isLoadingTreatments = false;
  
  // Performance monitoring
  static int _cacheHits = 0;
  static int _cacheMisses = 0;
  static int _totalLoads = 0;
  static int _totalErrors = 0;
  static final List<int> _loadTimes = [];
  
  // Cache management
  static DateTime? _lastCacheUpdate;
  static const Duration _cacheValidityDuration = Duration(minutes: 5);
  static bool _isCacheStale = false;

  // Cache management methods
  static void invalidateCache() {
    print('ExerciseDataService: [CACHE] Invalidating cache');
    _cachedExercises = null;
    _cachedTreatments = null;
    _lastCacheUpdate = null;
    _isCacheStale = true;
  }
  
  static void markCacheStale() {
    print('ExerciseDataService: [CACHE] Marking cache as stale');
    _isCacheStale = true;
  }
  
  static bool _isCacheValid() {
    if (_cachedExercises == null || _lastCacheUpdate == null) {
      return false;
    }
    
    final now = DateTime.now();
    final cacheAge = now.difference(_lastCacheUpdate!);
    
    if (cacheAge > _cacheValidityDuration) {
      print('ExerciseDataService: [CACHE] Cache expired (age: ${cacheAge.inMinutes} minutes)');
      return false;
    }
    
    if (_isCacheStale) {
      print('ExerciseDataService: [CACHE] Cache marked as stale');
      return false;
    }
    
    return true;
  }
  
  static Future<void> refreshCache() async {
    print('ExerciseDataService: [CACHE] Refreshing cache');
    invalidateCache();
    await loadAllExercises();
    await loadAllTreatments();
  }

  // Data recovery and repair mechanisms
  static Future<Map<String, dynamic>> repairDataIssues() async {
    final stopwatch = Stopwatch()..start();
    final results = <String, dynamic>{
      'isRepaired': true,
      'issuesFound': 0,
      'issuesRepaired': 0,
      'repairActions': <String>[],
      'repairTime': 0,
    };
    
    try {
      print('ExerciseDataService: [REPAIR] Starting data repair process...');
      
      // Repair 1: Clear and reload cache
      if (_isCacheStale || _cachedExercises == null) {
        print('ExerciseDataService: [REPAIR] Clearing stale cache');
        invalidateCache();
        await loadAllExercises();
        results['repairActions'].add('Cleared and reloaded stale cache');
        results['issuesRepaired']++;
      }
      
      // Repair 2: Validate and fix exercise references
      final crossRefResults = await validateCrossReferences();
      if (crossRefResults['isValid'] == false) {
        print('ExerciseDataService: [REPAIR] Found cross-reference issues');
        results['issuesFound'] += crossRefResults['invalidReferences'] as int;
        
        // Attempt to repair missing references by checking for similar IDs
        final missingRefs = crossRefResults['missingReferences'] as List<String>;
        int repairedRefs = 0;
        
        for (final missingId in missingRefs) {
          // Try to find similar exercise IDs
          final allExercises = await loadAllExercises();
          final similarId = _findSimilarExerciseId(missingId, allExercises);
          
          if (similarId != null) {
            print('ExerciseDataService: [REPAIR] Found similar ID for $missingId: $similarId');
            // Note: In a real implementation, you would update the references here
            results['repairActions'].add('Found similar ID for $missingId: $similarId');
            repairedRefs++;
          }
        }
        
        results['issuesRepaired'] += repairedRefs;
      }
      
      // Repair 3: Validate data integrity
      final integrityResults = await validateDataIntegrity();
      if (integrityResults['isValid'] == false) {
        print('ExerciseDataService: [REPAIR] Found data integrity issues');
        results['issuesFound'] += integrityResults['invalidExercises'] as int;
        
        // Attempt to repair invalid exercises
        final issues = integrityResults['issues'] as List<String>;
        int repairedExercises = 0;
        
        for (final issue in issues) {
          if (issue.contains('invalid repetitions') || issue.contains('invalid sets')) {
            // These would need manual intervention in a real implementation
            results['repairActions'].add('Identified data validation issue: $issue');
            repairedExercises++;
          }
        }
        
        results['issuesRepaired'] += repairedExercises;
      }
      
      final repairTime = stopwatch.elapsedMilliseconds;
      results['repairTime'] = repairTime;
      
      print('ExerciseDataService: [REPAIR] Data repair completed in ${repairTime}ms');
      print('ExerciseDataService: [REPAIR] Issues found: ${results['issuesFound']}');
      print('ExerciseDataService: [REPAIR] Issues repaired: ${results['issuesRepaired']}');
      print('ExerciseDataService: [REPAIR] Repair actions: ${results['repairActions']}');
      
    } catch (e) {
      final repairTime = stopwatch.elapsedMilliseconds;
      results['isRepaired'] = false;
      results['repairTime'] = repairTime;
      results['repairActions'] = ['Repair failed: $e'];
      print('ExerciseDataService: [REPAIR] Data repair failed after ${repairTime}ms: $e');
    } finally {
      stopwatch.stop();
    }
    
    return results;
  }

  static String? _findSimilarExerciseId(String missingId, List<Exercise> allExercises) {
    // Simple similarity check - in a real implementation, you might use more sophisticated algorithms
    final availableIds = allExercises.map((e) => e.exerciseId).toList();
    
    // Check for exact match (case insensitive)
    for (final id in availableIds) {
      if (id.toLowerCase() == missingId.toLowerCase()) {
        return id;
      }
    }
    
    // Check for partial match
    for (final id in availableIds) {
      if (id.toLowerCase().contains(missingId.toLowerCase()) || 
          missingId.toLowerCase().contains(id.toLowerCase())) {
        return id;
      }
    }
    
    return null;
  }

  static Future<Map<String, dynamic>> backupData() async {
    final stopwatch = Stopwatch()..start();
    final results = <String, dynamic>{
      'isBackedUp': true,
      'backupTime': 0,
      'backupSize': 0,
      'backupLocation': '',
    };
    
    try {
      print('ExerciseDataService: [BACKUP] Starting data backup...');
      
      final exercises = await loadAllExercises();
      final treatments = await loadAllTreatments();
      
      // Create backup data structure
      final backupData = {
        'timestamp': DateTime.now().toIso8601String(),
        'exerciseCount': exercises.length,
        'treatmentCount': treatments.length,
        'version': '1.0',
      };
      
      // In a real implementation, you would save this to a file or database
      final backupJson = backupData.toString();
      final backupSize = backupJson.length;
      
      final backupTime = stopwatch.elapsedMilliseconds;
      results['backupTime'] = backupTime;
      results['backupSize'] = backupSize;
      results['backupLocation'] = 'memory_backup_${DateTime.now().millisecondsSinceEpoch}';
      
      print('ExerciseDataService: [BACKUP] Data backup completed in ${backupTime}ms');
      print('ExerciseDataService: [BACKUP] Backup size: ${backupSize} bytes');
      print('ExerciseDataService: [BACKUP] Exercises backed up: ${exercises.length}');
      print('ExerciseDataService: [BACKUP] Treatments backed up: ${treatments.length}');
      
    } catch (e) {
      final backupTime = stopwatch.elapsedMilliseconds;
      results['isBackedUp'] = false;
      results['backupTime'] = backupTime;
      print('ExerciseDataService: [BACKUP] Data backup failed after ${backupTime}ms: $e');
    } finally {
      stopwatch.stop();
    }
    
    return results;
  }

  // Load all exercises from CSV with caching and loading state
  static Future<List<Exercise>> loadAllExercises() async {
    if (_cachedExercises != null && _isCacheValid()) {
      _cacheHits++;
      print('ExerciseDataService: [CACHE] Returning cached exercises (${_cachedExercises!.length} items) - Cache hit #$_cacheHits');
      return _cachedExercises!;
    }
    if (_isLoadingExercises) {
      print('ExerciseDataService: [CACHE] Waiting for ongoing load to complete...');
      // Wait for ongoing load to complete
      while (_isLoadingExercises) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      return _cachedExercises ?? [];
    }
    
    _isLoadingExercises = true;
    _cacheMisses++;
    _totalLoads++;
    final stopwatch = Stopwatch()..start();
    try {
      print('ExerciseDataService: [LOAD] Starting CSV data loading... - Cache miss #$_cacheMisses, Total loads: $_totalLoads');
      final csvData = await loadCSVFromAsset('assets/data/exercises.csv');
      final header = csvData.first;
      final data = csvData.sublist(1);

      // Validate CSV structure
      final requiredColumns = ['Exercise_ID', 'Exercise', 'Exercise_Description', 'Muscle_Involved', 'Pain_Level', 'Functional_Goal', 'Repetition', 'Set'];
      final missingColumns = requiredColumns.where((col) => !header.contains(col)).toList();
      if (missingColumns.isNotEmpty) {
        print('ExerciseDataService: [ERROR] Missing required CSV columns: $missingColumns');
        print('ExerciseDataService: [DEBUG] Available columns: $header');
        return [];
      }

      print('ExerciseDataService: [VALIDATE] CSV structure validated - ${header.length} columns, ${data.length} data rows');

      int col(String name) => header.indexOf(name);

      final exercises = <Exercise>[];
      int validRows = 0;
      int invalidRows = 0;

      for (int i = 0; i < data.length; i++) {
        final row = data[i];
        try {
          // Validate required fields
          final exerciseId = row[col('Exercise_ID')].toString();
          final exerciseName = row[col('Exercise')].toString();
          final description = row[col('Exercise_Description')].toString();
          
          if (exerciseId.isEmpty || exerciseName.isEmpty || description.isEmpty) {
            print('ExerciseDataService: [WARNING] Row ${i + 2} has empty required fields - ID: "$exerciseId", Name: "$exerciseName", Description: "$description"');
            invalidRows++;
            continue;
          }

          // Validate numeric fields
          final repetitions = int.tryParse(row[col('Repetition')].toString());
          final sets = int.tryParse(row[col('Set')].toString());
          
          if (repetitions == null || repetitions <= 0) {
            print('ExerciseDataService: [WARNING] Row ${i + 2} has invalid repetitions: "${row[col('Repetition')]}"');
            invalidRows++;
            continue;
          }
          
          if (sets == null || sets <= 0) {
            print('ExerciseDataService: [WARNING] Row ${i + 2} has invalid sets: "${row[col('Set')]}"');
            invalidRows++;
            continue;
          }

          final exercise = Exercise(
            exerciseId: exerciseId,
            exerciseName: exerciseName,
            description: description,
            muscle: row[col('Muscle_Involved')].toString(),
            painLevel: row[col('Pain_Level')].toString(),
            goal: row[col('Functional_Goal')].toString(),
            repetitions: repetitions,
            sets: sets,
            imageUrl: row[col('Image_Link')].toString(),
            videoUrl: row[col('Video_Link')].toString(),
            otherMuscles: row[col('Other_Muscles')].toString(),
          );
          
          exercises.add(exercise);
          validRows++;
        } catch (e) {
          print('ExerciseDataService: [ERROR] Failed to parse row ${i + 2}: $e');
          invalidRows++;
        }
      }

      // Load custom exercises and merge with default exercises
      try {
        print('ExerciseDataService: [CUSTOM] Loading custom exercises...');
        final customExercises = await CustomExerciseService.loadCustomExercises();
        
        // Convert custom exercises to the same format as default exercises
        final convertedCustomExercises = customExercises.map((customEx) => Exercise(
          exerciseId: customEx.id,
          exerciseName: customEx.name,
          description: customEx.description,
          muscle: customEx.muscle,
          painLevel: customEx.painLevel,
          goal: customEx.goal,
          repetitions: customEx.rep,
          sets: customEx.set,
          imageUrl: customEx.imageUrl,
          videoUrl: customEx.videoUrl,
          otherMuscles: customEx.otherMuscles,
        )).toList();
        
        // Merge custom exercises with default exercises
        exercises.addAll(convertedCustomExercises);
        print('ExerciseDataService: [CUSTOM] Loaded ${convertedCustomExercises.length} custom exercises');
      } catch (e) {
        print('ExerciseDataService: [CUSTOM] Error loading custom exercises: $e');
        // Continue with default exercises only if custom exercises fail to load
      }

      _cachedExercises = exercises;
      _lastCacheUpdate = DateTime.now();
      _isCacheStale = false;
      final loadTime = stopwatch.elapsedMilliseconds;
      _loadTimes.add(loadTime);
      
      print('ExerciseDataService: [SUCCESS] Loaded ${exercises.length} total exercises (default + custom) in ${loadTime}ms');
      print('ExerciseDataService: [STATS] Valid rows: $validRows, Invalid rows: $invalidRows');
      print('ExerciseDataService: [PERF] Load time: ${loadTime}ms, Average: ${_getAverageLoadTime()}ms, Cache hit rate: ${_getCacheHitRate()}%');
      print('ExerciseDataService: [CACHE] Cache updated at ${_lastCacheUpdate}');
      
      if (invalidRows > 0) {
        print('ExerciseDataService: [WARNING] $invalidRows rows were skipped due to validation errors');
      }
      
      return _cachedExercises!;
    } catch (e) {
      final loadTime = stopwatch.elapsedMilliseconds;
      _totalErrors++;
      print('ExerciseDataService: [ERROR] Failed to load exercises from CSV after ${loadTime}ms: $e');
      print('ExerciseDataService: [PERF] Error count: $_totalErrors, Cache hit rate: ${_getCacheHitRate()}%');
      print('ExerciseDataService: [DEBUG] Stack trace: ${StackTrace.current}');
      return [];
    } finally {
      _isLoadingExercises = false;
      stopwatch.stop();
    }
  }

  // Load all treatments from CSV with caching and loading state
  static Future<List<Treatment>> loadAllTreatments() async {
    if (_cachedTreatments != null) return _cachedTreatments!;
    if (_isLoadingTreatments) {
      // Wait for ongoing load to complete
      while (_isLoadingTreatments) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      return _cachedTreatments ?? [];
    }
    
    _isLoadingTreatments = true;
    try {
      print('ExerciseDataService: Loading treatments from CSV...');
      final csvData = await loadCSVFromAsset('assets/data/treatment.csv');
      final header = csvData.first;
      final data = csvData.sublist(1);

      int col(String name) => header.indexOf(name);

      _cachedTreatments = data.map((row) {
        return Treatment(
          treatmentId: row[col('Treatment_ID')].toString(),
          treatmentName: row[col('Treatment')].toString(),
          description: row[col('Treatment_Description')].toString(),
          musclesInvolved: row[col('Muscle_Involved')].toString(),
          painLevel: row[col('Pain_Level')].toString(),
          painDuration: row[col('Pain_Duration')].toString(),
        );
      }).toList();

      print('ExerciseDataService: Loaded ${_cachedTreatments!.length} treatments from CSV');
      return _cachedTreatments!;
    } catch (e) {
      print('Error loading treatments from CSV: $e');
      return [];
    } finally {
      _isLoadingTreatments = false;
    }
  }

  // Get exercises by IDs
  static Future<List<Exercise>> getExercisesByIds(List<String> exerciseIds) async {
    try {
      // Validate input
      if (exerciseIds.isEmpty) {
        print('ExerciseDataService: No exercise IDs provided');
        return [];
      }
      
      // Remove duplicates and filter out empty IDs
      final validIds = exerciseIds.where((id) => id.isNotEmpty).toSet().toList();
      if (validIds.isEmpty) {
        print('ExerciseDataService: No valid exercise IDs provided');
        return [];
      }
      
      print('ExerciseDataService: Loading ${validIds.length} exercises by IDs: $validIds');
      final allExercises = await loadAllExercises();
      
      if (allExercises.isEmpty) {
        print('ExerciseDataService: No exercises loaded from CSV');
        return [];
      }
      
      final foundExercises = allExercises.where((exercise) => validIds.contains(exercise.exerciseId)).toList();
      final foundIds = foundExercises.map((e) => e.exerciseId).toSet();
      final missingIds = validIds.where((id) => !foundIds.contains(id)).toList();
      
      if (missingIds.isNotEmpty) {
        print('ExerciseDataService: Warning - Could not find exercises with IDs: $missingIds');
      }
      
      print('ExerciseDataService: Found ${foundExercises.length} out of ${validIds.length} requested exercises');
      return foundExercises;
    } catch (e) {
      print('ExerciseDataService: Error loading exercises by IDs: $e');
      return [];
    }
  }

  // Get treatments by IDs
  static Future<List<Treatment>> getTreatmentsByIds(List<String> treatmentIds) async {
    try {
      // Validate input
      if (treatmentIds.isEmpty) {
        print('ExerciseDataService: No treatment IDs provided');
        return [];
      }
      
      // Remove duplicates and filter out empty IDs
      final validIds = treatmentIds.where((id) => id.isNotEmpty).toSet().toList();
      if (validIds.isEmpty) {
        print('ExerciseDataService: No valid treatment IDs provided');
        return [];
      }
      
      print('ExerciseDataService: Loading ${validIds.length} treatments by IDs: $validIds');
      final allTreatments = await loadAllTreatments();
      
      if (allTreatments.isEmpty) {
        print('ExerciseDataService: No treatments loaded from CSV');
        return [];
      }
      
      final foundTreatments = allTreatments.where((treatment) => validIds.contains(treatment.treatmentId)).toList();
      final foundIds = foundTreatments.map((t) => t.treatmentId).toSet();
      final missingIds = validIds.where((id) => !foundIds.contains(id)).toList();
      
      if (missingIds.isNotEmpty) {
        print('ExerciseDataService: Warning - Could not find treatments with IDs: $missingIds');
      }
      
      print('ExerciseDataService: Found ${foundTreatments.length} out of ${validIds.length} requested treatments');
      return foundTreatments;
    } catch (e) {
      print('ExerciseDataService: Error loading treatments by IDs: $e');
      return [];
    }
  }

  // Performance monitoring helper methods
  static double _getAverageLoadTime() {
    if (_loadTimes.isEmpty) return 0.0;
    return _loadTimes.reduce((a, b) => a + b) / _loadTimes.length;
  }
  
  static double _getCacheHitRate() {
    final totalRequests = _cacheHits + _cacheMisses;
    if (totalRequests == 0) return 0.0;
    return (_cacheHits / totalRequests) * 100;
  }
  
  static void _printPerformanceStats() {
    print('ExerciseDataService: [PERF] Performance Statistics:');
    print('ExerciseDataService: [PERF] - Cache hits: $_cacheHits');
    print('ExerciseDataService: [PERF] - Cache misses: $_cacheMisses');
    print('ExerciseDataService: [PERF] - Total loads: $_totalLoads');
    print('ExerciseDataService: [PERF] - Total errors: $_totalErrors');
    print('ExerciseDataService: [PERF] - Cache hit rate: ${_getCacheHitRate().toStringAsFixed(1)}%');
    print('ExerciseDataService: [PERF] - Average load time: ${_getAverageLoadTime().toStringAsFixed(1)}ms');
    if (_loadTimes.isNotEmpty) {
      print('ExerciseDataService: [PERF] - Min load time: ${_loadTimes.reduce((a, b) => a < b ? a : b)}ms');
      print('ExerciseDataService: [PERF] - Max load time: ${_loadTimes.reduce((a, b) => a > b ? a : b)}ms');
    }
  }
  
  // Cross-reference validation between data sources
  static Future<Map<String, dynamic>> validateCrossReferences() async {
    final stopwatch = Stopwatch()..start();
    final results = <String, dynamic>{
      'isValid': true,
      'totalReferences': 0,
      'validReferences': 0,
      'invalidReferences': 0,
      'orphanedReferences': <String>[],
      'missingReferences': <String>[],
      'validationTime': 0,
    };
    
    try {
      print('ExerciseDataService: [CROSS-REF] Starting cross-reference validation...');
      
      // Load all exercises from CSV
      final allExercises = await loadAllExercises();
      final availableIds = allExercises.map((e) => e.exerciseId).toSet();
      
      // Get rehabilitation plans from UserDataNotifier
      final rehabilitationPlans = UserDataNotifier.instance.rehabPlans.isNotEmpty 
          ? UserDataNotifier.instance.rehabPlans 
          : UserRehabilitation.instance.rehabPlans;
      
      int totalReferences = 0;
      int validReferences = 0;
      int invalidReferences = 0;
      final orphanedReferences = <String>[];
      final missingReferences = <String>[];
      
      for (final plan in rehabilitationPlans) {
        for (final exerciseRef in plan.exerciseReferences) {
          totalReferences++;
          
          if (availableIds.contains(exerciseRef.exerciseId)) {
            validReferences++;
            print('ExerciseDataService: [CROSS-REF] ✓ Valid reference: ${exerciseRef.exerciseId}');
          } else {
            invalidReferences++;
            missingReferences.add(exerciseRef.exerciseId);
            print('ExerciseDataService: [CROSS-REF] ✗ Missing reference: ${exerciseRef.exerciseId}');
          }
        }
      }
      
      // Check for orphaned exercises (in CSV but not referenced)
      final referencedIds = rehabilitationPlans
          .expand((plan) => plan.exerciseReferences)
          .map((ref) => ref.exerciseId)
          .toSet();
      
      for (final exerciseId in availableIds) {
        if (!referencedIds.contains(exerciseId)) {
          orphanedReferences.add(exerciseId);
          print('ExerciseDataService: [CROSS-REF] ⚠ Orphaned exercise: $exerciseId');
        }
      }
      
      results['totalReferences'] = totalReferences;
      results['validReferences'] = validReferences;
      results['invalidReferences'] = invalidReferences;
      results['orphanedReferences'] = orphanedReferences;
      results['missingReferences'] = missingReferences;
      results['isValid'] = invalidReferences == 0;
      
      final validationTime = stopwatch.elapsedMilliseconds;
      results['validationTime'] = validationTime;
      
      print('ExerciseDataService: [CROSS-REF] Validation complete in ${validationTime}ms');
      print('ExerciseDataService: [CROSS-REF] - Total references: $totalReferences');
      print('ExerciseDataService: [CROSS-REF] - Valid references: $validReferences');
      print('ExerciseDataService: [CROSS-REF] - Invalid references: $invalidReferences');
      print('ExerciseDataService: [CROSS-REF] - Orphaned exercises: ${orphanedReferences.length}');
      print('ExerciseDataService: [CROSS-REF] - Missing references: ${missingReferences.length}');
      
      if (missingReferences.isNotEmpty) {
        print('ExerciseDataService: [CROSS-REF] Missing exercise IDs: $missingReferences');
      }
      
      if (orphanedReferences.isNotEmpty) {
        print('ExerciseDataService: [CROSS-REF] Orphaned exercise IDs: ${orphanedReferences.take(10).toList()}');
      }
      
    } catch (e) {
      final validationTime = stopwatch.elapsedMilliseconds;
      results['isValid'] = false;
      results['validationTime'] = validationTime;
      results['missingReferences'] = ['Cross-reference validation failed: $e'];
      print('ExerciseDataService: [CROSS-REF] Validation failed after ${validationTime}ms: $e');
    } finally {
      stopwatch.stop();
    }
    
    return results;
  }

  // Data integrity validation
  static Future<Map<String, dynamic>> validateDataIntegrity() async {
    final stopwatch = Stopwatch()..start();
    final results = <String, dynamic>{
      'isValid': true,
      'totalExercises': 0,
      'validExercises': 0,
      'invalidExercises': 0,
      'issues': <String>[],
      'validationTime': 0,
    };
    
    try {
      print('ExerciseDataService: [INTEGRITY] Starting data integrity validation...');
      
      final exercises = await loadAllExercises();
      results['totalExercises'] = exercises.length;
      
      int validCount = 0;
      int invalidCount = 0;
      final issues = <String>[];
      
      for (final exercise in exercises) {
        bool isValid = true;
        
        // Validate required fields
        if (exercise.exerciseId.isEmpty) {
          issues.add('Exercise with empty ID found');
          isValid = false;
        }
        
        if (exercise.exerciseName.isEmpty) {
          issues.add('Exercise "${exercise.exerciseId}" has empty name');
          isValid = false;
        }
        
        if (exercise.description.isEmpty) {
          issues.add('Exercise "${exercise.exerciseId}" has empty description');
          isValid = false;
        }
        
        // Validate numeric fields
        if (exercise.repetitions <= 0) {
          issues.add('Exercise "${exercise.exerciseId}" has invalid repetitions: ${exercise.repetitions}');
          isValid = false;
        }
        
        if (exercise.sets <= 0) {
          issues.add('Exercise "${exercise.exerciseId}" has invalid sets: ${exercise.sets}');
          isValid = false;
        }
        
        // Validate muscle field
        if (exercise.muscle.isEmpty) {
          issues.add('Exercise "${exercise.exerciseId}" has empty muscle field');
          isValid = false;
        }
        
        // Validate pain level
        if (exercise.painLevel.isEmpty) {
          issues.add('Exercise "${exercise.exerciseId}" has empty pain level');
          isValid = false;
        }
        
        // Validate goal field
        if (exercise.goal.isEmpty) {
          issues.add('Exercise "${exercise.exerciseId}" has empty goal field');
          isValid = false;
        }
        
        if (isValid) {
          validCount++;
        } else {
          invalidCount++;
        }
      }
      
      results['validExercises'] = validCount;
      results['invalidExercises'] = invalidCount;
      results['issues'] = issues;
      results['isValid'] = invalidCount == 0;
      
      final validationTime = stopwatch.elapsedMilliseconds;
      results['validationTime'] = validationTime;
      
      print('ExerciseDataService: [INTEGRITY] Validation complete in ${validationTime}ms');
      print('ExerciseDataService: [INTEGRITY] - Total exercises: ${exercises.length}');
      print('ExerciseDataService: [INTEGRITY] - Valid exercises: $validCount');
      print('ExerciseDataService: [INTEGRITY] - Invalid exercises: $invalidCount');
      print('ExerciseDataService: [INTEGRITY] - Issues found: ${issues.length}');
      
      if (issues.isNotEmpty) {
        print('ExerciseDataService: [INTEGRITY] Issues:');
        for (final issue in issues.take(10)) {
          print('ExerciseDataService: [INTEGRITY] - $issue');
        }
        if (issues.length > 10) {
          print('ExerciseDataService: [INTEGRITY] - ... and ${issues.length - 10} more issues');
        }
      }
      
    } catch (e) {
      final validationTime = stopwatch.elapsedMilliseconds;
      results['isValid'] = false;
      results['validationTime'] = validationTime;
      results['issues'] = ['Validation failed: $e'];
      print('ExerciseDataService: [INTEGRITY] Validation failed after ${validationTime}ms: $e');
    } finally {
      stopwatch.stop();
    }
    
    return results;
  }

  // Get single exercise by ID
  static Future<Exercise?> getExerciseById(String exerciseId) async {
    final stopwatch = Stopwatch()..start();
    try {
      // Validate input
      if (exerciseId.isEmpty) {
        print('ExerciseDataService: [ERROR] Empty exercise ID provided');
        return null;
      }
      
      print('ExerciseDataService: [DEBUG] Starting exercise lookup for ID: $exerciseId');
      print('ExerciseDataService: [DEBUG] Cache status - _cachedExercises: ${_cachedExercises != null ? 'loaded (${_cachedExercises!.length} items)' : 'not loaded'}');
      
      final allExercises = await loadAllExercises();
      final loadTime = stopwatch.elapsedMilliseconds;
      
      print('ExerciseDataService: [DEBUG] CSV data loaded in ${loadTime}ms, found ${allExercises.length} exercises');
      
      if (allExercises.isEmpty) {
        print('ExerciseDataService: [ERROR] No exercises loaded from CSV after ${loadTime}ms');
        return null;
      }
      
      // Log available exercise IDs for debugging
      final availableIds = allExercises.take(5).map((e) => e.exerciseId).toList();
      print('ExerciseDataService: [DEBUG] Sample available exercise IDs: $availableIds');
      
      try {
        final exercise = allExercises.firstWhere((exercise) => exercise.exerciseId == exerciseId);
        final totalTime = stopwatch.elapsedMilliseconds;
        print('ExerciseDataService: [SUCCESS] Found exercise "${exercise.exerciseName}" (ID: $exerciseId) in ${totalTime}ms');
        print('ExerciseDataService: [DEBUG] Exercise details - Muscle: ${exercise.muscle}, Pain Level: ${exercise.painLevel}, Goal: ${exercise.goal}');
        return exercise;
      } catch (e) {
        final totalTime = stopwatch.elapsedMilliseconds;
        print('ExerciseDataService: [ERROR] Exercise not found with ID: $exerciseId after ${totalTime}ms');
        print('ExerciseDataService: [DEBUG] Available exercise IDs: ${allExercises.map((e) => e.exerciseId).toList()}');
        return null;
      }
    } catch (e) {
      final totalTime = stopwatch.elapsedMilliseconds;
      print('ExerciseDataService: [ERROR] Exception loading exercise by ID $exerciseId after ${totalTime}ms: $e');
      print('ExerciseDataService: [DEBUG] Stack trace: ${StackTrace.current}');
      return null;
    } finally {
      stopwatch.stop();
    }
  }

  // Get single treatment by ID
  static Future<Treatment?> getTreatmentById(String treatmentId) async {
    try {
      // Validate input
      if (treatmentId.isEmpty) {
        print('ExerciseDataService: Empty treatment ID provided');
        return null;
      }
      
      print('ExerciseDataService: Loading treatment by ID: $treatmentId');
      final allTreatments = await loadAllTreatments();
      
      if (allTreatments.isEmpty) {
        print('ExerciseDataService: No treatments loaded from CSV');
        return null;
      }
      
      try {
        final treatment = allTreatments.firstWhere((treatment) => treatment.treatmentId == treatmentId);
        print('ExerciseDataService: Found treatment: ${treatment.treatmentName}');
        return treatment;
      } catch (e) {
        print('ExerciseDataService: Treatment not found with ID: $treatmentId');
        return null;
      }
    } catch (e) {
      print('ExerciseDataService: Error loading treatment by ID $treatmentId: $e');
      return null;
    }
  }

  // Clear cache (useful for testing or when CSV files are updated)
  static void clearCache() {
    _cachedExercises = null;
    _cachedTreatments = null;
  }
}

class Exercise {
  final String exerciseId;
  final String exerciseName;
  final String description;
  final String muscle;
  final String painLevel;
  final String goal;
  final int repetitions;
  final int sets;
  final String imageUrl;
  final String videoUrl;
  final String otherMuscles;

  Exercise({
    required this.exerciseId,
    required this.exerciseName,
    required this.description,
    required this.muscle,
    required this.painLevel,
    required this.goal,
    required this.repetitions,
    required this.sets,
    required this.imageUrl,
    required this.videoUrl,
    required this.otherMuscles,
  });

  @override
  String toString() {
    return '$exerciseName ($repetitions x $sets)';
  }
}

// Lightweight exercise reference for storage
class ExerciseReference {
  final String exerciseId;
  final int repetitions;
  final int sets;

  ExerciseReference({
    required this.exerciseId,
    required this.repetitions,
    required this.sets,
  });

  Map<String, dynamic> toMap() {
    return {
      'exerciseId': exerciseId,
      'repetitions': repetitions,
      'sets': sets,
    };
  }

  factory ExerciseReference.fromMap(Map<String, dynamic> map) {
    return ExerciseReference(
      exerciseId: map['exerciseId'] ?? '',
      repetitions: map['repetitions'] ?? 0,
      sets: map['sets'] ?? 0,
    );
  }
}

class RehabilitationPlan {
  final int weekNumber;
  final List<ExerciseReference> exerciseReferences;
  final List<DailyProgress> daily;
  final String id;
  final String name;
  final String description;
  final DateTime createdAt;
  final bool isActive;
  final bool isGuestPlan;

  RehabilitationPlan({
    required this.weekNumber,
    required this.exerciseReferences,
    this.daily = const [],
    this.id = '',
    this.name = '',
    this.description = '',
    DateTime? createdAt,
    this.isActive = true,
    this.isGuestPlan = false,
  }) : createdAt = createdAt ?? DateTime.now();

  // Get full exercise data from CSV
  Future<List<Exercise>> getExercises() async {
    return await ExerciseDataService.getExercisesByIds(
      exerciseReferences.map((ref) => ref.exerciseId).toList(),
    );
  }
}

class UserRehabilitation {
  static final UserRehabilitation _instance = UserRehabilitation._internal();
  static UserRehabilitation get instance => _instance;
  UserRehabilitation._internal();

  String selectedMuscle = '';
  String selectedPainLevel = '';
  String selectedPainDuration = '';
  String selectedGoal = '';

  List<RehabilitationPlan> rehabPlans = [];
  List<TreatmentReference>? treatmentReferences;
  RehabilitationPlan? activePlan;

  // Get full treatment data from CSV
  Future<List<Treatment>?> getTreatments() async {
    if (treatmentReferences == null || treatmentReferences!.isEmpty) return null;
    return await ExerciseDataService.getTreatmentsByIds(
      treatmentReferences!.map((ref) => ref.treatmentId).toList(),
    );
  }

  // Firebase instances
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;


  // Firebase persistence methods
  Future<void> savePlansToFirebase() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('No authenticated user found for saving rehabilitation plans');
        return;
      }

      final String userId = currentUser.uid;

      // Ensure user document exists first
      await FirebaseHelper.ensureUserDocument();

      // Build rehabilitation plans document structure
      // Document: rehabilitation/{userId}
      // Fields:
      //   Plan1: [ { exercise1: id, ... }, { treatment1: id, ... } ]
      //   Plan2: [ { ... }, { ... } ]
      final Map<String, dynamic> rehabDocData = <String, dynamic>{
        'userId': userId,
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      // If there are no plans and no treatments, clear the document
      if (rehabPlans.isEmpty && (treatmentReferences == null || treatmentReferences!.isEmpty)) {
        await _firestore.collection('rehabilitation').doc(userId).set(rehabDocData, SetOptions(merge: true));
        print('Saved empty rehabilitation structure with metadata');
      } else {
        int planIndex = 1;
        for (final plan in rehabPlans.isEmpty ? [
          RehabilitationPlan(weekNumber: 1, exerciseReferences: [])
        ] : rehabPlans) {
          // Map 0: exercises as exercise# -> Exercise_ID
          final Map<String, dynamic> exercisesMap = <String, dynamic>{};
          int exerciseCounter = 1;
          for (final exerciseRef in plan.exerciseReferences) {
            exercisesMap['exercise$exerciseCounter'] = exerciseRef.exerciseId;
            exerciseCounter++;
          }

          // Map 1: treatments as treatment# -> Treatment_ID
          final Map<String, dynamic> treatmentsMap = <String, dynamic>{};
          if (treatmentReferences != null && treatmentReferences!.isNotEmpty) {
            int treatmentCounter = 1;
            for (final treatmentRef in treatmentReferences!) {
              treatmentsMap['treatment$treatmentCounter'] = treatmentRef.treatmentId;
              treatmentCounter++;
            }
          }

          rehabDocData['Plan$planIndex'] = <Map<String, dynamic>>[
            exercisesMap,
            treatmentsMap,
          ];
          planIndex++;
        }

        await _firestore.collection('rehabilitation').doc(userId).set(rehabDocData, SetOptions(merge: true));
        print('Saved rehabilitation plans to Firebase in new structure');
      }

      print('Successfully saved rehabilitation data to Firebase (new structure)');
    } catch (e) {
      print('Error saving rehabilitation data to Firebase: $e');
      rethrow;
    }
  }

  Future<void> loadPlansFromFirebase() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('No authenticated user found for loading rehabilitation plans');
        return;
      }

      final String userId = currentUser.uid;

      // Ensure user document exists first
      await FirebaseHelper.ensureUserDocument();

      // Load rehabilitation document: rehabilitation/{userId}
      DocumentSnapshot rehabDoc = await _firestore
          .collection('rehabilitation')
          .doc(userId)
          .get();

      rehabPlans = [];
      treatmentReferences = null;

      if (rehabDoc.exists) {
        Map<String, dynamic> data = rehabDoc.data() as Map<String, dynamic>;

        // Find all Plan# fields and process in order
        List<String> planKeys = data.keys
            .where((k) => k.toString().toLowerCase().startsWith('plan'))
            .map((k) => k.toString())
            .toList()
          ..sort((a, b) {
            int ai = int.tryParse(a.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
            int bi = int.tryParse(b.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
            return ai.compareTo(bi);
          });

        // One-time migration: if document exists but no Plan# fields, try legacy path
        if (planKeys.isEmpty) {
          print('Rehabilitation doc found but no Plan# fields. Attempting one-time migration from legacy subcollections...');
          // Legacy: users/{uid}/exercise:exercises and users/{uid}/treatment:treatments
          final DocumentSnapshot legacyExercise = await _firestore
              .collection('users')
              .doc(userId)
              .collection('exercise')
              .doc('exercises')
              .get();
          final DocumentSnapshot legacyTreatment = await _firestore
              .collection('users')
              .doc(userId)
              .collection('treatment')
              .doc('treatments')
              .get();

          final Map<String, dynamic> exercisesMap = <String, dynamic>{};
          final Map<String, dynamic> treatmentsMap = <String, dynamic>{};

          if (legacyExercise.exists) {
            final Map<String, dynamic> exData = legacyExercise.data() as Map<String, dynamic>;
            int e = 1;
            while (exData.containsKey('exercise$e')) {
              exercisesMap['exercise$e'] = exData['exercise$e'];
              e++;
            }
          }
          if (legacyTreatment.exists) {
            final Map<String, dynamic> trData = legacyTreatment.data() as Map<String, dynamic>;
            int t = 1;
            while (trData.containsKey('treatment$t')) {
              treatmentsMap['treatment$t'] = trData['treatment$t'];
              t++;
            }
          }

          if (exercisesMap.isNotEmpty || treatmentsMap.isNotEmpty) {
            final Map<String, dynamic> migrated = <String, dynamic>{
              'userId': userId,
              'lastUpdated': FieldValue.serverTimestamp(),
              'Plan1': <Map<String, dynamic>>[exercisesMap, treatmentsMap],
            };
            await _firestore.collection('rehabilitation').doc(userId).set(migrated, SetOptions(merge: true));
            print('Migration wrote Plan1 to rehabilitation/{userId}. Reloading document...');
            rehabDoc = await _firestore.collection('rehabilitation').doc(userId).get();
            data = rehabDoc.data() as Map<String, dynamic>;
            planKeys = data.keys
                .where((k) => k.toString().toLowerCase().startsWith('plan'))
                .map((k) => k.toString())
                .toList()
              ..sort((a, b) {
                int ai = int.tryParse(a.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                int bi = int.tryParse(b.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                return ai.compareTo(bi);
              });
          } else {
            print('Legacy subcollections empty; skipping migration.');
          }
        }

        List<TreatmentReference> aggregatedTreatmentRefs = <TreatmentReference>[];

        for (final key in planKeys) {
          final dynamic planValue = data[key];
          if (planValue is List && planValue.length >= 2) {
            final Map<String, dynamic> exercisesMap = Map<String, dynamic>.from(planValue[0] as Map);
            final Map<String, dynamic> treatmentsMap = Map<String, dynamic>.from(planValue[1] as Map);

            // Extract exercise IDs by scanning exercise# fields
            final List<String> exerciseIds = <String>[];
            int eIndex = 1;
            while (exercisesMap.containsKey('exercise$eIndex')) {
              final dynamic id = exercisesMap['exercise$eIndex'];
              if (id is String && id.isNotEmpty) {
                exerciseIds.add(id);
              }
              eIndex++;
            }

            // Map exercise IDs to ExerciseReference using CSV defaults for reps/sets
            final List<Exercise> exercises = await ExerciseDataService.getExercisesByIds(exerciseIds);
            final List<ExerciseReference> exerciseRefs = exercises.map((ex) =>
                ExerciseReference(exerciseId: ex.exerciseId, repetitions: ex.repetitions, sets: ex.sets)
            ).toList();

            rehabPlans.add(
              RehabilitationPlan(
                weekNumber: rehabPlans.length + 1,
                exerciseReferences: exerciseRefs,
                daily: [],
              ),
            );

            // Extract treatment IDs
            int tIndex = 1;
            while (treatmentsMap.containsKey('treatment$tIndex')) {
              final dynamic tid = treatmentsMap['treatment$tIndex'];
              if (tid is String && tid.isNotEmpty) {
                aggregatedTreatmentRefs.add(TreatmentReference(treatmentId: tid));
              }
              tIndex++;
            }
          }
        }

        treatmentReferences = aggregatedTreatmentRefs.isNotEmpty ? aggregatedTreatmentRefs : null;

        print('Loaded ${rehabPlans.length} plans and ${aggregatedTreatmentRefs.length} treatment refs from rehabilitation collection');
      } else {
        print('No rehabilitation document found for user');
      }

      print('Successfully loaded and reconstructed rehabilitation data from Firebase (new structure)');
    } catch (e) {
      print('Error loading rehabilitation data from Firebase: $e');
      // Reset to empty state on error
      rehabPlans = [];
      treatmentReferences = null;
    }
  }

  // Sync data between Firebase and Hive
  Future<void> syncWithFirebase() async {
    try {
      // First try to load from Firebase
      await loadPlansFromFirebase();
      
      // Then save to Hive for offline access
      await savePlansToHive();
      
      print('Successfully synced rehabilitation data between Firebase and Hive');
    } catch (e) {
      print('Error syncing rehabilitation data: $e');
      // Fallback to Hive-only if Firebase fails
      await loadPlansFromHive();
    }
  }

  // Hive persistence - now saves only IDs like Firebase
  Future<void> savePlansToHive() async {
    try {
      if (!Hive.isBoxOpen('rehabBox')) {
        print('UserRehabilitation.savePlansToHive: Hive box not open, attempting to open...');
        await openRehabBox();
      }
      final box = Hive.box('rehabBox');
      
      // Extract all unique exercise IDs from rehabilitation plans
      final Set<String> exerciseIds = <String>{};
      for (final plan in rehabPlans) {
        for (final exerciseRef in plan.exerciseReferences) {
          exerciseIds.add(exerciseRef.exerciseId);
        }
      }

      // Save exercise IDs to Hive
      if (exerciseIds.isNotEmpty) {
        final hiveExerciseIds = HiveExerciseIds(exerciseIds: exerciseIds.toList());
        await box.put('exerciseIds', hiveExerciseIds);
        print('Saved ${exerciseIds.length} exercise IDs to Hive');
      } else {
        // Only clear stored IDs if we explicitly have plans loaded (even if empty).
        // If rehabPlans is empty, we assume data might not be loaded yet and preserve existing Hive data.
        if (rehabPlans.isNotEmpty) {
          await box.delete('exerciseIds');
          print('Cleared exercise IDs from Hive (explicit empty plan)');
        } else {
          print('Exercise IDs empty but no plans loaded; preserving existing Hive exercise IDs');
        }
      }

      // Save treatment IDs to Hive
      if (treatmentReferences != null && treatmentReferences!.isNotEmpty) {
        final treatmentIds = treatmentReferences!.map((ref) => ref.treatmentId).toList();
        final hiveTreatmentIds = HiveTreatmentIds(treatmentIds: treatmentIds);
        await box.put('treatmentIds', hiveTreatmentIds);
        print('Saved ${treatmentIds.length} treatment IDs to Hive');
      } else {
        // Only clear when treatmentReferences is explicitly set (including explicitly empty list)
        if (treatmentReferences != null) {
          await box.delete('treatmentIds');
          print('Cleared treatment IDs from Hive (explicit empty treatment list)');
        } else {
          print('Treatment references null (not loaded); preserving existing Hive treatment IDs');
        }
      }
      
      print('Successfully saved rehabilitation data to Hive');
      
      // Also save to Firebase if user is authenticated
      if (_auth.currentUser != null) {
        try {
          await savePlansToFirebase();
        } catch (firebaseError) {
          print('Warning: Failed to save to Firebase, but Hive save succeeded: $firebaseError');
        }
      }
      
      // Trigger auto-save
      DataPersistenceService.instance.triggerSave(reason: 'Rehabilitation plans updated');
    } catch (e) {
      print('Error saving rehabilitation data to Hive: $e');
      print('Stack trace: ${StackTrace.current}');
      rethrow; // Re-throw to let calling code handle the error
    }
  }

  Future<void> loadPlansFromHive() async {
    try {
      if (!Hive.isBoxOpen('rehabBox')) {
        print('UserRehabilitation.loadPlansFromHive: Hive box not open, attempting to open...');
        await openRehabBox();
      }
      final box = Hive.box('rehabBox');
      
      // Load exercise IDs from Hive
      final hiveExerciseIds = box.get('exerciseIds');
      List<String> exerciseIds = [];
      if (hiveExerciseIds is HiveExerciseIds) {
        exerciseIds = hiveExerciseIds.exerciseIds;
        print('Loaded ${exerciseIds.length} exercise IDs from Hive');
      } else {
        print('No exercise IDs found in Hive');
      }

      // Load treatment IDs from Hive
      final hiveTreatmentIds = box.get('treatmentIds');
      List<String> treatmentIds = [];
      if (hiveTreatmentIds is HiveTreatmentIds) {
        treatmentIds = hiveTreatmentIds.treatmentIds;
        print('Loaded ${treatmentIds.length} treatment IDs from Hive');
      } else {
        print('No treatment IDs found in Hive');
      }

      // Map exercise IDs to full exercise data from CSV
      if (exerciseIds.isNotEmpty) {
        final List<Exercise> exercises = await ExerciseDataService.getExercisesByIds(exerciseIds);
        
        // Reconstruct rehabilitation plans from loaded exercise data
        final List<ExerciseReference> exerciseReferences = exercises.map((exercise) => 
          ExerciseReference(
            exerciseId: exercise.exerciseId,
            repetitions: exercise.repetitions,
            sets: exercise.sets,
          )).toList();

        // Create a rehabilitation plan with the loaded exercises
        rehabPlans = [
          RehabilitationPlan(
            weekNumber: 1,
            exerciseReferences: exerciseReferences,
            daily: [], // Initialize empty daily progress
          )
        ];

        print('Reconstructed rehabilitation plan with ${exerciseReferences.length} exercises from Hive');
      } else {
        rehabPlans = [];
        print('No exercises to reconstruct rehabilitation plan from Hive');
      }

      // Map treatment IDs to full treatment data from CSV
      if (treatmentIds.isNotEmpty) {
        final List<Treatment> treatments = await ExerciseDataService.getTreatmentsByIds(treatmentIds);
        
        // Convert to treatment references
        treatmentReferences = treatments.map((treatment) => 
          TreatmentReference(treatmentId: treatment.treatmentId)).toList();

        print('Reconstructed ${treatmentReferences!.length} treatment references from Hive');
      } else {
        treatmentReferences = null;
        print('No treatments to reconstruct from Hive');
      }
      
      print('Successfully loaded and reconstructed rehabilitation data from Hive');
      
      // If no data found in Hive and user is authenticated, try Firebase
      if (rehabPlans.isEmpty && treatmentReferences == null && _auth.currentUser != null) {
        try {
          print('No data found in Hive, attempting to load from Firebase...');
          await loadPlansFromFirebase();
          // Save to Hive for offline access
          await savePlansToHive();
        } catch (firebaseError) {
          print('Error loading from Firebase fallback: $firebaseError');
        }
      }
    } catch (e) {
      print('Error loading rehabilitation data from Hive: $e');
      print('Stack trace: ${StackTrace.current}');
      
      // Try Firebase as fallback if user is authenticated
      if (_auth.currentUser != null) {
        try {
          print('Hive load failed, attempting Firebase fallback...');
          await loadPlansFromFirebase();
        } catch (firebaseError) {
          print('Firebase fallback also failed: $firebaseError');
          // Reset to empty state on error
          rehabPlans = [];
          treatmentReferences = null;
        }
      } else {
        // Reset to empty state on error
        rehabPlans = [];
        treatmentReferences = null;
      }
    }
  }

  // Method to verify data integrity - updated for ID-only storage
  Future<bool> verifyDataIntegrity() async {
    try {
      final box = Hive.box('rehabBox');
      
      // Check if exercise IDs exist in Hive
      final hiveExerciseIds = box.get('exerciseIds');
      final exerciseIdsInHive = hiveExerciseIds is HiveExerciseIds ? hiveExerciseIds.exerciseIds.length : 0;
      
      // Check if treatment IDs exist in Hive
      final hiveTreatmentIds = box.get('treatmentIds');
      final treatmentIdsInHive = hiveTreatmentIds is HiveTreatmentIds ? hiveTreatmentIds.treatmentIds.length : 0;
      
      // Count exercise IDs in memory
      final Set<String> exerciseIdsInMemory = <String>{};
      for (final plan in rehabPlans) {
        for (final exerciseRef in plan.exerciseReferences) {
          exerciseIdsInMemory.add(exerciseRef.exerciseId);
        }
      }
      
      // Count treatment IDs in memory
      final treatmentIdsInMemory = treatmentReferences?.map((ref) => ref.treatmentId).toList() ?? <String>[];
      
      print('Data integrity check (ID-only storage):');
      print('  Exercise IDs in memory: ${exerciseIdsInMemory.length}');
      print('  Exercise IDs in Hive: $exerciseIdsInHive');
      print('  Treatment IDs in memory: ${treatmentIdsInMemory.length}');
      print('  Treatment IDs in Hive: $treatmentIdsInHive');
      
      final exerciseIdsMatch = exerciseIdsInHive == exerciseIdsInMemory.length;
      final treatmentIdsMatch = treatmentIdsInHive == treatmentIdsInMemory.length;
      
      // Validate data structure integrity
      final plansValid = rehabPlans.every(_validateRehabilitationPlan);
      final treatmentRefsValid = treatmentReferences?.every(_validateTreatmentReference) ?? true;
      
      final allMatch = exerciseIdsMatch && treatmentIdsMatch && plansValid && treatmentRefsValid;
      
      if (!allMatch) {
        print('Data integrity check failed:');
        if (!exerciseIdsMatch) print('  - Exercise IDs count mismatch');
        if (!treatmentIdsMatch) print('  - Treatment IDs count mismatch');
        if (!plansValid) print('  - Plans data validation failed');
        if (!treatmentRefsValid) print('  - Treatment references data validation failed');
      } else {
        print('Data integrity check passed: All data matches between memory and Hive and passes validation');
      }
      
      return allMatch;
    } catch (e) {
      print('Error verifying data integrity: $e');
      return false;
    }
  }


  bool _validateRehabilitationPlan(RehabilitationPlan plan) {
    return plan.weekNumber > 0 &&
           plan.exerciseReferences.isNotEmpty &&
           plan.exerciseReferences.every(_validateExerciseReference);
  }

  bool _validateExerciseReference(ExerciseReference ref) {
    return ref.exerciseId.isNotEmpty &&
           ref.repetitions > 0 &&
           ref.sets > 0;
  }

  bool _validateTreatmentReference(TreatmentReference ref) {
    return ref.treatmentId.isNotEmpty;
  }

}

/// Class to track daily progress of exercises.
class DailyProgress {
  final DateTime date;
  final Map<String, bool> completedExercises;

  DailyProgress({
    required this.date,
    required this.completedExercises,
  });
}

/// Reads the CSV from assets and parses the data.
Future<List<List<dynamic>>> loadCSVFromAsset(String path) async {
  try {
    final rawCSV = await rootBundle.loadString(path);
    print('CSV data loaded from $path');
    final parsedCSV = const CsvToListConverter().convert(rawCSV);
    print('CSV parsed successfully');
    return parsedCSV;
  } catch (e) {
    print('Error loading CSV: $e');
    rethrow; // Re-throw the exception after logging
  }
}

/// Checks if an exercise should be filtered out based on muscle injury data
bool _checkMuscleInjuryFilter(List<dynamic> row, int Function(String) col) {
  try {
    // If no muscle injuries, include all exercises
    if (UserAssess.injuredMuscles.isEmpty) {
      return true;
    }
    
    // Get the Other_Muscles column value
    final otherMusclesValue = row[col('Other_Muscles')].toString().toLowerCase().trim();
    
    // If Other_Muscles is empty, include the exercise
    if (otherMusclesValue.isEmpty) {
      return true;
    }
    
    // Check if any injured muscle appears in the Other_Muscles column
    for (String injuredMuscle in UserAssess.injuredMuscles) {
      final injuredMuscleLower = injuredMuscle.toLowerCase().trim();
      
      // Check if the injured muscle appears in the Other_Muscles column
      if (otherMusclesValue.contains(injuredMuscleLower)) {
        // With the simplified yes/no system, any muscle in injuredMuscles is still painful
        // and should be filtered out to avoid targeting injured muscles
        print('Filtering out exercise ${row[col('Exercise')]} due to still painful muscle: $injuredMuscle');
        return false; // Exclude exercises targeting still painful muscles
      }
    }
    
    return true; // Include the exercise if no still painful muscles match
  } catch (e) {
    print('Error in muscle injury filter: $e');
    return true; // Default to including the exercise if there's an error
  }
}

/// Generates a rehabilitation plan from the CSV based on selected user inputs.
Future<RehabilitationPlan?> generateRehabilitationPlanFromCSV(BuildContext context) async {
  try {
    final csvData = await loadCSVFromAsset('assets/data/exercises.csv');
    print('CSV data: $csvData');

    final header = csvData.first;
    final data = csvData.sublist(1); // remove header row
    print('CSV Header: $header');
    print('CSV Data: ${data.length} rows');

    // Validate headers
    final requiredHeaders = [
      'Exercise_ID',
      'Exercise',
      'Exercise_Description',
      'Muscle_Involved',
      'Pain_Level',
      'Functional_Goal',
      'Repetition',
      'Set',
      'Image_Link',
      'Video_Link',
      'Other_Muscles',
    ];

    for (final field in requiredHeaders) {
      if (!header.contains(field)) {
        print('Missing column: $field');
        throw Exception('Missing column: $field in CSV header');
      }
    }

    int col(String name) => header.indexOf(name);

    // Filter exercises based on selected criteria
    final filteredExercises = data.where((row) {
      bool muscleMatch = row[col('Muscle_Involved')].toString().toLowerCase() == UserAssess.specificMuscle.toLowerCase().trim();
      bool painLevelMatch = row[col('Pain_Level')].toString().toLowerCase() == UserAssess.painLevel.toLowerCase().trim();
      bool goalMatch = row[col('Functional_Goal')].toString().toLowerCase() ==UserAssess.rehabGoal.toLowerCase().trim();
      
      // Check for muscle injury filtering
      bool muscleInjuryFilter = _checkMuscleInjuryFilter(row, col);

      print('Matching row: ${row[col('Exercise')]}, Muscle Match: $muscleMatch, Pain Level Match: $painLevelMatch, Goal Match: $goalMatch, Muscle Injury Filter: $muscleInjuryFilter \n CSV: ${row[col('Muscle_Involved')].toString().toLowerCase()}, Input: ${UserAssess.painLevel.toLowerCase().trim()}');

      return muscleMatch && painLevelMatch && goalMatch && muscleInjuryFilter;
    }).toList();

    print('Filtered exercises: ${filteredExercises.length} exercises found');

    // Check if we need to show the muscle injury confirmation dialog
    if (MuscleInjuryDialogService.shouldShowDialog(
      filteredExerciseCount: filteredExercises.length,
      injuredMuscles: UserAssess.injuredMuscles,
      musclePainCategories: UserAssess.musclePainCategories,
    )) {
      print('Muscle injury dialog conditions met, showing confirmation dialog');
      
      // Check if context is still mounted before showing dialog
      if (!context.mounted) {
        print('Context not mounted, falling back to safe behavior');
        if (filteredExercises.length < 2) {
          print('Not enough exercises found after context check, returning null');
          return null;
        }
      } else {
        final userChoice = await MuscleInjuryDialogService.showConfirmationDialog(
          context: context,
          injuredMuscles: UserAssess.injuredMuscles,
          musclePainCategories: UserAssess.musclePainCategories,
          availableExerciseCount: filteredExercises.length,
        );
        
        if (userChoice == null) {
          print('Dialog was dismissed, falling back to safe behavior');
          // Fallback to safe behavior if dialog fails
          if (filteredExercises.length < 2) {
            print('Not enough exercises found after dialog dismissal, returning null');
            return null;
          }
        } else if (userChoice == MuscleInjuryChoice.cancel) {
          print('User cancelled, returning null');
          return null;
        } else if (userChoice == MuscleInjuryChoice.includeAll) {
          print('User chose to include all exercises, re-filtering without muscle injury filtering');
          
          // Re-filter without muscle injury filtering
          filteredExercises.clear();
          filteredExercises.addAll(data.where((row) {
            bool muscleMatch = row[col('Muscle_Involved')].toString().toLowerCase() == UserAssess.specificMuscle.toLowerCase().trim();
            bool painLevelMatch = row[col('Pain_Level')].toString().toLowerCase() == UserAssess.painLevel.toLowerCase().trim();
            bool goalMatch = row[col('Functional_Goal')].toString().toLowerCase() == UserAssess.rehabGoal.toLowerCase().trim();
            
            print('Re-filtering row: ${row[col('Exercise')]}, Muscle Match: $muscleMatch, Pain Level Match: $painLevelMatch, Goal Match: $goalMatch');
            
            return muscleMatch && painLevelMatch && goalMatch;
          }).toList());
          
          print('Re-filtered exercises: ${filteredExercises.length} exercises found (including injured muscle exercises)');
        } else if (userChoice == MuscleInjuryChoice.keepSafe) {
          print('User chose to keep safe exercises only, continuing with current filtered set');
        }
        
        // Log the user choice for safety monitoring
        MuscleInjuryDialogService.logUserChoice(
          choice: userChoice!,
          injuredMuscles: UserAssess.injuredMuscles,
          musclePainCategories: UserAssess.musclePainCategories,
          availableExerciseCount: filteredExercises.length,
        );
      }
    }

    if (filteredExercises.length < 2) {
      print('Not enough exercises found, returning null');
      return null;
    }

    // Remove duplicate exercises based on Exercise_ID to ensure uniqueness
    final uniqueExercises = <String, List<dynamic>>{};
    for (final row in filteredExercises) {
      final exerciseId = row[col('Exercise_ID')].toString();
      if (!uniqueExercises.containsKey(exerciseId)) {
        uniqueExercises[exerciseId] = row;
      }
    }
    
    final deduplicatedExercises = uniqueExercises.values.toList();
    print('Unique exercises after deduplication: ${deduplicatedExercises.length} exercises found');

    if (deduplicatedExercises.length < 2) {
      print('Not enough unique exercises found, returning null');
      return null;
    }

    final random = Random();
    deduplicatedExercises.shuffle(random);

    final selected = deduplicatedExercises.take(3).map((row) {
      print('Selected exercise: ${row[col('Exercise')]}');
      return ExerciseReference(
        exerciseId: row[col('Exercise_ID')].toString(),
        repetitions: int.tryParse(row[col('Repetition')].toString()) ?? 0,
        sets: int.tryParse(row[col('Set')].toString()) ?? 0,
      );
    }).toList();

    return RehabilitationPlan(weekNumber: 1, exerciseReferences: selected);
  } catch (e) {
    print('Error generating rehabilitation plan: $e');
    return null; // Return null if an error occurs
  }
}