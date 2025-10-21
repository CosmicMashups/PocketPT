import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../exercise/exercise_list.dart';

/// Service for managing custom exercises with dual storage (local CSV + Firebase)
class CustomExerciseService {
  static final CustomExerciseService _instance = CustomExerciseService._internal();
  static CustomExerciseService get instance => _instance;
  CustomExerciseService._internal();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get the path for the custom exercises CSV file
  static Future<String> _getCsvPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/exercises_custom.csv';
  }

  /// Generate unique exercise ID for custom exercises (CE### format)
  static Future<String> _generateExerciseId() async {
    try {
      final path = await _getCsvPath();
      final file = File(path);
      
      int maxId = 0;
      if (await file.exists()) {
        final content = await file.readAsString();
        final rows = const CsvToListConverter().convert(content);
        
        // Skip header row, find max CE### ID
        for (int i = 1; i < rows.length; i++) {
          final id = rows[i][0].toString();
          if (id.startsWith('CE')) {
            final number = int.tryParse(id.substring(2));
            if (number != null && number > maxId) {
              maxId = number;
            }
          }
        }
      }
      
      return 'CE${(maxId + 1).toString().padLeft(3, '0')}';
    } catch (e) {
      debugPrint('Error generating exercise ID: $e');
      // Fallback to timestamp-based ID
      return 'CE${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    }
  }

  /// Save custom exercise to both local CSV and Firebase
  static Future<void> saveExercise(Exercise exercise) async {
    try {
      // Save to local CSV
      await _saveToLocalCsv(exercise);
      
      // Save to Firebase if user is authenticated
      final user = _auth.currentUser;
      if (user != null) {
        await _saveToFirebase(exercise, user.uid);
      }
      
      debugPrint('Custom exercise saved successfully: ${exercise.id}');
    } catch (e) {
      debugPrint('Error saving custom exercise: $e');
      rethrow;
    }
  }

  /// Save exercise to local CSV file
  static Future<void> _saveToLocalCsv(Exercise exercise) async {
    try {
      final path = await _getCsvPath();
      final file = File(path);
      List<List<dynamic>> rows = [];

      // Read existing data if file exists
      if (await file.exists()) {
        final content = await file.readAsString();
        rows = const CsvToListConverter().convert(content);
      } else {
        // Create header row if file doesn't exist
        rows.add([
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
          'Other_Muscles'
        ]);
      }

      // Add new exercise row
      rows.add([
        exercise.id,
        exercise.name,
        exercise.description,
        exercise.muscle,
        exercise.painLevel,
        exercise.goal,
        exercise.rep,
        exercise.set,
        exercise.imageUrl,
        exercise.videoUrl,
        exercise.otherMuscles
      ]);

      // Write back to file
      final csvData = const ListToCsvConverter().convert(rows);
      await file.writeAsString(csvData);
      
      debugPrint('Custom exercise saved to local CSV: ${exercise.id}');
    } catch (e) {
      debugPrint('Error saving to local CSV: $e');
      rethrow;
    }
  }

  /// Save exercise to Firebase
  static Future<void> _saveToFirebase(Exercise exercise, String userId) async {
    try {
      final exerciseData = {
        'exerciseId': exercise.id,
        'name': exercise.name,
        'description': exercise.description,
        'muscle': exercise.muscle,
        'painLevel': exercise.painLevel,
        'goal': exercise.goal,
        'rep': exercise.rep,
        'set': exercise.set,
        'imageUrl': exercise.imageUrl,
        'videoUrl': exercise.videoUrl,
        'otherMuscles': exercise.otherMuscles,
        'createdAt': FieldValue.serverTimestamp(),
        'lastModified': FieldValue.serverTimestamp(),
        'userId': userId,
      };

      await _firestore
          .collection('customExercises')
          .doc(userId)
          .collection('exercises')
          .doc(exercise.id)
          .set(exerciseData);

      debugPrint('Custom exercise saved to Firebase: ${exercise.id}');
    } catch (e) {
      debugPrint('Error saving to Firebase: $e');
      // Don't rethrow - local save succeeded, Firebase is optional
    }
  }

  /// Load custom exercises from local CSV file
  static Future<List<Exercise>> loadCustomExercisesFromLocal() async {
    try {
      final path = await _getCsvPath();
      final file = File(path);
      
      if (!await file.exists()) {
        return [];
      }

      final content = await file.readAsString();
      final rows = const CsvToListConverter().convert(content);
      
      // Skip header row and convert to Exercise objects
      final exercises = rows.skip(1).map((row) {
        return Exercise(
          id: row[0].toString(),
          name: row[1].toString(),
          description: row[2].toString(),
          muscle: row[3].toString(),
          painLevel: row[4].toString(),
          goal: row[5].toString(),
          rep: int.tryParse(row[6].toString()) ?? 0,
          set: int.tryParse(row[7].toString()) ?? 0,
          imageUrl: row[8].toString(),
          videoUrl: row[9].toString(),
          otherMuscles: row.length > 10 ? row[10].toString() : '',
        );
      }).toList();

      debugPrint('Loaded ${exercises.length} custom exercises from local CSV');
      return exercises;
    } catch (e) {
      debugPrint('Error loading custom exercises from local CSV: $e');
      return [];
    }
  }

  /// Load custom exercises from Firebase
  static Future<List<Exercise>> loadCustomExercisesFromFirebase() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('No authenticated user for Firebase custom exercises');
        return [];
      }

      final querySnapshot = await _firestore
          .collection('customExercises')
          .doc(user.uid)
          .collection('exercises')
          .orderBy('createdAt', descending: false)
          .get();

      final exercises = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return Exercise(
          id: data['exerciseId'] ?? doc.id,
          name: data['name'] ?? '',
          description: data['description'] ?? '',
          muscle: data['muscle'] ?? '',
          painLevel: data['painLevel'] ?? '',
          goal: data['goal'] ?? '',
          rep: (data['rep'] ?? 0).toInt(),
          set: (data['set'] ?? 0).toInt(),
          imageUrl: data['imageUrl'] ?? 'exercise.jpg',
          videoUrl: data['videoUrl'] ?? '',
          otherMuscles: data['otherMuscles'] ?? '',
        );
      }).toList();

      debugPrint('Loaded ${exercises.length} custom exercises from Firebase');
      return exercises;
    } catch (e) {
      debugPrint('Error loading custom exercises from Firebase: $e');
      return [];
    }
  }

  /// Validate custom exercise data
  static String? validateExerciseData({
    required String name,
    required String description,
    required String muscle,
    required String painLevel,
    required String goal,
    required int rep,
    required int set,
    String? imageUrl,
    String? videoUrl,
  }) {
    if (name.trim().isEmpty || name.trim().length < 3) {
      return 'Exercise name must be at least 3 characters long';
    }
    
    if (description.trim().isEmpty || description.trim().length < 10) {
      return 'Exercise description must be at least 10 characters long';
    }
    
    if (muscle.trim().isEmpty) {
      return 'Please select a muscle group';
    }
    
    if (painLevel.trim().isEmpty) {
      return 'Please select a pain level';
    }
    
    if (goal.trim().isEmpty) {
      return 'Please select a functional goal';
    }
    
    if (rep < 1) {
      return 'Repetitions must be at least 1';
    }
    
    if (set < 1) {
      return 'Sets must be at least 1';
    }
    
    return null; // Valid
  }

  /// Create a new custom exercise with validation and ID generation
  static Future<Exercise> createCustomExercise({
    required String name,
    required String description,
    required String muscle,
    required String painLevel,
    required String goal,
    required int rep,
    required int set,
    String? imageUrl,
    String? videoUrl,
    String? otherMuscles,
  }) async {
    // Validate input data
    final validationError = validateExerciseData(
      name: name,
      description: description,
      muscle: muscle,
      painLevel: painLevel,
      goal: goal,
      rep: rep,
      set: set,
      imageUrl: imageUrl,
      videoUrl: videoUrl,
    );
    
    if (validationError != null) {
      throw Exception(validationError);
    }

    // Generate unique ID
    final exerciseId = await _generateExerciseId();

    // Create exercise object
    final exercise = Exercise(
      id: exerciseId,
      name: name.trim(),
      description: description.trim(),
      muscle: muscle.trim(),
      painLevel: painLevel.trim(),
      goal: goal.trim(),
      rep: rep,
      set: set,
      imageUrl: imageUrl?.trim() ?? 'exercise.jpg',
      videoUrl: videoUrl?.trim() ?? '',
      otherMuscles: otherMuscles?.trim() ?? '',
    );

    return exercise;
  }

  /// Sync custom exercises from Firebase to local storage
  static Future<void> syncFromFirebase() async {
    try {
      final firebaseExercises = await loadCustomExercisesFromFirebase();
      final localExercises = await loadCustomExercisesFromLocal();
      
      // Find exercises that exist in Firebase but not locally
      final localIds = localExercises.map((e) => e.id).toSet();
      final newExercises = firebaseExercises.where((e) => !localIds.contains(e.id)).toList();
      
      // Save new exercises to local CSV
      for (final exercise in newExercises) {
        await _saveToLocalCsv(exercise);
      }
      
      debugPrint('Synced ${newExercises.length} custom exercises from Firebase to local storage');
    } catch (e) {
      debugPrint('Error syncing from Firebase: $e');
    }
  }
}
