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
      print('CustomExerciseService: ✅ Successfully saved to Hive: ${exercise.name}');
      
      // Save to Firebase if authenticated (don't fail if Firebase save fails)
      bool firebaseSaveSuccess = false;
      try {
        await _saveToFirebase(hiveExercise);
        firebaseSaveSuccess = true;
        print('CustomExerciseService: ✅ Successfully saved to both Hive and Firebase: ${exercise.name}');
      } on FirebaseException catch (firebaseEx) {
        print('CustomExerciseService: ⚠️ Firebase save failed, but Hive save succeeded:');
        print('  Firebase Error Code: ${firebaseEx.code}');
        print('  Firebase Error Message: ${firebaseEx.message}');
        print('  Firebase Plugin: ${firebaseEx.plugin}');
        print('  Exercise was saved locally and will sync when connection is restored.');
      } catch (firebaseError, stackTrace) {
        print('CustomExerciseService: ⚠️ Firebase save failed with unexpected error:');
        print('  Error: $firebaseError');
        print('  Type: ${firebaseError.runtimeType}');
        print('  Stack: $stackTrace');
        print('  Exercise was saved locally and will sync when connection is restored.');
      }
      
      // Update cache
      _cachedCustomExercises ??= [];
      _cachedCustomExercises!.add(hiveExercise);
      
      print('CustomExerciseService: ✅ Custom exercise saved successfully (Hive: ✅, Firebase: ${firebaseSaveSuccess ? "✅" : "⚠️"})');
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
      // Ensure user is authenticated and get the authenticated user
      final authenticatedUser = await FirebaseHelper.ensureAuthenticatedUser();
      if (authenticatedUser == null) {
        print('CustomExerciseService: No authenticated user available, skipping Firebase save');
        return;
      }

      // Ensure user document exists before saving to subcollection
      try {
        await FirebaseHelper.ensureUserDocument();
        print('CustomExerciseService: User document verified/created');
      } catch (userDocError) {
        print('CustomExerciseService: Warning - Could not ensure user document: $userDocError');
        // Continue anyway - Firestore rules might allow the write
      }

      final firestore = FirebaseFirestore.instance;
      final userId = authenticatedUser.uid;
      
      // Include userId in document data to satisfy Firestore rules validation
      final exerciseData = {
        'id': exercise.id,
        'userId': userId, // Required by Firestore rules isValidUserId check
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
      };

      // Match the deployed Firestore rules path: customExercises/{userId}/exercises/{exerciseId}
      final collectionPath = 'customExercises/$userId/exercises';
      final documentPath = '$collectionPath/${exercise.id}';

      print('CustomExerciseService: Attempting to save to Firebase:');
      print('  User ID: $userId');
      print('  User Email: ${authenticatedUser.email}');
      print('  Exercise ID: ${exercise.id}');
      print('  Collection Path: $collectionPath');
      print('  Document Path: $documentPath');
      print('  Exercise Data Keys: ${exerciseData.keys.toList()}');
      print('  Document includes userId: ${exerciseData.containsKey('userId')}');

      // Attempt the save operation with explicit error handling
      try {
        await firestore
            .collection('customExercises')
            .doc(userId)
            .collection('exercises')
            .doc(exercise.id)
            .set(exerciseData, SetOptions(merge: false));
        
        print('CustomExerciseService: Set operation completed without exception');
      } catch (setError) {
        print('CustomExerciseService: Set operation failed: $setError');
        print('CustomExerciseService: Set error type: ${setError.runtimeType}');
        rethrow;
      }

      // Verify the save by reading it back (with a small delay to ensure consistency)
      await Future.delayed(const Duration(milliseconds: 100));
      
      final docSnapshot = await firestore
          .collection('customExercises')
          .doc(userId)
          .collection('exercises')
          .doc(exercise.id)
          .get();

      if (docSnapshot.exists) {
        print('CustomExerciseService: ✅ Successfully saved and verified in Firebase: ${exercise.name}');
        print('  Document ID: ${docSnapshot.id}');
        print('  Document exists: ${docSnapshot.exists}');
        final savedData = docSnapshot.data();
        if (savedData != null) {
          print('  Saved fields: ${savedData.keys.toList()}');
        }
      } else {
        final errorMsg = 'Document verification failed: document does not exist after save. Path: $documentPath';
        print('CustomExerciseService: ❌ $errorMsg');
        throw Exception(errorMsg);
      }
    } on FirebaseException catch (e) {
      print('CustomExerciseService: FirebaseException saving to Firebase:');
      print('  Code: ${e.code}');
      print('  Message: ${e.message}');
      print('  Plugin: ${e.plugin}');
      rethrow;
    } catch (e, stackTrace) {
      print('CustomExerciseService: Error saving to Firebase: $e');
      print('CustomExerciseService: Error type: ${e.runtimeType}');
      print('CustomExerciseService: Stack trace: $stackTrace');
      rethrow;
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
      final userId = user.uid;
      final snapshot = await firestore
          .collection('customExercises')
          .doc(userId)
          .collection('exercises')
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
      final userId = user.uid;
      await firestore
          .collection('customExercises')
          .doc(userId)
          .collection('exercises')
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