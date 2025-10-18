import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'data/globals.dart';
import 'data/firebase_helper.dart';

/// Comprehensive test to verify all Firebase collections are accessible
class FirebaseCollectionsAccessTest {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Test all Firebase collections access as specified in documentation
  static Future<Map<String, dynamic>> testAllCollectionsAccess() async {
    final results = <String, dynamic>{
      'success': true,
      'timestamp': DateTime.now().toIso8601String(),
      'collections': <String, dynamic>{},
      'errors': <String>[],
      'summary': <String, dynamic>{},
    };

    try {
      debugPrint('FirebaseCollectionsAccessTest: Starting comprehensive collection access test');

      // Check authentication
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        results['success'] = false;
        results['errors'].add('No authenticated user found');
        return results;
      }

      final String userId = currentUser.uid;
      debugPrint('FirebaseCollectionsAccessTest: Testing for user: $userId');

      // Test 1: Ensure all collections exist
      debugPrint('FirebaseCollectionsAccessTest: Step 1 - Ensuring all collections exist');
      final collectionResults = await FirebaseHelper.ensureAllCollectionsExist();
      results['collections']['creation'] = collectionResults;

      if (collectionResults['success'] != true) {
        results['errors'].addAll(collectionResults['errors'] ?? []);
      }

      // Test 2: Test users/{userId} collection
      debugPrint('FirebaseCollectionsAccessTest: Step 2 - Testing users collection');
      final usersTest = await _testUsersCollection(userId);
      results['collections']['users'] = usersTest;

      // Test 3: Test rehabilitation/{userId} collection
      debugPrint('FirebaseCollectionsAccessTest: Step 3 - Testing rehabilitation collection');
      final rehabilitationTest = await _testRehabilitationCollection(userId);
      results['collections']['rehabilitation'] = rehabilitationTest;

      // Test 4: Test progress/{userId} collection
      debugPrint('FirebaseCollectionsAccessTest: Step 4 - Testing progress collection');
      final progressTest = await _testProgressCollection(userId);
      results['collections']['progress'] = progressTest;

      // Test 5: Test assessment/{userId} collection
      debugPrint('FirebaseCollectionsAccessTest: Step 5 - Testing assessment collection');
      final assessmentTest = await _testAssessmentCollection(userId);
      results['collections']['assessment'] = assessmentTest;

      // Test 6: Test settings/{userId} collection
      debugPrint('FirebaseCollectionsAccessTest: Step 6 - Testing settings collection');
      final settingsTest = await _testSettingsCollection(userId);
      results['collections']['settings'] = settingsTest;

      // Test 7: Test painHistory/{userId} collection
      debugPrint('FirebaseCollectionsAccessTest: Step 7 - Testing painHistory collection');
      final painHistoryTest = await _testPainHistoryCollection(userId);
      results['collections']['painHistory'] = painHistoryTest;

      // Test 8: Test exerciseHistory/{userId} collection
      debugPrint('FirebaseCollectionsAccessTest: Step 8 - Testing exerciseHistory collection');
      final exerciseHistoryTest = await _testExerciseHistoryCollection(userId);
      results['collections']['exerciseHistory'] = exerciseHistoryTest;

      // Test 9: Test data sync operations
      debugPrint('FirebaseCollectionsAccessTest: Step 9 - Testing data sync operations');
      final syncTest = await _testDataSyncOperations();
      results['collections']['sync'] = syncTest;

      // Test 10: Test write operations for each collection
      debugPrint('FirebaseCollectionsAccessTest: Step 10 - Testing write operations');
      final writeTest = await _testWriteOperations(userId);
      results['collections']['writeOperations'] = writeTest;

      // Generate summary
      results['summary'] = _generateSummary(results['collections']);

      // Determine overall success
      final allTestsPassed = results['collections'].values
          .where((test) => test is Map<String, dynamic>)
          .every((test) => test['success'] == true);

      results['success'] = allTestsPassed && results['errors'].isEmpty;

      debugPrint('FirebaseCollectionsAccessTest: Test completed - Success: ${results['success']}');
      return results;

    } catch (e) {
      debugPrint('FirebaseCollectionsAccessTest: Error during test: $e');
      results['success'] = false;
      results['errors'].add('General error: $e');
      return results;
    }
  }

  /// Test users/{userId} collection access
  static Future<Map<String, dynamic>> _testUsersCollection(String userId) async {
    try {
      // Test read access
      final doc = await _firestore.collection('users').doc(userId).get();
      final canRead = doc.exists;

      // Test write access
      await _firestore.collection('users').doc(userId).update({
        'lastTested': FieldValue.serverTimestamp(),
      });
      final canWrite = true;

      return {
        'success': canRead && canWrite,
        'canRead': canRead,
        'canWrite': canWrite,
        'documentExists': doc.exists,
        'data': doc.exists ? doc.data() : null,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Test rehabilitation/{userId} collection access
  static Future<Map<String, dynamic>> _testRehabilitationCollection(String userId) async {
    try {
      // Test read access
      final doc = await _firestore.collection('rehabilitation').doc(userId).get();
      final canRead = true; // Collection exists even if document doesn't

      // Test write access
      await _firestore.collection('rehabilitation').doc(userId).set({
        'testData': 'test',
        'lastTested': FieldValue.serverTimestamp(),
        'userId': userId,
      }, SetOptions(merge: true));
      final canWrite = true;

      return {
        'success': canRead && canWrite,
        'canRead': canRead,
        'canWrite': canWrite,
        'documentExists': doc.exists,
        'data': doc.exists ? doc.data() : null,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Test progress/{userId} collection access
  static Future<Map<String, dynamic>> _testProgressCollection(String userId) async {
    try {
      // Test read access
      final doc = await _firestore.collection('progress').doc(userId).get();
      final canRead = true;

      // Test write access
      await _firestore.collection('progress').doc(userId).set({
        'title': 'Test Progress',
        'titleColor': '#FF0000',
        'streak': 0,
        'totalDays': 0,
        'totalExercises': 0,
        'totalSeconds': 0,
        'lastTested': FieldValue.serverTimestamp(),
        'userId': userId,
      }, SetOptions(merge: true));
      final canWrite = true;

      return {
        'success': canRead && canWrite,
        'canRead': canRead,
        'canWrite': canWrite,
        'documentExists': doc.exists,
        'data': doc.exists ? doc.data() : null,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Test assessment/{userId} collection access
  static Future<Map<String, dynamic>> _testAssessmentCollection(String userId) async {
    try {
      // Test read access
      final doc = await _firestore.collection('assessment').doc(userId).get();
      final canRead = true;

      // Test write access
      await _firestore.collection('assessment').doc(userId).set({
        'rehabGoal': 'Test Goal',
        'generalMuscle': 'Test Muscle',
        'specificMuscle': 'Test Specific',
        'painScale': 0,
        'painLevel': 'None',
        'painType': 'None',
        'painDuration': 'None',
        'isInjured': false,
        'isAssessed': true,
        'lastTested': FieldValue.serverTimestamp(),
        'userId': userId,
      }, SetOptions(merge: true));
      final canWrite = true;

      return {
        'success': canRead && canWrite,
        'canRead': canRead,
        'canWrite': canWrite,
        'documentExists': doc.exists,
        'data': doc.exists ? doc.data() : null,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Test settings/{userId} collection access
  static Future<Map<String, dynamic>> _testSettingsCollection(String userId) async {
    try {
      // Test read access
      final doc = await _firestore.collection('settings').doc(userId).get();
      final canRead = true;

      // Test write access
      await _firestore.collection('settings').doc(userId).set({
        'isDailyReminder': true,
        'isStreakAlert': true,
        'isExerciseReminder': true,
        'exerciseReminderHour': 8,
        'exerciseReminderMinute': 0,
        'lastTested': FieldValue.serverTimestamp(),
        'userId': userId,
      }, SetOptions(merge: true));
      final canWrite = true;

      return {
        'success': canRead && canWrite,
        'canRead': canRead,
        'canWrite': canWrite,
        'documentExists': doc.exists,
        'data': doc.exists ? doc.data() : null,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Test painHistory/{userId} collection access
  static Future<Map<String, dynamic>> _testPainHistoryCollection(String userId) async {
    try {
      // Test read access
      final doc = await _firestore.collection('painHistory').doc(userId).get();
      final canRead = true;

      // Test write access
      await _firestore.collection('painHistory').doc(userId).set({
        'entries': [
          {
            'date': Timestamp.fromDate(DateTime.now()),
            'painScale': 0,
            'painLevel': 'None',
          }
        ],
        'lastPromptedDate': null,
        'lastTested': FieldValue.serverTimestamp(),
        'userId': userId,
      }, SetOptions(merge: true));
      final canWrite = true;

      return {
        'success': canRead && canWrite,
        'canRead': canRead,
        'canWrite': canWrite,
        'documentExists': doc.exists,
        'data': doc.exists ? doc.data() : null,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Test exerciseHistory/{userId} collection access
  static Future<Map<String, dynamic>> _testExerciseHistoryCollection(String userId) async {
    try {
      // Test read access
      final doc = await _firestore.collection('exerciseHistory').doc(userId).get();
      final canRead = true;

      // Test write access
      await _firestore.collection('exerciseHistory').doc(userId).set({
        'entries': [
          {
            'date': Timestamp.fromDate(DateTime.now()),
            'exerciseId': 'TEST001',
            'exerciseName': 'Test Exercise',
            'sets': 1,
            'reps': 1,
            'durationSeconds': 60,
            'status': 'completed',
          }
        ],
        'lastTested': FieldValue.serverTimestamp(),
        'userId': userId,
      }, SetOptions(merge: true));
      final canWrite = true;

      return {
        'success': canRead && canWrite,
        'canRead': canRead,
        'canWrite': canWrite,
        'documentExists': doc.exists,
        'data': doc.exists ? doc.data() : null,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Test data sync operations
  static Future<Map<String, dynamic>> _testDataSyncOperations() async {
    try {
      final results = <String, dynamic>{
        'success': true,
        'operations': <String, dynamic>{},
      };

      // Test UserDetails sync
      try {
        await UserDetails.updateInFirebase();
        results['operations']['userDetails'] = {'success': true};
      } catch (e) {
        results['operations']['userDetails'] = {'success': false, 'error': e.toString()};
        results['success'] = false;
      }

      // Test UserProgress sync
      try {
        await UserProgress.saveToFirebase();
        results['operations']['userProgress'] = {'success': true};
      } catch (e) {
        results['operations']['userProgress'] = {'success': false, 'error': e.toString()};
        results['success'] = false;
      }

      // Test UserAssess sync
      try {
        await UserAssess.saveToFirebase();
        results['operations']['userAssess'] = {'success': true};
      } catch (e) {
        results['operations']['userAssess'] = {'success': false, 'error': e.toString()};
        results['success'] = false;
      }

      // Test UserSettings sync
      try {
        await UserSettings.saveToFirebase();
        results['operations']['userSettings'] = {'success': true};
      } catch (e) {
        results['operations']['userSettings'] = {'success': false, 'error': e.toString()};
        results['success'] = false;
      }

      // Test PainHistory sync
      try {
        await PainHistory.saveToFirebase();
        results['operations']['painHistory'] = {'success': true};
      } catch (e) {
        results['operations']['painHistory'] = {'success': false, 'error': e.toString()};
        results['success'] = false;
      }

      // Test ExerciseHistory sync
      try {
        await ExerciseHistory.saveToFirebase();
        results['operations']['exerciseHistory'] = {'success': true};
      } catch (e) {
        results['operations']['exerciseHistory'] = {'success': false, 'error': e.toString()};
        results['success'] = false;
      }

      return results;
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Generate summary of test results
  static Map<String, dynamic> _generateSummary(Map<String, dynamic> collections) {
    final summary = <String, dynamic>{
      'totalCollections': 0,
      'successfulCollections': 0,
      'failedCollections': 0,
      'collectionsWithData': 0,
      'collectionsWithoutData': 0,
    };

    for (final entry in collections.entries) {
      final collectionData = entry.value;

      if (collectionData is Map<String, dynamic>) {
        summary['totalCollections']++;
        
        if (collectionData['success'] == true) {
          summary['successfulCollections']++;
        } else {
          summary['failedCollections']++;
        }

        if (collectionData['documentExists'] == true) {
          summary['collectionsWithData']++;
        } else {
          summary['collectionsWithoutData']++;
        }
      }
    }

    return summary;
  }

  /// Test write operations for all collections
  static Future<Map<String, dynamic>> _testWriteOperations(String userId) async {
    try {
      final results = <String, dynamic>{
        'success': true,
        'operations': <String, dynamic>{},
      };

      // Test writing to each collection
      final collections = [
        'users',
        'rehabilitation', 
        'progress',
        'assessment',
        'settings',
        'painHistory',
        'exerciseHistory',
      ];

      for (final collectionName in collections) {
        try {
          final testData = {
            'testWrite': true,
            'timestamp': FieldValue.serverTimestamp(),
            'userId': userId,
          };

          // Write test data
          await _firestore.collection(collectionName).doc(userId).set(testData, SetOptions(merge: true));
          
          // Read it back to verify
          final doc = await _firestore.collection(collectionName).doc(userId).get();
          final canRead = doc.exists;
          final data = doc.exists ? doc.data() : null;
          
          results['operations'][collectionName] = {
            'success': true,
            'canWrite': true,
            'canRead': canRead,
            'dataExists': data != null,
          };
        } catch (e) {
          results['operations'][collectionName] = {
            'success': false,
            'error': e.toString(),
          };
          results['success'] = false;
        }
      }

      return results;
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}
