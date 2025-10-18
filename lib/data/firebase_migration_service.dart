import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'unified_data_models.dart';
import 'unified_firebase_service.dart';

/// Service for migrating existing Firebase data to unified schema
class FirebaseMigrationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Check if migration is needed for current user
  static Future<bool> isMigrationNeeded() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Check if user has old format data
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return false;

      final data = userDoc.data() as Map<String, dynamic>;
      
      // Check for old format indicators
      final hasOldFormat = data.containsKey('createdAt') && !data.containsKey('lastUpdated');
      final hasMissingFields = !data.containsKey('isGuest') || !data.containsKey('notifications');
      
      return hasOldFormat || hasMissingFields;
    } catch (e) {
      debugPrint('FirebaseMigrationService: Error checking migration status: $e');
      return false;
    }
  }

  /// Perform complete migration from old Firebase format to unified format
  static Future<bool> performMigration() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('FirebaseMigrationService: No authenticated user');
        return false;
      }

      debugPrint('FirebaseMigrationService: Starting migration for user ${user.uid}');
      
      // Migrate each data type
      await _migrateUserDetails(user.uid);
      await _migrateUserProgress(user.uid);
      await _migrateUserSettings(user.uid);
      await _migratePainHistory(user.uid);
      await _migrateExerciseHistory(user.uid);
      await _migrateRehabilitationPlans(user.uid);

      debugPrint('FirebaseMigrationService: Migration completed successfully');
      return true;
    } catch (e) {
      debugPrint('FirebaseMigrationService: Migration failed: $e');
      return false;
    }
  }

  /// Migrate UserDetails from old format to unified format
  static Future<void> _migrateUserDetails(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return;

      final data = doc.data() as Map<String, dynamic>;
      
      // Create unified UserDetails from old format
      final unifiedUserDetails = UnifiedUserDetails(
        userId: userId,
        firstName: data['firstName'] ?? '',
        lastName: data['lastName'] ?? '',
        email: data['email'] ?? '',
        password: '', // Never store password in Firebase
        profilePicture: data['profilePicture'] ?? '01.jpg',
        hasCompletedAssessment: data['hasCompletedAssessment'] ?? false,
        isGuest: data['isGuest'] ?? false,
        guestSessionId: data['guestSessionId'],
        notifications: List<String>.from(data['notifications'] ?? []),
        lastModified: data['lastUpdated'] != null 
            ? (data['lastUpdated'] as Timestamp).toDate()
            : data['createdAt'] != null 
                ? (data['createdAt'] as Timestamp).toDate()
                : DateTime.now(),
      );

      // Save using unified service
      await UnifiedFirebaseService.saveUserDetails(unifiedUserDetails);
      
      debugPrint('FirebaseMigrationService: Migrated UserDetails');
    } catch (e) {
      debugPrint('FirebaseMigrationService: Error migrating UserDetails: $e');
    }
  }

  /// Migrate UserProgress from old format to unified format
  static Future<void> _migrateUserProgress(String userId) async {
    try {
      final doc = await _firestore.collection('progress').doc(userId).get();
      if (!doc.exists) return;

      final data = doc.data() as Map<String, dynamic>;
      
      // Create unified UserProgress from old format
      final unifiedUserProgress = UnifiedUserProgress(
        userId: userId,
        title: data['title'] ?? 'Initiator',
        titleColor: data['titleColor'] ?? '',
        streak: data['streak'] ?? 0,
        totalDays: data['totalDays'] ?? 0,
        totalExercises: data['totalExercises'] ?? 0,
        totalSeconds: data['totalSeconds'] ?? 0,
        notes: data['notes'],
        lastExerciseDate: data['lastExerciseDate']?.toDate(),
        lastModified: data['lastUpdated'] != null 
            ? (data['lastUpdated'] as Timestamp).toDate()
            : DateTime.now(),
      );

      // Save using unified service
      await UnifiedFirebaseService.saveUserProgress(unifiedUserProgress);
      
      debugPrint('FirebaseMigrationService: Migrated UserProgress');
    } catch (e) {
      debugPrint('FirebaseMigrationService: Error migrating UserProgress: $e');
    }
  }

  /// Migrate UserSettings from old format to unified format
  static Future<void> _migrateUserSettings(String userId) async {
    try {
      final doc = await _firestore.collection('settings').doc(userId).get();
      if (!doc.exists) return;

      final data = doc.data() as Map<String, dynamic>;
      
      // Create unified UserSettings from old format
      final unifiedUserSettings = UnifiedUserSettings(
        userId: userId,
        isDailyReminder: data['isDailyReminder'] ?? true,
        isStreakAlert: data['isStreakAlert'] ?? true,
        isExerciseReminder: data['isExerciseReminder'] ?? true,
        exerciseReminderHour: data['exerciseReminderHour'] ?? 8,
        exerciseReminderMinute: data['exerciseReminderMinute'] ?? 0,
        lastModified: data['lastUpdated'] != null 
            ? (data['lastUpdated'] as Timestamp).toDate()
            : DateTime.now(),
      );

      // Save using unified service
      await UnifiedFirebaseService.saveUserSettings(unifiedUserSettings);
      
      debugPrint('FirebaseMigrationService: Migrated UserSettings');
    } catch (e) {
      debugPrint('FirebaseMigrationService: Error migrating UserSettings: $e');
    }
  }

  /// Migrate PainHistory from old format to unified format
  static Future<void> _migratePainHistory(String userId) async {
    try {
      final doc = await _firestore.collection('painHistory').doc(userId).get();
      if (!doc.exists) return;

      final data = doc.data() as Map<String, dynamic>;
      final entries = data['entries'] as List<dynamic>? ?? [];
      
      final List<UnifiedPainRecordEntry> unifiedEntries = [];
      
      for (final entry in entries) {
        if (entry is Map<String, dynamic>) {
          final unifiedEntry = UnifiedPainRecordEntry(
            userId: userId,
            date: entry['date'] != null 
                ? (entry['date'] as Timestamp).toDate()
                : DateTime.now(),
            painScale: entry['painScale'] ?? 0,
            painLevel: entry['painLevel'] ?? '',
            lastModified: data['lastUpdated'] != null 
                ? (data['lastUpdated'] as Timestamp).toDate()
                : DateTime.now(),
          );
          unifiedEntries.add(unifiedEntry);
        }
      }

      // Save using unified service
      await UnifiedFirebaseService.savePainHistory(unifiedEntries);
      
      debugPrint('FirebaseMigrationService: Migrated PainHistory (${unifiedEntries.length} entries)');
    } catch (e) {
      debugPrint('FirebaseMigrationService: Error migrating PainHistory: $e');
    }
  }

  /// Migrate ExerciseHistory from old format to unified format
  static Future<void> _migrateExerciseHistory(String userId) async {
    try {
      final doc = await _firestore.collection('exerciseHistory').doc(userId).get();
      if (!doc.exists) return;

      final data = doc.data() as Map<String, dynamic>;
      final entries = data['entries'] as List<dynamic>? ?? [];
      
      final List<UnifiedExerciseRecordEntry> unifiedEntries = [];
      
      for (final entry in entries) {
        if (entry is Map<String, dynamic>) {
          final unifiedEntry = UnifiedExerciseRecordEntry(
            userId: userId,
            date: entry['date'] != null 
                ? (entry['date'] as Timestamp).toDate()
                : DateTime.now(),
            exerciseId: entry['exerciseId'] ?? '',
            exerciseName: entry['exerciseName'] ?? '',
            sets: entry['sets'] ?? 0,
            reps: entry['reps'] ?? 0,
            durationSeconds: entry['durationSeconds'] ?? 0,
            status: entry['status'] ?? 'completed',
            lastModified: data['lastUpdated'] != null 
                ? (data['lastUpdated'] as Timestamp).toDate()
                : DateTime.now(),
          );
          unifiedEntries.add(unifiedEntry);
        }
      }

      // Save using unified service
      await UnifiedFirebaseService.saveExerciseHistory(unifiedEntries);
      
      debugPrint('FirebaseMigrationService: Migrated ExerciseHistory (${unifiedEntries.length} entries)');
    } catch (e) {
      debugPrint('FirebaseMigrationService: Error migrating ExerciseHistory: $e');
    }
  }

  /// Migrate RehabilitationPlans from old format to unified format
  static Future<void> _migrateRehabilitationPlans(String userId) async {
    try {
      final doc = await _firestore.collection('rehabilitation').doc(userId).get();
      if (!doc.exists) return;

      final data = doc.data() as Map<String, dynamic>;
      
      // Handle old complex nested structure
      final List<UnifiedRehabilitationPlan> unifiedPlans = [];
      
      // Check for old Plan1, Plan2, etc. structure
      final planKeys = data.keys.where((key) => key.toLowerCase().startsWith('plan')).toList();
      
      if (planKeys.isNotEmpty) {
        // Old format with Plan1, Plan2, etc.
        for (int i = 0; i < planKeys.length; i++) {
          final planKey = planKeys[i];
          final planData = data[planKey] as List<dynamic>?;
          
          if (planData != null && planData.length >= 2) {
            final exercisesData = planData[0] as Map<String, dynamic>? ?? {};
            final treatmentsData = planData[1] as Map<String, dynamic>? ?? {};
            
            // Extract exercise IDs
            final exerciseIds = <String>[];
            for (final entry in exercisesData.entries) {
              if (entry.value is Map<String, dynamic>) {
                final exerciseData = entry.value as Map<String, dynamic>;
                if (exerciseData['exerciseId'] != null) {
                  exerciseIds.add(exerciseData['exerciseId'] as String);
                }
              }
            }
            
            // Extract treatment IDs
            final treatmentIds = <String>[];
            for (final entry in treatmentsData.entries) {
              if (entry.value is Map<String, dynamic>) {
                final treatmentData = entry.value as Map<String, dynamic>;
                if (treatmentData['treatmentId'] != null) {
                  treatmentIds.add(treatmentData['treatmentId'] as String);
                }
              }
            }
            
            final unifiedPlan = UnifiedRehabilitationPlan(
              userId: userId,
              exerciseIds: exerciseIds,
              treatmentIds: treatmentIds,
              weekNumber: i + 1,
              lastModified: data['lastUpdated'] != null 
                  ? (data['lastUpdated'] as Timestamp).toDate()
                  : DateTime.now(),
            );
            unifiedPlans.add(unifiedPlan);
          }
        }
      } else {
        // Check for new format
        final plans = data['plans'] as List<dynamic>? ?? [];
        for (final plan in plans) {
          if (plan is Map<String, dynamic>) {
            final unifiedPlan = UnifiedRehabilitationPlan.fromFirebaseMap(plan);
            unifiedPlans.add(unifiedPlan);
          }
        }
      }

      // Save using unified service
      await UnifiedFirebaseService.saveRehabilitationPlans(unifiedPlans);
      
      debugPrint('FirebaseMigrationService: Migrated RehabilitationPlans (${unifiedPlans.length} plans)');
    } catch (e) {
      debugPrint('FirebaseMigrationService: Error migrating RehabilitationPlans: $e');
    }
  }

  /// Validate migrated data
  static Future<bool> validateMigration() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Check if all required documents exist and have correct structure
      final userDetails = await UnifiedFirebaseService.loadUserDetails();
      final userProgress = await UnifiedFirebaseService.loadUserProgress();
      final userSettings = await UnifiedFirebaseService.loadUserSettings();

      if (userDetails == null || userProgress == null || userSettings == null) {
        debugPrint('FirebaseMigrationService: Validation failed - missing required data');
        return false;
      }

      // Validate data integrity
      if (!userDetails.validate() || !userProgress.validate() || !userSettings.validate()) {
        debugPrint('FirebaseMigrationService: Validation failed - invalid data');
        return false;
      }

      debugPrint('FirebaseMigrationService: Validation passed');
      return true;
    } catch (e) {
      debugPrint('FirebaseMigrationService: Validation error: $e');
      return false;
    }
  }

  /// Create backup of existing data before migration
  static Future<bool> createBackup() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final backupData = <String, dynamic>{};
      
      // Backup all collections
      final collections = ['users', 'progress', 'settings', 'painHistory', 'exerciseHistory', 'rehabilitation'];
      
      for (final collection in collections) {
        final doc = await _firestore.collection(collection).doc(user.uid).get();
        if (doc.exists) {
          backupData[collection] = doc.data();
        }
      }

      // Save backup to a backup collection
      await _firestore.collection('_backups').doc('${user.uid}_${DateTime.now().millisecondsSinceEpoch}').set({
        'userId': user.uid,
        'backupData': backupData,
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('FirebaseMigrationService: Backup created successfully');
      return true;
    } catch (e) {
      debugPrint('FirebaseMigrationService: Error creating backup: $e');
      return false;
    }
  }

  /// Restore from backup
  static Future<bool> restoreFromBackup(String backupId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final backupDoc = await _firestore.collection('_backups').doc(backupId).get();
      if (!backupDoc.exists) return false;

      final backupData = backupDoc.data() as Map<String, dynamic>;
      final data = backupData['backupData'] as Map<String, dynamic>;

      // Restore all collections
      for (final entry in data.entries) {
        final collection = entry.key;
        final docData = entry.value as Map<String, dynamic>;
        
        await _firestore.collection(collection).doc(user.uid).set(docData);
      }

      debugPrint('FirebaseMigrationService: Restored from backup successfully');
      return true;
    } catch (e) {
      debugPrint('FirebaseMigrationService: Error restoring from backup: $e');
      return false;
    }
  }
}
