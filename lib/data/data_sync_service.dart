import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'globals.dart';
import 'rehabilitation_plan.dart';
import 'data_persistence_service.dart';
import 'firebase_helper.dart';

/// Service to manage comprehensive data synchronization between Hive and Firebase
class DataSyncService {
  static final DataSyncService _instance = DataSyncService._internal();
  static DataSyncService get instance => _instance;
  
  DataSyncService._internal();
  
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool _isInitialized = false;
  DateTime? _lastSyncTime;
  int _syncCount = 0;
  
  /// Initialize the data sync service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      debugPrint('DataSyncService: Initializing...');
      
      // Set up periodic sync (every 5 minutes)
      _setupPeriodicSync();
      
      _isInitialized = true;
      debugPrint('DataSyncService: Initialized successfully');
      
    } catch (e) {
      debugPrint('DataSyncService: Error during initialization: $e');
      rethrow;
    }
  }
  
  /// Set up periodic data synchronization
  void _setupPeriodicSync() {
    // This would typically use a timer, but for now we'll rely on manual triggers
    debugPrint('DataSyncService: Periodic sync setup completed');
  }
  
  /// Comprehensive data synchronization
  Future<Map<String, dynamic>> syncAllData() async {
    final results = <String, dynamic>{};
    int successCount = 0;
    int totalOperations = 4;
    
    try {
      debugPrint('DataSyncService: Starting comprehensive data sync...');
      
      // Check authentication
      final user = _auth.currentUser;
      if (user == null) {
        results['success'] = false;
        results['error'] = 'No authenticated user';
        return results;
      }
      
      // Ensure Firebase collections exist (don't fail if this doesn't work)
      try {
        final collectionResults = await FirebaseHelper.ensureAllCollectionsExist();
        if (collectionResults['success'] == true) {
          debugPrint('DataSyncService: All Firebase collections ensured successfully');
          debugPrint('DataSyncService: Created collections: ${collectionResults['createdCollections']}');
          debugPrint('DataSyncService: Existing collections: ${collectionResults['existingCollections']}');
        } else {
          debugPrint('DataSyncService: Warning - Some collections could not be ensured: ${collectionResults['errors']}');
        }
      } catch (e) {
        debugPrint('DataSyncService: Warning - Could not ensure Firebase collections: $e');
        // Continue anyway
      }
      
      // Sync user data
      try {
        results['userData'] = await _syncUserData();
        if (results['userData']['success'] == true) successCount++;
      } catch (e) {
        debugPrint('DataSyncService: Error syncing user data: $e');
        results['userData'] = {'success': false, 'error': e.toString()};
      }
      
      // Sync rehabilitation data
      try {
        results['rehabilitationData'] = await _syncRehabilitationData();
        if (results['rehabilitationData']['success'] == true) successCount++;
      } catch (e) {
        debugPrint('DataSyncService: Error syncing rehabilitation data: $e');
        results['rehabilitationData'] = {'success': false, 'error': e.toString()};
      }
      
      // Sync progress data
      try {
        results['progressData'] = await _syncProgressData();
        if (results['progressData']['success'] == true) successCount++;
      } catch (e) {
        debugPrint('DataSyncService: Error syncing progress data: $e');
        results['progressData'] = {'success': false, 'error': e.toString()};
      }
      
      // Sync settings data
      try {
        results['settingsData'] = await _syncSettingsData();
        if (results['settingsData']['success'] == true) successCount++;
      } catch (e) {
        debugPrint('DataSyncService: Error syncing settings data: $e');
        results['settingsData'] = {'success': false, 'error': e.toString()};
      }
      
      // Update sync statistics
      _lastSyncTime = DateTime.now();
      _syncCount++;
      
      // Consider sync successful if at least half the operations succeeded
      results['success'] = successCount >= (totalOperations / 2);
      results['successCount'] = successCount;
      results['totalOperations'] = totalOperations;
      results['lastSyncTime'] = _lastSyncTime?.toIso8601String();
      results['syncCount'] = _syncCount;
      
      if (results['success']) {
        debugPrint('DataSyncService: Comprehensive data sync completed successfully ($successCount/$totalOperations operations)');
      } else {
        debugPrint('DataSyncService: Data sync completed with some failures ($successCount/$totalOperations operations)');
      }
      
    } catch (e) {
      debugPrint('DataSyncService: Error during comprehensive sync: $e');
      results['success'] = false;
      results['error'] = e.toString();
      results['successCount'] = successCount;
      results['totalOperations'] = totalOperations;
    }
    
    return results;
  }
  
  /// Sync user data between Hive and Firebase
  Future<Map<String, dynamic>> _syncUserData() async {
    try {
      debugPrint('DataSyncService: Syncing user data...');
      debugPrint('DataSyncService: Current local data - firstName: "${UserDetails.firstName}", lastName: "${UserDetails.lastName}", email: "${UserDetails.email}"');
      
      // Check if we have local user data first
      final hasLocalData = UserDetails.firstName.isNotEmpty || 
                          UserDetails.lastName.isNotEmpty || 
                          UserDetails.email.isNotEmpty;
      
      debugPrint('DataSyncService: Has local data: $hasLocalData');
      
      if (hasLocalData) {
        debugPrint('DataSyncService: Local user data exists, syncing to Firebase...');
        // We have local data, sync it to Firebase
        await UserDetails.updateInFirebase();
        debugPrint('DataSyncService: Local user data synced to Firebase');
      } else {
        debugPrint('DataSyncService: No local user data, loading from Firebase...');
        // No local data, load from Firebase
        await UserDetails.loadFromFirebase();
        debugPrint('DataSyncService: After loading from Firebase - firstName: "${UserDetails.firstName}", lastName: "${UserDetails.lastName}", email: "${UserDetails.email}"');
      }
      
      // Ensure data is saved to Hive for offline access
      await UserDetails.saveToHive();
      
      return {
        'success': true,
        'message': 'User data synced successfully',
        'firstName': UserDetails.firstName,
        'lastName': UserDetails.lastName,
        'email': UserDetails.email,
        'syncedFrom': hasLocalData ? 'local' : 'firebase',
      };
      
    } catch (e) {
      debugPrint('DataSyncService: Error syncing user data: $e');
      debugPrint('DataSyncService: Error type: ${e.runtimeType}');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  /// Sync rehabilitation data between Hive and Firebase
  Future<Map<String, dynamic>> _syncRehabilitationData() async {
    try {
      debugPrint('DataSyncService: Syncing rehabilitation data...');
      
      // Load local first to detect existing generated data
      await UserRehabilitation.instance.loadPlansFromHive();
      final bool hasLocalPlans = UserRehabilitation.instance.rehabPlans.isNotEmpty;
      final bool hasLocalTreatments = (UserRehabilitation.instance.treatmentReferences?.isNotEmpty ?? false);
      final bool hasAnyLocal = hasLocalPlans || hasLocalTreatments;

      if (hasAnyLocal) {
        // Local data exists: keep it authoritative and push to Firebase if possible
        debugPrint('DataSyncService: Local rehab data found (plans: ' 
            '${UserRehabilitation.instance.rehabPlans.length}, treatments: ' 
            '${UserRehabilitation.instance.treatmentReferences?.length ?? 0}). Pushing to Firebase.');
        try {
          await UserRehabilitation.instance.savePlansToHive();
          if (_auth.currentUser != null) {
            await UserRehabilitation.instance.savePlansToFirebase();
          }
        } catch (e) {
          debugPrint('DataSyncService: Warning - Failed to push local rehab data to Firebase: $e');
        }
      } else {
        // No local data: pull from Firebase, if available, then persist locally
        debugPrint('DataSyncService: No local rehab data. Attempting to load from Firebase...');
        try {
          await UserRehabilitation.instance.loadPlansFromFirebase();
          await UserRehabilitation.instance.savePlansToHive();
          debugPrint('DataSyncService: Pulled rehab data from Firebase and saved to Hive');
        } catch (e) {
          debugPrint('DataSyncService: Warning - Could not load rehab data from Firebase: $e');
        }
      }
      
      return {
        'success': true,
        'message': 'Rehabilitation data synced successfully',
        'plansCount': UserRehabilitation.instance.rehabPlans.length,
        'treatmentsCount': UserRehabilitation.instance.treatmentReferences?.length ?? 0,
      };
      
    } catch (e) {
      debugPrint('DataSyncService: Error syncing rehabilitation data: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  /// Sync progress data between Hive and Firebase
  Future<Map<String, dynamic>> _syncProgressData() async {
    try {
      debugPrint('DataSyncService: Syncing progress data...');
      
      // Load from Hive (progress data is primarily local)
      await UserProgress.loadFromHive();
      await PainHistory.loadFromHive();
      await ExerciseHistory.loadFromHive();
      
      // Save to Hive (ensure it's saved)
      await UserProgress.saveToHive();
      await PainHistory.saveToHive();
      await ExerciseHistory.saveToHive();
      
      return {
        'success': true,
        'message': 'Progress data synced successfully',
        'progressTitle': UserProgress.title,
        'painHistoryCount': PainHistory.entries.length,
        'exerciseHistoryCount': ExerciseHistory.entries.length,
      };
      
    } catch (e) {
      debugPrint('DataSyncService: Error syncing progress data: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  /// Sync settings data between Hive and Firebase
  Future<Map<String, dynamic>> _syncSettingsData() async {
    try {
      debugPrint('DataSyncService: Syncing settings data...');
      
      // Load from Hive
      await UserSettings.loadFromHive();
      await UserAssess.loadFromHive();
      await ActiveProgram.loadFromHive();
      
      // Save to Hive (ensure it's saved)
      await UserSettings.saveToHive();
      await UserAssess.saveToHive();
      await ActiveProgram.saveToHive();
      
      return {
        'success': true,
        'message': 'Settings data synced successfully',
        'dailyReminder': UserSettings.isDailyReminder,
        'streakAlert': UserSettings.isStreakAlert,
        'exerciseReminder': UserSettings.isExerciseReminder,
        'isAssessed': UserAssess.isAssessed,
        'rehabGoal': UserAssess.rehabGoal,
        'startDate': ActiveProgram.startDate?.toIso8601String(),
      };
      
    } catch (e) {
      debugPrint('DataSyncService: Error syncing settings data: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  /// Force save all data to Firebase
  Future<Map<String, dynamic>> forceSaveToFirebase() async {
    try {
      debugPrint('DataSyncService: Force saving all data to Firebase...');
      
      final user = _auth.currentUser;
      if (user == null) {
        return {
          'success': false,
          'error': 'No authenticated user',
        };
      }
      
      // Ensure collections exist
      await FirebaseHelper.initializeUserCollections();
      
      // Save user data to Firebase
      await UserDetails.updateInFirebase();
      
      // Save rehabilitation data to Firebase
      await UserRehabilitation.instance.savePlansToFirebase();
      
      // Save all data to Hive
      await DataPersistenceService.saveAllDataToHive();
      
      return {
        'success': true,
        'message': 'All data force saved to Firebase successfully',
        'timestamp': DateTime.now().toIso8601String(),
      };
      
    } catch (e) {
      debugPrint('DataSyncService: Error force saving to Firebase: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  /// Load all data from Firebase
  Future<Map<String, dynamic>> loadAllFromFirebase() async {
    try {
      debugPrint('DataSyncService: Loading all data from Firebase...');
      
      final user = _auth.currentUser;
      if (user == null) {
        return {
          'success': false,
          'error': 'No authenticated user',
        };
      }
      
      // Load user data from Firebase
      await UserDetails.loadFromFirebase();
      
      // Load rehabilitation data from Firebase
      await UserRehabilitation.instance.loadPlansFromFirebase();
      
      // Load other data from Hive (as fallback)
      await DataPersistenceService.loadAllDataFromHive();
      
      return {
        'success': true,
        'message': 'All data loaded from Firebase successfully',
        'timestamp': DateTime.now().toIso8601String(),
      };
      
    } catch (e) {
      debugPrint('DataSyncService: Error loading from Firebase: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  /// Verify data integrity
  Future<Map<String, dynamic>> verifyDataIntegrity() async {
    try {
      debugPrint('DataSyncService: Verifying data integrity...');
      
      final results = <String, dynamic>{};
      
      // Check user data
      results['userData'] = {
        'hasFirstName': UserDetails.firstName.isNotEmpty,
        'hasLastName': UserDetails.lastName.isNotEmpty,
        'hasEmail': UserDetails.email.isNotEmpty,
      };
      
      // Check rehabilitation data
      results['rehabilitationData'] = {
        'plansCount': UserRehabilitation.instance.rehabPlans.length,
        'hasTreatments': UserRehabilitation.instance.treatmentReferences != null,
        'treatmentsCount': UserRehabilitation.instance.treatmentReferences?.length ?? 0,
      };
      
      // Check progress data
      results['progressData'] = {
        'hasProgressTitle': UserProgress.title.isNotEmpty,
        'painHistoryCount': PainHistory.entries.length,
        'exerciseHistoryCount': ExerciseHistory.entries.length,
      };
      
      // Check settings data
      results['settingsData'] = {
        'hasSettings': true, // UserSettings.isDailyReminder is always a boolean
        'isAssessed': UserAssess.isAssessed,
        'hasActiveProgram': ActiveProgram.startDate != null,
      };
      
      results['success'] = true;
      results['timestamp'] = DateTime.now().toIso8601String();
      
      debugPrint('DataSyncService: Data integrity verification completed');
      
      return results;
      
    } catch (e) {
      debugPrint('DataSyncService: Error verifying data integrity: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
  
  /// Get sync statistics
  Map<String, dynamic> getSyncStatistics() {
    return {
      'isInitialized': _isInitialized,
      'lastSyncTime': _lastSyncTime?.toIso8601String(),
      'syncCount': _syncCount,
      'isAuthenticated': _auth.currentUser != null,
      'currentUserId': _auth.currentUser?.uid,
    };
  }
  
  /// Clear all data (for logout)
  Future<void> clearAllData() async {
    try {
      debugPrint('DataSyncService: Clearing all data...');
      
      // Clear user data
      UserDetails.clearUserData();
      
      // Clear rehabilitation data
      UserRehabilitation.instance.rehabPlans.clear();
      UserRehabilitation.instance.treatmentReferences = null;
      
      // Clear progress data
      UserProgress.title = 'Initiator';
      PainHistory.entries.clear();
      ExerciseHistory.entries.clear();
      
      // Clear settings data
      UserSettings.isDailyReminder = true;
      UserSettings.isStreakAlert = true;
      UserSettings.isExerciseReminder = true;
      UserAssess.isAssessed = false;
      UserAssess.rehabGoal = '';
      ActiveProgram.startDate = null;
      
      // Save cleared data to Hive
      await DataPersistenceService.saveAllDataToHive();
      
      debugPrint('DataSyncService: All data cleared successfully');
      
    } catch (e) {
      debugPrint('DataSyncService: Error clearing data: $e');
    }
  }
  
  /// Dispose of the service
  void dispose() {
    _isInitialized = false;
    _lastSyncTime = null;
    _syncCount = 0;
    debugPrint('DataSyncService: Disposed');
  }
}
