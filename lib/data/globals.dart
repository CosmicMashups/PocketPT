import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'hive_models.dart';
import 'rehabilitation_plan.dart';
import 'data_persistence_service.dart';
import 'firebase_helper.dart';
import 'user_data_notifier.dart';

// Class: AppDetails
class AppDetails {
  static bool isLogin = false;
}

// Class: Details of the User
class UserDetails {
  static String firstName = '';
  static String lastName = '';
  static String email = '';
  static String password = '';
  static String profilePicture = '01.jpg'; // Default profile picture
  static bool hasCompletedAssessment = false;
  static bool isGuest = false;
  static String? guestSessionId;
  static List<String> notifications = [
    // 'You have a new workout plan: Push-Ups 3 sets, 10 reps.',
    // 'Reminder: Complete your lateral raise exercises today.',
    // 'Your streak is 5 days. Keep up the good work!',
    // 'It\'s time for your next workout session.',
    // 'You completed 3 exercises today! Great job.',
    // 'New workout suggestion: 3 sets of Squats.',
    // 'Time to hydrate after your workout. Drink water!',
    // 'You\'ve reached 70% of your weekly goal. Keep going!',
    // 'Reminder: Check your progress and update your stats.',
    // 'You\'ve burned 200 calories today. Well done!',
  ];

  // Firebase instances
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Load user data from Firebase
  static Future<void> loadFromFirebase() async {
    try {
      // Set loading state
      UserDataNotifier.instance.setLoading(true);
      
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('UserDetails.loadFromFirebase: No authenticated user found');
        UserDataNotifier.instance.setLoading(false);
        return;
      }

      debugPrint('UserDetails.loadFromFirebase: Loading data for user: ${currentUser.uid}');
      debugPrint('UserDetails.loadFromFirebase: User email: ${currentUser.email}');
      debugPrint('UserDetails.loadFromFirebase: User displayName: ${currentUser.displayName}');

      // Ensure all collections exist before loading data
      debugPrint('UserDetails.loadFromFirebase: Ensuring all collections exist...');
      try {
        await FirebaseHelper.ensureAllCollectionsExist();
        debugPrint('UserDetails.loadFromFirebase: All collections ensured successfully');
      } catch (e) {
        debugPrint('UserDetails.loadFromFirebase: Warning - Could not ensure all collections: $e');
        // Continue anyway, as the user document might still exist
      }

      // Get user data from Firestore
      final DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      debugPrint('UserDetails.loadFromFirebase: Document exists: ${userDoc.exists}');
      
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        debugPrint('UserDetails.loadFromFirebase: Raw user data: $userData');
        
        final String? firebaseFirstName = userData['firstName'];
        final String? firebaseLastName = userData['lastName'];
        final String? firebaseEmail = userData['email'];
        final String? firebaseProfilePicture = userData['profilePicture'];
        final bool? firebaseHasCompletedAssessment = userData['hasCompletedAssessment'];
        
        debugPrint('UserDetails.loadFromFirebase: Firebase firstName: "$firebaseFirstName"');
        debugPrint('UserDetails.loadFromFirebase: Firebase lastName: "$firebaseLastName"');
        debugPrint('UserDetails.loadFromFirebase: Firebase email: "$firebaseEmail"');
        debugPrint('UserDetails.loadFromFirebase: Firebase hasCompletedAssessment: $firebaseHasCompletedAssessment');
        
        firstName = firebaseFirstName ?? '';
        lastName = firebaseLastName ?? '';
        email = firebaseEmail ?? currentUser.email ?? '';
        profilePicture = firebaseProfilePicture ?? '01.jpg'; // Default to first profile picture
        password = ''; // Never store password in plain text
        hasCompletedAssessment = firebaseHasCompletedAssessment ?? false;
        
        debugPrint('UserDetails.loadFromFirebase: Final values - firstName: "$firstName", lastName: "$lastName", email: "$email"');
        
        // Notify UI of data changes
        UserDataNotifier.instance.updateUserData(
          firstName: firstName,
          lastName: lastName,
          email: email,
          hasCompletedAssessment: hasCompletedAssessment,
        );
        
        // Save to Hive for offline access
        await saveToHive();
      } else {
        debugPrint('UserDetails.loadFromFirebase: User document not found in Firestore, creating new user document');
        
        // Create user document with basic info
        firstName = currentUser.displayName?.split(' ').first ?? '';
        lastName = currentUser.displayName?.split(' ').skip(1).join(' ') ?? '';
        email = currentUser.email ?? '';
        
        debugPrint('UserDetails.loadFromFirebase: Creating document with - firstName: "$firstName", lastName: "$lastName", email: "$email"');
        
        // Create the user document in Firebase
        await _firestore.collection('users').doc(currentUser.uid).set({
          'userId': currentUser.uid,
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
          'lastUpdated': FieldValue.serverTimestamp(),
        });
        
        debugPrint('UserDetails.loadFromFirebase: Created new user document in Firebase: $firstName $lastName ($email)');
        
        // Notify UI of data changes
        UserDataNotifier.instance.updateUserData(
          firstName: firstName,
          lastName: lastName,
          email: email,
          hasCompletedAssessment: hasCompletedAssessment,
        );
        
        // Save to Hive for offline access
        await saveToHive();
      }
      
      // Clear loading state
      UserDataNotifier.instance.setLoading(false);
    } catch (e) {
      debugPrint('UserDetails.loadFromFirebase: Error loading user data from Firebase: $e');
      debugPrint('UserDetails.loadFromFirebase: Error type: ${e.runtimeType}');
      if (e is FirebaseException) {
        debugPrint('UserDetails.loadFromFirebase: Firebase error code: ${e.code}');
        debugPrint('UserDetails.loadFromFirebase: Firebase error message: ${e.message}');
      }
      
      // Clear loading state on error
      UserDataNotifier.instance.setLoading(false);
    }
  }

  // Update user data in Firebase
  static Future<void> updateInFirebase({
    String? newFirstName,
    String? newLastName,
    String? newEmail,
    String? newProfilePicture,
  }) async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      final Map<String, dynamic> updateData = {
        'userId': currentUser.uid,
        'lastUpdated': FieldValue.serverTimestamp(),
      };
      
      if (newFirstName != null) {
        updateData['firstName'] = newFirstName;
        firstName = newFirstName;
      }
      if (newLastName != null) {
        updateData['lastName'] = newLastName;
        lastName = newLastName;
      }
      if (newEmail != null) {
        updateData['email'] = newEmail;
        email = newEmail;
      }
      if (newProfilePicture != null) {
        updateData['profilePicture'] = newProfilePicture;
        profilePicture = newProfilePicture;
      }

      // Use set with merge to create document if it doesn't exist
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .set(updateData, SetOptions(merge: true));
      
      debugPrint('Updated user data in Firebase');
      
      // Notify UI of data changes
      UserDataNotifier.instance.updateUserData(
        firstName: newFirstName,
        lastName: newLastName,
        email: newEmail,
        profilePicture: newProfilePicture,
      );
      
      // Save to Hive for offline access
      await saveToHive();
    } catch (e) {
      debugPrint('Error updating user data in Firebase: $e');
      rethrow;
    }
  }

  // Check if user is authenticated
  static bool get isAuthenticated => _auth.currentUser != null;

  // Get current user ID
  static String? get currentUserId => _auth.currentUser?.uid;
  
  // Check if user data is properly loaded
  static bool get hasUserData => firstName.isNotEmpty || lastName.isNotEmpty || email.isNotEmpty;
  
  // Verify Hive data integrity
  static Future<bool> verifyHiveData() async {
    try {
      if (!Hive.isBoxOpen('rehabBox')) {
        await Hive.openBox('rehabBox');
      }
      
      final box = Hive.box('rehabBox');
      final hiveUserDetails = box.get('userDetails');
      
      if (hiveUserDetails is HiveUserDetails) {
        final hasValidData = hiveUserDetails.firstName.isNotEmpty || 
                            hiveUserDetails.lastName.isNotEmpty || 
                            hiveUserDetails.email.isNotEmpty;
        debugPrint('UserDetails.verifyHiveData: Data integrity check - Valid: $hasValidData');
        debugPrint('UserDetails.verifyHiveData: Stored data - firstName: "${hiveUserDetails.firstName}", lastName: "${hiveUserDetails.lastName}", email: "${hiveUserDetails.email}"');
        return hasValidData;
      }
      
      debugPrint('UserDetails.verifyHiveData: No user data found in Hive');
      return false;
    } catch (e) {
      debugPrint('UserDetails.verifyHiveData: Error verifying Hive data: $e');
      return false;
    }
  }
  
  // Test method to verify offline functionality
  static Future<Map<String, dynamic>> testOfflineFunctionality() async {
    try {
      debugPrint('UserDetails.testOfflineFunctionality: Starting offline test...');
      
      // Save current data to Hive
      await saveToHive();
      debugPrint('UserDetails.testOfflineFunctionality: Data saved to Hive');
      
      // Clear current data
      final originalFirstName = firstName;
      final originalLastName = lastName;
      final originalEmail = email;
      firstName = '';
      lastName = '';
      email = '';
      debugPrint('UserDetails.testOfflineFunctionality: Current data cleared');
      
      // Load from Hive
      await loadFromHive();
      debugPrint('UserDetails.testOfflineFunctionality: Data loaded from Hive');
      
      // Verify data was restored
      final dataRestored = firstName == originalFirstName && 
                          lastName == originalLastName && 
                          email == originalEmail;
      
      debugPrint('UserDetails.testOfflineFunctionality: Data restoration test - Success: $dataRestored');
      debugPrint('UserDetails.testOfflineFunctionality: Restored data - firstName: "$firstName", lastName: "$lastName", email: "$email"');
      
      return {
        'success': dataRestored,
        'originalData': {
          'firstName': originalFirstName,
          'lastName': originalLastName,
          'email': originalEmail,
        },
        'restoredData': {
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
        },
        'message': dataRestored ? 'Offline functionality working correctly' : 'Offline functionality failed'
      };
    } catch (e) {
      debugPrint('UserDetails.testOfflineFunctionality: Error during test: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Offline functionality test failed'
      };
    }
  }

  // Ensure all Firebase collections exist for the current user
  static Future<Map<String, dynamic>> ensureAllCollectionsExist() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        return {
          'success': false,
          'error': 'No authenticated user found',
        };
      }

      debugPrint('UserDetails.ensureAllCollectionsExist: Ensuring all collections for user: ${currentUser.uid}');
      
      // Use the comprehensive collection creation method
      final results = await FirebaseHelper.ensureAllCollectionsExist();
      
      debugPrint('UserDetails.ensureAllCollectionsExist: Collection creation results: $results');
      
      return results;
    } catch (e) {
      debugPrint('UserDetails.ensureAllCollectionsExist: Error ensuring collections: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Mark assessment as completed
  static Future<void> markAssessmentCompleted() async {
    try {
      hasCompletedAssessment = true;
      
      // Update in Firebase
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        await _firestore.collection('users').doc(currentUser.uid).update({
          'hasCompletedAssessment': true,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }
      
      // Save to Hive
      await saveToHive();
      
      debugPrint('Assessment marked as completed');
    } catch (e) {
      debugPrint('Error marking assessment as completed: $e');
    }
  }

  // Clear user data (for logout)
  static void clearUserData() {
    firstName = '';
    lastName = '';
    email = '';
    password = '';
    hasCompletedAssessment = false;
    isGuest = false;
    guestSessionId = null;
    notifications.clear();
    debugPrint('User data cleared');
  }

  // Sign out user and clear data
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
      clearUserData();
      debugPrint('User signed out successfully');
    } catch (e) {
      debugPrint('Error signing out: $e');
      rethrow;
    }
  }

  // Hive persistence methods
  static Future<void> saveToHive() async {
    try {
      // Check if Hive box is open
      if (!Hive.isBoxOpen('rehabBox')) {
        debugPrint('UserDetails.saveToHive: Hive box not open, attempting to open...');
        await Hive.openBox('rehabBox');
      }
      
      final box = Hive.box('rehabBox');
      final hiveUserDetails = HiveUserDetails(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
        notifications: List<String>.from(notifications),
        isGuest: isGuest,
        guestSessionId: guestSessionId,
        profilePicture: profilePicture,
      );
      
      await box.put('userDetails', hiveUserDetails);
      // Persist assessment completion flag separately to avoid adapter changes
      await box.put('hasCompletedAssessment', hasCompletedAssessment);
      
      debugPrint('UserDetails.saveToHive: Successfully saved - firstName: "$firstName", lastName: "$lastName", email: "$email", isGuest: $isGuest');
      
      // Trigger auto-save
      DataPersistenceService.instance.triggerSave(reason: 'User details updated');
    } catch (e) {
      debugPrint('UserDetails.saveToHive: Error saving to Hive: $e');
      debugPrint('UserDetails.saveToHive: Error type: ${e.runtimeType}');
      rethrow;
    }
  }

  static Future<void> loadFromHive() async {
    try {
      // Check if Hive box is open
      if (!Hive.isBoxOpen('rehabBox')) {
        debugPrint('UserDetails.loadFromHive: Hive box not open, attempting to open...');
        await Hive.openBox('rehabBox');
      }
      
      final box = Hive.box('rehabBox');
      final hiveUserDetails = box.get('userDetails');
      
      if (hiveUserDetails is HiveUserDetails) {
        firstName = hiveUserDetails.firstName;
        lastName = hiveUserDetails.lastName;
        email = hiveUserDetails.email;
        password = hiveUserDetails.password;
        notifications = List<String>.from(hiveUserDetails.notifications);
        isGuest = hiveUserDetails.isGuest;
        guestSessionId = hiveUserDetails.guestSessionId;
        profilePicture = hiveUserDetails.profilePicture;
        
        // Load assessment completion flag if present
        final storedHasCompleted = box.get('hasCompletedAssessment');
        if (storedHasCompleted is bool) {
          hasCompletedAssessment = storedHasCompleted;
        }
        
        debugPrint('UserDetails.loadFromHive: Successfully loaded - firstName: "$firstName", lastName: "$lastName", email: "$email", isGuest: $isGuest');
        
        // Notify UI of data changes
        UserDataNotifier.instance.updateUserData(
          firstName: firstName,
          lastName: lastName,
          email: email,
          hasCompletedAssessment: hasCompletedAssessment,
        );
      } else {
        debugPrint('UserDetails.loadFromHive: No user details found in Hive');
        // Try to load from Firebase if no local data exists
        try {
          await loadFromFirebase();
        } catch (firebaseError) {
          debugPrint('UserDetails.loadFromHive: Firebase fallback failed: $firebaseError');
          // Set default values if both Hive and Firebase fail
          firstName = '';
          lastName = '';
          email = '';
          password = '';
          hasCompletedAssessment = false;
          isGuest = false;
          guestSessionId = null;
          notifications = [];
        }
      }
    } catch (e) {
      debugPrint('UserDetails.loadFromHive: Error loading from Hive: $e');
      debugPrint('UserDetails.loadFromHive: Error type: ${e.runtimeType}');
      
      // Fallback to Firebase if Hive fails
      try {
        debugPrint('UserDetails.loadFromHive: Attempting Firebase fallback...');
        await loadFromFirebase();
      } catch (firebaseError) {
        debugPrint('UserDetails.loadFromHive: Firebase fallback failed: $firebaseError');
        // Set default values if both Hive and Firebase fail
        firstName = '';
        lastName = '';
        email = '';
        password = '';
        hasCompletedAssessment = false;
        isGuest = false;
        guestSessionId = null;
        notifications = [];
        
        // Notify UI with empty data
        UserDataNotifier.instance.updateUserData(
          firstName: firstName,
          lastName: lastName,
          email: email,
          hasCompletedAssessment: hasCompletedAssessment,
        );
      }
    }
  }
}

// Class: Tracking the progress of the user
class UserProgress {
  static String title = 'Initiator';
  static String titleColor = '';
  static int streak = 0;
  static int totalDays = 0;
  static int totalExercises = 0;
  static int totalMinutes = (totalSeconds / 60).toInt();
  static int totalSeconds = 0;
  static String? notes;
  static DateTime? lastExerciseDate;

  // Hive persistence methods
  static Future<void> saveToHive() async {
    try {
      final box = Hive.box('rehabBox');
      final hiveUserProgress = HiveUserProgress(
        title: title,
        titleColor: titleColor,
        streak: streak,
        totalDays: totalDays,
        totalExercises: totalExercises,
        totalSeconds: totalSeconds,
        notes: notes,
        lastExerciseDate: lastExerciseDate,
      );
      await box.put('userProgress', hiveUserProgress);
      debugPrint('Saved user progress to Hive');
      
      // Trigger auto-save
      DataPersistenceService.instance.triggerSave(reason: 'User progress updated');
    } catch (e) {
      debugPrint('Error saving user progress to Hive: $e');
      rethrow;
    }
  }

  static Future<void> loadFromHive() async {
    try {
      final box = Hive.box('rehabBox');
      final hiveUserProgress = box.get('userProgress');
      if (hiveUserProgress is HiveUserProgress) {
        title = hiveUserProgress.title;
        titleColor = hiveUserProgress.titleColor;
        streak = hiveUserProgress.streak;
        totalDays = hiveUserProgress.totalDays;
        totalExercises = hiveUserProgress.totalExercises;
        totalSeconds = hiveUserProgress.totalSeconds;
        notes = hiveUserProgress.notes;
        lastExerciseDate = hiveUserProgress.lastExerciseDate;
        debugPrint('Loaded user progress from Hive: $title, streak: $streak, total exercises: $totalExercises');
      } else {
        debugPrint('No user progress found in Hive, using defaults');
      }
    } catch (e) {
      debugPrint('Error loading user progress from Hive: $e');
    }
  }
}

// Class: Initial Assessment Data
class UserAssess {
  static String rehabGoal = '';
  static String generalMuscle = '';
  static String specificMuscle = '';
  static File? painVideo;
  static int painScale = 0;
  static String painLevel = '';
  static String painType = '';
  static String painDuration = '';
  static bool isInjured = false;
  static bool isAssessed = false;

  // Hive persistence methods
  static Future<void> saveToHive() async {
    try {
      final box = Hive.box('rehabBox');
      final hiveUserAssess = HiveUserAssess(
        rehabGoal: rehabGoal,
        generalMuscle: generalMuscle,
        specificMuscle: specificMuscle,
        painScale: painScale,
        painLevel: painLevel,
        painType: painType,
        painDuration: painDuration,
        isInjured: isInjured,
        isAssessed: isAssessed,
      );
      await box.put('userAssess', hiveUserAssess);
      debugPrint('Saved user assessment to Hive');
      
      // Trigger auto-save
      DataPersistenceService.instance.triggerSave(reason: 'User assessment updated');
    } catch (e) {
      debugPrint('Error saving user assessment to Hive: $e');
      rethrow;
    }
  }

  static Future<void> loadFromHive() async {
    try {
      final box = Hive.box('rehabBox');
      final hiveUserAssess = box.get('userAssess');
      if (hiveUserAssess is HiveUserAssess) {
        rehabGoal = hiveUserAssess.rehabGoal;
        generalMuscle = hiveUserAssess.generalMuscle;
        specificMuscle = hiveUserAssess.specificMuscle;
        painScale = hiveUserAssess.painScale;
        painLevel = hiveUserAssess.painLevel;
        painType = hiveUserAssess.painType;
        painDuration = hiveUserAssess.painDuration;
        isInjured = hiveUserAssess.isInjured;
        isAssessed = hiveUserAssess.isAssessed;
        debugPrint('Loaded user assessment from Hive');
      } else {
        debugPrint('No user assessment data found in Hive, using defaults');
      }
    } catch (e) {
      debugPrint('Error loading user assessment from Hive: $e');
    }
  }
}

// Class: Preferences of the User
class UserSettings {
  static bool isDailyReminder = true; // Pain assessment / general prompts
  static bool isStreakAlert = true;
  static bool isExerciseReminder = true; // 08:00 AM exercise reminder toggle
  static TimeOfDay exerciseReminderTime = const TimeOfDay(hour: 8, minute: 0);

  // Hive persistence methods
  static Future<void> saveToHive() async {
    try {
      final box = Hive.box('rehabBox');
      final hiveUserSettings = HiveUserSettings(
        isDailyReminder: isDailyReminder,
        isStreakAlert: isStreakAlert,
        isExerciseReminder: isExerciseReminder,
        exerciseReminderHour: exerciseReminderTime.hour,
        exerciseReminderMinute: exerciseReminderTime.minute,
      );
      await box.put('userSettings', hiveUserSettings);
      debugPrint('Saved user settings to Hive');
      
      // Trigger auto-save
      DataPersistenceService.instance.triggerSave(reason: 'User settings updated');
    } catch (e) {
      debugPrint('Error saving user settings to Hive: $e');
      rethrow;
    }
  }

  static Future<void> loadFromHive() async {
    try {
      final box = Hive.box('rehabBox');
      final hiveUserSettings = box.get('userSettings');
      if (hiveUserSettings is HiveUserSettings) {
        isDailyReminder = hiveUserSettings.isDailyReminder;
        isStreakAlert = hiveUserSettings.isStreakAlert;
        isExerciseReminder = hiveUserSettings.isExerciseReminder;
        exerciseReminderTime = TimeOfDay(
          hour: hiveUserSettings.exerciseReminderHour,
          minute: hiveUserSettings.exerciseReminderMinute,
        );
        debugPrint('Loaded user settings from Hive: daily reminder: $isDailyReminder, exercise reminder: $isExerciseReminder at ${exerciseReminderTime.hour}:${exerciseReminderTime.minute.toString().padLeft(2, '0')}');
      } else {
        debugPrint('No user settings found in Hive, using defaults');
      }
    } catch (e) {
      debugPrint('Error loading user settings from Hive: $e');
    }
  }
}

// Class: Active Program metadata
class ActiveProgram {
  static DateTime? startDate;

  // Hive persistence methods
  static Future<void> saveToHive() async {
    try {
      final box = Hive.box('rehabBox');
      final hiveActiveProgram = HiveActiveProgram(startDate: startDate);
      await box.put('activeProgram', hiveActiveProgram);
      debugPrint('Saved active program to Hive');
      
      // Trigger auto-save
      DataPersistenceService.instance.triggerSave(reason: 'Active program updated');
    } catch (e) {
      debugPrint('Error saving active program to Hive: $e');
      rethrow;
    }
  }

  static Future<void> loadFromHive() async {
    try {
      final box = Hive.box('rehabBox');
      final hiveActiveProgram = box.get('activeProgram');
      if (hiveActiveProgram is HiveActiveProgram) {
        startDate = hiveActiveProgram.startDate;
        debugPrint('Loaded active program from Hive: start date: ${startDate?.toString() ?? 'null'}');
      } else {
        debugPrint('No active program found in Hive, using defaults');
      }
    } catch (e) {
      debugPrint('Error loading active program from Hive: $e');
    }
  }
}

// Class: Pain Assessment History Tracking
class PainRecordEntry {
  final DateTime date;
  final int painScale;
  final String painLevel;

  const PainRecordEntry({
    required this.date,
    required this.painScale,
    required this.painLevel,
  });
}

// Class: Exercise Completion History Tracking
class ExerciseRecordEntry {
  final DateTime date;
  final String exerciseId;
  final String exerciseName;
  final int sets;
  final int reps;
  final int durationSeconds;
  final String status; // 'completed', 'skipped', 'partial'

  const ExerciseRecordEntry({
    required this.date,
    required this.exerciseId,
    required this.exerciseName,
    required this.sets,
    required this.reps,
    required this.durationSeconds,
    required this.status,
  });
}

class PainHistory {
  // Stores all historical pain entries in chronological order (oldest -> newest)
  static final List<PainRecordEntry> entries = <PainRecordEntry>[];

  // Tracks the last date we showed the "pain changed" dialog to avoid spamming
  static DateTime? _lastPromptedDate;

  // Add or update today's entry. If an entry for today exists, replace it with the latest
  static void recordToday({required int painScale, required String painLevel, DateTime? now}) {
    final DateTime today = _toDateOnly(now ?? DateTime.now());
    final int existingIndex = entries.lastIndexWhere((e) => _isSameDate(e.date, today));

    final PainRecordEntry newEntry = PainRecordEntry(
      date: today,
      painScale: painScale,
      painLevel: painLevel,
    );

    if (existingIndex >= 0) {
      entries[existingIndex] = newEntry;
    } else {
      entries.add(newEntry);
    }
  }

  // Returns the latest entry strictly before today, or null if none
  static PainRecordEntry? latestEntryBeforeToday({DateTime? now}) {
    final DateTime today = _toDateOnly(now ?? DateTime.now());
    for (int i = entries.length - 1; i >= 0; i--) {
      if (entries[i].date.isBefore(today)) {
        return entries[i];
      }
    }
    return null;
  }

  // Returns today's entry if present
  static PainRecordEntry? todaysEntry({DateTime? now}) {
    final DateTime today = _toDateOnly(now ?? DateTime.now());
    try {
      return entries.firstWhere((e) => _isSameDate(e.date, today));
    } catch (_) {
      return null;
    }
  }

  // Determines if we should prompt the user today due to a change vs yesterday
  static bool shouldPromptForRetake({DateTime? now}) {
    final DateTime today = _toDateOnly(now ?? DateTime.now());
    // Only one prompt per calendar day
    if (_lastPromptedDate != null && _isSameDate(_lastPromptedDate!, today)) {
      return false;
    }

    final PainRecordEntry? todayEntry = todaysEntry(now: today);
    final PainRecordEntry? priorEntry = latestEntryBeforeToday(now: today);

    if (todayEntry == null || priorEntry == null) {
      return false; // Need both to compare
    }

    return todayEntry.painScale != priorEntry.painScale;
  }

  static void markPromptedToday({DateTime? now}) {
    _lastPromptedDate = _toDateOnly(now ?? DateTime.now());
  }

  static DateTime _toDateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
  static bool _isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // Convenience getters for reports
  static List<int> getAllPainScales() => entries.map((e) => e.painScale).toList(growable: false);
  static List<String> getAllPainLevels() => entries.map((e) => e.painLevel).toList(growable: false);
  static List<DateTime> getAllDates() => entries.map((e) => e.date).toList(growable: false);

  // Check if painScale has stayed the same for N consecutive calendar days including today
  static bool hasSamePainForConsecutiveDays(int days, {DateTime? now}) {
    if (entries.length < days) return false;
    final DateTime today = _toDateOnly(now ?? DateTime.now());
    // Build a map of dateOnly -> painScale for quick access
    final Map<DateTime, int> byDate = {};
    for (final e in entries) {
      byDate[_toDateOnly(e.date)] = e.painScale;
    }
    int? baseline;
    for (int i = 0; i < days; i++) {
      final DateTime d = _toDateOnly(today.subtract(Duration(days: i)));
      if (!byDate.containsKey(d)) return false; // missing day
      final int current = byDate[d]!;
      baseline ??= current;
      if (current != baseline) return false;
    }
    return true;
  }

  // Hive persistence methods
  static Future<void> saveToHive() async {
    try {
      final box = Hive.box('rehabBox');
      final hiveEntries = entries.map((e) => HivePainRecordEntry.fromPainRecordEntry(e)).toList();
      await box.put('painHistory', hiveEntries);
      debugPrint('Saved ${entries.length} pain history entries to Hive');
      
      // Trigger auto-save
      DataPersistenceService.instance.triggerSave(reason: 'Pain history updated');
    } catch (e) {
      debugPrint('Error saving pain history to Hive: $e');
      rethrow;
    }
  }

  static Future<void> loadFromHive() async {
    try {
      final box = Hive.box('rehabBox');
      final hiveEntries = box.get('painHistory', defaultValue: <HivePainRecordEntry>[]);
      if (hiveEntries is List<HivePainRecordEntry>) {
        entries.clear();
        entries.addAll(hiveEntries.map((he) => he.toPainRecordEntry()));
        debugPrint('Loaded ${entries.length} pain history entries from Hive');
      }
    } catch (e) {
      debugPrint('Error loading pain history from Hive: $e');
      // Reset to empty state on error
      entries.clear();
    }
  }

  // Enhanced recordToday method that also saves to Hive
  static Future<void> recordTodayAndSave({required int painScale, required String painLevel, DateTime? now}) async {
    recordToday(painScale: painScale, painLevel: painLevel, now: now);
    await saveToHive();
  }
}

class ExerciseHistory {
  // Stores all historical exercise entries in chronological order (oldest -> newest)
  static final List<ExerciseRecordEntry> entries = <ExerciseRecordEntry>[];

  // Add or update today's exercise entry
  static void recordToday({
    required String exerciseId,
    required String exerciseName,
    required int sets,
    required int reps,
    required int durationSeconds,
    required String status,
    DateTime? now,
  }) {
    final DateTime today = _toDateOnly(now ?? DateTime.now());
    
    // Remove any existing entry for this exercise on this date
    entries.removeWhere((e) => 
      _isSameDate(e.date, today) && e.exerciseId == exerciseId);

    final ExerciseRecordEntry newEntry = ExerciseRecordEntry(
      date: today,
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      sets: sets,
      reps: reps,
      durationSeconds: durationSeconds,
      status: status,
    );

    entries.add(newEntry);
  }

  // Get all exercises completed on a specific date
  static List<ExerciseRecordEntry> getExercisesForDate(DateTime date) {
    final DateTime dateOnly = _toDateOnly(date);
    return entries.where((e) => _isSameDate(e.date, dateOnly)).toList();
  }

  // Check if user has completed any exercises on a specific date
  static bool hasExercisesOnDate(DateTime date) {
    final DateTime dateOnly = _toDateOnly(date);
    return entries.any((e) => _isSameDate(e.date, dateOnly) && e.status == 'completed');
  }

  // Get total exercises completed on a specific date
  static int getCompletedExercisesCountForDate(DateTime date) {
    final DateTime dateOnly = _toDateOnly(date);
    return entries.where((e) => 
      _isSameDate(e.date, dateOnly) && e.status == 'completed').length;
  }

  // Helper method to convert DateTime to date only (removes time)
  static DateTime _toDateOnly(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }

  // Helper method to check if two dates are the same (date only)
  static bool _isSameDate(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  // Hive persistence methods
  static Future<void> saveToHive() async {
    try {
      final box = Hive.box('rehabBox');
      final hiveEntries = entries.map((e) => HiveExerciseRecordEntry.fromExerciseRecordEntry(e)).toList();
      await box.put('exerciseHistory', hiveEntries);
      debugPrint('Saved ${entries.length} exercise history entries to Hive');
      
      // Trigger auto-save
      DataPersistenceService.instance.triggerSave(reason: 'Exercise history updated');
    } catch (e) {
      debugPrint('Error saving exercise history to Hive: $e');
      rethrow;
    }
  }

  static Future<void> loadFromHive() async {
    try {
      final box = Hive.box('rehabBox');
      final hiveEntries = box.get('exerciseHistory', defaultValue: <HiveExerciseRecordEntry>[]);
      if (hiveEntries is List<HiveExerciseRecordEntry>) {
        entries.clear();
        entries.addAll(hiveEntries.map((he) => he.toExerciseRecordEntry()));
        debugPrint('Loaded ${entries.length} exercise history entries from Hive');
      }
    } catch (e) {
      debugPrint('Error loading exercise history from Hive: $e');
      // Reset to empty state on error
      entries.clear();
    }
  }

  // Enhanced recordToday method that also saves to Hive
  static Future<void> recordTodayAndSave({
    required String exerciseId,
    required String exerciseName,
    required int sets,
    required int reps,
    required int durationSeconds,
    required String status,
    DateTime? now,
  }) async {
    recordToday(
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      sets: sets,
      reps: reps,
      durationSeconds: durationSeconds,
      status: status,
      now: now,
    );
    await saveToHive();
  }

  // Calculate today's exercise progress percentage based on current rehabilitation plan
  static double calculateTodaysProgressPercentage() {
    final rehabPlans = UserRehabilitation.instance.rehabPlans;
    if (rehabPlans.isEmpty) return 0.0;

    final plan = rehabPlans.first;
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    
    // Get all exercises for today
    final todayExercises = getExercisesForDate(todayDate);
    
    // If no exercises recorded today, return 0%
    if (todayExercises.isEmpty) return 0.0;
    
    // Calculate progress based on exercise status
    double totalProgress = 0.0;
    final totalExercises = plan.exerciseReferences.length;
    
    for (final exerciseRef in plan.exerciseReferences) {
      final exerciseRecord = todayExercises.firstWhere(
        (record) => record.exerciseId == exerciseRef.exerciseId,
        orElse: () => ExerciseRecordEntry(
          date: todayDate,
          exerciseId: exerciseRef.exerciseId,
          exerciseName: 'Exercise ${exerciseRef.exerciseId}', // Placeholder name
          sets: exerciseRef.sets,
          reps: exerciseRef.repetitions,
          durationSeconds: 0,
          status: 'not_started',
        ),
      );
      
      // Calculate progress for this exercise based on status
      switch (exerciseRecord.status) {
        case 'completed':
          totalProgress += 1.0; // 100% for completed exercises
          break;
        case 'partial':
          totalProgress += 0.5; // 50% for partially completed exercises
          break;
        case 'skipped':
          totalProgress += 0.0; // 0% for skipped exercises
          break;
        case 'not_started':
        default:
          totalProgress += 0.0; // 0% for not started exercises
          break;
      }
    }
    
    // Return percentage (0.0 to 1.0)
    return totalExercises > 0 ? totalProgress / totalExercises : 0.0;
  }

  // Get the current exercise the user should be working on (next incomplete exercise)
  static Exercise? getCurrentExercise() {
    final rehabPlans = UserRehabilitation.instance.rehabPlans;
    if (rehabPlans.isEmpty) return null;

    final plan = rehabPlans.first;
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    
    // Get all exercises for today
    final todayExercises = getExercisesForDate(todayDate);
    
    // Find the first exercise that is not completed
    for (final exerciseRef in plan.exerciseReferences) {
      final exerciseRecord = todayExercises.firstWhere(
        (record) => record.exerciseId == exerciseRef.exerciseId,
        orElse: () => ExerciseRecordEntry(
          date: todayDate,
          exerciseId: exerciseRef.exerciseId,
          exerciseName: 'Exercise ${exerciseRef.exerciseId}', // Placeholder name
          sets: exerciseRef.sets,
          reps: exerciseRef.repetitions,
          durationSeconds: 0,
          status: 'not_started',
        ),
      );
      
      if (exerciseRecord.status != 'completed') {
        // Return a placeholder exercise with the reference data
        return Exercise(
          exerciseId: exerciseRef.exerciseId,
          exerciseName: 'Exercise ${exerciseRef.exerciseId}',
          description: 'Exercise from plan',
          muscle: 'Unknown',
          painLevel: 'Unknown',
          goal: 'Unknown',
          repetitions: exerciseRef.repetitions,
          sets: exerciseRef.sets,
          imageUrl: '',
          videoUrl: '',
        );
      }
    }
    
    // If all exercises are completed, return the last exercise
    if (plan.exerciseReferences.isNotEmpty) {
      final lastRef = plan.exerciseReferences.last;
      return Exercise(
        exerciseId: lastRef.exerciseId,
        exerciseName: 'Exercise ${lastRef.exerciseId}',
        description: 'Exercise from plan',
        muscle: 'Unknown',
        painLevel: 'Unknown',
        goal: 'Unknown',
        repetitions: lastRef.repetitions,
        sets: lastRef.sets,
        imageUrl: '',
        videoUrl: '',
      );
    }
    return null;
  }
}

// Program Archives for reports (exercise/treatment snapshots to avoid circular deps)
class ExerciseSnapshot {
  final String exerciseId;
  final String exerciseName;
  final String description;
  final String muscle;
  final String painLevel;
  final String goal;
  final int repetitions;
  final int sets;
  final String imageUrl;
  final String videoUrl;

  const ExerciseSnapshot({
    required this.exerciseId,
    required this.exerciseName,
    required this.description,
    required this.muscle,
    required this.painLevel,
    required this.goal,
    required this.repetitions,
    required this.sets,
    required this.imageUrl,
    required this.videoUrl,
  });
}

class TreatmentSnapshot {
  final String treatmentId;
  final String treatmentName;
  final String description;
  final String musclesInvolved;
  final String painLevel;
  final String painDuration;

  const TreatmentSnapshot({
    required this.treatmentId,
    required this.treatmentName,
    required this.description,
    required this.musclesInvolved,
    required this.painLevel,
    required this.painDuration,
  });
}

class ArchivedProgram {
  final DateTime startDate;
  final DateTime endDate;
  final int daysCompleted;
  final List<ExerciseSnapshot> exercises;
  final List<TreatmentSnapshot>? treatments;

  const ArchivedProgram({
    required this.startDate,
    required this.endDate,
    required this.daysCompleted,
    required this.exercises,
    this.treatments,
  });
}

class ProgramArchive {
  static final List<ArchivedProgram> archived = <ArchivedProgram>[];

  static void addArchive(ArchivedProgram program) {
    archived.add(program);
  }
}

// ROM Assessment Constants and Configuration
class ROMAssessment {
  // UI Colors (matching Jupyter BGR format converted to Flutter)
  static const Color backgroundColor = Color(0xFF323232);        // Dark Grey background (50, 50, 50)
  static const Color textColor = Color(0xFFFFFFFF);             // White text (255, 255, 255)
  static const Color highlightColor = Color(0xFF00FFFF);        // Yellow/Cyan for highlights (255, 255, 0)
  
  // Pain/ROM Scale Colors (matching Jupyter BGR format converted to Flutter)
  static const Color severeColor = Color(0xFF0000FF);           // Red for Severe Pain/Limited ROM (0, 0, 255)
  static const Color moderateColor = Color(0xFF00A5FF);         // Orange for Moderate Pain/ROM (0, 165, 255)
  static const Color goodColor = Color(0xFF00FF00);             // Green for Good ROM/Low Pain (0, 255, 0)
  static const Color compensationColor = Color(0xFF00FFFF);     // Yellow for Compensation Warning (0, 255, 255)
  
  // MediaPipe Drawing Colors
  static const Color landmarkColor = Color(0xFF00FF00);         // Green for Pose Landmarks (0, 255, 0)
  static const Color connectionColor = Color(0xFFFFFFFF);       // White for Pose Connections (255, 255, 255)
  
  // Target display dimensions (matching Jupyter constants)
  static const double displayWidth = 1280.0;
  static const double displayHeight = 720.0;
  
  // ROM Thresholds (matching Jupyter constants exactly)
  // Triceps Extension (Shoulder-Elbow-Wrist angle)
  static const double tricepsSevereAngle = 90.0;      // Angle < 90° -> Severe (Limited Extension)
  static const double tricepsModerateAngle = 135.0;   // 90° <= Angle < 135° -> Moderate (Partial Extension)
  // Angle >= 135° -> Good (Good Extension)
  
  // Shoulder Assessment (Hip-Shoulder-Elbow angle)
  static const double shoulderGoodAngle = 150.0;       // Angle > 150° -> Good Mobility/Low Pain (Arm closer to body)
  static const double shoulderLowPainAngle = 110.0;   // 111° <= Angle <= 150° -> Low Pain (Arm down/partial)
  static const double shoulderModerateAngle = 90.0;   // 90° <= Angle <= 110° -> Moderate Pain (Closer to T-pose)
  // Angle < 90° -> Severe Pain (Arm raised high)
  
  // ROM Labels (matching Jupyter format exactly)
  static const Map<String, Map<String, String>> romLabels = {
    'triceps': {
      'severe': 'Triceps ROM: Severe (<90°)',
      'moderate': 'Triceps ROM: Moderate (90-135°)',
      'good': 'Triceps ROM: Good (>=135°)',
    },
    'shoulders': {
      'severe': 'Shoulder Pain: Severe (<90°)',
      'moderate': 'Shoulder Pain: Moderate (90-110°)',
      'low': 'Shoulder Pain: Low (111-150°)',
      'good': 'Shoulder Mobility: Good (>=151°)',
    },
  };
  
  // Compensation Thresholds (matching Jupyter constants exactly)
  static const double shoulderElevationThreshold = 0.05; // 5% of hip distance -> Warning
  static const double torsoLeanThreshold = 0.05;        // 5% of hip distance -> Warning
  
  // Compensation Warning Messages
  static const String shoulderElevationWarning = 'Warning: Shoulder Elevation Compensation';
  static const String torsoLeanWarning = 'Warning: Torso Lean Compensation';
  
  // Pain Scale Mapping (adjusted to match ROM logic)
  static const Map<String, List<int>> painScaleMapping = {
    'severe': [0, 3],      // Severe pain/limited ROM
    'moderate': [4, 6],    // Moderate pain/partial ROM
    'low': [7, 8],         // Low pain/good ROM
    'good': [9, 10],       // Good mobility/minimal pain
  };
}