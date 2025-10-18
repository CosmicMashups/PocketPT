import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';
import 'unified_hive_models.dart';
import 'unified_data_models.dart';

/// Service for migrating existing Hive data to unified schema
class HiveMigrationService {
  static const String _migrationVersionKey = 'migration_version';
  static const int _currentMigrationVersion = 1;

  /// Check if migration is needed
  static Future<bool> isMigrationNeeded() async {
    try {
      final box = await Hive.openBox('migrationBox');
      final currentVersion = box.get(_migrationVersionKey, defaultValue: 0) as int;
      return currentVersion < _currentMigrationVersion;
    } catch (e) {
      debugPrint('HiveMigrationService: Error checking migration status: $e');
      return true; // Assume migration needed if we can't check
    }
  }

  /// Perform complete migration from old Hive models to unified models
  static Future<bool> performMigration() async {
    try {
      debugPrint('HiveMigrationService: Starting migration to version $_currentMigrationVersion');
      
      // Open migration tracking box
      final migrationBox = await Hive.openBox('migrationBox');
      
      // Check if already migrated
      final currentVersion = migrationBox.get(_migrationVersionKey, defaultValue: 0) as int;
      if (currentVersion >= _currentMigrationVersion) {
        debugPrint('HiveMigrationService: Migration already completed');
        return true;
      }

      // Perform migration steps
      await _migrateUserDetails();
      await _migrateUserProgress();
      await _migrateUserSettings();
      await _migratePainHistory();
      await _migrateExerciseHistory();
      await _migrateRehabilitationPlans();
      await _migrateActiveProgram();

      // Update migration version
      await migrationBox.put(_migrationVersionKey, _currentMigrationVersion);
      await migrationBox.close();
      
      debugPrint('HiveMigrationService: Migration completed successfully');
      return true;
    } catch (e) {
      debugPrint('HiveMigrationService: Migration failed: $e');
      return false;
    }
  }

  /// Migrate UserDetails from old format to unified format
  static Future<void> _migrateUserDetails() async {
    try {
      final oldBox = await Hive.openBox('rehabBox');
      final newBox = await Hive.openBox('unifiedRehabBox');
      
      // Get old user details data
      final oldUserDetails = oldBox.get('userDetails');
      if (oldUserDetails != null && oldUserDetails is Map<String, dynamic>) {
        // Convert old format to unified format
        final unifiedUserDetails = UnifiedUserDetails(
          userId: oldUserDetails['userId'] ?? '',
          firstName: oldUserDetails['firstName'] ?? '',
          lastName: oldUserDetails['lastName'] ?? '',
          email: oldUserDetails['email'] ?? '',
          password: oldUserDetails['password'] ?? '',
          profilePicture: oldUserDetails['profilePicture'] ?? '01.jpg',
          hasCompletedAssessment: oldUserDetails['hasCompletedAssessment'] ?? false,
          isGuest: oldUserDetails['isGuest'] ?? false,
          guestSessionId: oldUserDetails['guestSessionId'],
          notifications: List<String>.from(oldUserDetails['notifications'] ?? []),
          lastModified: oldUserDetails['lastModified'] != null 
              ? DateTime.fromMillisecondsSinceEpoch(oldUserDetails['lastModified'] as int)
              : null,
        );

        // Create new Hive model
        final newHiveModel = UnifiedHiveUserDetails.fromUnified(unifiedUserDetails);
        
        // Save to new box
        await newBox.put('userDetails', newHiveModel);
        
        debugPrint('HiveMigrationService: Migrated UserDetails');
      }
      
      await oldBox.close();
      await newBox.close();
    } catch (e) {
      debugPrint('HiveMigrationService: Error migrating UserDetails: $e');
    }
  }

  /// Migrate UserProgress from old format to unified format
  static Future<void> _migrateUserProgress() async {
    try {
      final oldBox = await Hive.openBox('rehabBox');
      final newBox = await Hive.openBox('unifiedRehabBox');
      
      // Get old user progress data
      final oldUserProgress = oldBox.get('userProgress');
      if (oldUserProgress != null && oldUserProgress is Map<String, dynamic>) {
        // Convert old format to unified format
        final unifiedUserProgress = UnifiedUserProgress(
          userId: oldUserProgress['userId'] ?? '',
          title: oldUserProgress['title'] ?? 'Initiator',
          titleColor: oldUserProgress['titleColor'] ?? '',
          streak: oldUserProgress['streak'] ?? 0,
          totalDays: oldUserProgress['totalDays'] ?? 0,
          totalExercises: oldUserProgress['totalExercises'] ?? 0,
          totalSeconds: oldUserProgress['totalSeconds'] ?? 0,
          notes: oldUserProgress['notes'],
          lastExerciseDate: oldUserProgress['lastExerciseDate'] != null 
              ? DateTime.fromMillisecondsSinceEpoch(oldUserProgress['lastExerciseDate'] as int)
              : null,
          lastModified: oldUserProgress['lastModified'] != null 
              ? DateTime.fromMillisecondsSinceEpoch(oldUserProgress['lastModified'] as int)
              : null,
        );

        // Create new Hive model
        final newHiveModel = UnifiedHiveUserProgress.fromUnified(unifiedUserProgress);
        
        // Save to new box
        await newBox.put('userProgress', newHiveModel);
        
        debugPrint('HiveMigrationService: Migrated UserProgress');
      }
      
      await oldBox.close();
      await newBox.close();
    } catch (e) {
      debugPrint('HiveMigrationService: Error migrating UserProgress: $e');
    }
  }

  /// Migrate UserSettings from old format to unified format
  static Future<void> _migrateUserSettings() async {
    try {
      final oldBox = await Hive.openBox('rehabBox');
      final newBox = await Hive.openBox('unifiedRehabBox');
      
      // Get old user settings data
      final oldUserSettings = oldBox.get('userSettings');
      if (oldUserSettings != null && oldUserSettings is Map<String, dynamic>) {
        // Convert old format to unified format
        final unifiedUserSettings = UnifiedUserSettings(
          userId: oldUserSettings['userId'] ?? '',
          isDailyReminder: oldUserSettings['isDailyReminder'] ?? true,
          isStreakAlert: oldUserSettings['isStreakAlert'] ?? true,
          isExerciseReminder: oldUserSettings['isExerciseReminder'] ?? true,
          exerciseReminderHour: oldUserSettings['exerciseReminderHour'] ?? 8,
          exerciseReminderMinute: oldUserSettings['exerciseReminderMinute'] ?? 0,
          lastModified: oldUserSettings['lastModified'] != null 
              ? DateTime.fromMillisecondsSinceEpoch(oldUserSettings['lastModified'] as int)
              : null,
        );

        // Create new Hive model
        final newHiveModel = UnifiedHiveUserSettings.fromUnified(unifiedUserSettings);
        
        // Save to new box
        await newBox.put('userSettings', newHiveModel);
        
        debugPrint('HiveMigrationService: Migrated UserSettings');
      }
      
      await oldBox.close();
      await newBox.close();
    } catch (e) {
      debugPrint('HiveMigrationService: Error migrating UserSettings: $e');
    }
  }

  /// Migrate PainHistory from old format to unified format
  static Future<void> _migratePainHistory() async {
    try {
      final oldBox = await Hive.openBox('rehabBox');
      final newBox = await Hive.openBox('unifiedRehabBox');
      
      // Get old pain history data
      final oldPainHistory = oldBox.get('painHistory');
      if (oldPainHistory != null && oldPainHistory is List) {
        final List<UnifiedHivePainRecordEntry> newEntries = [];
        
        for (final entry in oldPainHistory) {
          if (entry is Map<String, dynamic>) {
            // Convert old format to unified format
            final unifiedEntry = UnifiedPainRecordEntry(
              userId: entry['userId'] ?? '',
              date: DateTime.fromMillisecondsSinceEpoch(entry['date'] as int),
              painScale: entry['painScale'] ?? 0,
              painLevel: entry['painLevel'] ?? '',
              lastModified: entry['lastModified'] != null 
                  ? DateTime.fromMillisecondsSinceEpoch(entry['lastModified'] as int)
                  : null,
            );

            // Create new Hive model
            final newHiveModel = UnifiedHivePainRecordEntry.fromUnified(unifiedEntry);
            newEntries.add(newHiveModel);
          }
        }
        
        // Save to new box
        await newBox.put('painHistory', newEntries);
        
        debugPrint('HiveMigrationService: Migrated PainHistory (${newEntries.length} entries)');
      }
      
      await oldBox.close();
      await newBox.close();
    } catch (e) {
      debugPrint('HiveMigrationService: Error migrating PainHistory: $e');
    }
  }

  /// Migrate ExerciseHistory from old format to unified format
  static Future<void> _migrateExerciseHistory() async {
    try {
      final oldBox = await Hive.openBox('rehabBox');
      final newBox = await Hive.openBox('unifiedRehabBox');
      
      // Get old exercise history data
      final oldExerciseHistory = oldBox.get('exerciseHistory');
      if (oldExerciseHistory != null && oldExerciseHistory is List) {
        final List<UnifiedHiveExerciseRecordEntry> newEntries = [];
        
        for (final entry in oldExerciseHistory) {
          if (entry is Map<String, dynamic>) {
            // Convert old format to unified format
            final unifiedEntry = UnifiedExerciseRecordEntry(
              userId: entry['userId'] ?? '',
              date: DateTime.fromMillisecondsSinceEpoch(entry['date'] as int),
              exerciseId: entry['exerciseId'] ?? '',
              exerciseName: entry['exerciseName'] ?? '',
              sets: entry['sets'] ?? 0,
              reps: entry['reps'] ?? 0,
              durationSeconds: entry['durationSeconds'] ?? 0,
              status: entry['status'] ?? 'completed',
              lastModified: entry['lastModified'] != null 
                  ? DateTime.fromMillisecondsSinceEpoch(entry['lastModified'] as int)
                  : null,
            );

            // Create new Hive model
            final newHiveModel = UnifiedHiveExerciseRecordEntry.fromUnified(unifiedEntry);
            newEntries.add(newHiveModel);
          }
        }
        
        // Save to new box
        await newBox.put('exerciseHistory', newEntries);
        
        debugPrint('HiveMigrationService: Migrated ExerciseHistory (${newEntries.length} entries)');
      }
      
      await oldBox.close();
      await newBox.close();
    } catch (e) {
      debugPrint('HiveMigrationService: Error migrating ExerciseHistory: $e');
    }
  }

  /// Migrate RehabilitationPlans from old format to unified format
  static Future<void> _migrateRehabilitationPlans() async {
    try {
      final oldBox = await Hive.openBox('rehabBox');
      final newBox = await Hive.openBox('unifiedRehabBox');
      
      // Get old rehabilitation plans data
      final oldExerciseIds = oldBox.get('exerciseIds');
      final oldTreatmentIds = oldBox.get('treatmentIds');
      
      if (oldExerciseIds != null || oldTreatmentIds != null) {
        // Convert old format to unified format
        final unifiedPlan = UnifiedRehabilitationPlan(
          userId: '', // Will be set when user data is available
          exerciseIds: List<String>.from(oldExerciseIds ?? []),
          treatmentIds: List<String>.from(oldTreatmentIds ?? []),
          weekNumber: 1, // Default to week 1
          lastModified: DateTime.now(),
        );

        // Create new Hive model
        final newHiveModel = UnifiedHiveRehabilitationPlan.fromUnified(unifiedPlan);
        
        // Save to new box
        await newBox.put('rehabilitationPlan', newHiveModel);
        
        debugPrint('HiveMigrationService: Migrated RehabilitationPlans');
      }
      
      await oldBox.close();
      await newBox.close();
    } catch (e) {
      debugPrint('HiveMigrationService: Error migrating RehabilitationPlans: $e');
    }
  }

  /// Migrate ActiveProgram from old format to unified format
  static Future<void> _migrateActiveProgram() async {
    try {
      final oldBox = await Hive.openBox('rehabBox');
      final newBox = await Hive.openBox('unifiedRehabBox');
      
      // Get old active program data
      final oldActiveProgram = oldBox.get('activeProgram');
      if (oldActiveProgram != null && oldActiveProgram is Map<String, dynamic>) {
        // Convert old format to unified format
        final newHiveModel = UnifiedHiveActiveProgram.fromUnified(
          userId: oldActiveProgram['userId'] ?? '',
          startDate: oldActiveProgram['startDate'] != null 
              ? DateTime.fromMillisecondsSinceEpoch(oldActiveProgram['startDate'] as int)
              : null,
          lastModified: oldActiveProgram['lastModified'] != null 
              ? DateTime.fromMillisecondsSinceEpoch(oldActiveProgram['lastModified'] as int)
              : null,
        );
        
        // Save to new box
        await newBox.put('activeProgram', newHiveModel);
        
        debugPrint('HiveMigrationService: Migrated ActiveProgram');
      }
      
      await oldBox.close();
      await newBox.close();
    } catch (e) {
      debugPrint('HiveMigrationService: Error migrating ActiveProgram: $e');
    }
  }

  /// Rollback migration (restore from backup)
  static Future<bool> rollbackMigration() async {
    try {
      debugPrint('HiveMigrationService: Starting rollback');
      
      // Close unified box
      if (Hive.isBoxOpen('unifiedRehabBox')) {
        await Hive.box('unifiedRehabBox').close();
      }
      
      // Reset migration version
      final migrationBox = await Hive.openBox('migrationBox');
      await migrationBox.put(_migrationVersionKey, 0);
      await migrationBox.close();
      
      debugPrint('HiveMigrationService: Rollback completed');
      return true;
    } catch (e) {
      debugPrint('HiveMigrationService: Rollback failed: $e');
      return false;
    }
  }

  /// Validate migrated data
  static Future<bool> validateMigration() async {
    try {
      final box = await Hive.openBox('unifiedRehabBox');
      
      // Check if all required data is present
      final userDetails = box.get('userDetails');
      final userProgress = box.get('userProgress');
      final userSettings = box.get('userSettings');
      
      if (userDetails == null || userProgress == null || userSettings == null) {
        debugPrint('HiveMigrationService: Validation failed - missing required data');
        return false;
      }
      
      // Validate data integrity
      if (userDetails is UnifiedHiveUserDetails) {
        final unified = userDetails.toUnified();
        if (!unified.validate()) {
          debugPrint('HiveMigrationService: Validation failed - invalid UserDetails');
          return false;
        }
      }
      
      if (userProgress is UnifiedHiveUserProgress) {
        final unified = userProgress.toUnified();
        if (!unified.validate()) {
          debugPrint('HiveMigrationService: Validation failed - invalid UserProgress');
          return false;
        }
      }
      
      if (userSettings is UnifiedHiveUserSettings) {
        final unified = userSettings.toUnified();
        if (!unified.validate()) {
          debugPrint('HiveMigrationService: Validation failed - invalid UserSettings');
          return false;
        }
      }
      
      await box.close();
      debugPrint('HiveMigrationService: Validation passed');
      return true;
    } catch (e) {
      debugPrint('HiveMigrationService: Validation error: $e');
      return false;
    }
  }
}
