import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'data/globals.dart';
import 'data/firebase_helper.dart';

/// Comprehensive test to verify Firebase collections can be written to and read from
class FirebaseWriteOperationsTest {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Test all Firebase collections write/read operations
  static Future<Map<String, dynamic>> testAllWriteOperations() async {
    final results = <String, dynamic>{
      'success': true,
      'timestamp': DateTime.now().toIso8601String(),
      'collections': <String, dynamic>{},
      'errors': <String>[],
      'summary': <String, dynamic>{},
    };

    try {
      debugPrint('FirebaseWriteOperationsTest: Starting comprehensive write operations test');

      // Check authentication
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        results['success'] = false;
        results['errors'].add('No authenticated user found');
        return results;
      }

      final String userId = currentUser.uid;
      debugPrint('FirebaseWriteOperationsTest: Testing write operations for user: $userId');

      // Test 1: Ensure all collections exist
      debugPrint('FirebaseWriteOperationsTest: Step 1 - Ensuring all collections exist');
      final collectionResults = await FirebaseHelper.ensureAllCollectionsExist();
      results['collections']['creation'] = collectionResults;

      // Test 2: Test users/{userId} collection write/read
      debugPrint('FirebaseWriteOperationsTest: Step 2 - Testing users collection write/read');
      final usersTest = await _testUsersCollectionWriteRead(userId);
      results['collections']['users'] = usersTest;

      // Test 3: Test rehabilitation/{userId} collection write/read
      debugPrint('FirebaseWriteOperationsTest: Step 3 - Testing rehabilitation collection write/read');
      final rehabilitationTest = await _testRehabilitationCollectionWriteRead(userId);
      results['collections']['rehabilitation'] = rehabilitationTest;

      // Test 4: Test progress/{userId} collection write/read
      debugPrint('FirebaseWriteOperationsTest: Step 4 - Testing progress collection write/read');
      final progressTest = await _testProgressCollectionWriteRead(userId);
      results['collections']['progress'] = progressTest;

      // Test 5: Test assessment/{userId} collection write/read
      debugPrint('FirebaseWriteOperationsTest: Step 5 - Testing assessment collection write/read');
      final assessmentTest = await _testAssessmentCollectionWriteRead(userId);
      results['collections']['assessment'] = assessmentTest;

      // Test 6: Test settings/{userId} collection write/read
      debugPrint('FirebaseWriteOperationsTest: Step 6 - Testing settings collection write/read');
      final settingsTest = await _testSettingsCollectionWriteRead(userId);
      results['collections']['settings'] = settingsTest;

      // Test 7: Test painHistory/{userId} collection write/read
      debugPrint('FirebaseWriteOperationsTest: Step 7 - Testing painHistory collection write/read');
      final painHistoryTest = await _testPainHistoryCollectionWriteRead(userId);
      results['collections']['painHistory'] = painHistoryTest;

      // Test 8: Test exerciseHistory/{userId} collection write/read
      debugPrint('FirebaseWriteOperationsTest: Step 8 - Testing exerciseHistory collection write/read');
      final exerciseHistoryTest = await _testExerciseHistoryCollectionWriteRead(userId);
      results['collections']['exerciseHistory'] = exerciseHistoryTest;

      // Test 9: Test application data sync operations
      debugPrint('FirebaseWriteOperationsTest: Step 9 - Testing application data sync operations');
      final syncTest = await _testApplicationDataSync();
      results['collections']['applicationSync'] = syncTest;

      // Generate summary
      results['summary'] = _generateSummary(results['collections']);

      // Determine overall success
      final allTestsPassed = results['collections'].values
          .where((test) => test is Map<String, dynamic> && test.containsKey('success'))
          .every((test) => test['success'] == true);

      results['success'] = allTestsPassed && results['errors'].isEmpty;

      debugPrint('FirebaseWriteOperationsTest: Test completed - Success: ${results['success']}');
      return results;

    } catch (e) {
      debugPrint('FirebaseWriteOperationsTest: Error during test: $e');
      results['success'] = false;
      results['errors'].add('General error: $e');
      return results;
    }
  }

  /// Test users/{userId} collection write/read operations
  static Future<Map<String, dynamic>> _testUsersCollectionWriteRead(String userId) async {
    try {
      final testData = {
        'userId': userId,
        'firstName': 'Test User',
        'lastName': 'Write Test',
        'email': 'testuser@example.com',
        'hasCompletedAssessment': true,
        'profilePicture': 'https://example.com/profile.jpg',
        'testWriteTimestamp': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      // Test write operation
      await _firestore.collection('users').doc(userId).set(testData, SetOptions(merge: true));
      debugPrint('FirebaseWriteOperationsTest: Successfully wrote to users collection');

      // Test read operation
      final doc = await _firestore.collection('users').doc(userId).get();
      final canRead = doc.exists;
      final readData = doc.exists ? doc.data() : null;

      // Verify data integrity
      final dataMatches = canRead && 
          readData != null && 
          readData['firstName'] == 'Test User' &&
          readData['lastName'] == 'Write Test' &&
          readData['email'] == 'testuser@example.com';

      return {
        'success': canRead && dataMatches,
        'canWrite': true,
        'canRead': canRead,
        'dataMatches': dataMatches,
        'documentExists': doc.exists,
        'testData': testData,
        'readData': readData,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Test rehabilitation/{userId} collection write/read operations
  static Future<Map<String, dynamic>> _testRehabilitationCollectionWriteRead(String userId) async {
    try {
      final testData = {
        'userId': userId,
        'lastUpdated': FieldValue.serverTimestamp(),
        'Plan1': [
          {
            'exercise1': 'EX001',
            'exercise2': 'EX002',
            'exercise3': 'EX003',
          },
          {
            'treatment1': 'TR001',
            'treatment2': 'TR002',
          }
        ],
        'Plan2': [
          {
            'exercise1': 'EX004',
            'exercise2': 'EX005',
          },
          {
            'treatment1': 'TR003',
          }
        ],
        'testWriteTimestamp': FieldValue.serverTimestamp(),
      };

      // Test write operation
      await _firestore.collection('rehabilitation').doc(userId).set(testData, SetOptions(merge: true));
      debugPrint('FirebaseWriteOperationsTest: Successfully wrote to rehabilitation collection');

      // Test read operation
      final doc = await _firestore.collection('rehabilitation').doc(userId).get();
      final canRead = doc.exists;
      final readData = doc.exists ? doc.data() : null;

      // Verify data integrity
      final dataMatches = canRead && 
          readData != null && 
          readData['Plan1'] != null &&
          readData['Plan2'] != null &&
          (readData['Plan1'] as List).length == 2 &&
          (readData['Plan2'] as List).length == 2;

      return {
        'success': canRead && dataMatches,
        'canWrite': true,
        'canRead': canRead,
        'dataMatches': dataMatches,
        'documentExists': doc.exists,
        'testData': testData,
        'readData': readData,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Test progress/{userId} collection write/read operations
  static Future<Map<String, dynamic>> _testProgressCollectionWriteRead(String userId) async {
    try {
      final testData = {
        'title': 'Test Progress',
        'titleColor': '#FF0000',
        'streak': 5,
        'totalDays': 30,
        'totalExercises': 150,
        'totalSeconds': 7200,
        'notes': 'Test progress notes',
        'lastExerciseDate': Timestamp.fromDate(DateTime.now()),
        'lastUpdated': FieldValue.serverTimestamp(),
        'userId': userId,
        'testWriteTimestamp': FieldValue.serverTimestamp(),
      };

      // Test write operation
      await _firestore.collection('progress').doc(userId).set(testData, SetOptions(merge: true));
      debugPrint('FirebaseWriteOperationsTest: Successfully wrote to progress collection');

      // Test read operation
      final doc = await _firestore.collection('progress').doc(userId).get();
      final canRead = doc.exists;
      final readData = doc.exists ? doc.data() : null;

      // Verify data integrity
      final dataMatches = canRead && 
          readData != null && 
          readData['title'] == 'Test Progress' &&
          readData['streak'] == 5 &&
          readData['totalDays'] == 30;

      return {
        'success': canRead && dataMatches,
        'canWrite': true,
        'canRead': canRead,
        'dataMatches': dataMatches,
        'documentExists': doc.exists,
        'testData': testData,
        'readData': readData,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Test assessment/{userId} collection write/read operations
  static Future<Map<String, dynamic>> _testAssessmentCollectionWriteRead(String userId) async {
    try {
      final testData = {
        'rehabGoal': 'Test Goal',
        'generalMuscle': 'Test Muscle Group',
        'specificMuscle': 'Test Specific Muscle',
        'painScale': 7,
        'painLevel': 'Moderate',
        'painType': 'Sharp',
        'painDuration': 'Chronic',
        'isInjured': true,
        'isAssessed': true,
        'lastUpdated': FieldValue.serverTimestamp(),
        'userId': userId,
        'testWriteTimestamp': FieldValue.serverTimestamp(),
      };

      // Test write operation
      await _firestore.collection('assessment').doc(userId).set(testData, SetOptions(merge: true));
      debugPrint('FirebaseWriteOperationsTest: Successfully wrote to assessment collection');

      // Test read operation
      final doc = await _firestore.collection('assessment').doc(userId).get();
      final canRead = doc.exists;
      final readData = doc.exists ? doc.data() : null;

      // Verify data integrity
      final dataMatches = canRead && 
          readData != null && 
          readData['rehabGoal'] == 'Test Goal' &&
          readData['painScale'] == 7 &&
          readData['isInjured'] == true;

      return {
        'success': canRead && dataMatches,
        'canWrite': true,
        'canRead': canRead,
        'dataMatches': dataMatches,
        'documentExists': doc.exists,
        'testData': testData,
        'readData': readData,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Test settings/{userId} collection write/read operations
  static Future<Map<String, dynamic>> _testSettingsCollectionWriteRead(String userId) async {
    try {
      final testData = {
        'isDailyReminder': true,
        'isStreakAlert': false,
        'isExerciseReminder': true,
        'exerciseReminderHour': 9,
        'exerciseReminderMinute': 30,
        'lastUpdated': FieldValue.serverTimestamp(),
        'userId': userId,
        'testWriteTimestamp': FieldValue.serverTimestamp(),
      };

      // Test write operation
      await _firestore.collection('settings').doc(userId).set(testData, SetOptions(merge: true));
      debugPrint('FirebaseWriteOperationsTest: Successfully wrote to settings collection');

      // Test read operation
      final doc = await _firestore.collection('settings').doc(userId).get();
      final canRead = doc.exists;
      final readData = doc.exists ? doc.data() : null;

      // Verify data integrity
      final dataMatches = canRead && 
          readData != null && 
          readData['isDailyReminder'] == true &&
          readData['exerciseReminderHour'] == 9 &&
          readData['exerciseReminderMinute'] == 30;

      return {
        'success': canRead && dataMatches,
        'canWrite': true,
        'canRead': canRead,
        'dataMatches': dataMatches,
        'documentExists': doc.exists,
        'testData': testData,
        'readData': readData,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Test painHistory/{userId} collection write/read operations
  static Future<Map<String, dynamic>> _testPainHistoryCollectionWriteRead(String userId) async {
    try {
      final testData = {
        'entries': [
          {
            'date': Timestamp.fromDate(DateTime.now()),
            'painScale': 6,
            'painLevel': 'Moderate',
          },
          {
            'date': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
            'painScale': 4,
            'painLevel': 'Mild',
          }
        ],
        'lastPromptedDate': Timestamp.fromDate(DateTime.now()),
        'lastUpdated': FieldValue.serverTimestamp(),
        'userId': userId,
        'testWriteTimestamp': FieldValue.serverTimestamp(),
      };

      // Test write operation
      await _firestore.collection('painHistory').doc(userId).set(testData, SetOptions(merge: true));
      debugPrint('FirebaseWriteOperationsTest: Successfully wrote to painHistory collection');

      // Test read operation
      final doc = await _firestore.collection('painHistory').doc(userId).get();
      final canRead = doc.exists;
      final readData = doc.exists ? doc.data() : null;

      // Verify data integrity
      final dataMatches = canRead && 
          readData != null && 
          readData['entries'] != null &&
          (readData['entries'] as List).length == 2;

      return {
        'success': canRead && dataMatches,
        'canWrite': true,
        'canRead': canRead,
        'dataMatches': dataMatches,
        'documentExists': doc.exists,
        'testData': testData,
        'readData': readData,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Test exerciseHistory/{userId} collection write/read operations
  static Future<Map<String, dynamic>> _testExerciseHistoryCollectionWriteRead(String userId) async {
    try {
      final testData = {
        'entries': [
          {
            'date': Timestamp.fromDate(DateTime.now()),
            'exerciseId': 'EX001',
            'exerciseName': 'Test Exercise 1',
            'sets': 3,
            'reps': 10,
            'durationSeconds': 300,
            'status': 'completed',
          },
          {
            'date': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
            'exerciseId': 'EX002',
            'exerciseName': 'Test Exercise 2',
            'sets': 2,
            'reps': 15,
            'durationSeconds': 240,
            'status': 'completed',
          }
        ],
        'lastUpdated': FieldValue.serverTimestamp(),
        'userId': userId,
        'testWriteTimestamp': FieldValue.serverTimestamp(),
      };

      // Test write operation
      await _firestore.collection('exerciseHistory').doc(userId).set(testData, SetOptions(merge: true));
      debugPrint('FirebaseWriteOperationsTest: Successfully wrote to exerciseHistory collection');

      // Test read operation
      final doc = await _firestore.collection('exerciseHistory').doc(userId).get();
      final canRead = doc.exists;
      final readData = doc.exists ? doc.data() : null;

      // Verify data integrity
      final dataMatches = canRead && 
          readData != null && 
          readData['entries'] != null &&
          (readData['entries'] as List).length == 2;

      return {
        'success': canRead && dataMatches,
        'canWrite': true,
        'canRead': canRead,
        'dataMatches': dataMatches,
        'documentExists': doc.exists,
        'testData': testData,
        'readData': readData,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Test application data sync operations
  static Future<Map<String, dynamic>> _testApplicationDataSync() async {
    try {
      final results = <String, dynamic>{
        'success': true,
        'operations': <String, dynamic>{},
      };

      // Test UserDetails sync
      try {
        // Set some test data
        UserDetails.firstName = 'Test User';
        UserDetails.lastName = 'Sync Test';
        UserDetails.email = 'sync@example.com';
        UserDetails.hasCompletedAssessment = true;
        
        await UserDetails.updateInFirebase();
        results['operations']['userDetails'] = {'success': true, 'message': 'UserDetails synced successfully'};
      } catch (e) {
        results['operations']['userDetails'] = {'success': false, 'error': e.toString()};
        results['success'] = false;
      }

      // Test UserProgress sync
      try {
        UserProgress.title = 'Test Progress';
        UserProgress.streak = 10;
        UserProgress.totalDays = 50;
        UserProgress.totalExercises = 200;
        UserProgress.totalSeconds = 10000;
        
        await UserProgress.saveToFirebase();
        results['operations']['userProgress'] = {'success': true, 'message': 'UserProgress synced successfully'};
      } catch (e) {
        results['operations']['userProgress'] = {'success': false, 'error': e.toString()};
        results['success'] = false;
      }

      // Test UserAssess sync
      try {
        UserAssess.rehabGoal = 'Test Goal';
        UserAssess.generalMuscle = 'Test Muscle';
        UserAssess.specificMuscle = 'Test Specific';
        UserAssess.painScale = 5;
        UserAssess.painLevel = 'Moderate';
        UserAssess.painType = 'Dull';
        UserAssess.painDuration = 'Acute';
        UserAssess.isInjured = false;
        UserAssess.isAssessed = true;
        
        await UserAssess.saveToFirebase();
        results['operations']['userAssess'] = {'success': true, 'message': 'UserAssess synced successfully'};
      } catch (e) {
        results['operations']['userAssess'] = {'success': false, 'error': e.toString()};
        results['success'] = false;
      }

      // Test UserSettings sync
      try {
        UserSettings.isDailyReminder = true;
        UserSettings.isStreakAlert = true;
        UserSettings.isExerciseReminder = false;
        UserSettings.exerciseReminderTime = const TimeOfDay(hour: 8, minute: 0);
        
        await UserSettings.saveToFirebase();
        results['operations']['userSettings'] = {'success': true, 'message': 'UserSettings synced successfully'};
      } catch (e) {
        results['operations']['userSettings'] = {'success': false, 'error': e.toString()};
        results['success'] = false;
      }

      // Test PainHistory sync
      try {
        PainHistory.recordToday(painScale: 6, painLevel: 'Moderate');
        PainHistory.recordToday(painScale: 4, painLevel: 'Mild', now: DateTime.now().subtract(const Duration(days: 1)));
        
        await PainHistory.saveToFirebase();
        results['operations']['painHistory'] = {'success': true, 'message': 'PainHistory synced successfully'};
      } catch (e) {
        results['operations']['painHistory'] = {'success': false, 'error': e.toString()};
        results['success'] = false;
      }

      // Test ExerciseHistory sync
      try {
        ExerciseHistory.recordToday(
          exerciseId: 'EX001',
          exerciseName: 'Test Exercise',
          sets: 3,
          reps: 10,
          durationSeconds: 300,
          status: 'completed',
        );
        
        await ExerciseHistory.saveToFirebase();
        results['operations']['exerciseHistory'] = {'success': true, 'message': 'ExerciseHistory synced successfully'};
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
      'collectionsWithWriteAccess': 0,
      'collectionsWithReadAccess': 0,
      'collectionsWithDataIntegrity': 0,
    };

    for (final entry in collections.entries) {
      final collectionData = entry.value;

      if (collectionData is Map<String, dynamic> && collectionData.containsKey('success')) {
        summary['totalCollections']++;
        
        if (collectionData['success'] == true) {
          summary['successfulCollections']++;
        } else {
          summary['failedCollections']++;
        }

        if (collectionData['canWrite'] == true) {
          summary['collectionsWithWriteAccess']++;
        }

        if (collectionData['canRead'] == true) {
          summary['collectionsWithReadAccess']++;
        }

        if (collectionData['dataMatches'] == true) {
          summary['collectionsWithDataIntegrity']++;
        }
      }
    }

    return summary;
  }
}
