import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'globals.dart';
import 'rehabilitation_plan.dart';
import 'hive_models.dart';
import 'user_data_notifier.dart';

/// Service to handle fast loading of critical data for immediate app startup
class FastLoadingService {
  static final FastLoadingService _instance = FastLoadingService._internal();
  static FastLoadingService get instance => _instance;
  
  FastLoadingService._internal();
  
  bool _isInitialized = false;
  bool _isLoading = false;
  final Completer<void> _loadingCompleter = Completer<void>();
  
  /// Initialize fast loading service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      debugPrint('FastLoadingService: Initializing...');
      
      // Start loading critical data immediately
      _loadCriticalData();
      
      _isInitialized = true;
      debugPrint('FastLoadingService: Initialized successfully');
      
    } catch (e) {
      debugPrint('FastLoadingService: Error during initialization: $e');
      rethrow;
    }
  }
  
  /// Load critical data for immediate app startup
  Future<void> _loadCriticalData() async {
    if (_isLoading) return;
    
    _isLoading = true;
    try {
      debugPrint('FastLoadingService: Loading critical data...');
      
      // Load only essential data for immediate startup
      await Future.wait([
        _loadUserDetails(),
        _loadUserSettings(),
        _loadUserAssessment(),
        _loadActiveProgram(),
      ]);
      
      debugPrint('FastLoadingService: Critical data loaded successfully');
      
      if (!_loadingCompleter.isCompleted) {
        _loadingCompleter.complete();
      }
      
    } catch (e) {
      debugPrint('FastLoadingService: Error loading critical data: $e');
      if (!_loadingCompleter.isCompleted) {
        _loadingCompleter.completeError(e);
      }
    } finally {
      _isLoading = false;
    }
  }
  
  /// Load user details (essential for authentication check)
  Future<void> _loadUserDetails() async {
    try {
      final box = Hive.box('rehabBox');
      final hiveUserDetails = box.get('userDetails');
      if (hiveUserDetails is HiveUserDetails) {
        UserDetails.firstName = hiveUserDetails.firstName;
        UserDetails.lastName = hiveUserDetails.lastName;
        UserDetails.email = hiveUserDetails.email;
        UserDetails.password = hiveUserDetails.password;
        UserDetails.notifications = hiveUserDetails.notifications;
        UserDetails.isGuest = hiveUserDetails.isGuest;
        UserDetails.guestSessionId = hiveUserDetails.guestSessionId;
        
        // Load assessment completion flag if present
        final storedHasCompleted = box.get('hasCompletedAssessment');
        if (storedHasCompleted is bool) {
          UserDetails.hasCompletedAssessment = storedHasCompleted;
        }
        
        debugPrint('FastLoadingService: User details loaded - firstName: "${UserDetails.firstName}", lastName: "${UserDetails.lastName}", email: "${UserDetails.email}", isGuest: ${UserDetails.isGuest}, hasCompletedAssessment: ${UserDetails.hasCompletedAssessment}');
        
        // Notify UI of data changes
        UserDataNotifier.instance.updateUserData(
          firstName: UserDetails.firstName,
          lastName: UserDetails.lastName,
          email: UserDetails.email,
          hasCompletedAssessment: UserDetails.hasCompletedAssessment,
        );
      } else {
        debugPrint('FastLoadingService: No user details found in Hive');
      }
    } catch (e) {
      debugPrint('FastLoadingService: Error loading user details: $e');
    }
  }
  
  /// Load user settings (essential for UI)
  Future<void> _loadUserSettings() async {
    try {
      final box = Hive.box('rehabBox');
      final hiveUserSettings = box.get('userSettings');
      if (hiveUserSettings is HiveUserSettings) {
        UserSettings.isDailyReminder = hiveUserSettings.isDailyReminder;
        UserSettings.isStreakAlert = hiveUserSettings.isStreakAlert;
        UserSettings.isExerciseReminder = hiveUserSettings.isExerciseReminder;
        UserSettings.exerciseReminderTime = TimeOfDay(
          hour: hiveUserSettings.exerciseReminderHour,
          minute: hiveUserSettings.exerciseReminderMinute,
        );
        debugPrint('FastLoadingService: User settings loaded');
      }
    } catch (e) {
      debugPrint('FastLoadingService: Error loading user settings: $e');
    }
  }
  
  /// Load user assessment (essential for navigation)
  Future<void> _loadUserAssessment() async {
    try {
      final box = Hive.box('rehabBox');
      final hiveUserAssess = box.get('userAssess');
      if (hiveUserAssess is HiveUserAssess) {
        UserAssess.rehabGoal = hiveUserAssess.rehabGoal;
        UserAssess.generalMuscle = hiveUserAssess.generalMuscle;
        UserAssess.specificMuscle = hiveUserAssess.specificMuscle;
        UserAssess.painScale = hiveUserAssess.painScale;
        UserAssess.painLevel = hiveUserAssess.painLevel;
        UserAssess.painType = hiveUserAssess.painType;
        UserAssess.painDuration = hiveUserAssess.painDuration;
        UserAssess.isInjured = hiveUserAssess.isInjured;
        UserAssess.isAssessed = hiveUserAssess.isAssessed;
        debugPrint('FastLoadingService: User assessment loaded');
      }
    } catch (e) {
      debugPrint('FastLoadingService: Error loading user assessment: $e');
    }
  }
  
  /// Load active program (essential for exercise data)
  Future<void> _loadActiveProgram() async {
    try {
      final box = Hive.box('rehabBox');
      final hiveActiveProgram = box.get('activeProgram');
      if (hiveActiveProgram is HiveActiveProgram) {
        ActiveProgram.startDate = hiveActiveProgram.startDate;
        debugPrint('FastLoadingService: Active program loaded');
      }
    } catch (e) {
      debugPrint('FastLoadingService: Error loading active program: $e');
    }
  }
  
  /// Wait for critical data to be loaded
  Future<void> waitForCriticalData() async {
    if (!_isLoading && _loadingCompleter.isCompleted) {
      return;
    }
    
    return _loadingCompleter.future;
  }
  
  /// Load non-critical data in background
  Future<void> loadBackgroundData() async {
    try {
      debugPrint('FastLoadingService: Loading background data...');
      
      // Load non-critical data that can be loaded later
      await Future.wait([
        _loadUserProgress(),
        _loadPainHistory(),
        _loadExerciseHistory(),
        _loadRehabilitationPlans(),
      ]);
      
      debugPrint('FastLoadingService: Background data loaded successfully');
      
    } catch (e) {
      debugPrint('FastLoadingService: Error loading background data: $e');
    }
  }
  
  /// Load user progress (non-critical)
  Future<void> _loadUserProgress() async {
    try {
      final box = Hive.box('rehabBox');
      final hiveUserProgress = box.get('userProgress');
      if (hiveUserProgress is HiveUserProgress) {
        UserProgress.title = hiveUserProgress.title;
        UserProgress.titleColor = hiveUserProgress.titleColor;
        UserProgress.streak = hiveUserProgress.streak;
        UserProgress.totalDays = hiveUserProgress.totalDays;
        UserProgress.totalExercises = hiveUserProgress.totalExercises;
        UserProgress.totalSeconds = hiveUserProgress.totalSeconds;
        UserProgress.notes = hiveUserProgress.notes;
        UserProgress.lastExerciseDate = hiveUserProgress.lastExerciseDate;
        debugPrint('FastLoadingService: User progress loaded');
      }
    } catch (e) {
      debugPrint('FastLoadingService: Error loading user progress: $e');
    }
  }
  
  /// Load pain history (non-critical)
  Future<void> _loadPainHistory() async {
    try {
      final box = Hive.box('rehabBox');
      final hiveEntries = box.get('painHistory', defaultValue: <HivePainRecordEntry>[]);
      if (hiveEntries is List<HivePainRecordEntry>) {
        PainHistory.entries.clear();
        PainHistory.entries.addAll(hiveEntries.map((he) => he.toPainRecordEntry()));
        debugPrint('FastLoadingService: Pain history loaded (${PainHistory.entries.length} entries)');
      }
    } catch (e) {
      debugPrint('FastLoadingService: Error loading pain history: $e');
    }
  }
  
  /// Load exercise history (non-critical)
  Future<void> _loadExerciseHistory() async {
    try {
      final box = Hive.box('rehabBox');
      final hiveEntries = box.get('exerciseHistory', defaultValue: <HiveExerciseRecordEntry>[]);
      if (hiveEntries is List<HiveExerciseRecordEntry>) {
        ExerciseHistory.entries.clear();
        ExerciseHistory.entries.addAll(hiveEntries.map((he) => he.toExerciseRecordEntry()));
        debugPrint('FastLoadingService: Exercise history loaded (${ExerciseHistory.entries.length} entries)');
      }
    } catch (e) {
      debugPrint('FastLoadingService: Error loading exercise history: $e');
    }
  }
  
  /// Load rehabilitation plans (non-critical)
  Future<void> _loadRehabilitationPlans() async {
    try {
      await UserRehabilitation.instance.loadPlansFromHive();
      debugPrint('FastLoadingService: Rehabilitation plans loaded');
    } catch (e) {
      debugPrint('FastLoadingService: Error loading rehabilitation plans: $e');
    }
  }
  
  /// Get loading status
  Map<String, dynamic> getStatus() {
    return {
      'isInitialized': _isInitialized,
      'isLoading': _isLoading,
      'isCompleted': _loadingCompleter.isCompleted,
    };
  }
  
  /// Dispose of the service
  void dispose() {
    _isInitialized = false;
    _isLoading = false;
    if (!_loadingCompleter.isCompleted) {
      _loadingCompleter.complete();
    }
    debugPrint('FastLoadingService: Disposed');
  }
}
