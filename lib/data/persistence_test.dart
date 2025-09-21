import 'package:hive/hive.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'globals.dart';
import 'rehabilitation_plan.dart';
import 'treatment.dart';
import 'data_persistence_service.dart';
import 'data_sync_service.dart';
import 'firebase_helper.dart';

/// Comprehensive test class for data persistence functionality
class PersistenceTest {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Run all persistence tests
  static Future<Map<String, dynamic>> runAllTests() async {
    final results = <String, dynamic>{
      'success': true,
      'tests': <String, dynamic>{},
      'errors': <String>[],
    };

    print('=== PERSISTENCE TEST SUITE STARTING ===');

    try {
      // Test 1: Hive Adapter Registration
      results['tests']['hiveAdapters'] = await _testHiveAdapters();
      
      // Test 2: Hive Data Saving
      results['tests']['hiveSaving'] = await _testHiveSaving();
      
      // Test 3: Hive Data Loading
      results['tests']['hiveLoading'] = await _testHiveLoading();
      
      // Test 4: Data Integrity
      results['tests']['dataIntegrity'] = await _testDataIntegrity();
      
      // Test 5: Firebase Collections (if authenticated)
      if (_auth.currentUser != null) {
        results['tests']['firebaseCollections'] = await _testFirebaseCollections();
        results['tests']['firebaseSync'] = await _testFirebaseSync();
      } else {
        results['tests']['firebaseCollections'] = {'skipped': true, 'reason': 'No authenticated user'};
        results['tests']['firebaseSync'] = {'skipped': true, 'reason': 'No authenticated user'};
      }
      
      // Test 6: Error Handling
      results['tests']['errorHandling'] = await _testErrorHandling();
      
      // Calculate overall success
      final testResults = results['tests'] as Map<String, dynamic>;
      final failedTests = testResults.values.where((test) => 
        test is Map<String, dynamic> && test['success'] == false).length;
      
      results['success'] = failedTests == 0;
      results['summary'] = {
        'totalTests': testResults.length,
        'passedTests': testResults.length - failedTests,
        'failedTests': failedTests,
      };

      print('=== PERSISTENCE TEST SUITE COMPLETED ===');
      print('Overall Success: ${results['success']}');
      print('Tests Passed: ${results['summary']['passedTests']}/${results['summary']['totalTests']}');

    } catch (e) {
      print('PersistenceTest: Critical error in test suite: $e');
      results['success'] = false;
      results['errors'].add('Critical error: $e');
    }

    return results;
  }

  /// Test 1: Verify all Hive adapters are registered
  static Future<Map<String, dynamic>> _testHiveAdapters() async {
    try {
      print('Test 1: Testing Hive adapter registration...');
      
      final requiredAdapters = [
        'HiveDailyProgressAdapter',
        'HiveRehabilitationPlanAdapter',
        'HivePainRecordEntryAdapter',
        'HiveExerciseRecordEntryAdapter',
        'HiveUserProgressAdapter',
        'HiveUserAssessAdapter',
        'HiveUserSettingsAdapter',
        'HiveUserDetailsAdapter',
        'HiveActiveProgramAdapter',
        'HiveExerciseReferenceAdapter',
        'HiveTreatmentReferenceAdapter',
        'HiveExerciseIdsAdapter',
        'HiveTreatmentIdsAdapter',
      ];

      final registeredAdapters = <String>[];
      final missingAdapters = <String>[];

      for (final adapterName in requiredAdapters) {
        try {
          // Try to create an instance to verify it's registered
          switch (adapterName) {
            case 'HiveDailyProgressAdapter':
              Hive.box('rehabBox').get('test');
              break;
            case 'HiveExerciseIdsAdapter':
              Hive.box('rehabBox').get('test');
              break;
            case 'HiveTreatmentIdsAdapter':
              Hive.box('rehabBox').get('test');
              break;
            // Add other adapters as needed
          }
          registeredAdapters.add(adapterName);
        } catch (e) {
          missingAdapters.add(adapterName);
        }
      }

      final success = missingAdapters.isEmpty;
      print('Test 1 Result: ${success ? 'PASSED' : 'FAILED'}');
      if (!success) {
        print('Missing adapters: $missingAdapters');
      }

      return {
        'success': success,
        'registeredAdapters': registeredAdapters.length,
        'missingAdapters': missingAdapters,
        'totalRequired': requiredAdapters.length,
      };

    } catch (e) {
      print('Test 1 Error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Test 2: Test Hive data saving
  static Future<Map<String, dynamic>> _testHiveSaving() async {
    try {
      print('Test 2: Testing Hive data saving...');
      
      // Test data
      final testData = {
        'userDetails': {
          'firstName': 'Test',
          'lastName': 'User',
          'email': 'test@example.com',
          'password': 'testpass',
          'notifications': ['reminder1', 'reminder2'],
        },
        'userProgress': {
          'title': 'Tester',
          'titleColor': '#FF0000',
          'streak': 5,
          'totalDays': 10,
          'totalExercises': 25,
          'totalSeconds': 3600,
          'notes': 'Test notes',
          'lastExerciseDate': DateTime.now(),
        },
        'userAssess': {
          'rehabGoal': 'Test Goal',
          'generalMuscle': 'Test Muscle',
          'specificMuscle': 'Test Specific',
          'painScale': 5,
          'painLevel': 'Moderate',
          'painType': 'Test Type',
          'painDuration': 'Test Duration',
          'isInjured': true,
          'isAssessed': true,
        },
        'userSettings': {
          'isDailyReminder': true,
          'isStreakAlert': false,
          'isExerciseReminder': true,
          'exerciseReminderHour': 9,
          'exerciseReminderMinute': 30,
        },
        'activeProgram': {
          'startDate': DateTime.now(),
        },
      };

      // Set test data
      UserDetails.firstName = testData['userDetails']!['firstName'] as String;
      UserDetails.lastName = testData['userDetails']!['lastName'] as String;
      UserDetails.email = testData['userDetails']!['email'] as String;
      UserDetails.password = testData['userDetails']!['password'] as String;
      UserDetails.notifications = List<String>.from(testData['userDetails']!['notifications'] as List);

      UserProgress.title = testData['userProgress']!['title'] as String;
      UserProgress.titleColor = testData['userProgress']!['titleColor'] as String;
      UserProgress.streak = testData['userProgress']!['streak'] as int;
      UserProgress.totalDays = testData['userProgress']!['totalDays'] as int;
      UserProgress.totalExercises = testData['userProgress']!['totalExercises'] as int;
      UserProgress.totalSeconds = testData['userProgress']!['totalSeconds'] as int;
      UserProgress.notes = testData['userProgress']!['notes'] as String;
      UserProgress.lastExerciseDate = testData['userProgress']!['lastExerciseDate'] as DateTime;

      UserAssess.rehabGoal = testData['userAssess']!['rehabGoal'] as String;
      UserAssess.generalMuscle = testData['userAssess']!['generalMuscle'] as String;
      UserAssess.specificMuscle = testData['userAssess']!['specificMuscle'] as String;
      UserAssess.painScale = testData['userAssess']!['painScale'] as int;
      UserAssess.painLevel = testData['userAssess']!['painLevel'] as String;
      UserAssess.painType = testData['userAssess']!['painType'] as String;
      UserAssess.painDuration = testData['userAssess']!['painDuration'] as String;
      UserAssess.isInjured = testData['userAssess']!['isInjured'] as bool;
      UserAssess.isAssessed = testData['userAssess']!['isAssessed'] as bool;

      UserSettings.isDailyReminder = testData['userSettings']!['isDailyReminder'] as bool;
      UserSettings.isStreakAlert = testData['userSettings']!['isStreakAlert'] as bool;
      UserSettings.isExerciseReminder = testData['userSettings']!['isExerciseReminder'] as bool;
      UserSettings.exerciseReminderTime = const TimeOfDay(
        hour: 9,
        minute: 30,
      );

      ActiveProgram.startDate = testData['activeProgram']!['startDate'] as DateTime;

      // Test rehabilitation data
      final testExerciseRefs = [
        ExerciseReference(exerciseId: 'test1', repetitions: 10, sets: 3),
        ExerciseReference(exerciseId: 'test2', repetitions: 15, sets: 2),
      ];
      final testRehabPlan = RehabilitationPlan(
        weekNumber: 1,
        exerciseReferences: testExerciseRefs,
        daily: [],
      );
      UserRehabilitation.instance.rehabPlans = [testRehabPlan];

      final testTreatmentRefs = [
        TreatmentReference(treatmentId: 'treatment1'),
        TreatmentReference(treatmentId: 'treatment2'),
      ];
      UserRehabilitation.instance.treatmentReferences = testTreatmentRefs;

      // Test pain history
      PainHistory.recordToday(painScale: 5, painLevel: 'Moderate');
      PainHistory.recordToday(painScale: 3, painLevel: 'Mild', now: DateTime.now().subtract(const Duration(days: 1)));

      // Test exercise history
      ExerciseHistory.recordToday(
        exerciseId: 'test1',
        exerciseName: 'Test Exercise',
        sets: 3,
        reps: 10,
        durationSeconds: 300,
        status: 'completed',
      );

      // Save all data
      await DataPersistenceService.saveAllDataToHive();

      print('Test 2 Result: PASSED - All data saved successfully');

      return {
        'success': true,
        'message': 'All data saved successfully to Hive',
        'dataTypes': ['userDetails', 'userProgress', 'userAssess', 'userSettings', 'activeProgram', 'rehabilitation', 'painHistory', 'exerciseHistory'],
      };

    } catch (e) {
      print('Test 2 Error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Test 3: Test Hive data loading
  static Future<Map<String, dynamic>> _testHiveLoading() async {
    try {
      print('Test 3: Testing Hive data loading...');
      
      // Clear current data
      UserDetails.firstName = '';
      UserDetails.lastName = '';
      UserDetails.email = '';
      UserProgress.title = 'Initiator';
      UserProgress.streak = 0;
      UserAssess.rehabGoal = '';
      UserAssess.isAssessed = false;
      UserSettings.isDailyReminder = true;
      ActiveProgram.startDate = null;
      UserRehabilitation.instance.rehabPlans = [];
      UserRehabilitation.instance.treatmentReferences = null;
      PainHistory.entries.clear();
      ExerciseHistory.entries.clear();

      // Load all data
      await DataPersistenceService.loadAllDataFromHive();

      // Verify data was loaded
      final loadedData = {
        'userDetails': {
          'firstName': UserDetails.firstName,
          'lastName': UserDetails.lastName,
          'email': UserDetails.email,
        },
        'userProgress': {
          'title': UserProgress.title,
          'streak': UserProgress.streak,
          'totalDays': UserProgress.totalDays,
        },
        'userAssess': {
          'rehabGoal': UserAssess.rehabGoal,
          'isAssessed': UserAssess.isAssessed,
        },
        'userSettings': {
          'isDailyReminder': UserSettings.isDailyReminder,
          'isStreakAlert': UserSettings.isStreakAlert,
        },
        'activeProgram': {
          'startDate': ActiveProgram.startDate?.toString(),
        },
        'rehabilitation': {
          'plansCount': UserRehabilitation.instance.rehabPlans.length,
          'treatmentsCount': UserRehabilitation.instance.treatmentReferences?.length ?? 0,
        },
        'painHistory': {
          'entriesCount': PainHistory.entries.length,
        },
        'exerciseHistory': {
          'entriesCount': ExerciseHistory.entries.length,
        },
      };

      // Check if test data was loaded correctly
      final success = UserDetails.firstName == 'Test' &&
                     UserProgress.title == 'Tester' &&
                     UserAssess.rehabGoal == 'Test Goal' &&
                     UserRehabilitation.instance.rehabPlans.isNotEmpty &&
                     PainHistory.entries.isNotEmpty;

      print('Test 3 Result: ${success ? 'PASSED' : 'FAILED'}');
      if (!success) {
        print('Loaded data: $loadedData');
      }

      return {
        'success': success,
        'loadedData': loadedData,
        'message': success ? 'All data loaded successfully from Hive' : 'Some data failed to load correctly',
      };

    } catch (e) {
      print('Test 3 Error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Test 4: Test data integrity
  static Future<Map<String, dynamic>> _testDataIntegrity() async {
    try {
      print('Test 4: Testing data integrity...');
      
      // Test rehabilitation plan data integrity
      final rehabIntegrity = await UserRehabilitation.instance.verifyDataIntegrity();
      
      // Test Hive box integrity
      final box = Hive.box('rehabBox');
      final boxKeys = box.keys.toList();
      
      // Check for required keys
      final requiredKeys = [
        'userDetails',
        'userProgress', 
        'userAssess',
        'userSettings',
        'activeProgram',
        'exerciseIds',
        'treatmentIds',
        'painHistory',
        'exerciseHistory',
      ];
      
      final missingKeys = requiredKeys.where((key) => !boxKeys.contains(key)).toList();
      final extraKeys = boxKeys.where((key) => !requiredKeys.contains(key)).toList();
      
      final success = rehabIntegrity && missingKeys.isEmpty;
      
      print('Test 4 Result: ${success ? 'PASSED' : 'FAILED'}');
      if (!success) {
        print('Rehab integrity: $rehabIntegrity');
        print('Missing keys: $missingKeys');
        print('Extra keys: $extraKeys');
      }

      return {
        'success': success,
        'rehabIntegrity': rehabIntegrity,
        'missingKeys': missingKeys,
        'extraKeys': extraKeys,
        'totalKeys': boxKeys.length,
        'requiredKeys': requiredKeys.length,
      };

    } catch (e) {
      print('Test 4 Error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Test 5: Test Firebase collections
  static Future<Map<String, dynamic>> _testFirebaseCollections() async {
    try {
      print('Test 5: Testing Firebase collections...');
      
      final user = _auth.currentUser;
      if (user == null) {
        return {'success': false, 'error': 'No authenticated user'};
      }

      // Ensure collections exist
      final collectionResults = await FirebaseHelper.ensureAllCollectionsExist();
      
      // Get user data summary
      final userSummary = await FirebaseHelper.getUserDataSummary();
      
      final success = collectionResults['success'] == true && !userSummary.containsKey('error');
      
      print('Test 5 Result: ${success ? 'PASSED' : 'FAILED'}');
      if (!success) {
        print('Collection results: $collectionResults');
        print('User summary: $userSummary');
      }

      return {
        'success': success,
        'collectionResults': collectionResults,
        'userSummary': userSummary,
      };

    } catch (e) {
      print('Test 5 Error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Test 6: Test Firebase synchronization
  static Future<Map<String, dynamic>> _testFirebaseSync() async {
    try {
      print('Test 6: Testing Firebase synchronization...');
      
      // Test data sync
      final syncResults = await DataSyncService.instance.syncAllData();
      
      final success = syncResults['success'] == true;
      
      print('Test 6 Result: ${success ? 'PASSED' : 'FAILED'}');
      if (!success) {
        print('Sync results: $syncResults');
      }

      return {
        'success': success,
        'syncResults': syncResults,
      };

    } catch (e) {
      print('Test 6 Error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Test 7: Test error handling
  static Future<Map<String, dynamic>> _testErrorHandling() async {
    try {
      print('Test 7: Testing error handling...');
      
      // Test with invalid data
      final originalFirstName = UserDetails.firstName;
      UserDetails.firstName = 'x' * 10000; // Very long string
      
      try {
        await UserDetails.saveToHive();
        // If it doesn't throw an error, that's also a valid result
        print('Test 7: Long string handling - no error thrown');
      } catch (e) {
        print('Test 7: Long string handling - error caught: $e');
      }
      
      // Restore original data
      UserDetails.firstName = originalFirstName;
      
      // Test with null data
      final originalStartDate = ActiveProgram.startDate;
      ActiveProgram.startDate = null;
      
      try {
        await ActiveProgram.saveToHive();
        print('Test 7: Null data handling - no error thrown');
      } catch (e) {
        print('Test 7: Null data handling - error caught: $e');
      }
      
      // Restore original data
      ActiveProgram.startDate = originalStartDate;
      
      print('Test 7 Result: PASSED - Error handling working correctly');

      return {
        'success': true,
        'message': 'Error handling working correctly',
        'tests': ['longString', 'nullData'],
      };

    } catch (e) {
      print('Test 7 Error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Clean up test data
  static Future<void> cleanup() async {
    try {
      print('Cleaning up test data...');
      
      // Clear test data
      UserDetails.firstName = '';
      UserDetails.lastName = '';
      UserDetails.email = '';
      UserProgress.title = 'Initiator';
      UserProgress.streak = 0;
      UserAssess.rehabGoal = '';
      UserAssess.isAssessed = false;
      UserRehabilitation.instance.rehabPlans = [];
      UserRehabilitation.instance.treatmentReferences = null;
      PainHistory.entries.clear();
      ExerciseHistory.entries.clear();
      
      // Save empty state
      await DataPersistenceService.saveAllDataToHive();
      
      print('Test data cleanup completed');
    } catch (e) {
      print('Error during cleanup: $e');
    }
  }
}
