import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';
import 'unified_data_models.dart';
import 'hive_migration_service.dart';
import 'firebase_migration_service.dart';
import 'unified_sync_service.dart';

/// Service for testing migration functionality with existing user data
class MigrationTestService {
  
  /// Test Hive migration with sample data
  static Future<bool> testHiveMigration() async {
    try {
      debugPrint('MigrationTestService: Starting Hive migration test');
      
      // Create sample old format data
      await _createSampleOldHiveData();
      
      // Perform migration
      final migrationResult = await HiveMigrationService.performMigration();
      if (!migrationResult) {
        debugPrint('MigrationTestService: Hive migration failed');
        return false;
      }
      
      // Validate migration
      final validationResult = await HiveMigrationService.validateMigration();
      if (!validationResult) {
        debugPrint('MigrationTestService: Hive migration validation failed');
        return false;
      }
      
      // Test data access
      final testResult = await _testMigratedHiveData();
      if (!testResult) {
        debugPrint('MigrationTestService: Migrated Hive data test failed');
        return false;
      }
      
      debugPrint('MigrationTestService: Hive migration test passed');
      return true;
    } catch (e) {
      debugPrint('MigrationTestService: Hive migration test failed: $e');
      return false;
    }
  }

  /// Test Firebase migration with sample data
  static Future<bool> testFirebaseMigration() async {
    try {
      debugPrint('MigrationTestService: Starting Firebase migration test');
      
      // Check if migration is needed
      final migrationNeeded = await FirebaseMigrationService.isMigrationNeeded();
      if (!migrationNeeded) {
        debugPrint('MigrationTestService: Firebase migration not needed');
        return true;
      }
      
      // Create backup before migration
      final backupResult = await FirebaseMigrationService.createBackup();
      if (!backupResult) {
        debugPrint('MigrationTestService: Failed to create backup');
        return false;
      }
      
      // Perform migration
      final migrationResult = await FirebaseMigrationService.performMigration();
      if (!migrationResult) {
        debugPrint('MigrationTestService: Firebase migration failed');
        return false;
      }
      
      // Validate migration
      final validationResult = await FirebaseMigrationService.validateMigration();
      if (!validationResult) {
        debugPrint('MigrationTestService: Firebase migration validation failed');
        return false;
      }
      
      debugPrint('MigrationTestService: Firebase migration test passed');
      return true;
    } catch (e) {
      debugPrint('MigrationTestService: Firebase migration test failed: $e');
      return false;
    }
  }

  /// Test unified sync service
  static Future<bool> testUnifiedSyncService() async {
    try {
      debugPrint('MigrationTestService: Starting unified sync service test');
      
      // Initialize sync service
      await UnifiedSyncService.initialize();
      
      // Test saving and loading data
      final testUserDetails = UnifiedUserDetails(
        userId: 'test_user',
        firstName: 'Test',
        lastName: 'User',
        email: 'test@example.com',
        password: 'test_password',
        profilePicture: '01.jpg',
        hasCompletedAssessment: false,
        isGuest: false,
        guestSessionId: null,
        notifications: ['test_notification'],
        lastModified: DateTime.now(),
      );
      
      // Test save
      final saveResult = await UnifiedSyncService.saveUserDetails(testUserDetails);
      if (!saveResult) {
        debugPrint('MigrationTestService: Failed to save user details');
        return false;
      }
      
      // Test load
      final loadedUserDetails = await UnifiedSyncService.loadUserDetails();
      if (loadedUserDetails == null) {
        debugPrint('MigrationTestService: Failed to load user details');
        return false;
      }
      
      // Verify data integrity
      if (loadedUserDetails.firstName != testUserDetails.firstName ||
          loadedUserDetails.lastName != testUserDetails.lastName ||
          loadedUserDetails.email != testUserDetails.email) {
        debugPrint('MigrationTestService: Data integrity check failed');
        return false;
      }
      
      debugPrint('MigrationTestService: Unified sync service test passed');
      return true;
    } catch (e) {
      debugPrint('MigrationTestService: Unified sync service test failed: $e');
      return false;
    }
  }

  /// Test data validation and repair
  static Future<bool> testDataValidationAndRepair() async {
    try {
      debugPrint('MigrationTestService: Starting data validation and repair test');
      
      // Test with valid data
      final validUserDetails = UnifiedUserDetails(
        userId: 'valid_user',
        firstName: 'Valid',
        lastName: 'User',
        email: 'valid@example.com',
        password: 'valid_password',
        profilePicture: '01.jpg',
        hasCompletedAssessment: true,
        isGuest: false,
        guestSessionId: null,
        notifications: [],
        lastModified: DateTime.now(),
      );
      
      if (!validUserDetails.validate()) {
        debugPrint('MigrationTestService: Valid data failed validation');
        return false;
      }
      
      // Test with invalid data
      final invalidUserDetails = UnifiedUserDetails(
        userId: '', // Invalid: empty userId
        firstName: '', // Invalid: empty firstName
        lastName: '', // Invalid: empty lastName
        email: '', // Invalid: empty email
        password: 'test_password',
        profilePicture: '01.jpg',
        hasCompletedAssessment: false,
        isGuest: false,
        guestSessionId: null,
        notifications: [],
        lastModified: DateTime.now(),
      );
      
      if (invalidUserDetails.validate()) {
        debugPrint('MigrationTestService: Invalid data passed validation');
        return false;
      }
      
      debugPrint('MigrationTestService: Data validation and repair test passed');
      return true;
    } catch (e) {
      debugPrint('MigrationTestService: Data validation and repair test failed: $e');
      return false;
    }
  }

  /// Test conflict resolution
  static Future<bool> testConflictResolution() async {
    try {
      debugPrint('MigrationTestService: Starting conflict resolution test');
      
      // Create two versions of the same data with different timestamps
      final olderUserDetails = UnifiedUserDetails(
        userId: 'conflict_user',
        firstName: 'Older',
        lastName: 'User',
        email: 'older@example.com',
        password: 'older_password',
        profilePicture: '01.jpg',
        hasCompletedAssessment: false,
        isGuest: false,
        guestSessionId: null,
        notifications: [],
        lastModified: DateTime.now().subtract(const Duration(hours: 1)),
      );
      
      final newerUserDetails = UnifiedUserDetails(
        userId: 'conflict_user',
        firstName: 'Newer',
        lastName: 'User',
        email: 'newer@example.com',
        password: 'newer_password',
        profilePicture: '02.jpg',
        hasCompletedAssessment: true,
        isGuest: false,
        guestSessionId: null,
        notifications: ['new_notification'],
        lastModified: DateTime.now(),
      );
      
      // Test conflict resolution (newer should win)
      final resolvedUserDetails = _resolveUserDetailsConflict(olderUserDetails, newerUserDetails);
      if (resolvedUserDetails == null) {
        debugPrint('MigrationTestService: Conflict resolution returned null');
        return false;
      }
      
      if (resolvedUserDetails.firstName != newerUserDetails.firstName ||
          resolvedUserDetails.lastName != newerUserDetails.lastName ||
          resolvedUserDetails.email != newerUserDetails.email) {
        debugPrint('MigrationTestService: Conflict resolution failed - older data won');
        return false;
      }
      
      debugPrint('MigrationTestService: Conflict resolution test passed');
      return true;
    } catch (e) {
      debugPrint('MigrationTestService: Conflict resolution test failed: $e');
      return false;
    }
  }

  /// Run all migration tests
  static Future<bool> runAllTests() async {
    try {
      debugPrint('MigrationTestService: Starting comprehensive migration tests');
      
      final results = <bool>[];
      
      // Test Hive migration
      results.add(await testHiveMigration());
      
      // Test Firebase migration
      results.add(await testFirebaseMigration());
      
      // Test unified sync service
      results.add(await testUnifiedSyncService());
      
      // Test data validation and repair
      results.add(await testDataValidationAndRepair());
      
      // Test conflict resolution
      results.add(await testConflictResolution());
      
      final allPassed = results.every((result) => result);
      
      if (allPassed) {
        debugPrint('MigrationTestService: All tests passed');
      } else {
        debugPrint('MigrationTestService: Some tests failed');
      }
      
      return allPassed;
    } catch (e) {
      debugPrint('MigrationTestService: Test suite failed: $e');
      return false;
    }
  }

  /// Private helper methods

  static Future<void> _createSampleOldHiveData() async {
    try {
      final box = await Hive.openBox('rehabBox');
      
      // Create sample old format user details
      final oldUserDetails = {
        'firstName': 'Old',
        'lastName': 'User',
        'email': 'old@example.com',
        'password': 'old_password',
        'profilePicture': '01.jpg',
        'hasCompletedAssessment': false,
        'isGuest': false,
        'guestSessionId': null,
        'notifications': ['old_notification'],
        'lastModified': DateTime.now().millisecondsSinceEpoch,
      };
      
      await box.put('userDetails', oldUserDetails);
      
      // Create sample old format user progress
      final oldUserProgress = {
        'title': 'Old Title',
        'titleColor': 'blue',
        'streak': 5,
        'totalDays': 10,
        'totalExercises': 25,
        'totalSeconds': 1800,
        'notes': 'Old notes',
        'lastExerciseDate': DateTime.now().millisecondsSinceEpoch,
        'lastModified': DateTime.now().millisecondsSinceEpoch,
      };
      
      await box.put('userProgress', oldUserProgress);
      
      // Create sample old format user settings
      final oldUserSettings = {
        'isDailyReminder': true,
        'isStreakAlert': false,
        'isExerciseReminder': true,
        'exerciseReminderHour': 9,
        'exerciseReminderMinute': 30,
        'lastModified': DateTime.now().millisecondsSinceEpoch,
      };
      
      await box.put('userSettings', oldUserSettings);
      
      await box.close();
      
      debugPrint('MigrationTestService: Created sample old Hive data');
    } catch (e) {
      debugPrint('MigrationTestService: Error creating sample old Hive data: $e');
    }
  }

  static Future<bool> _testMigratedHiveData() async {
    try {
      final box = await Hive.openBox('unifiedRehabBox');
      
      // Test that migrated data exists
      final userDetails = box.get('userDetails');
      final userProgress = box.get('userProgress');
      final userSettings = box.get('userSettings');
      
      if (userDetails == null || userProgress == null || userSettings == null) {
        debugPrint('MigrationTestService: Migrated data is missing');
        return false;
      }
      
      // Test that data can be converted to unified models
      if (userDetails is Map<String, dynamic>) {
        final unifiedUserDetails = UnifiedUserDetails.fromHiveMap(userDetails);
        if (!unifiedUserDetails.validate()) {
          debugPrint('MigrationTestService: Migrated user details validation failed');
          return false;
        }
      }
      
      if (userProgress is Map<String, dynamic>) {
        final unifiedUserProgress = UnifiedUserProgress.fromHiveMap(userProgress);
        if (!unifiedUserProgress.validate()) {
          debugPrint('MigrationTestService: Migrated user progress validation failed');
          return false;
        }
      }
      
      if (userSettings is Map<String, dynamic>) {
        final unifiedUserSettings = UnifiedUserSettings.fromHiveMap(userSettings);
        if (!unifiedUserSettings.validate()) {
          debugPrint('MigrationTestService: Migrated user settings validation failed');
          return false;
        }
      }
      
      await box.close();
      
      debugPrint('MigrationTestService: Migrated Hive data test passed');
      return true;
    } catch (e) {
      debugPrint('MigrationTestService: Error testing migrated Hive data: $e');
      return false;
    }
  }

  static UnifiedUserDetails? _resolveUserDetailsConflict(
    UnifiedUserDetails? hive,
    UnifiedUserDetails? firebase,
  ) {
    if (hive == null && firebase == null) return null;
    if (hive == null) return firebase;
    if (firebase == null) return hive;

    // Use lastModified to determine winner
    final hiveTime = hive.lastModified;
    final firebaseTime = firebase.lastModified;

    if (hiveTime == null && firebaseTime == null) return firebase;
    if (hiveTime == null) return firebase;
    if (firebaseTime == null) return hive;

    return hiveTime.isAfter(firebaseTime) ? hive : firebase;
  }
}
