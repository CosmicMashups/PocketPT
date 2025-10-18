import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'data/globals.dart';
import 'data/data_sync_service.dart';
import 'data/firebase_helper.dart';

/// Test class to verify Firebase integration with the new flat collection structure
class FirebaseIntegrationTest {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Test the complete Firebase integration
  static Future<Map<String, dynamic>> testCompleteIntegration() async {
    final results = <String, dynamic>{
      'success': true,
      'tests': <String, dynamic>{},
      'errors': <String>[],
    };

    try {
      debugPrint('FirebaseIntegrationTest: Starting complete integration test...');

      // Test 1: Authentication
      results['tests']['authentication'] = await _testAuthentication();
      
      // Test 2: Collection Creation
      results['tests']['collections'] = await _testCollectionCreation();
      
      // Test 3: Data Sync
      results['tests']['dataSync'] = await _testDataSync();
      
      // Test 4: Data Persistence
      results['tests']['dataPersistence'] = await _testDataPersistence();

      // Check overall success
      final allTestsPassed = results['tests'].values.every((test) => test['success'] == true);
      results['success'] = allTestsPassed;

      debugPrint('FirebaseIntegrationTest: Integration test completed - Success: ${results['success']}');

    } catch (e) {
      debugPrint('FirebaseIntegrationTest: Error during integration test: $e');
      results['success'] = false;
      results['errors'].add(e.toString());
    }

    return results;
  }

  /// Test Firebase authentication
  static Future<Map<String, dynamic>> _testAuthentication() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        return {
          'success': false,
          'error': 'No authenticated user found',
        };
      }

      debugPrint('FirebaseIntegrationTest: Authentication test passed - User: ${currentUser.uid}');
      return {
        'success': true,
        'userId': currentUser.uid,
        'email': currentUser.email,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Test Firebase collection creation
  static Future<Map<String, dynamic>> _testCollectionCreation() async {
    try {
      debugPrint('FirebaseIntegrationTest: Testing collection creation...');
      
      final collectionResults = await FirebaseHelper.ensureAllCollectionsExist();
      
      debugPrint('FirebaseIntegrationTest: Collection creation test completed');
      return {
        'success': collectionResults['success'],
        'createdCollections': collectionResults['createdCollections'],
        'existingCollections': collectionResults['existingCollections'],
        'errors': collectionResults['errors'],
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Test data synchronization
  static Future<Map<String, dynamic>> _testDataSync() async {
    try {
      debugPrint('FirebaseIntegrationTest: Testing data synchronization...');
      
      // Initialize data sync service
      await DataSyncService.instance.initialize();
      
      // Test comprehensive sync
      final syncResults = await DataSyncService.instance.syncAllData();
      
      debugPrint('FirebaseIntegrationTest: Data sync test completed');
      return {
        'success': syncResults['success'],
        'syncCount': syncResults['syncCount'],
        'totalOperations': syncResults['totalOperations'],
        'successCount': syncResults['successCount'],
        'lastSyncTime': syncResults['lastSyncTime'],
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Test data persistence with sample data
  static Future<Map<String, dynamic>> _testDataPersistence() async {
    try {
      debugPrint('FirebaseIntegrationTest: Testing data persistence...');
      
      // Set some test data
      UserProgress.title = 'Test User';
      UserProgress.streak = 5;
      UserProgress.totalExercises = 10;
      
      UserAssess.rehabGoal = 'Test Goal';
      UserAssess.generalMuscle = 'Shoulder';
      UserAssess.isAssessed = true;
      
      UserSettings.isDailyReminder = false;
      UserSettings.isStreakAlert = true;
      
      // Add some test pain history
      PainHistory.recordToday(painScale: 3, painLevel: 'Mild');
      
      // Add some test exercise history
      ExerciseHistory.recordToday(
        exerciseId: 'TEST001',
        exerciseName: 'Test Exercise',
        sets: 3,
        reps: 10,
        durationSeconds: 300,
        status: 'completed',
      );

      // Save all data to Firebase
      await UserProgress.saveToFirebase();
      await UserAssess.saveToFirebase();
      await UserSettings.saveToFirebase();
      await PainHistory.saveToFirebase();
      await ExerciseHistory.saveToFirebase();

      // Verify data was saved by loading it back
      await UserProgress.loadFromFirebase();
      await UserAssess.loadFromFirebase();
      await UserSettings.loadFromFirebase();
      await PainHistory.loadFromFirebase();
      await ExerciseHistory.loadFromFirebase();

      final dataMatches = UserProgress.title == 'Test User' &&
                         UserProgress.streak == 5 &&
                         UserAssess.rehabGoal == 'Test Goal' &&
                         UserSettings.isDailyReminder == false &&
                         PainHistory.entries.isNotEmpty &&
                         ExerciseHistory.entries.isNotEmpty;

      debugPrint('FirebaseIntegrationTest: Data persistence test completed - Data matches: $dataMatches');
      
      return {
        'success': dataMatches,
        'progressTitle': UserProgress.title,
        'progressStreak': UserProgress.streak,
        'assessmentGoal': UserAssess.rehabGoal,
        'settingsDailyReminder': UserSettings.isDailyReminder,
        'painHistoryCount': PainHistory.entries.length,
        'exerciseHistoryCount': ExerciseHistory.entries.length,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Test individual Firebase collections
  static Future<Map<String, dynamic>> testIndividualCollections() async {
    final results = <String, dynamic>{
      'success': true,
      'collections': <String, dynamic>{},
      'errors': <String>[],
    };

    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        results['success'] = false;
        results['errors'].add('No authenticated user found');
        return results;
      }

      final String userId = currentUser.uid;
      final List<String> collections = [
        'users',
        'rehabilitation',
        'progress',
        'assessment',
        'settings',
        'painHistory',
        'exerciseHistory',
      ];

      for (final collection in collections) {
        try {
          final DocumentSnapshot doc = await _firestore
              .collection(collection)
              .doc(userId)
              .get();

          results['collections'][collection] = {
            'exists': doc.exists,
            'hasData': doc.exists && doc.data() != null,
          };

          if (doc.exists && doc.data() != null) {
            final data = doc.data() as Map<String, dynamic>;
            results['collections'][collection]['fields'] = data.keys.toList();
            results['collections'][collection]['lastUpdated'] = data['lastUpdated'];
          }
        } catch (e) {
          results['collections'][collection] = {
            'exists': false,
            'error': e.toString(),
          };
          results['errors'].add('$collection: $e');
        }
      }

      debugPrint('FirebaseIntegrationTest: Individual collections test completed');
      return results;
    } catch (e) {
      results['success'] = false;
      results['errors'].add('General error: $e');
      return results;
    }
  }

  /// Clear test data from Firebase
  static Future<void> clearTestData() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final String userId = currentUser.uid;
      final List<String> collections = [
        'progress',
        'assessment',
        'settings',
        'painHistory',
        'exerciseHistory',
      ];

      for (final collection in collections) {
        try {
          await _firestore.collection(collection).doc(userId).delete();
          debugPrint('FirebaseIntegrationTest: Cleared test data from $collection');
        } catch (e) {
          debugPrint('FirebaseIntegrationTest: Error clearing $collection: $e');
        }
      }

      debugPrint('FirebaseIntegrationTest: Test data cleared successfully');
    } catch (e) {
      debugPrint('FirebaseIntegrationTest: Error clearing test data: $e');
    }
  }
}
