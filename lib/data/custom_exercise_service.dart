import 'package:hive/hive.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../exercise/exercise_list.dart';
import 'hive_models.dart';
import 'firebase_helper.dart';
import 'globals.dart';

class CustomExerciseService {
  static List<HiveCustomExercise>? _cachedCustomExercises;
  static bool _isLoading = false;
  
  /// Save custom exercise to Hive and Firebase
  static Future<void> saveExercise(Exercise exercise) async {
    try {
      print('CustomExerciseService: Saving custom exercise: ${exercise.name}');
      
      // Create Hive model
      final now = DateTime.now();
      final hiveExercise = HiveCustomExercise(
        id: exercise.id,
        name: exercise.name,
        description: exercise.description,
        muscle: exercise.muscle,
        painLevel: exercise.painLevel,
        goal: exercise.goal,
        rep: exercise.rep,
        set: exercise.set,
        imageUrl: exercise.imageUrl,
        videoUrl: exercise.videoUrl,
        otherMuscles: exercise.otherMuscles,
        createdAt: now,
        lastModified: now,
      );
      
      // Save to Hive
      await _saveToHive(hiveExercise);
      
      // Save to Firebase if authenticated
      await _saveToFirebase(hiveExercise);
      
      // Update cache
      _cachedCustomExercises ??= [];
      _cachedCustomExercises!.add(hiveExercise);
      
      print('CustomExerciseService: Successfully saved custom exercise: ${exercise.name}');
    } catch (e) {
      print('CustomExerciseService: Error saving exercise: $e');
      rethrow;
    }
  }

  /// Load custom exercises from Hive and Firebase
  static Future<List<Exercise>> loadCustomExercises() async {
    if (_cachedCustomExercises != null) {
      return _cachedCustomExercises!.map(_hiveToExercise).toList();
    }
    
    if (_isLoading) {
      // Wait for ongoing load
      while (_isLoading) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      return _cachedCustomExercises?.map(_hiveToExercise).toList() ?? [];
    }
    
    _isLoading = true;
    try {
      print('CustomExerciseService: Loading custom exercises...');
      
      // Load from Hive first
      await _loadFromHive();
      
      // Try to sync from Firebase if authenticated
      await _syncFromFirebase();
      
      final exercises = _cachedCustomExercises?.map(_hiveToExercise).toList() ?? [];
      print('CustomExerciseService: Loaded ${exercises.length} custom exercises');
      return exercises;
    } catch (e) {
      print('CustomExerciseService: Error loading custom exercises: $e');
      return [];
    } finally {
      _isLoading = false;
    }
  }

  /// Delete custom exercise from Hive and Firebase
  static Future<bool> deleteCustomExercise(String exerciseId) async {
    try {
      print('CustomExerciseService: Deleting custom exercise: $exerciseId');
      
      // Remove from Hive
      await _deleteFromHive(exerciseId);
      
      // Remove from Firebase if authenticated
      await _deleteFromFirebase(exerciseId);
      
      // Update cache
      _cachedCustomExercises?.removeWhere((ex) => ex.id == exerciseId);
      
      print('CustomExerciseService: Successfully deleted custom exercise: $exerciseId');
      return true;
    } catch (e) {
      print('CustomExerciseService: Error deleting custom exercise: $e');
      return false;
    }
  }

  /// Get count of custom exercises
  static Future<int> getCustomExerciseCount() async {
    try {
      final exercises = await loadCustomExercises();
      return exercises.length;
    } catch (e) {
      print('CustomExerciseService: Error getting custom exercise count: $e');
      return 0;
    }
  }

  /// Save to Hive
  static Future<void> _saveToHive(HiveCustomExercise exercise) async {
    try {
      if (!Hive.isBoxOpen('rehabBox')) {
        await openRehabBox();
      }
      
      final box = Hive.box('rehabBox');
      final customExercises = List<HiveCustomExercise>.from(box.get('customExercises', defaultValue: <HiveCustomExercise>[]));
      
      // Remove existing exercise with same ID
      customExercises.removeWhere((ex) => ex.id == exercise.id);
      
      // Add new exercise
      customExercises.add(exercise);
      
      // Save to Hive
      await box.put('customExercises', customExercises);
      
      print('CustomExerciseService: Saved to Hive: ${exercise.name}');
    } catch (e) {
      print('CustomExerciseService: Error saving to Hive: $e');
      rethrow;
    }
  }

  /// Load from Hive
  static Future<void> _loadFromHive() async {
    try {
      if (!Hive.isBoxOpen('rehabBox')) {
        await openRehabBox();
      }
      
      final box = Hive.box('rehabBox');
      final customExercises = List<HiveCustomExercise>.from(box.get('customExercises', defaultValue: <HiveCustomExercise>[]));
      
      _cachedCustomExercises = customExercises;
      print('CustomExerciseService: Loaded ${customExercises.length} custom exercises from Hive');
    } catch (e) {
      print('CustomExerciseService: Error loading from Hive: $e');
      _cachedCustomExercises = [];
    }
  }

  /// Save to Firebase
  static Future<void> _saveToFirebase(HiveCustomExercise exercise) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('CustomExerciseService: No authenticated user, skipping Firebase save');
        return;
      }

      await FirebaseHelper.ensureAuthenticatedUser();
      if (FirebaseAuth.instance.currentUser == null) {
        print('CustomExerciseService: User authentication failed, skipping Firebase save');
        return;
      }

      final firestore = FirebaseFirestore.instance;
      await firestore
          .collection('users')
          .doc(user.uid)
          .collection('customExercises')
          .doc(exercise.id)
          .set({
        'id': exercise.id,
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
        'createdAt': exercise.createdAt.toIso8601String(),
        'lastModified': exercise.lastModified.toIso8601String(),
      });

      print('CustomExerciseService: Saved to Firebase: ${exercise.name}');
    } catch (e) {
      print('CustomExerciseService: Error saving to Firebase: $e');
      // Don't rethrow - Firebase is optional
    }
  }

  /// Sync from Firebase
  static Future<void> _syncFromFirebase() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('CustomExerciseService: No authenticated user, skipping Firebase sync');
        return;
      }

      await FirebaseHelper.ensureAuthenticatedUser();
      if (FirebaseAuth.instance.currentUser == null) {
        print('CustomExerciseService: User authentication failed, skipping Firebase sync');
        return;
      }

      final firestore = FirebaseFirestore.instance;
      final snapshot = await firestore
          .collection('users')
          .doc(user.uid)
          .collection('customExercises')
          .get();

      final firebaseExercises = <HiveCustomExercise>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        firebaseExercises.add(HiveCustomExercise(
          id: data['id'] ?? doc.id,
          name: data['name'] ?? '',
          description: data['description'] ?? '',
          muscle: data['muscle'] ?? '',
          painLevel: data['painLevel'] ?? '',
          goal: data['goal'] ?? '',
          rep: data['rep'] ?? 0,
          set: data['set'] ?? 0,
          imageUrl: data['imageUrl'] ?? '',
          videoUrl: data['videoUrl'] ?? '',
          otherMuscles: data['otherMuscles'] ?? '',
          createdAt: DateTime.tryParse(data['createdAt'] ?? '') ?? DateTime.now(),
          lastModified: DateTime.tryParse(data['lastModified'] ?? '') ?? DateTime.now(),
        ));
      }

      // Merge with Hive data (Firebase takes precedence for conflicts)
      final hiveExercises = _cachedCustomExercises ?? [];
      final mergedExercises = <HiveCustomExercise>[];
      final processedIds = <String>{};

      // Add Firebase exercises first
      for (final firebaseEx in firebaseExercises) {
        mergedExercises.add(firebaseEx);
        processedIds.add(firebaseEx.id);
      }

      // Add Hive exercises that aren't in Firebase
      for (final hiveEx in hiveExercises) {
        if (!processedIds.contains(hiveEx.id)) {
          mergedExercises.add(hiveEx);
        }
      }

      _cachedCustomExercises = mergedExercises;

      // Save merged data back to Hive
      if (!Hive.isBoxOpen('rehabBox')) {
        await openRehabBox();
      }
      final box = Hive.box('rehabBox');
      await box.put('customExercises', mergedExercises);

      print('CustomExerciseService: Synced ${firebaseExercises.length} custom exercises from Firebase');
    } catch (e) {
      print('CustomExerciseService: Error syncing from Firebase: $e');
      // Don't rethrow - Firebase is optional
    }
  }

  /// Delete from Hive
  static Future<void> _deleteFromHive(String exerciseId) async {
    try {
      if (!Hive.isBoxOpen('rehabBox')) {
        await openRehabBox();
      }
      
      final box = Hive.box('rehabBox');
      final customExercises = List<HiveCustomExercise>.from(box.get('customExercises', defaultValue: <HiveCustomExercise>[]));
      
      customExercises.removeWhere((ex) => ex.id == exerciseId);
      await box.put('customExercises', customExercises);
      
      print('CustomExerciseService: Deleted from Hive: $exerciseId');
    } catch (e) {
      print('CustomExerciseService: Error deleting from Hive: $e');
      rethrow;
    }
  }

  /// Delete from Firebase
  static Future<void> _deleteFromFirebase(String exerciseId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('CustomExerciseService: No authenticated user, skipping Firebase delete');
        return;
      }

      await FirebaseHelper.ensureAuthenticatedUser();
      if (FirebaseAuth.instance.currentUser == null) {
        print('CustomExerciseService: User authentication failed, skipping Firebase delete');
        return;
      }

      final firestore = FirebaseFirestore.instance;
      await firestore
          .collection('users')
          .doc(user.uid)
          .collection('customExercises')
          .doc(exerciseId)
          .delete();

      print('CustomExerciseService: Deleted from Firebase: $exerciseId');
    } catch (e) {
      print('CustomExerciseService: Error deleting from Firebase: $e');
      // Don't rethrow - Firebase is optional
    }
  }

  /// Convert HiveCustomExercise to Exercise
  static Exercise _hiveToExercise(HiveCustomExercise hiveEx) {
    return Exercise(
      id: hiveEx.id,
      name: hiveEx.name,
      description: hiveEx.description,
      muscle: hiveEx.muscle,
      painLevel: hiveEx.painLevel,
      goal: hiveEx.goal,
      rep: hiveEx.rep,
      set: hiveEx.set,
      imageUrl: hiveEx.imageUrl,
      videoUrl: hiveEx.videoUrl,
      otherMuscles: hiveEx.otherMuscles,
    );
  }

  /// Clear cache
  static void clearCache() {
    _cachedCustomExercises = null;
    print('CustomExerciseService: Cache cleared');
  }
}