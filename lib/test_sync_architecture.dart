import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import 'data/globals.dart';
import 'data/data_sync_service.dart';
import 'data/sync_queue.dart';
import 'data/data_persistence_service.dart';

/// Comprehensive test suite for the new Hive-Firebase sync architecture
class SyncArchitectureTest {
  static bool _isInitialized = false;

  /// Initialize test environment
  static Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize Hive for testing
    final directory = await getTemporaryDirectory();
    Hive.init(directory.path);
    await Hive.openBox('rehabBox');

    _isInitialized = true;
    debugPrint('SyncArchitectureTest: Test environment initialized');
  }

  /// Test 1: Verify Hive loads before Firebase sync
  static Future<Map<String, dynamic>> testHiveLoadsBeforeFirebase() async {
    try {
      debugPrint('SyncArchitectureTest: Testing Hive loads before Firebase...');

      // Clear existing data
      await _clearAllData();

      // Set up test data in Hive
      UserDetails.firstName = 'Test';
      UserDetails.lastName = 'User';
      UserDetails.email = 'test@example.com';
      await UserDetails.saveToHive();

      UserAssess.rehabGoal = 'Pain Relief';
      UserAssess.generalMuscle = 'Shoulder';
      await UserAssess.saveToHive();

      // Clear in-memory data
      UserDetails.firstName = '';
      UserDetails.lastName = '';
      UserDetails.email = '';
      UserAssess.rehabGoal = '';
      UserAssess.generalMuscle = '';

      // Test that Hive data loads correctly
      await UserDetails.loadFromHive();
      await UserAssess.loadFromHive();

      final hasUserData = UserDetails.hasUserData;
      final hasAssessmentData = UserAssess.rehabGoal.isNotEmpty;

      return {
        'success': hasUserData && hasAssessmentData,
        'hasUserData': hasUserData,
        'hasAssessmentData': hasAssessmentData,
        'userFirstName': UserDetails.firstName,
        'assessmentGoal': UserAssess.rehabGoal,
      };
    } catch (e) {
      debugPrint('SyncArchitectureTest: Error in testHiveLoadsBeforeFirebase: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Test 2: Verify timestamp-based conflict resolution
  static Future<Map<String, dynamic>> testTimestampConflictResolution() async {
    try {
      debugPrint('SyncArchitectureTest: Testing timestamp conflict resolution...');

      // Clear existing data
      await _clearAllData();

      // Set up local data with timestamp
      UserDetails.firstName = 'Local';
      UserDetails.lastName = 'User';
      await UserDetails.saveToHive();

      final localTimestamp = UserDetails.lastModified!;
      debugPrint('SyncArchitectureTest: Local timestamp: $localTimestamp');

      // Simulate Firebase data with older timestamp
      final firebaseData = {
        'firstName': 'Remote',
        'lastName': 'User',
        'lastModified': localTimestamp.subtract(Duration(hours: 1)),
      };

      // Test conflict resolution - local should win
      final dataSyncService = DataSyncService.instance;
      final mergedData = dataSyncService._mergeUserData(firebaseData);

      final localWins = mergedData['firstName'] == 'Local';
      final timestampCorrect = mergedData['lastModified'] == localTimestamp;

      return {
        'success': localWins && timestampCorrect,
        'localWins': localWins,
        'timestampCorrect': timestampCorrect,
        'mergedFirstName': mergedData['firstName'],
        'localTimestamp': localTimestamp.toIso8601String(),
        'firebaseTimestamp': firebaseData['lastModified'].toIso8601String(),
      };
    } catch (e) {
      debugPrint('SyncArchitectureTest: Error in testTimestampConflictResolution: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Test 3: Verify offline writes queue properly
  static Future<Map<String, dynamic>> testOfflineWritesQueue() async {
    try {
      debugPrint('SyncArchitectureTest: Testing offline writes queue...');

      // Clear existing data and queue
      await _clearAllData();
      SyncQueue.clearQueue();

      // Simulate offline operation
      SyncQueue.enqueue('updateUserAssess', {
        'rehabGoal': 'Test Goal',
        'generalMuscle': 'Test Muscle',
      });

      final queueLength = SyncQueue.length;
      final hasOperations = SyncQueue.isNotEmpty;

      return {
        'success': queueLength == 1 && hasOperations,
        'queueLength': queueLength,
        'hasOperations': hasOperations,
      };
    } catch (e) {
      debugPrint('SyncArchitectureTest: Error in testOfflineWritesQueue: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Test 4: Verify widget displays data after Hive load
  static Future<Map<String, dynamic>> testWidgetDisplaysDataAfterHiveLoad() async {
    try {
      debugPrint('SyncArchitectureTest: Testing widget displays data after Hive load...');

      // Clear existing data
      await _clearAllData();

      // Set up test data in Hive
      UserAssess.rehabGoal = 'Pain Relief';
      UserAssess.generalMuscle = 'Shoulder';
      await UserAssess.saveToHive();

      // Clear in-memory data
      UserAssess.rehabGoal = '';
      UserAssess.generalMuscle = '';

      // Simulate widget loading process
      await UserAssess.loadFromHive();
      
      // Copy to AssessmentData (as widgets do)
      AssessmentData.rehabGoal = UserAssess.rehabGoal;
      AssessmentData.generalMuscle = UserAssess.generalMuscle;

      final dataLoaded = AssessmentData.rehabGoal == 'Pain Relief' && 
                        AssessmentData.generalMuscle == 'Shoulder';

      return {
        'success': dataLoaded,
        'rehabGoal': AssessmentData.rehabGoal,
        'generalMuscle': AssessmentData.generalMuscle,
        'userAssessGoal': UserAssess.rehabGoal,
        'userAssessMuscle': UserAssess.generalMuscle,
      };
    } catch (e) {
      debugPrint('SyncArchitectureTest: Error in testWidgetDisplaysDataAfterHiveLoad: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Test 5: Verify sync queue persistence
  static Future<Map<String, dynamic>> testSyncQueuePersistence() async {
    try {
      debugPrint('SyncArchitectureTest: Testing sync queue persistence...');

      // Clear existing data and queue
      await _clearAllData();
      SyncQueue.clearQueue();

      // Add operations to queue
      SyncQueue.enqueue('updateUserDetails', {'firstName': 'Test'});
      SyncQueue.enqueue('updateUserAssess', {'rehabGoal': 'Test Goal'});

      final initialLength = SyncQueue.length;

      // Simulate app restart by reloading queue
      await SyncQueue.loadQueueFromHive();
      final reloadedLength = SyncQueue.length;

      final queuePersisted = initialLength == reloadedLength && reloadedLength == 2;

      return {
        'success': queuePersisted,
        'initialLength': initialLength,
        'reloadedLength': reloadedLength,
      };
    } catch (e) {
      debugPrint('SyncArchitectureTest: Error in testSyncQueuePersistence: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Test 6: Verify data integrity after sync
  static Future<Map<String, dynamic>> testDataIntegrityAfterSync() async {
    try {
      debugPrint('SyncArchitectureTest: Testing data integrity after sync...');

      // Clear existing data
      await _clearAllData();

      // Set up test data
      UserDetails.firstName = 'Test';
      UserDetails.lastName = 'User';
      await UserDetails.saveToHive();

      UserAssess.rehabGoal = 'Pain Relief';
      await UserAssess.saveToHive();

      // Verify data integrity
      final integrityCheck = await DataPersistenceService.validateDataIntegrity();

      return {
        'success': integrityCheck,
        'integrityCheck': integrityCheck,
      };
    } catch (e) {
      debugPrint('SyncArchitectureTest: Error in testDataIntegrityAfterSync: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Run all tests
  static Future<Map<String, dynamic>> runAllTests() async {
    debugPrint('SyncArchitectureTest: Running all sync architecture tests...');

    await initialize();

    final results = <String, dynamic>{};
    int passedTests = 0;
    int totalTests = 6;

    // Test 1: Hive loads before Firebase
    results['test1_hiveLoadsBeforeFirebase'] = await testHiveLoadsBeforeFirebase();
    if (results['test1_hiveLoadsBeforeFirebase']['success']) passedTests++;

    // Test 2: Timestamp conflict resolution
    results['test2_timestampConflictResolution'] = await testTimestampConflictResolution();
    if (results['test2_timestampConflictResolution']['success']) passedTests++;

    // Test 3: Offline writes queue
    results['test3_offlineWritesQueue'] = await testOfflineWritesQueue();
    if (results['test3_offlineWritesQueue']['success']) passedTests++;

    // Test 4: Widget displays data after Hive load
    results['test4_widgetDisplaysDataAfterHiveLoad'] = await testWidgetDisplaysDataAfterHiveLoad();
    if (results['test4_widgetDisplaysDataAfterHiveLoad']['success']) passedTests++;

    // Test 5: Sync queue persistence
    results['test5_syncQueuePersistence'] = await testSyncQueuePersistence();
    if (results['test5_syncQueuePersistence']['success']) passedTests++;

    // Test 6: Data integrity after sync
    results['test6_dataIntegrityAfterSync'] = await testDataIntegrityAfterSync();
    if (results['test6_dataIntegrityAfterSync']['success']) passedTests++;

    results['summary'] = {
      'passedTests': passedTests,
      'totalTests': totalTests,
      'successRate': (passedTests / totalTests * 100).toStringAsFixed(1) + '%',
      'allTestsPassed': passedTests == totalTests,
    };

    debugPrint('SyncArchitectureTest: Test results - $passedTests/$totalTests tests passed');
    debugPrint('SyncArchitectureTest: Success rate - ${results['summary']['successRate']}');

    return results;
  }

  /// Clear all test data
  static Future<void> _clearAllData() async {
    try {
      if (Hive.isBoxOpen('rehabBox')) {
        await Hive.box('rehabBox').clear();
      }
      
      // Clear in-memory data
      UserDetails.clearUserData();
      UserProgress.title = 'Initiator';
      UserProgress.streak = 0;
      UserProgress.totalExercises = 0;
      UserAssess.rehabGoal = '';
      UserAssess.generalMuscle = '';
      UserAssess.specificMuscle = '';
      UserAssess.painScale = 0;
      UserAssess.painLevel = '';
      UserAssess.painType = '';
      UserAssess.painDuration = '';
      UserAssess.isInjured = false;
      UserAssess.isAssessed = false;
      
      AssessmentData.reset();
    } catch (e) {
      debugPrint('SyncArchitectureTest: Error clearing test data: $e');
    }
  }

  /// Dispose test environment
  static Future<void> dispose() async {
    try {
      await Hive.close();
      _isInitialized = false;
      debugPrint('SyncArchitectureTest: Test environment disposed');
    } catch (e) {
      debugPrint('SyncArchitectureTest: Error disposing test environment: $e');
    }
  }
}
