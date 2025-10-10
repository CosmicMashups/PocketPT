import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'globals.dart';
import 'rehabilitation_plan.dart';

/// Service for automatic saving of data to Firebase from Hive
/// Runs in background and only syncs when user is authenticated
class AutoSaveService {
  static final AutoSaveService _instance = AutoSaveService._internal();
  static AutoSaveService get instance => _instance;
  AutoSaveService._internal();

  Timer? _autoSaveTimer;
  bool _isSaving = false;
  DateTime? _lastSaveTime;
  int _saveCount = 0;
  
  // Auto-save configuration
  static const Duration _autoSaveInterval = Duration(minutes: 5);
  
  /// Initialize the auto-save service
  void initialize() {
    debugPrint('AutoSaveService: Initializing auto-save service');
    _startAutoSaveTimer();
  }
  
  /// Dispose the service
  void dispose() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = null;
  }
  
  /// Start the auto-save timer
  void _startAutoSaveTimer() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(_autoSaveInterval, (timer) {
      _performAutoSave();
    });
  }
  
  /// Perform automatic save to Firebase
  Future<void> _performAutoSave() async {
    if (_isSaving) {
      debugPrint('AutoSaveService: Save already in progress, skipping...');
      return;
    }

    // Check if user is authenticated and not in guest mode
    if (!UserDetails.isAuthenticated || UserDetails.isGuest) {
      debugPrint('AutoSaveService: User not authenticated or in guest mode, skipping auto-save');
      return;
    }

    // Check if enough time has passed since last save
    if (_lastSaveTime != null) {
      final timeSinceLastSave = DateTime.now().difference(_lastSaveTime!);
      if (timeSinceLastSave < _autoSaveInterval) {
        debugPrint('AutoSaveService: Not enough time passed since last save, skipping...');
        return;
      }
    }

    _isSaving = true;
    _saveCount++;
    
    try {
      debugPrint('AutoSaveService: Starting auto-save #$_saveCount...');
      
      final startTime = DateTime.now();
      
      // Save all data to Firebase
      await _saveAllDataToFirebase();
      
      final duration = DateTime.now().difference(startTime);
      _lastSaveTime = DateTime.now();
      
      debugPrint('AutoSaveService: Auto-save #$_saveCount completed successfully in ${duration.inMilliseconds}ms');
      
    } catch (e) {
      debugPrint('AutoSaveService: Auto-save #$_saveCount failed: $e');
      debugPrint('AutoSaveService: Error type: ${e.runtimeType}');
      
      // Don't update lastSaveTime on failure to retry sooner
    } finally {
      _isSaving = false;
    }
  }
  
  /// Save all data to Firebase
  Future<void> _saveAllDataToFirebase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No authenticated user for auto-save');
    }

    // Save user details
    await UserDetails.updateInFirebase();
    debugPrint('AutoSaveService: User details saved to Firebase');

    // Save user progress
    await _saveUserProgressToFirebase();
    debugPrint('AutoSaveService: User progress saved to Firebase');

    // Save user assessment
    await _saveUserAssessmentToFirebase();
    debugPrint('AutoSaveService: User assessment saved to Firebase');

    // Save user settings
    await _saveUserSettingsToFirebase();
    debugPrint('AutoSaveService: User settings saved to Firebase');

    // Save pain history
    await _savePainHistoryToFirebase();
    debugPrint('AutoSaveService: Pain history saved to Firebase');

    // Save exercise history
    await _saveExerciseHistoryToFirebase();
    debugPrint('AutoSaveService: Exercise history saved to Firebase');

    // Save rehabilitation plans
    await _saveRehabilitationPlansToFirebase();
    debugPrint('AutoSaveService: Rehabilitation plans saved to Firebase');
  }
  
  /// Save user progress to Firebase
  Future<void> _saveUserProgressToFirebase() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Save user progress data to Firebase
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('userData')
          .doc('progress')
          .set({
        'title': UserProgress.title,
        'titleColor': UserProgress.titleColor,
        'streak': UserProgress.streak,
        'totalDays': UserProgress.totalDays,
        'totalExercises': UserProgress.totalExercises,
        'totalSeconds': UserProgress.totalSeconds,
        'notes': UserProgress.notes,
        'lastExerciseDate': UserProgress.lastExerciseDate?.toIso8601String(),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('AutoSaveService: Error saving user progress to Firebase: $e');
      rethrow;
    }
  }
  
  /// Save user assessment to Firebase
  Future<void> _saveUserAssessmentToFirebase() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Save user assessment data to Firebase
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('userData')
          .doc('assessment')
          .set({
        'rehabGoal': UserAssess.rehabGoal,
        'generalMuscle': UserAssess.generalMuscle,
        'specificMuscle': UserAssess.specificMuscle,
        'painScale': UserAssess.painScale,
        'painLevel': UserAssess.painLevel,
        'painType': UserAssess.painType,
        'painDuration': UserAssess.painDuration,
        'isInjured': UserAssess.isInjured,
        'isAssessed': UserAssess.isAssessed,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('AutoSaveService: Error saving user assessment to Firebase: $e');
      rethrow;
    }
  }
  
  /// Save user settings to Firebase
  Future<void> _saveUserSettingsToFirebase() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Save user settings data to Firebase
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('userData')
          .doc('settings')
          .set({
        'isDailyReminder': UserSettings.isDailyReminder,
        'isStreakAlert': UserSettings.isStreakAlert,
        'isExerciseReminder': UserSettings.isExerciseReminder,
        'exerciseReminderHour': UserSettings.exerciseReminderTime.hour,
        'exerciseReminderMinute': UserSettings.exerciseReminderTime.minute,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('AutoSaveService: Error saving user settings to Firebase: $e');
      rethrow;
    }
  }
  
  /// Save pain history to Firebase
  Future<void> _savePainHistoryToFirebase() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Convert pain history entries to Firebase format
      final painHistoryData = PainHistory.entries.map((entry) => {
        'date': entry.date.toIso8601String(),
        'painScale': entry.painScale,
        'painLevel': entry.painLevel,
      }).toList();

      // Save pain history data to Firebase
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('userData')
          .doc('painHistory')
          .set({
        'entries': painHistoryData,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('AutoSaveService: Error saving pain history to Firebase: $e');
      rethrow;
    }
  }
  
  /// Save exercise history to Firebase
  Future<void> _saveExerciseHistoryToFirebase() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Convert exercise history entries to Firebase format
      final exerciseHistoryData = ExerciseHistory.entries.map((entry) => {
        'date': entry.date.toIso8601String(),
        'exerciseId': entry.exerciseId,
        'exerciseName': entry.exerciseName,
        'sets': entry.sets,
        'reps': entry.reps,
        'durationSeconds': entry.durationSeconds,
        'status': entry.status,
      }).toList();

      // Save exercise history data to Firebase
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('userData')
          .doc('exerciseHistory')
          .set({
        'entries': exerciseHistoryData,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('AutoSaveService: Error saving exercise history to Firebase: $e');
      rethrow;
    }
  }
  
  /// Save rehabilitation plans to Firebase
  Future<void> _saveRehabilitationPlansToFirebase() async {
    try {
      await UserRehabilitation.instance.savePlansToFirebase();
    } catch (e) {
      debugPrint('AutoSaveService: Error saving rehabilitation plans to Firebase: $e');
      rethrow;
    }
  }
  
  /// Force an immediate save (useful for critical operations)
  Future<void> forceSave({String? reason}) async {
    if (_isSaving) {
      debugPrint('AutoSaveService: Force save requested but save already in progress, skipping...');
      return;
    }

    if (!UserDetails.isAuthenticated || UserDetails.isGuest) {
      debugPrint('AutoSaveService: Force save requested but user not authenticated or in guest mode');
      return;
    }

    debugPrint('AutoSaveService: Force save requested - $reason');
    
    _isSaving = true;
    try {
      await _saveAllDataToFirebase();
      _lastSaveTime = DateTime.now();
      debugPrint('AutoSaveService: Force save completed successfully');
    } catch (e) {
      debugPrint('AutoSaveService: Force save failed: $e');
      rethrow;
    } finally {
      _isSaving = false;
    }
  }
  
  /// Get auto-save status
  Map<String, dynamic> getStatus() {
    return {
      'isInitialized': _autoSaveTimer != null,
      'isSaving': _isSaving,
      'lastSaveTime': _lastSaveTime?.toIso8601String(),
      'saveCount': _saveCount,
      'autoSaveInterval': _autoSaveInterval.inMinutes,
    };
  }
  
  /// Enable/disable auto-save
  void setEnabled(bool enabled) {
    if (enabled && _autoSaveTimer == null) {
      _startAutoSaveTimer();
      debugPrint('AutoSaveService: Auto-save enabled');
    } else if (!enabled && _autoSaveTimer != null) {
      _autoSaveTimer?.cancel();
      _autoSaveTimer = null;
      debugPrint('AutoSaveService: Auto-save disabled');
    }
  }
}

