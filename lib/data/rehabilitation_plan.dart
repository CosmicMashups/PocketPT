import 'dart:math';
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

// Service to handle CSV data retrieval
class ExerciseDataService {
  static List<Exercise>? _cachedExercises;
  static List<Treatment>? _cachedTreatments;
  static bool _isLoadingExercises = false;
  static bool _isLoadingTreatments = false;

  // Load all exercises from CSV with caching and loading state
  static Future<List<Exercise>> loadAllExercises() async {
    if (_cachedExercises != null) return _cachedExercises!;
    if (_isLoadingExercises) {
      // Wait for ongoing load to complete
      while (_isLoadingExercises) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      return _cachedExercises ?? [];
    }
    
    _isLoadingExercises = true;
    try {
      print('ExerciseDataService: Loading exercises from CSV...');
      final csvData = await loadCSVFromAsset('assets/data/exercises.csv');
      final header = csvData.first;
      final data = csvData.sublist(1);

      int col(String name) => header.indexOf(name);

      _cachedExercises = data.map((row) {
        return Exercise(
          exerciseId: row[col('Exercise_ID')].toString(),
          exerciseName: row[col('Exercise')].toString(),
          description: row[col('Exercise_Description')].toString(),
          muscle: row[col('Muscle_Involved')].toString(),
          painLevel: row[col('Pain_Level')].toString(),
          goal: row[col('Functional_Goal')].toString(),
          repetitions: int.tryParse(row[col('Repetition')].toString()) ?? 0,
          sets: int.tryParse(row[col('Set')].toString()) ?? 0,
          imageUrl: row[col('Image_Link')].toString(),
          videoUrl: row[col('Video_Link')].toString(),
        );
      }).toList();

      print('ExerciseDataService: Loaded ${_cachedExercises!.length} exercises from CSV');
      return _cachedExercises!;
    } catch (e) {
      print('Error loading exercises from CSV: $e');
      return [];
    } finally {
      _isLoadingExercises = false;
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
    final allExercises = await loadAllExercises();
    return allExercises.where((exercise) => exerciseIds.contains(exercise.exerciseId)).toList();
  }

  // Get treatments by IDs
  static Future<List<Treatment>> getTreatmentsByIds(List<String> treatmentIds) async {
    final allTreatments = await loadAllTreatments();
    return allTreatments.where((treatment) => treatmentIds.contains(treatment.treatmentId)).toList();
  }

  // Get single exercise by ID
  static Future<Exercise?> getExerciseById(String exerciseId) async {
    final allExercises = await loadAllExercises();
    try {
      return allExercises.firstWhere((exercise) => exercise.exerciseId == exerciseId);
    } catch (e) {
      return null;
    }
  }

  // Get single treatment by ID
  static Future<Treatment?> getTreatmentById(String treatmentId) async {
    final allTreatments = await loadAllTreatments();
    try {
      return allTreatments.firstWhere((treatment) => treatment.treatmentId == treatmentId);
    } catch (e) {
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

  RehabilitationPlan({
    required this.weekNumber,
    required this.exerciseReferences,
    this.daily = const [],
  });

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

      // Extract all unique exercise IDs from rehabilitation plans
      final Set<String> exerciseIds = <String>{};
      for (final plan in rehabPlans) {
        for (final exerciseRef in plan.exerciseReferences) {
          exerciseIds.add(exerciseRef.exerciseId);
        }
      }

      // Save exercise IDs in the required format (exercise1, exercise2, etc.)
      if (exerciseIds.isNotEmpty) {
        final Map<String, dynamic> exerciseData = <String, dynamic>{};
        int index = 1;
        for (final exerciseId in exerciseIds) {
          exerciseData['exercise$index'] = exerciseId;
          index++;
        }
        exerciseData['lastUpdated'] = FieldValue.serverTimestamp();
        exerciseData['userId'] = userId;

        await _firestore
            .collection('users')
            .doc(userId)
            .collection('exercise')
            .doc('exercises')
            .set(exerciseData);

        print('Saved ${exerciseIds.length} exercise IDs to Firebase exercise collection');
      }

      // Save treatment IDs in the required format (treatment1, treatment2, etc.)
      if (treatmentReferences != null && treatmentReferences!.isNotEmpty) {
        final Map<String, dynamic> treatmentData = <String, dynamic>{};
        int index = 1;
        for (final treatmentRef in treatmentReferences!) {
          treatmentData['treatment$index'] = treatmentRef.treatmentId;
          index++;
        }
        treatmentData['lastUpdated'] = FieldValue.serverTimestamp();
        treatmentData['userId'] = userId;

        await _firestore
            .collection('users')
            .doc(userId)
            .collection('treatment')
            .doc('treatments')
            .set(treatmentData);

        print('Saved ${treatmentReferences!.length} treatment IDs to Firebase treatment collection');
      } else {
        // Clear treatments if none exist
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('treatment')
            .doc('treatments')
            .delete();
        print('Cleared treatment references from Firebase');
      }

      print('Successfully saved rehabilitation data to Firebase');
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

      // Load exercise IDs from Firebase
      final DocumentSnapshot exerciseDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('exercise')
          .doc('exercises')
          .get();

      List<String> exerciseIds = [];
      if (exerciseDoc.exists) {
        final data = exerciseDoc.data() as Map<String, dynamic>;
        // Extract exercise IDs from exercise1, exercise2, etc. fields
        int index = 1;
        while (data.containsKey('exercise$index')) {
          exerciseIds.add(data['exercise$index'] as String);
          index++;
        }
        print('Loaded ${exerciseIds.length} exercise IDs from Firebase');
      } else {
        print('No exercise IDs found in Firebase');
      }

      // Load treatment IDs from Firebase
      final DocumentSnapshot treatmentDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('treatment')
          .doc('treatments')
          .get();

      List<String> treatmentIds = [];
      if (treatmentDoc.exists) {
        final data = treatmentDoc.data() as Map<String, dynamic>;
        // Extract treatment IDs from treatment1, treatment2, etc. fields
        int index = 1;
        while (data.containsKey('treatment$index')) {
          treatmentIds.add(data['treatment$index'] as String);
          index++;
        }
        print('Loaded ${treatmentIds.length} treatment IDs from Firebase');
      } else {
        print('No treatment IDs found in Firebase');
      }

      // Map exercise IDs to full exercise data from CSV
      if (exerciseIds.isNotEmpty) {
        final List<Exercise> exercises = await ExerciseDataService.getExercisesByIds(exerciseIds);
        
        // Reconstruct rehabilitation plans from loaded exercise data
        // For now, create a simple plan with all exercises
        // In a real implementation, you might want to store additional metadata
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

        print('Reconstructed rehabilitation plan with ${exerciseReferences.length} exercises');
      } else {
        rehabPlans = [];
        print('No exercises to reconstruct rehabilitation plan');
      }

      // Map treatment IDs to full treatment data from CSV
      if (treatmentIds.isNotEmpty) {
        final List<Treatment> treatments = await ExerciseDataService.getTreatmentsByIds(treatmentIds);
        
        // Convert to treatment references
        treatmentReferences = treatments.map((treatment) => 
          TreatmentReference(treatmentId: treatment.treatmentId)).toList();

        print('Reconstructed ${treatmentReferences!.length} treatment references');
      } else {
        treatmentReferences = null;
        print('No treatments to reconstruct');
      }

      print('Successfully loaded and reconstructed rehabilitation data from Firebase');
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
        await box.delete('exerciseIds');
        print('Cleared exercise IDs from Hive');
      }

      // Save treatment IDs to Hive
      if (treatmentReferences != null && treatmentReferences!.isNotEmpty) {
        final treatmentIds = treatmentReferences!.map((ref) => ref.treatmentId).toList();
        final hiveTreatmentIds = HiveTreatmentIds(treatmentIds: treatmentIds);
        await box.put('treatmentIds', hiveTreatmentIds);
        print('Saved ${treatmentIds.length} treatment IDs to Hive');
      } else {
        await box.delete('treatmentIds');
        print('Cleared treatment IDs from Hive');
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

/// Generates a rehabilitation plan from the CSV based on selected user inputs.
Future<RehabilitationPlan?> generateRehabilitationPlanFromCSV() async {
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

      print('Matching row: ${row[col('Exercise')]}, Muscle Match: $muscleMatch, Pain Level Match: $painLevelMatch, Goal Match: $goalMatch \n CSV: ${row[col('Muscle_Involved')].toString().toLowerCase()}, Input: ${UserAssess.painLevel.toLowerCase().trim()}');

      return muscleMatch && painLevelMatch && goalMatch;
    }).toList();

    print('Filtered exercises: ${filteredExercises.length} exercises found');

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