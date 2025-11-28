import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/globals.dart';
import '../../data/rehabilitation_plan.dart';
import '../../data/data_persistence_service.dart';
import '../../data/firebase_helper.dart';

/// Repository for reports data with Hive and Firebase integration
class ReportsRepository {
  static final ReportsRepository _instance = ReportsRepository._internal();
  static ReportsRepository get instance => _instance;
  ReportsRepository._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get rehabilitation plans from local storage with Firebase sync
  Future<List<RehabilitationPlan>> getRehabilitationPlans() async {
    try {
      debugPrint('ReportsRepository: Loading rehabilitation plans...');
      
      // Try to load from local storage first
      try {
        await DataPersistenceService.loadAllDataFromHive();
      } catch (e) {
        debugPrint('ReportsRepository: Error loading from Hive, continuing with in-memory data: $e');
        // Continue with whatever data is already in memory
      }
      
      final userRehab = UserRehabilitation.instance;
      final plans = userRehab.rehabPlans.isNotEmpty ? userRehab.rehabPlans : <RehabilitationPlan>[];
      
      debugPrint('ReportsRepository: Loaded ${plans.length} rehabilitation plans from local storage');
      
      // Attempt Firebase sync in background (non-blocking)
      if (plans.isNotEmpty) {
        _syncRehabPlansToFirebase(plans).catchError((e) {
          debugPrint('ReportsRepository: Firebase sync failed: $e');
        });
      }
      
      return plans;
      
    } catch (e, stackTrace) {
      debugPrint('ReportsRepository: Error loading rehabilitation plans: $e');
      debugPrint('ReportsRepository: Stack trace: $stackTrace');
      // Return empty list instead of rethrowing to prevent blank page
      return <RehabilitationPlan>[];
    }
  }

  /// Get exercise history from local storage with Firebase sync
  Future<List<ExerciseRecordEntry>> getExerciseHistory({bool forceRefresh = false}) async {
    try {
      debugPrint('ReportsRepository: Loading exercise history...');
      
      final user = _auth.currentUser;
      
      // If user is authenticated and not guest, try to load from Firebase first to get all historical data
      if (user != null && !UserDetails.isGuest) {
        try {
          debugPrint('ReportsRepository: Loading exercise history from Firebase...');
          await ExerciseHistory.loadFromFirebase();
          debugPrint('ReportsRepository: Loaded ${ExerciseHistory.entries.length} exercise history entries from Firebase');
          
          // Save to Hive for offline access
          try {
            await ExerciseHistory.saveToHive();
          } catch (e) {
            debugPrint('ReportsRepository: Error saving to Hive after Firebase load: $e');
            // Continue even if Hive save fails
          }
        } catch (e) {
          debugPrint('ReportsRepository: Error loading from Firebase, falling back to Hive: $e');
          // Fall back to Hive if Firebase fails
          try {
            await ExerciseHistory.loadFromHive();
          } catch (hiveError) {
            debugPrint('ReportsRepository: Error loading from Hive: $hiveError');
            // Return empty list if both fail
            return <ExerciseRecordEntry>[];
          }
        }
      } else {
        // For guests or unauthenticated users, load from Hive only
        try {
          await ExerciseHistory.loadFromHive();
        } catch (e) {
          debugPrint('ReportsRepository: Error loading exercise history from Hive: $e');
          // Return empty list if Hive load fails
          return <ExerciseRecordEntry>[];
        }
      }
      
      final history = ExerciseHistory.entries.isNotEmpty ? ExerciseHistory.entries : <ExerciseRecordEntry>[];
      debugPrint('ReportsRepository: Loaded ${history.length} exercise history entries total');
      
      // Attempt Firebase sync in background (only if not already synced)
      if (!forceRefresh && user != null && !UserDetails.isGuest && history.isNotEmpty) {
        _syncExerciseHistoryToFirebase(history).catchError((e) {
          debugPrint('ReportsRepository: Firebase sync failed: $e');
        });
      }
      
      return history;
      
    } catch (e, stackTrace) {
      debugPrint('ReportsRepository: Error loading exercise history: $e');
      debugPrint('ReportsRepository: Stack trace: $stackTrace');
      // Return empty list instead of rethrowing to prevent blank page
      return <ExerciseRecordEntry>[];
    }
  }

  /// Get pain history from local storage with Firebase sync
  Future<List<PainRecordEntry>> getPainHistory({bool forceRefresh = false}) async {
    try {
      debugPrint('ReportsRepository: Loading pain history...');
      
      final user = _auth.currentUser;
      
      // If user is authenticated and not guest, try to load from Firebase first to get all historical data
      if (user != null && !UserDetails.isGuest) {
        try {
          debugPrint('ReportsRepository: Loading pain history from Firebase...');
          await PainHistory.loadFromFirebase();
          debugPrint('ReportsRepository: Loaded ${PainHistory.entries.length} pain history entries from Firebase');
          
          // Save to Hive for offline access
          try {
            await PainHistory.saveToHive();
          } catch (e) {
            debugPrint('ReportsRepository: Error saving to Hive after Firebase load: $e');
            // Continue even if Hive save fails
          }
        } catch (e) {
          debugPrint('ReportsRepository: Error loading from Firebase, falling back to Hive: $e');
          // Fall back to Hive if Firebase fails
          try {
            await PainHistory.loadFromHive();
          } catch (hiveError) {
            debugPrint('ReportsRepository: Error loading from Hive: $hiveError');
            // Return empty list if both fail
            return <PainRecordEntry>[];
          }
        }
      } else {
        // For guests or unauthenticated users, load from Hive only
        try {
          await PainHistory.loadFromHive();
        } catch (e) {
          debugPrint('ReportsRepository: Error loading pain history from Hive: $e');
          // Return empty list if Hive load fails
          return <PainRecordEntry>[];
        }
      }
      
      final history = PainHistory.entries.isNotEmpty ? PainHistory.entries : <PainRecordEntry>[];
      debugPrint('ReportsRepository: Loaded ${history.length} pain history entries total');
      
      // Attempt Firebase sync in background (only if not already synced)
      if (!forceRefresh && user != null && !UserDetails.isGuest && history.isNotEmpty) {
        _syncPainHistoryToFirebase(history).catchError((e) {
          debugPrint('ReportsRepository: Firebase sync failed: $e');
        });
      }
      
      return history;
      
    } catch (e, stackTrace) {
      debugPrint('ReportsRepository: Error loading pain history: $e');
      debugPrint('ReportsRepository: Stack trace: $stackTrace');
      // Return empty list instead of rethrowing to prevent blank page
      return <PainRecordEntry>[];
    }
  }

  /// Get user progress data
  Future<UserProgressData> getUserProgress() async {
    try {
      debugPrint('ReportsRepository: Loading user progress...');
      
      await UserProgress.loadFromHive();
      
      return UserProgressData(
        title: UserProgress.title,
        streak: UserProgress.streak,
        totalDays: UserProgress.totalDays,
        totalExercises: UserProgress.totalExercises,
        totalMinutes: UserProgress.totalMinutes,
        notes: UserProgress.notes,
        lastExerciseDate: UserProgress.lastExerciseDate,
      );
      
    } catch (e) {
      debugPrint('ReportsRepository: Error loading user progress: $e');
      rethrow;
    }
  }

  /// Get user assessment data from local storage
  Future<UserAssessmentData> getUserAssessment() async {
    try {
      debugPrint('ReportsRepository: Loading user assessment...');
      
      await UserAssess.loadFromHive();
      
      return UserAssessmentData(
        specificMuscle: UserAssess.specificMuscle,
        painDuration: UserAssess.painDuration,
        painLevel: UserAssess.painLevel,
        rehabGoal: UserAssess.rehabGoal,
        painType: UserAssess.painType,
      );
      
    } catch (e) {
      debugPrint('ReportsRepository: Error loading user assessment: $e');
      rethrow;
    }
  }

  /// Get assessment data from Firebase
  Future<Map<String, dynamic>?> getAssessmentDataFromFirebase({bool forceRefresh = false}) async {
    try {
      debugPrint('ReportsRepository: Loading assessment data from Firebase...');
      
      final user = _auth.currentUser;
      if (user == null || UserDetails.isGuest) {
        debugPrint('ReportsRepository: No authenticated user or guest user, skipping Firebase load');
        return null;
      }

      final DocumentSnapshot doc = await _firestore
          .collection('assessment')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        debugPrint('ReportsRepository: Successfully loaded assessment data from Firebase');
        return data;
      } else {
        debugPrint('ReportsRepository: No assessment document found in Firebase');
        return null;
      }
    } catch (e) {
      debugPrint('ReportsRepository: Error loading assessment data from Firebase: $e');
      rethrow;
    }
  }

  /// Get user details
  Future<UserDetailsData> getUserDetails() async {
    try {
      debugPrint('ReportsRepository: Loading user details...');
      
      await UserDetails.loadFromHive();
      
      return UserDetailsData(
        firstName: UserDetails.firstName,
        lastName: UserDetails.lastName,
        email: UserDetails.email,
        isGuest: UserDetails.isGuest,
        hasCompletedAssessment: UserDetails.hasCompletedAssessment,
        lastModified: UserDetails.lastModified,
      );
      
    } catch (e) {
      debugPrint('ReportsRepository: Error loading user details: $e');
      rethrow;
    }
  }

  /// Sync rehabilitation plans to Firebase
  Future<void> _syncRehabPlansToFirebase(List<RehabilitationPlan> plans) async {
    final user = _auth.currentUser;
    if (user == null || UserDetails.isGuest) return;

    try {
      debugPrint('ReportsRepository: Syncing rehabilitation plans to Firebase...');
      
      await FirebaseHelper.initializeUserCollections();
      
      // Convert plans to serializable format
      final plansData = plans.map((plan) => {
        'weekNumber': plan.weekNumber,
        'isActive': plan.isActive,
        'createdAt': plan.createdAt.toIso8601String(),
        'exerciseReferences': plan.exerciseReferences.map((ref) => {
          'exerciseId': ref.exerciseId,
          'sets': ref.sets,
          'repetitions': ref.repetitions,
        }).toList(),
        'daily': plan.daily.map((daily) => {
          'date': daily.date.toIso8601String(),
          'completedExercises': daily.completedExercises,
        }).toList(),
      }).toList();
      
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('rehabilitation_plans')
          .doc('plans')
          .set({
        'plans': plansData,
        'lastUpdated': FieldValue.serverTimestamp(),
        'version': '1.0',
      });
      
      debugPrint('ReportsRepository: Successfully synced rehabilitation plans to Firebase');
      
    } catch (e) {
      debugPrint('ReportsRepository: Error syncing rehabilitation plans to Firebase: $e');
      rethrow;
    }
  }

  /// Sync exercise history to Firebase
  Future<void> _syncExerciseHistoryToFirebase(List<ExerciseRecordEntry> history) async {
    final user = _auth.currentUser;
    if (user == null || UserDetails.isGuest) return;

    try {
      debugPrint('ReportsRepository: Syncing exercise history to Firebase...');
      
      await FirebaseHelper.initializeUserCollections();
      
      // Convert history to serializable format
      final historyData = history.map((entry) => {
        'date': entry.date.toIso8601String(),
        'exerciseId': entry.exerciseId,
        'exerciseName': entry.exerciseName,
        'sets': entry.sets,
        'reps': entry.reps,
        'durationSeconds': entry.durationSeconds,
        'status': entry.status,
      }).toList();
      
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('exercise_history')
          .doc('history')
          .set({
        'entries': historyData,
        'lastUpdated': FieldValue.serverTimestamp(),
        'version': '1.0',
      });
      
      debugPrint('ReportsRepository: Successfully synced exercise history to Firebase');
      
    } catch (e) {
      debugPrint('ReportsRepository: Error syncing exercise history to Firebase: $e');
      rethrow;
    }
  }

  /// Sync pain history to Firebase
  Future<void> _syncPainHistoryToFirebase(List<PainRecordEntry> history) async {
    final user = _auth.currentUser;
    if (user == null || UserDetails.isGuest) return;

    try {
      debugPrint('ReportsRepository: Syncing pain history to Firebase...');
      
      await FirebaseHelper.initializeUserCollections();
      
      // Convert history to serializable format
      final historyData = history.map((entry) => {
        'date': entry.date.toIso8601String(),
        'painScale': entry.painScale,
        'painLevel': entry.painLevel,
      }).toList();
      
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('pain_history')
          .doc('history')
          .set({
        'entries': historyData,
        'lastUpdated': FieldValue.serverTimestamp(),
        'version': '1.0',
      });
      
      debugPrint('ReportsRepository: Successfully synced pain history to Firebase');
      
    } catch (e) {
      debugPrint('ReportsRepository: Error syncing pain history to Firebase: $e');
      rethrow;
    }
  }

  /// Force refresh all data from Firebase
  Future<void> refreshFromFirebase() async {
    final user = _auth.currentUser;
    if (user == null || UserDetails.isGuest) return;

    try {
      debugPrint('ReportsRepository: Refreshing data from Firebase...');
      
      await FirebaseHelper.initializeUserCollections();
      
      // Load data from Firebase
      await UserDetails.loadFromFirebase();
      await UserRehabilitation.instance.loadPlansFromFirebase();
      await ExerciseHistory.loadFromFirebase();
      await PainHistory.loadFromFirebase();
      
      // Save to local storage
      await DataPersistenceService.saveAllDataToHive();
      
      debugPrint('ReportsRepository: Successfully refreshed data from Firebase');
      
    } catch (e) {
      debugPrint('ReportsRepository: Error refreshing data from Firebase: $e');
      rethrow;
    }
  }

  /// Check if data is stale and needs refresh
  bool isDataStale({Duration maxAge = const Duration(hours: 1)}) {
    try {
      if (!Hive.isBoxOpen('rehabBox')) return true;
      
      final box = Hive.box('rehabBox');
      final lastSaveTimestamp = box.get('lastSaveTimestamp');
      
      if (lastSaveTimestamp == null) return true;
      
      final lastSave = DateTime.parse(lastSaveTimestamp);
      return DateTime.now().difference(lastSave) > maxAge;
      
    } catch (e) {
      debugPrint('ReportsRepository: Error checking data staleness: $e');
      return true;
    }
  }
}

/// Data models for reports
class UserProgressData {
  final String title;
  final int streak;
  final int totalDays;
  final int totalExercises;
  final int totalMinutes;
  final String? notes;
  final DateTime? lastExerciseDate;

  UserProgressData({
    required this.title,
    required this.streak,
    required this.totalDays,
    required this.totalExercises,
    required this.totalMinutes,
    this.notes,
    this.lastExerciseDate,
  });
}

class UserAssessmentData {
  final String specificMuscle;
  final String painDuration;
  final String painLevel;
  final String rehabGoal;
  final String painType;

  UserAssessmentData({
    required this.specificMuscle,
    required this.painDuration,
    required this.painLevel,
    required this.rehabGoal,
    required this.painType,
  });
}

class UserDetailsData {
  final String firstName;
  final String lastName;
  final String email;
  final bool isGuest;
  final bool hasCompletedAssessment;
  final DateTime? lastModified;

  UserDetailsData({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.isGuest,
    required this.hasCompletedAssessment,
    this.lastModified,
  });
}
