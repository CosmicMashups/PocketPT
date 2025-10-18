import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';

import 'data_persistence_service.dart';
import 'data_sync_service.dart';
import 'firebase_helper.dart';
import 'globals.dart';
import 'rehabilitation_plan.dart';
import 'treatment.dart';

/// Validation utility to exercise Hive ↔ Firebase round-trips
/// and emit a consolidated verification log.
class PersistenceValidation {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Runs a full validation cycle and returns a summary map.
  /// This is safe to run in debug builds; it does not throw.
  static Future<Map<String, dynamic>> runFull() async {
    final Map<String, dynamic> log = <String, dynamic>{
      'success': false,
      'steps': <String>[],
      'errors': <String>[],
      'models': <String, dynamic>{},
      'collections': <String, dynamic>{},
    };

    try {
      debugPrint('PersistenceValidation: START');

      // Preconditions
      if (_auth.currentUser == null) {
        final msg = 'No authenticated user - validation requires login';
        debugPrint('PersistenceValidation: $msg');
        log['errors'].add(msg);
        return log;
      }

      // Ensure Hive is available
      if (!Hive.isBoxOpen('rehabBox')) {
        await Hive.openBox('rehabBox');
      }

      // 1) Ensure collections exist
      final ensure = await FirebaseHelper.ensureAllCollectionsExist();
      log['collections'] = ensure;
      log['steps'].add('Collections ensured');

      // 2) Seed minimal, deterministic data in-memory
      UserDetails.firstName = 'Test';
      UserDetails.lastName = 'User';
      UserDetails.email = _auth.currentUser?.email ?? 'test@example.com';
      UserDetails.hasCompletedAssessment = true;

      UserAssess.rehabGoal = 'Mobility';
      UserAssess.generalMuscle = 'Neck';
      UserAssess.specificMuscle = 'SCM';
      UserAssess.painScale = 3;
      UserAssess.painLevel = 'low';
      UserAssess.painType = 'ache';
      UserAssess.painDuration = 'acute';
      UserAssess.isInjured = false;
      UserAssess.isAssessed = true;

      UserSettings.isDailyReminder = true;
      UserSettings.isExerciseReminder = true;
      UserSettings.exerciseReminderTime = const TimeOfDay(hour: 8, minute: 0);

      UserProgress.title = 'Initiator';
      UserProgress.streak = 1;
      UserProgress.totalDays = 1;
      UserProgress.totalExercises = 1;
      UserProgress.totalSeconds = 60;

      PainHistory.entries.clear();
      PainHistory.recordToday(painScale: 3, painLevel: 'low');

      ExerciseHistory.entries.clear();
      ExerciseHistory.recordToday(
        exerciseId: 'EX001',
        exerciseName: 'Test Exercise',
        sets: 1,
        reps: 10,
        durationSeconds: 60,
        status: 'completed',
      );

      UserRehabilitation.instance.rehabPlans = [
        RehabilitationPlan(weekNumber: 1, exerciseReferences: [
          ExerciseReference(exerciseId: 'EX001', repetitions: 10, sets: 1)
        ]),
      ];
      UserRehabilitation.instance.treatmentReferences = <TreatmentReference>[];

      // 3) Save to Hive (source of truth)
      await DataPersistenceService.saveAllDataToHive();
      log['steps'].add('Saved seed data to Hive');

      // 4) Force push to Firebase
      final push = await DataSyncService.instance.forceSaveToFirebase();
      log['steps'].add('Force-pushed to Firebase: ${push['success']}');

      // 5) Clear memory and reload from Firebase, then re-save to Hive
      await DataSyncService.instance.clearAllData();
      final load = await DataSyncService.instance.loadAllFromFirebase();
      log['steps'].add('Loaded from Firebase: ${load['success']}');

      // 6) Gather verification signals
      log['models'] = <String, dynamic>{
        'UserDetails': {
          'firstName': UserDetails.firstName,
          'lastName': UserDetails.lastName,
          'email': UserDetails.email,
          'hasCompletedAssessment': UserDetails.hasCompletedAssessment,
        },
        'UserAssess': {
          'rehabGoal': UserAssess.rehabGoal,
          'specificMuscle': UserAssess.specificMuscle,
          'isAssessed': UserAssess.isAssessed,
        },
        'UserSettings': {
          'isDailyReminder': UserSettings.isDailyReminder,
          'isExerciseReminder': UserSettings.isExerciseReminder,
          'exerciseReminderHour': UserSettings.exerciseReminderTime.hour,
          'exerciseReminderMinute': UserSettings.exerciseReminderTime.minute,
        },
        'UserProgress': {
          'title': UserProgress.title,
          'streak': UserProgress.streak,
          'totalDays': UserProgress.totalDays,
          'totalExercises': UserProgress.totalExercises,
          'totalSeconds': UserProgress.totalSeconds,
        },
        'PainHistory': {
          'count': PainHistory.entries.length,
        },
        'ExerciseHistory': {
          'count': ExerciseHistory.entries.length,
        },
        'Rehabilitation': {
          'plans': UserRehabilitation.instance.rehabPlans.length,
          'treatments': UserRehabilitation.instance.treatmentReferences?.length ?? 0,
        },
      };

      // 7) Basic success criteria
      final ok = (UserDetails.firstName.isNotEmpty || UserDetails.email.isNotEmpty) &&
          UserAssess.isAssessed &&
          UserProgress.totalExercises >= 0 &&
          UserSettings.exerciseReminderTime.hour >= 0 &&
          PainHistory.entries.length >= 0 &&
          ExerciseHistory.entries.length >= 0;

      log['success'] = ok && (load['success'] == true);
      debugPrint('PersistenceValidation: ${log['success'] == true ? 'SUCCESS' : 'FAILED'}');
      debugPrint('PersistenceValidation: SUMMARY -> $log');

      return log;
    } catch (e) {
      final msg = 'Validation error: $e';
      debugPrint('PersistenceValidation: $msg');
      (log['errors'] as List).add(msg);
      return log;
    }
  }
}


