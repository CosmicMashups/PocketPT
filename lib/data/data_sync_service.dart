import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'globals.dart';
import 'rehabilitation_plan.dart';
import 'data_persistence_service.dart';
import 'firebase_helper.dart';
import 'sync_queue.dart';

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
  
  /// Comprehensive data synchronization with offline-first architecture
  Future<Map<String, dynamic>> syncAllData() async {
    final results = <String, dynamic>{};
    
    try {
      debugPrint('DataSyncService: Starting offline-first data sync...');
      
      // STEP 1: Load all data from Hive first (Hive is source of truth)
      await _loadAllFromHive();
      
      // STEP 2: Check if user is authenticated
      if (!_isUserAuthenticated()) {
        results['success'] = false;
        results['error'] = 'No authenticated user';
        results['message'] = 'Sync skipped - user not authenticated';
        return results;
      }
      
      // STEP 3: Process sync queue first (offline operations)
      await _processSyncQueue();
      
      // STEP 4: Fetch Firebase data in background
      final firebaseData = await _fetchAllFromFirebase();
      
      // STEP 5: Merge with conflict resolution (timestamp-based)
      final mergedData = await _mergeData(firebaseData);
      
      // STEP 6: Save merged result to Hive
      await _saveAllToHive(mergedData);
      
      // STEP 7: Push any local-only changes to Firebase
      await _pushLocalChangesToFirebase();
      
      // Update sync statistics
      _lastSyncTime = DateTime.now();
      _syncCount++;
      
      results['success'] = true;
      results['message'] = 'Offline-first sync completed successfully';
      results['lastSyncTime'] = _lastSyncTime?.toIso8601String();
      results['syncCount'] = _syncCount;
      results['mergedData'] = mergedData;
      
      debugPrint('DataSyncService: Offline-first sync completed successfully');
      
    } catch (e) {
      debugPrint('DataSyncService: Error during offline-first sync: $e');
      results['success'] = false;
      results['error'] = e.toString();
      results['message'] = 'Sync failed - see logs for details';
    }
    
    return results;
  }

  /// Load all data from Hive (source of truth)
  Future<void> _loadAllFromHive() async {
    debugPrint('DataSyncService: Loading all data from Hive...');
    await DataPersistenceService.loadAllDataFromHive();
    debugPrint('DataSyncService: All data loaded from Hive');
  }

  /// Check if user is authenticated
  bool _isUserAuthenticated() {
    return _auth.currentUser != null;
  }

  /// Process sync queue for offline operations
  Future<void> _processSyncQueue() async {
    debugPrint('DataSyncService: Processing sync queue...');
    await SyncQueue.flushQueue();
    debugPrint('DataSyncService: Sync queue processed');
  }

  /// Fetch all data from Firebase
  Future<Map<String, dynamic>> _fetchAllFromFirebase() async {
    debugPrint('DataSyncService: Fetching data from Firebase...');
    
    final firebaseData = <String, dynamic>{};
    
    try {
      // Fetch user data
      final userData = await _fetchUserDataFromFirebase();
      if (userData != null) firebaseData['userData'] = userData;
      
      // Fetch assessment data
      final assessData = await _fetchAssessmentDataFromFirebase();
      if (assessData != null) firebaseData['assessmentData'] = assessData;
      
      // Fetch progress data
      final progressData = await _fetchProgressDataFromFirebase();
      if (progressData != null) firebaseData['progressData'] = progressData;
      
      // Fetch settings data
      final settingsData = await _fetchSettingsDataFromFirebase();
      if (settingsData != null) firebaseData['settingsData'] = settingsData;

      // Fetch histories (pain/exercise)
      final historiesData = await _fetchHistoriesFromFirebase();
      if (historiesData.containsKey('painHistoryData')) {
        firebaseData['painHistoryData'] = historiesData['painHistoryData'];
      }
      if (historiesData.containsKey('exerciseHistoryData')) {
        firebaseData['exerciseHistoryData'] = historiesData['exerciseHistoryData'];
      }
      
      debugPrint('DataSyncService: Firebase data fetched successfully');
    } catch (e) {
      debugPrint('DataSyncService: Error fetching from Firebase: $e');
      // Continue with empty data - Hive data will be used
    }
    
    return firebaseData;
  }

  /// Merge Firebase data with local data using timestamp-based conflict resolution
  Future<Map<String, dynamic>> _mergeData(Map<String, dynamic> firebaseData) async {
    debugPrint('DataSyncService: Merging data with conflict resolution...');
    
    final mergedData = <String, dynamic>{};
    
    // Merge user data
    if (firebaseData.containsKey('userData')) {
      mergedData['userData'] = _mergeUserData(firebaseData['userData']);
    }
    
    // Merge assessment data
    if (firebaseData.containsKey('assessmentData')) {
      mergedData['assessmentData'] = _mergeAssessmentData(firebaseData['assessmentData']);
    }
    
    // Merge progress data
    if (firebaseData.containsKey('progressData')) {
      mergedData['progressData'] = _mergeProgressData(firebaseData['progressData']);
    }
    
    // Merge settings data
    if (firebaseData.containsKey('settingsData')) {
      mergedData['settingsData'] = _mergeSettingsData(firebaseData['settingsData']);
    }

    // Merge pain history data
    if (firebaseData.containsKey('painHistoryData')) {
      mergedData['painHistoryData'] = _mergePainHistoryData(firebaseData['painHistoryData']);
    }
    // Merge exercise history data
    if (firebaseData.containsKey('exerciseHistoryData')) {
      mergedData['exerciseHistoryData'] = _mergeExerciseHistoryData(firebaseData['exerciseHistoryData']);
    }
    
    debugPrint('DataSyncService: Data merged successfully');
    return mergedData;
  }

  /// Save merged data to Hive
  Future<void> _saveAllToHive(Map<String, dynamic> mergedData) async {
    debugPrint('DataSyncService: Saving merged data to Hive...');
    
    // Apply merged data to in-memory objects
    if (mergedData.containsKey('userData')) {
      _applyUserDataToMemory(mergedData['userData']);
    }
    if (mergedData.containsKey('assessmentData')) {
      _applyAssessmentDataToMemory(mergedData['assessmentData']);
    }
    if (mergedData.containsKey('progressData')) {
      _applyProgressDataToMemory(mergedData['progressData']);
    }
    if (mergedData.containsKey('settingsData')) {
      _applySettingsDataToMemory(mergedData['settingsData']);
    }
    if (mergedData.containsKey('painHistoryData')) {
      _applyPainHistoryToMemory(mergedData['painHistoryData']);
    }
    if (mergedData.containsKey('exerciseHistoryData')) {
      _applyExerciseHistoryToMemory(mergedData['exerciseHistoryData']);
    }
    
    // Save all data to Hive
    await DataPersistenceService.saveAllDataToHive();
    debugPrint('DataSyncService: Merged data saved to Hive');
  }

  /// Push local changes to Firebase
  Future<void> _pushLocalChangesToFirebase() async {
    debugPrint('DataSyncService: Pushing local changes to Firebase...');
    
    try {
      // Push user data
      await UserDetails.updateInFirebase();
      
      // Push assessment data
      await UserAssess.saveToFirebase();
      
      // Push progress data
      await UserProgress.saveToFirebase();
      
      // Push settings data
      await UserSettings.saveToFirebase();
      
      // Push history data
      await PainHistory.saveToFirebase();
      await ExerciseHistory.saveToFirebase();
      
      debugPrint('DataSyncService: Local changes pushed to Firebase');
    } catch (e) {
      debugPrint('DataSyncService: Error pushing to Firebase: $e');
      // Don't throw - this is background sync
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
      await FirebaseHelper.ensureAllCollectionsExist();
      
      // Save user data to Firebase
      await UserDetails.updateInFirebase();
      
      // Save rehabilitation data to Firebase
      await UserRehabilitation.instance.savePlansToFirebase();
      
      // Save progress data to Firebase
      await UserProgress.saveToFirebase();
      await PainHistory.saveToFirebase();
      await ExerciseHistory.saveToFirebase();
      
      // Save settings data to Firebase
      await UserSettings.saveToFirebase();
      await UserAssess.saveToFirebase();
      
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
      
      // Load progress data from Firebase
      await UserProgress.loadFromFirebase();
      await PainHistory.loadFromFirebase();
      await ExerciseHistory.loadFromFirebase();
      
      // Load settings data from Firebase
      await UserSettings.loadFromFirebase();
      await UserAssess.loadFromFirebase();
      
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

  // Helper methods for data fetching, merging, and application

  /// Fetch user data from Firebase
  Future<Map<String, dynamic>?> _fetchUserDataFromFirebase() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        data['lastModified'] = doc.data()?['lastUpdated']?.toDate();
        return data;
      }
      return null;
    } catch (e) {
      debugPrint('DataSyncService: Error fetching user data from Firebase: $e');
      return null;
    }
  }

  /// Fetch assessment data from Firebase
  Future<Map<String, dynamic>?> _fetchAssessmentDataFromFirebase() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await FirebaseFirestore.instance
          .collection('assessment')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        data['lastModified'] = doc.data()?['lastUpdated']?.toDate();
        return data;
      }
      return null;
    } catch (e) {
      debugPrint('DataSyncService: Error fetching assessment data from Firebase: $e');
      return null;
    }
  }

  /// Fetch histories (pain and exercise) from Firebase
  Future<Map<String, dynamic>> _fetchHistoriesFromFirebase() async {
    final user = _auth.currentUser;
    if (user == null) return <String, dynamic>{};

    final Map<String, dynamic> result = <String, dynamic>{};
    try {
      // Pain history
      final painDoc = await FirebaseFirestore.instance
          .collection('painHistory')
          .doc(user.uid)
          .get();
      if (painDoc.exists) {
        final data = painDoc.data() as Map<String, dynamic>;
        // Attach lastModified from lastUpdated or latest entry date
        DateTime? lastModified = (data['lastUpdated'] as Timestamp?)?.toDate();
        if (lastModified == null) {
          final List<dynamic> entries = data['entries'] ?? [];
          for (final entry in entries) {
            final ts = (entry['date'] as Timestamp?)?.toDate();
            if (ts != null && (lastModified == null || ts.isAfter(lastModified))) {
              lastModified = ts;
            }
          }
        }
        data['lastModified'] = lastModified;
        result['painHistoryData'] = data;
      }

      // Exercise history
      final exerciseDoc = await FirebaseFirestore.instance
          .collection('exerciseHistory')
          .doc(user.uid)
          .get();
      if (exerciseDoc.exists) {
        final data = exerciseDoc.data() as Map<String, dynamic>;
        DateTime? lastModified = (data['lastUpdated'] as Timestamp?)?.toDate();
        if (lastModified == null) {
          final List<dynamic> entries = data['entries'] ?? [];
          for (final entry in entries) {
            final ts = (entry['date'] as Timestamp?)?.toDate();
            if (ts != null && (lastModified == null || ts.isAfter(lastModified))) {
              lastModified = ts;
            }
          }
        }
        data['lastModified'] = lastModified;
        result['exerciseHistoryData'] = data;
      }
    } catch (e) {
      debugPrint('DataSyncService: Error fetching histories from Firebase: $e');
    }

    return result;
  }

  /// Fetch progress data from Firebase
  Future<Map<String, dynamic>?> _fetchProgressDataFromFirebase() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await FirebaseFirestore.instance
          .collection('progress')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        data['lastModified'] = doc.data()?['lastUpdated']?.toDate();
        return data;
      }
      return null;
    } catch (e) {
      debugPrint('DataSyncService: Error fetching progress data from Firebase: $e');
      return null;
    }
  }

  /// Fetch settings data from Firebase
  Future<Map<String, dynamic>?> _fetchSettingsDataFromFirebase() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        data['lastModified'] = doc.data()?['lastUpdated']?.toDate();
        return data;
      }
      return null;
    } catch (e) {
      debugPrint('DataSyncService: Error fetching settings data from Firebase: $e');
      return null;
    }
  }

  /// Merge user data using timestamp-based conflict resolution
  Map<String, dynamic> _mergeUserData(Map<String, dynamic> firebaseData) {
    final localLastModified = UserDetails.lastModified;
    final firebaseLastModified = firebaseData['lastModified'] as DateTime?;

    if (localLastModified == null && firebaseLastModified == null) {
      return _getCurrentUserData();
    } else if (localLastModified == null) {
      return firebaseData; // Use Firebase data
    } else if (firebaseLastModified == null) {
      return _getCurrentUserData(); // Use local data
    } else if (localLastModified.isAfter(firebaseLastModified)) {
      return _getCurrentUserData(); // Local is newer
    } else {
      return firebaseData; // Firebase is newer
    }
  }

  /// Merge assessment data using timestamp-based conflict resolution
  Map<String, dynamic> _mergeAssessmentData(Map<String, dynamic> firebaseData) {
    final localLastModified = UserAssess.lastModified;
    final firebaseLastModified = firebaseData['lastModified'] as DateTime?;

    if (localLastModified == null && firebaseLastModified == null) {
      return _getCurrentAssessmentData();
    } else if (localLastModified == null) {
      return firebaseData; // Use Firebase data
    } else if (firebaseLastModified == null) {
      return _getCurrentAssessmentData(); // Use local data
    } else if (localLastModified.isAfter(firebaseLastModified)) {
      return _getCurrentAssessmentData(); // Local is newer
    } else {
      return firebaseData; // Firebase is newer
    }
  }

  /// Merge progress data using timestamp-based conflict resolution
  Map<String, dynamic> _mergeProgressData(Map<String, dynamic> firebaseData) {
    final localLastModified = UserProgress.lastModified;
    final firebaseLastModified = firebaseData['lastModified'] as DateTime?;

    if (localLastModified == null && firebaseLastModified == null) {
      return _getCurrentProgressData();
    } else if (localLastModified == null) {
      return firebaseData; // Use Firebase data
    } else if (firebaseLastModified == null) {
      return _getCurrentProgressData(); // Use local data
    } else if (localLastModified.isAfter(firebaseLastModified)) {
      return _getCurrentProgressData(); // Local is newer
    } else {
      return firebaseData; // Firebase is newer
    }
  }

  /// Merge settings data using timestamp-based conflict resolution
  Map<String, dynamic> _mergeSettingsData(Map<String, dynamic> firebaseData) {
    final localLastModified = UserSettings.lastModified;
    final firebaseLastModified = firebaseData['lastModified'] as DateTime?;

    if (localLastModified == null && firebaseLastModified == null) {
      return _getCurrentSettingsData();
    } else if (localLastModified == null) {
      return firebaseData; // Use Firebase data
    } else if (firebaseLastModified == null) {
      return _getCurrentSettingsData(); // Use local data
    } else if (localLastModified.isAfter(firebaseLastModified)) {
      return _getCurrentSettingsData(); // Local is newer
    } else {
      return firebaseData; // Firebase is newer
    }
  }

  /// Merge pain history using timestamp-based conflict resolution
  Map<String, dynamic> _mergePainHistoryData(Map<String, dynamic> firebaseData) {
    final DateTime? localLastModified = _getLocalPainHistoryLastModified();
    final DateTime? firebaseLastModified = firebaseData['lastModified'] as DateTime?;

    if (localLastModified == null && firebaseLastModified == null) {
      return _getCurrentPainHistoryData();
    } else if (localLastModified == null) {
      return firebaseData; // Use Firebase data
    } else if (firebaseLastModified == null) {
      return _getCurrentPainHistoryData(); // Use local data
    } else if (localLastModified.isAfter(firebaseLastModified)) {
      return _getCurrentPainHistoryData(); // Local is newer
    } else {
      return firebaseData; // Firebase is newer
    }
  }

  /// Merge exercise history using timestamp-based conflict resolution
  Map<String, dynamic> _mergeExerciseHistoryData(Map<String, dynamic> firebaseData) {
    final DateTime? localLastModified = _getLocalExerciseHistoryLastModified();
    final DateTime? firebaseLastModified = firebaseData['lastModified'] as DateTime?;

    if (localLastModified == null && firebaseLastModified == null) {
      return _getCurrentExerciseHistoryData();
    } else if (localLastModified == null) {
      return firebaseData; // Use Firebase data
    } else if (firebaseLastModified == null) {
      return _getCurrentExerciseHistoryData(); // Use local data
    } else if (localLastModified.isAfter(firebaseLastModified)) {
      return _getCurrentExerciseHistoryData(); // Local is newer
    } else {
      return firebaseData; // Firebase is newer
    }
  }

  /// Get current user data as Map
  Map<String, dynamic> _getCurrentUserData() {
    return {
      'firstName': UserDetails.firstName,
      'lastName': UserDetails.lastName,
      'email': UserDetails.email,
      'profilePicture': UserDetails.profilePicture,
      'hasCompletedAssessment': UserDetails.hasCompletedAssessment,
      'lastModified': UserDetails.lastModified,
    };
  }

  /// Get current assessment data as Map
  Map<String, dynamic> _getCurrentAssessmentData() {
    return {
      'rehabGoal': UserAssess.rehabGoal,
      'generalMuscle': UserAssess.generalMuscle,
      'specificMuscle': UserAssess.specificMuscle,
      'painScale': UserAssess.painScale,
      'painLevel': UserAssess.painLevel,
      'painType': UserAssess.painType,
      'painDuration': UserAssess.painDuration,
      'isInjured': UserAssess.isInjured,
      'isAssessed': UserAssess.isAssessed,
      'lastModified': UserAssess.lastModified,
    };
  }

  /// Get current progress data as Map
  Map<String, dynamic> _getCurrentProgressData() {
    return {
      'title': UserProgress.title,
      'titleColor': UserProgress.titleColor,
      'streak': UserProgress.streak,
      'totalDays': UserProgress.totalDays,
      'totalExercises': UserProgress.totalExercises,
      'totalSeconds': UserProgress.totalSeconds,
      'notes': UserProgress.notes,
      'lastExerciseDate': UserProgress.lastExerciseDate,
      'lastModified': UserProgress.lastModified,
    };
  }

  /// Get current settings data as Map
  Map<String, dynamic> _getCurrentSettingsData() {
    return {
      'isDailyReminder': UserSettings.isDailyReminder,
      'isStreakAlert': UserSettings.isStreakAlert,
      'isExerciseReminder': UserSettings.isExerciseReminder,
      'exerciseReminderHour': UserSettings.exerciseReminderTime.hour,
      'exerciseReminderMinute': UserSettings.exerciseReminderTime.minute,
      'lastModified': UserSettings.lastModified,
    };
  }

  /// Get current pain history as Map
  Map<String, dynamic> _getCurrentPainHistoryData() {
    final entries = PainHistory.entries
        .map((e) => {
              'date': e.date,
              'painScale': e.painScale,
              'painLevel': e.painLevel,
            })
        .toList();
    return {
      'entries': entries,
      'lastModified': _getLocalPainHistoryLastModified(),
    };
  }

  /// Get current exercise history as Map
  Map<String, dynamic> _getCurrentExerciseHistoryData() {
    final entries = ExerciseHistory.entries
        .map((e) => {
              'date': e.date,
              'exerciseId': e.exerciseId,
              'exerciseName': e.exerciseName,
              'sets': e.sets,
              'reps': e.reps,
              'durationSeconds': e.durationSeconds,
              'status': e.status,
            })
        .toList();
    return {
      'entries': entries,
      'lastModified': _getLocalExerciseHistoryLastModified(),
    };
  }

  DateTime? _getLocalPainHistoryLastModified() {
    DateTime? last;
    for (final e in PainHistory.entries) {
      if (last == null || e.date.isAfter(last)) last = e.date;
    }
    return last;
  }

  DateTime? _getLocalExerciseHistoryLastModified() {
    DateTime? last;
    for (final e in ExerciseHistory.entries) {
      if (last == null || e.date.isAfter(last)) last = e.date;
    }
    return last;
  }

  /// Apply user data to memory
  void _applyUserDataToMemory(Map<String, dynamic> data) {
    if (data['firstName'] != null) UserDetails.firstName = data['firstName'];
    if (data['lastName'] != null) UserDetails.lastName = data['lastName'];
    if (data['email'] != null) UserDetails.email = data['email'];
    if (data['profilePicture'] != null) UserDetails.profilePicture = data['profilePicture'];
    if (data['hasCompletedAssessment'] != null) UserDetails.hasCompletedAssessment = data['hasCompletedAssessment'];
    if (data['lastModified'] != null) UserDetails.lastModified = data['lastModified'];
  }

  /// Apply assessment data to memory
  void _applyAssessmentDataToMemory(Map<String, dynamic> data) {
    if (data['rehabGoal'] != null) UserAssess.rehabGoal = data['rehabGoal'];
    if (data['generalMuscle'] != null) UserAssess.generalMuscle = data['generalMuscle'];
    if (data['specificMuscle'] != null) UserAssess.specificMuscle = data['specificMuscle'];
    if (data['painScale'] != null) UserAssess.painScale = data['painScale'];
    if (data['painLevel'] != null) UserAssess.painLevel = data['painLevel'];
    if (data['painType'] != null) UserAssess.painType = data['painType'];
    if (data['painDuration'] != null) UserAssess.painDuration = data['painDuration'];
    if (data['isInjured'] != null) UserAssess.isInjured = data['isInjured'];
    if (data['isAssessed'] != null) UserAssess.isAssessed = data['isAssessed'];
    if (data['lastModified'] != null) UserAssess.lastModified = data['lastModified'];
  }

  /// Apply progress data to memory
  void _applyProgressDataToMemory(Map<String, dynamic> data) {
    if (data['title'] != null) UserProgress.title = data['title'];
    if (data['titleColor'] != null) UserProgress.titleColor = data['titleColor'];
    if (data['streak'] != null) UserProgress.streak = data['streak'];
    if (data['totalDays'] != null) UserProgress.totalDays = data['totalDays'];
    if (data['totalExercises'] != null) UserProgress.totalExercises = data['totalExercises'];
    if (data['totalSeconds'] != null) UserProgress.totalSeconds = data['totalSeconds'];
    if (data['notes'] != null) UserProgress.notes = data['notes'];
    if (data['lastExerciseDate'] != null) UserProgress.lastExerciseDate = data['lastExerciseDate'];
    if (data['lastModified'] != null) UserProgress.lastModified = data['lastModified'];
  }

  /// Apply settings data to memory
  void _applySettingsDataToMemory(Map<String, dynamic> data) {
    if (data['isDailyReminder'] != null) UserSettings.isDailyReminder = data['isDailyReminder'];
    if (data['isStreakAlert'] != null) UserSettings.isStreakAlert = data['isStreakAlert'];
    if (data['isExerciseReminder'] != null) UserSettings.isExerciseReminder = data['isExerciseReminder'];
    if (data['exerciseReminderHour'] != null && data['exerciseReminderMinute'] != null) {
      UserSettings.exerciseReminderTime = TimeOfDay(
        hour: data['exerciseReminderHour'],
        minute: data['exerciseReminderMinute'],
      );
    }
    if (data['lastModified'] != null) UserSettings.lastModified = data['lastModified'];
  }

  /// Apply pain history data to memory
  void _applyPainHistoryToMemory(Map<String, dynamic> data) {
    final List<dynamic> entriesData = data['entries'] ?? <dynamic>[];
    PainHistory.entries.clear();
    for (final entryData in entriesData) {
      final Map<String, dynamic> m = Map<String, dynamic>.from(entryData as Map);
      final DateTime date = m['date'] is DateTime
          ? (m['date'] as DateTime)
          : ((m['date'] is Timestamp) ? (m['date'] as Timestamp).toDate() : DateTime.now());
      PainHistory.entries.add(PainRecordEntry(
        date: date,
        painScale: m['painScale'] ?? 0,
        painLevel: m['painLevel'] ?? '',
      ));
    }
  }

  /// Apply exercise history data to memory
  void _applyExerciseHistoryToMemory(Map<String, dynamic> data) {
    final List<dynamic> entriesData = data['entries'] ?? <dynamic>[];
    ExerciseHistory.entries.clear();
    for (final entryData in entriesData) {
      final Map<String, dynamic> m = Map<String, dynamic>.from(entryData as Map);
      final DateTime date = m['date'] is DateTime
          ? (m['date'] as DateTime)
          : ((m['date'] is Timestamp) ? (m['date'] as Timestamp).toDate() : DateTime.now());
      ExerciseHistory.entries.add(ExerciseRecordEntry(
        date: date,
        exerciseId: m['exerciseId'] ?? '',
        exerciseName: m['exerciseName'] ?? '',
        sets: m['sets'] ?? 0,
        reps: m['reps'] ?? 0,
        durationSeconds: m['durationSeconds'] ?? 0,
        status: m['status'] ?? 'completed',
      ));
    }
  }
}
