import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'rehabilitation_plan.dart';
import 'data_persistence_service.dart';
import 'firebase_helper.dart';
import 'user_data_notifier.dart';
import '../assessment/assessment_data.dart';
import 'hive_models.dart';

// Enhanced Hive box opening with better error handling and adapter registration
Future<Box> openRehabBox() async {
  try {
    // Ensure all adapters are registered before opening the box
    // This is critical for web platform where adapters may not be registered in main.dart
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(HiveDailyProgressAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(HivePainRecordEntryAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(HiveExerciseRecordEntryAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(HiveUserProgressAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(HiveUserAssessAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(HiveUserSettingsAdapter());
    }
    if (!Hive.isAdapterRegistered(6)) {
      Hive.registerAdapter(HiveUserDetailsAdapter());
    }
    if (!Hive.isAdapterRegistered(7)) {
      Hive.registerAdapter(HiveActiveProgramAdapter());
    }
    if (!Hive.isAdapterRegistered(8)) {
      Hive.registerAdapter(HiveRehabilitationPlanAdapter());
    }
    if (!Hive.isAdapterRegistered(9)) {
      Hive.registerAdapter(HiveExerciseReferenceAdapter());
    }
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(HiveTreatmentReferenceAdapter());
    }
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(HiveExerciseIdsAdapter());
    }
    if (!Hive.isAdapterRegistered(12)) {
      Hive.registerAdapter(HiveTreatmentIdsAdapter());
    }
    
    if (!Hive.isBoxOpen('rehabBox')) {
      debugPrint('🔓 Opening rehabBox...');
      return await Hive.openBox('rehabBox');
    } else {
      debugPrint('✅ rehabBox already open');
      return Hive.box('rehabBox');
    }
  } catch (e) {
    debugPrint('❌ Error opening rehabBox: $e');
    try {
      await Hive.deleteBoxFromDisk('rehabBox');
      debugPrint('🔄 Deleted and recreating rehabBox');
      return await Hive.openBox('rehabBox');
    } catch (e2) {
      debugPrint('💥 Critical Hive failure: $e2');
      rethrow;
    }
  }
}

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
  static DateTime? lastModified;
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
        await openRehabBox();
      }
      
      final box = Hive.box('rehabBox');
      final userDetailsData = box.get('userDetails');
      
      if (userDetailsData is Map<String, dynamic>) {
        final hasValidData = (userDetailsData['firstName'] ?? '').toString().isNotEmpty || 
                            (userDetailsData['lastName'] ?? '').toString().isNotEmpty || 
                            (userDetailsData['email'] ?? '').toString().isNotEmpty;
        debugPrint('UserDetails.verifyHiveData: Data integrity check - Valid: $hasValidData');
        debugPrint('UserDetails.verifyHiveData: Stored data - firstName: "${userDetailsData['firstName']}", lastName: "${userDetailsData['lastName']}", email: "${userDetailsData['email']}"');
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
      debugPrint('UserDetails.markAssessmentCompleted: Starting assessment completion');
      hasCompletedAssessment = true;
      
      // Update in Firebase with proper authentication checks
      debugPrint('UserDetails.markAssessmentCompleted: Checking authentication');
      final currentUser = await FirebaseHelper.ensureAuthenticatedUser();
      if (currentUser != null) {
        debugPrint('UserDetails.markAssessmentCompleted: User authenticated, proceeding with Firestore update');
        try {
          
          // Check if user document exists, create if it doesn't
          final userDocRef = _firestore.collection('users').doc(currentUser.uid);
          final userDoc = await userDocRef.get();
          
          if (!userDoc.exists) {
            debugPrint('User document does not exist, creating it first');
            await userDocRef.set({
              'userId': currentUser.uid,
              'firstName': firstName.isNotEmpty ? firstName : (currentUser.displayName?.split(' ').first ?? ''),
              'lastName': lastName.isNotEmpty ? lastName : (currentUser.displayName?.split(' ').skip(1).join(' ') ?? ''),
              'email': currentUser.email ?? '',
              'hasCompletedAssessment': true,
              'createdAt': FieldValue.serverTimestamp(),
              'lastUpdated': FieldValue.serverTimestamp(),
            });
            debugPrint('User document created with assessment completion status');
          } else {
            // Update existing document
            await userDocRef.update({
              'hasCompletedAssessment': true,
              'lastUpdated': FieldValue.serverTimestamp(),
            });
            debugPrint('User document updated with assessment completion status');
          }
        } catch (firestoreError) {
          debugPrint('UserDetails.markAssessmentCompleted: Firestore error during assessment completion: $firestoreError');
          // Don't rethrow - continue with local storage
          // This ensures the app continues to work even if Firestore is unavailable
        }
      } else {
        debugPrint('UserDetails.markAssessmentCompleted: No authenticated user found during assessment completion');
      }
      
      // Save to Hive (always do this regardless of Firestore success)
      await saveToHive();
      
      debugPrint('UserDetails.markAssessmentCompleted: Assessment marked as completed locally');
    } catch (e) {
      debugPrint('UserDetails.markAssessmentCompleted: Error marking assessment as completed: $e');
      // Ensure local state is still updated even if everything else fails
      hasCompletedAssessment = true;
      try {
        await saveToHive();
        debugPrint('UserDetails.markAssessmentCompleted: Local state saved despite error');
      } catch (hiveError) {
        debugPrint('UserDetails.markAssessmentCompleted: Error saving to Hive: $hiveError');
      }
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

  // Hive persistence methods - Simplified using Map
  static Future<void> saveToHive() async {
    try {
      // Check if Hive box is open
      if (!Hive.isBoxOpen('rehabBox')) {
        debugPrint('UserDetails.saveToHive: Hive box not open, attempting to open...');
        await openRehabBox();
      }
      
      final box = Hive.box('rehabBox');
      
      // Update timestamp
      lastModified = DateTime.now();
      
      // Save user details as a simple Map
      final userDetailsMap = {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'password': password,
        'notifications': List<String>.from(notifications),
        'isGuest': isGuest,
        'guestSessionId': guestSessionId,
        'profilePicture': profilePicture,
        'hasCompletedAssessment': hasCompletedAssessment,
        'lastModified': lastModified?.millisecondsSinceEpoch,
      };
      
      await box.put('userDetails', userDetailsMap);
      
      debugPrint('UserDetails.saveToHive: Successfully saved - firstName: "$firstName", lastName: "$lastName", email: "$email", isGuest: $isGuest, lastModified: $lastModified');
      
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
        await openRehabBox();
      }
      
      final box = Hive.box('rehabBox');
      final userDetailsData = box.get('userDetails');
      
      if (userDetailsData is Map<String, dynamic>) {
        firstName = userDetailsData['firstName'] ?? '';
        lastName = userDetailsData['lastName'] ?? '';
        email = userDetailsData['email'] ?? '';
        password = userDetailsData['password'] ?? '';
        notifications = List<String>.from(userDetailsData['notifications'] ?? []);
        isGuest = userDetailsData['isGuest'] ?? false;
        guestSessionId = userDetailsData['guestSessionId'];
        profilePicture = userDetailsData['profilePicture'] ?? '01.jpg';
        hasCompletedAssessment = userDetailsData['hasCompletedAssessment'] ?? false;
        
        // Load timestamp
        final lastModifiedTimestamp = userDetailsData['lastModified'];
        if (lastModifiedTimestamp is int) {
          lastModified = DateTime.fromMillisecondsSinceEpoch(lastModifiedTimestamp);
        } else {
          lastModified = null;
        }
        
        debugPrint('UserDetails.loadFromHive: Successfully loaded - firstName: "$firstName", lastName: "$lastName", email: "$email", isGuest: $isGuest, lastModified: $lastModified');
        
        // Notify UI of data changes
        UserDataNotifier.instance.updateUserData(
          firstName: firstName,
          lastName: lastName,
          email: email,
          hasCompletedAssessment: hasCompletedAssessment,
        );
      } else {
        debugPrint('UserDetails.loadFromHive: No user details found in Hive, using defaults');
        // Set default values if no Hive data exists
        firstName = '';
        lastName = '';
        email = '';
        password = '';
        hasCompletedAssessment = false;
        isGuest = false;
        guestSessionId = null;
        notifications = [];
        lastModified = null;
        
        // Notify UI with empty data
        UserDataNotifier.instance.updateUserData(
          firstName: firstName,
          lastName: lastName,
          email: email,
          hasCompletedAssessment: hasCompletedAssessment,
        );
      }
    } catch (e) {
      debugPrint('UserDetails.loadFromHive: Error loading from Hive: $e');
      debugPrint('UserDetails.loadFromHive: Error type: ${e.runtimeType}');
      
      // Set default values if Hive fails
      firstName = '';
      lastName = '';
      email = '';
      password = '';
      hasCompletedAssessment = false;
      isGuest = false;
      guestSessionId = null;
      notifications = [];
      lastModified = null;
      
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
  static DateTime? lastModified;

  // Firebase instances
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Firebase sync methods
  static Future<void> saveToFirebase() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('UserProgress.saveToFirebase: No authenticated user found');
        return;
      }

      debugPrint('UserProgress.saveToFirebase: Saving progress to Firebase');
      
      await _firestore.collection('progress').doc(currentUser.uid).set({
        'title': title,
        'titleColor': titleColor,
        'streak': streak,
        'totalDays': totalDays,
        'totalExercises': totalExercises,
        'totalSeconds': totalSeconds,
        'notes': notes,
        'lastExerciseDate': lastExerciseDate,
        'lastUpdated': FieldValue.serverTimestamp(),
        'userId': currentUser.uid,
      });
      
      debugPrint('UserProgress.saveToFirebase: Successfully saved progress to Firebase');
    } catch (e) {
      debugPrint('UserProgress.saveToFirebase: Error saving to Firebase: $e');
      rethrow;
    }
  }

  static Future<void> loadFromFirebase() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('UserProgress.loadFromFirebase: No authenticated user found');
        return;
      }

      debugPrint('UserProgress.loadFromFirebase: Loading progress from Firebase');
      
      final DocumentSnapshot doc = await _firestore
          .collection('progress')
          .doc(currentUser.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        title = data['title'] ?? 'Initiator';
        titleColor = data['titleColor'] ?? '';
        streak = data['streak'] ?? 0;
        totalDays = data['totalDays'] ?? 0;
        totalExercises = data['totalExercises'] ?? 0;
        totalSeconds = data['totalSeconds'] ?? 0;
        notes = data['notes'];
        lastExerciseDate = data['lastExerciseDate']?.toDate();
        
        debugPrint('UserProgress.loadFromFirebase: Successfully loaded progress from Firebase');
        
        // Save to Hive for offline access
        await saveToHive();
      } else {
        debugPrint('UserProgress.loadFromFirebase: No progress document found in Firebase');
      }
    } catch (e) {
      debugPrint('UserProgress.loadFromFirebase: Error loading from Firebase: $e');
      rethrow;
    }
  }

  // Hive persistence methods - Simplified using Map
  static Future<void> saveToHive() async {
    try {
      if (!Hive.isBoxOpen('rehabBox')) {
        debugPrint('UserProgress.saveToHive: Hive box not open, attempting to open...');
        await openRehabBox();
      }
      final box = Hive.box('rehabBox');
      
      // Update timestamp
      lastModified = DateTime.now();
      
      // Save user progress as a simple Map
      final userProgressMap = {
        'title': title,
        'titleColor': titleColor,
        'streak': streak,
        'totalDays': totalDays,
        'totalExercises': totalExercises,
        'totalSeconds': totalSeconds,
        'notes': notes,
        'lastExerciseDate': lastExerciseDate?.millisecondsSinceEpoch,
        'lastModified': lastModified?.millisecondsSinceEpoch,
      };
      
      await box.put('userProgress', userProgressMap);
      debugPrint('Saved user progress to Hive - lastModified: $lastModified');
      
      // Trigger auto-save
      DataPersistenceService.instance.triggerSave(reason: 'User progress updated');
    } catch (e) {
      debugPrint('Error saving user progress to Hive: $e');
      rethrow;
    }
  }

  static Future<void> loadFromHive() async {
    try {
      if (!Hive.isBoxOpen('rehabBox')) {
        debugPrint('UserProgress.loadFromHive: Hive box not open, attempting to open...');
        await openRehabBox();
      }
      final box = Hive.box('rehabBox');
      final userProgressData = box.get('userProgress');
      
      if (userProgressData is Map<String, dynamic>) {
        title = userProgressData['title'] ?? 'Initiator';
        titleColor = userProgressData['titleColor'] ?? '';
        streak = userProgressData['streak'] ?? 0;
        totalDays = userProgressData['totalDays'] ?? 0;
        totalExercises = userProgressData['totalExercises'] ?? 0;
        totalSeconds = userProgressData['totalSeconds'] ?? 0;
        notes = userProgressData['notes'];
        
        // Convert timestamp back to DateTime
        final lastExerciseTimestamp = userProgressData['lastExerciseDate'];
        if (lastExerciseTimestamp is int) {
          lastExerciseDate = DateTime.fromMillisecondsSinceEpoch(lastExerciseTimestamp);
        } else {
          lastExerciseDate = null;
        }
        
        // Load lastModified timestamp
        final lastModifiedTimestamp = userProgressData['lastModified'];
        if (lastModifiedTimestamp is int) {
          lastModified = DateTime.fromMillisecondsSinceEpoch(lastModifiedTimestamp);
        } else {
          lastModified = null;
        }
        
        debugPrint('Loaded user progress from Hive: $title, streak: $streak, total exercises: $totalExercises, lastModified: $lastModified');
      } else {
        debugPrint('No user progress found in Hive, using defaults');
        lastModified = null;
      }
    } catch (e) {
      debugPrint('Error loading user progress from Hive: $e');
      lastModified = null;
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
  static DateTime? lastModified;
  
  // Muscle injury assessment fields
  static List<String> injuredMuscles = [];
  static Map<String, int> musclePainLevels = {}; // muscle name -> pain level (0-10)
  static Map<String, String> musclePainCategories = {}; // muscle name -> category (Low/Moderate/Severe)
  static Map<String, bool> muscleStillPainful = {}; // muscle name -> still experiencing pain (true/false)

  // Assessment stored locally only; no Firebase/Hive persistence
  // Keep fields in-memory and mirror to AssessmentData when asked to save/load

  // Firebase sync methods
  static Future<void> saveToFirebase() async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        debugPrint('UserAssess.saveToFirebase: No authenticated user found');
        return;
      }

      debugPrint('UserAssess.saveToFirebase: Saving assessment to Firebase');
      
      await FirebaseFirestore.instance.collection('assessment').doc(currentUser.uid).set({
        'rehabGoal': rehabGoal,
        'generalMuscle': generalMuscle,
        'specificMuscle': specificMuscle,
        'painScale': painScale,
        'painLevel': painLevel,
        'painType': painType,
        'painDuration': painDuration,
        'isInjured': isInjured,
        'isAssessed': isAssessed,
        'injuredMuscles': injuredMuscles,
        'musclePainLevels': musclePainLevels,
        'musclePainCategories': musclePainCategories,
        'muscleStillPainful': muscleStillPainful,
        'lastUpdated': FieldValue.serverTimestamp(),
        'userId': currentUser.uid,
      });
      
      debugPrint('UserAssess.saveToFirebase: Successfully saved assessment to Firebase');
    } catch (e) {
      debugPrint('UserAssess.saveToFirebase: Error saving to Firebase: $e');
      rethrow;
    }
  }

  static Future<void> loadFromFirebase() async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        debugPrint('UserAssess.loadFromFirebase: No authenticated user found');
        return;
      }

      debugPrint('UserAssess.loadFromFirebase: Loading assessment from Firebase');
      
      final DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('assessment')
          .doc(currentUser.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        rehabGoal = data['rehabGoal'] ?? '';
        generalMuscle = data['generalMuscle'] ?? '';
        specificMuscle = data['specificMuscle'] ?? '';
        painScale = data['painScale'] ?? 0;
        painLevel = data['painLevel'] ?? '';
        painType = data['painType'] ?? '';
        painDuration = data['painDuration'] ?? '';
        isInjured = data['isInjured'] ?? false;
        isAssessed = data['isAssessed'] ?? false;
        injuredMuscles = List<String>.from(data['injuredMuscles'] ?? []);
        musclePainLevels = Map<String, int>.from(data['musclePainLevels'] ?? {});
        musclePainCategories = Map<String, String>.from(data['musclePainCategories'] ?? {});
        muscleStillPainful = Map<String, bool>.from(data['muscleStillPainful'] ?? {});
        
        debugPrint('UserAssess.loadFromFirebase: Successfully loaded assessment from Firebase');
        
        // Save to Hive for offline access
        await saveToHive();
      } else {
        debugPrint('UserAssess.loadFromFirebase: No assessment document found in Firebase');
      }
    } catch (e) {
      debugPrint('UserAssess.loadFromFirebase: Error loading from Firebase: $e');
      rethrow;
    }
  }

  // Hive persistence methods
  static Future<void> saveToHive() async {
    try {
      // Check if Hive box is open
      if (!Hive.isBoxOpen('rehabBox')) {
        debugPrint('UserAssess.saveToHive: Hive box not open, attempting to open...');
        await openRehabBox();
      }
      
      final box = Hive.box('rehabBox');
      
      // Create HiveUserAssess object and save to Hive
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
      
      // Also sync to AssessmentData for backward compatibility
      lastModified = DateTime.now();
      AssessmentData.rehabGoal = rehabGoal;
      AssessmentData.generalMuscle = generalMuscle;
      AssessmentData.specificMuscle = specificMuscle;
      AssessmentData.painScale = painScale;
      AssessmentData.painLevel = painLevel;
      AssessmentData.painType = painType;
      AssessmentData.painDuration = painDuration;
      AssessmentData.isInjured = isInjured;
      AssessmentData.isAssessed = isAssessed;
      AssessmentData.injuredMuscles = injuredMuscles;
      AssessmentData.musclePainLevels = musclePainLevels;
      AssessmentData.musclePainCategories = musclePainCategories;
      AssessmentData.muscleStillPainful = muscleStillPainful;
      
      debugPrint('UserAssess.saveToHive: Saved to Hive and synced to AssessmentData');
      debugPrint('UserAssess.saveToHive: specificMuscle = "$specificMuscle"');
    } catch (e) {
      debugPrint('UserAssess.saveToHive: Error saving to Hive: $e');
      rethrow;
    }
  }

  static Future<void> loadFromHive() async {
    try {
      // Check if Hive box is open
      if (!Hive.isBoxOpen('rehabBox')) {
        debugPrint('UserAssess.loadFromHive: Hive box not open, attempting to open...');
        await openRehabBox();
      }
      
      final box = Hive.box('rehabBox');
      final hiveUserAssess = box.get('userAssess');
      
      // Load from Hive first if available
      if (hiveUserAssess is HiveUserAssess) {
        debugPrint('UserAssess.loadFromHive: Loading from Hive (userAssess key)');
        
        // Update UserAssess from Hive data
        rehabGoal = hiveUserAssess.rehabGoal;
        generalMuscle = hiveUserAssess.generalMuscle;
        specificMuscle = hiveUserAssess.specificMuscle;
        painScale = hiveUserAssess.painScale;
        painLevel = hiveUserAssess.painLevel;
        painType = hiveUserAssess.painType;
        painDuration = hiveUserAssess.painDuration;
        isInjured = hiveUserAssess.isInjured;
        isAssessed = hiveUserAssess.isAssessed;
        
        // Also sync to AssessmentData
        AssessmentData.rehabGoal = rehabGoal;
        AssessmentData.generalMuscle = generalMuscle;
        AssessmentData.specificMuscle = specificMuscle;
        AssessmentData.painScale = painScale;
        AssessmentData.painLevel = painLevel;
        AssessmentData.painType = painType;
        AssessmentData.painDuration = painDuration;
        AssessmentData.isInjured = isInjured;
        AssessmentData.isAssessed = isAssessed;
        
        debugPrint('UserAssess.loadFromHive: Loaded from Hive successfully');
        debugPrint('UserAssess.loadFromHive: specificMuscle = "$specificMuscle"');
        return; // Successfully loaded from Hive, don't need Firebase
      } else {
        debugPrint('UserAssess.loadFromHive: No Hive data found (userAssess key), will try Firebase if needed');
        // If no Hive data, fall back to mirroring AssessmentData (for backward compatibility)
        rehabGoal = AssessmentData.rehabGoal;
        generalMuscle = AssessmentData.generalMuscle;
        specificMuscle = AssessmentData.specificMuscle;
        painScale = AssessmentData.painScale;
        painLevel = AssessmentData.painLevel;
        painType = AssessmentData.painType;
        painDuration = AssessmentData.painDuration;
        isInjured = AssessmentData.isInjured;
        isAssessed = AssessmentData.isAssessed;
        injuredMuscles = AssessmentData.injuredMuscles;
        musclePainLevels = AssessmentData.musclePainLevels;
        musclePainCategories = AssessmentData.musclePainCategories;
        muscleStillPainful = AssessmentData.muscleStillPainful;
      }
    } catch (e) {
      debugPrint('UserAssess.loadFromHive: Error loading from Hive: $e');
      debugPrint('UserAssess.loadFromHive: Falling back to AssessmentData mirror');
      // Fallback to mirroring AssessmentData on error
      rehabGoal = AssessmentData.rehabGoal;
      generalMuscle = AssessmentData.generalMuscle;
      specificMuscle = AssessmentData.specificMuscle;
      painScale = AssessmentData.painScale;
      painLevel = AssessmentData.painLevel;
      painType = AssessmentData.painType;
      painDuration = AssessmentData.painDuration;
      isInjured = AssessmentData.isInjured;
      isAssessed = AssessmentData.isAssessed;
      injuredMuscles = AssessmentData.injuredMuscles;
      musclePainLevels = AssessmentData.musclePainLevels;
      musclePainCategories = AssessmentData.musclePainCategories;
      muscleStillPainful = AssessmentData.muscleStillPainful;
    }
  }
}

// Class: Preferences of the User
class UserSettings {
  static bool isDailyReminder = true; // Pain assessment / general prompts
  static bool isStreakAlert = true;
  static bool isExerciseReminder = true; // 08:00 AM exercise reminder toggle
  static TimeOfDay exerciseReminderTime = const TimeOfDay(hour: 8, minute: 0);
  static bool showModeratePainBanner = true; // Show moderate pain banner during exercises/assessments
  static bool showSeverePainDialog = true; // Show severe pain dialog during exercises/assessments
  static DateTime? lastModified;

  // Firebase instances
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Firebase sync methods
  static Future<void> saveToFirebase() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('UserSettings.saveToFirebase: No authenticated user found');
        return;
      }

      debugPrint('UserSettings.saveToFirebase: Saving settings to Firebase');
      
      await _firestore.collection('settings').doc(currentUser.uid).set({
        'isDailyReminder': isDailyReminder,
        'isStreakAlert': isStreakAlert,
        'isExerciseReminder': isExerciseReminder,
        'exerciseReminderHour': exerciseReminderTime.hour,
        'exerciseReminderMinute': exerciseReminderTime.minute,
        'showModeratePainBanner': showModeratePainBanner,
        'showSeverePainDialog': showSeverePainDialog,
        'lastUpdated': FieldValue.serverTimestamp(),
        'userId': currentUser.uid,
      });
      
      debugPrint('UserSettings.saveToFirebase: Successfully saved settings to Firebase');
    } catch (e) {
      debugPrint('UserSettings.saveToFirebase: Error saving to Firebase: $e');
      rethrow;
    }
  }

  static Future<void> loadFromFirebase() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('UserSettings.loadFromFirebase: No authenticated user found');
        return;
      }

      debugPrint('UserSettings.loadFromFirebase: Loading settings from Firebase');
      
      final DocumentSnapshot doc = await _firestore
          .collection('settings')
          .doc(currentUser.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        isDailyReminder = data['isDailyReminder'] ?? true;
        isStreakAlert = data['isStreakAlert'] ?? true;
        isExerciseReminder = data['isExerciseReminder'] ?? true;
        exerciseReminderTime = TimeOfDay(
          hour: data['exerciseReminderHour'] ?? 8,
          minute: data['exerciseReminderMinute'] ?? 0,
        );
        showModeratePainBanner = data['showModeratePainBanner'] ?? true;
        showSeverePainDialog = data['showSeverePainDialog'] ?? true;
        
        debugPrint('UserSettings.loadFromFirebase: Successfully loaded settings from Firebase');
        
        // Save to Hive for offline access
        await saveToHive();
      } else {
        debugPrint('UserSettings.loadFromFirebase: No settings document found in Firebase');
      }
    } catch (e) {
      debugPrint('UserSettings.loadFromFirebase: Error loading from Firebase: $e');
      rethrow;
    }
  }

  // Hive persistence methods - Simplified using Map
  static Future<void> saveToHive() async {
    try {
      if (!Hive.isBoxOpen('rehabBox')) {
        debugPrint('UserSettings.saveToHive: Hive box not open, attempting to open...');
        await openRehabBox();
      }
      final box = Hive.box('rehabBox');
      
      // Update timestamp
      lastModified = DateTime.now();
      
      // Save user settings as a simple Map
      final userSettingsMap = {
        'isDailyReminder': isDailyReminder,
        'isStreakAlert': isStreakAlert,
        'isExerciseReminder': isExerciseReminder,
        'exerciseReminderHour': exerciseReminderTime.hour,
        'exerciseReminderMinute': exerciseReminderTime.minute,
        'showModeratePainBanner': showModeratePainBanner,
        'showSeverePainDialog': showSeverePainDialog,
        'lastModified': lastModified?.millisecondsSinceEpoch,
      };
      
      await box.put('userSettings', userSettingsMap);
      debugPrint('Saved user settings to Hive - lastModified: $lastModified');
      
      // Trigger auto-save
      DataPersistenceService.instance.triggerSave(reason: 'User settings updated');
    } catch (e) {
      debugPrint('Error saving user settings to Hive: $e');
      rethrow;
    }
  }

  static Future<void> loadFromHive() async {
    try {
      if (!Hive.isBoxOpen('rehabBox')) {
        debugPrint('UserSettings.loadFromHive: Hive box not open, attempting to open...');
        await openRehabBox();
      }
      final box = Hive.box('rehabBox');
      final userSettingsData = box.get('userSettings');
      
      if (userSettingsData is Map<String, dynamic>) {
        isDailyReminder = userSettingsData['isDailyReminder'] ?? true;
        isStreakAlert = userSettingsData['isStreakAlert'] ?? true;
        isExerciseReminder = userSettingsData['isExerciseReminder'] ?? true;
        exerciseReminderTime = TimeOfDay(
          hour: userSettingsData['exerciseReminderHour'] ?? 8,
          minute: userSettingsData['exerciseReminderMinute'] ?? 0,
        );
        showModeratePainBanner = userSettingsData['showModeratePainBanner'] ?? true;
        showSeverePainDialog = userSettingsData['showSeverePainDialog'] ?? true;
        
        // Load lastModified timestamp
        final lastModifiedTimestamp = userSettingsData['lastModified'];
        if (lastModifiedTimestamp is int) {
          lastModified = DateTime.fromMillisecondsSinceEpoch(lastModifiedTimestamp);
        } else {
          lastModified = null;
        }
        
        debugPrint('Loaded user settings from Hive: daily reminder: $isDailyReminder, exercise reminder: $isExerciseReminder at ${exerciseReminderTime.hour}:${exerciseReminderTime.minute.toString().padLeft(2, '0')}, showModeratePainBanner: $showModeratePainBanner, showSeverePainDialog: $showSeverePainDialog, lastModified: $lastModified');
      } else {
        debugPrint('No user settings found in Hive, using defaults');
        lastModified = null;
      }
    } catch (e) {
      debugPrint('Error loading user settings from Hive: $e');
      lastModified = null;
    }
  }
}

// Class: Active Program metadata
class ActiveProgram {
  static DateTime? startDate;

  // Hive persistence methods - Simplified using Map
  static Future<void> saveToHive() async {
    try {
      if (!Hive.isBoxOpen('rehabBox')) {
        debugPrint('ActiveProgram.saveToHive: Hive box not open, attempting to open...');
        await openRehabBox();
      }
      final box = Hive.box('rehabBox');
      
      // Save active program as a simple Map
      final activeProgramMap = {
        'startDate': startDate?.millisecondsSinceEpoch,
      };
      
      await box.put('activeProgram', activeProgramMap);
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
      if (!Hive.isBoxOpen('rehabBox')) {
        debugPrint('ActiveProgram.loadFromHive: Hive box not open, attempting to open...');
        await openRehabBox();
      }
      final box = Hive.box('rehabBox');
      final activeProgramData = box.get('activeProgram');
      
      if (activeProgramData is Map<String, dynamic>) {
        // Convert timestamp back to DateTime
        final startDateTimestamp = activeProgramData['startDate'];
        if (startDateTimestamp is int) {
          startDate = DateTime.fromMillisecondsSinceEpoch(startDateTimestamp);
        } else {
          startDate = null;
        }
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
  final int? painScale; // Optional: Pain scale (0-10) detected during exercise
  final String? painLevel; // Optional: Pain level ('Low', 'Moderate', 'Severe') detected during exercise

  const ExerciseRecordEntry({
    required this.date,
    required this.exerciseId,
    required this.exerciseName,
    required this.sets,
    required this.reps,
    required this.durationSeconds,
    required this.status,
    this.painScale,
    this.painLevel,
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

  // Firebase instances
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Firebase sync methods
  static Future<void> saveToFirebase() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('PainHistory.saveToFirebase: No authenticated user found');
        return;
      }

      debugPrint('PainHistory.saveToFirebase: Saving pain history to Firebase');
      
      final List<Map<String, dynamic>> entriesData = entries.map((entry) => {
        'date': Timestamp.fromDate(entry.date),
        'painScale': entry.painScale,
        'painLevel': entry.painLevel,
      }).toList();
      
      await _firestore.collection('painHistory').doc(currentUser.uid).set({
        'entries': entriesData,
        'lastPromptedDate': _lastPromptedDate != null ? Timestamp.fromDate(_lastPromptedDate!) : null,
        'lastUpdated': FieldValue.serverTimestamp(),
        'userId': currentUser.uid,
      });
      
      debugPrint('PainHistory.saveToFirebase: Successfully saved ${entries.length} pain history entries to Firebase');
    } catch (e) {
      debugPrint('PainHistory.saveToFirebase: Error saving to Firebase: $e');
      rethrow;
    }
  }

  static Future<void> loadFromFirebase() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('PainHistory.loadFromFirebase: No authenticated user found');
        return;
      }

      debugPrint('PainHistory.loadFromFirebase: Loading pain history from Firebase');
      
      final DocumentSnapshot doc = await _firestore
          .collection('painHistory')
          .doc(currentUser.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final List<dynamic> entriesData = data['entries'] ?? [];
        
        entries.clear();
        entries.addAll(entriesData.map((entryData) => PainRecordEntry(
          date: (entryData['date'] as Timestamp).toDate(),
          painScale: entryData['painScale'] ?? 0,
          painLevel: entryData['painLevel'] ?? '',
        )));
        
        _lastPromptedDate = data['lastPromptedDate']?.toDate();
        
        debugPrint('PainHistory.loadFromFirebase: Successfully loaded ${entries.length} pain history entries from Firebase');
        
        // Save to Hive for offline access
        await saveToHive();
      } else {
        debugPrint('PainHistory.loadFromFirebase: No pain history document found in Firebase');
      }
    } catch (e) {
      debugPrint('PainHistory.loadFromFirebase: Error loading from Firebase: $e');
      rethrow;
    }
  }

  // Hive persistence methods - Simplified using List of Maps
  static Future<void> saveToHive() async {
    int retryCount = 0;
    const maxRetries = 3;
    
    while (retryCount < maxRetries) {
      try {
        // Validate data before saving
        if (!_validatePainHistoryData()) {
          throw Exception('Pain history data validation failed');
        }
        
        if (!Hive.isBoxOpen('rehabBox')) {
          debugPrint('PainHistory.saveToHive: Hive box not open, attempting to open...');
          await openRehabBox();
        }
        final box = Hive.box('rehabBox');
        
        // Save pain history as a simple List of Maps
        final painHistoryList = entries.map((entry) => {
          'date': entry.date.millisecondsSinceEpoch,
          'painScale': entry.painScale,
          'painLevel': entry.painLevel,
        }).toList();
        
        await box.put('painHistory', painHistoryList);
        debugPrint('Saved ${entries.length} pain history entries to Hive');
        
        // Verify the save was successful
        final savedData = box.get('painHistory');
        if (savedData == null || (savedData as List).length != entries.length) {
          throw Exception('Data verification failed after save');
        }
        
        // Trigger auto-save
        DataPersistenceService.instance.triggerSave(reason: 'Pain history updated');
        return; // Success, exit retry loop
        
      } catch (e) {
        retryCount++;
        debugPrint('PainHistory.saveToHive: Attempt $retryCount failed: $e');
        
        if (retryCount >= maxRetries) {
          debugPrint('PainHistory.saveToHive: All retry attempts failed');
          rethrow;
        }
        
        // Wait before retry (exponential backoff)
        await Future.delayed(Duration(milliseconds: 500 * retryCount));
      }
    }
  }
  
  // Validate pain history data integrity
  static bool _validatePainHistoryData() {
    try {
      for (final entry in entries) {
        // Validate pain scale is within valid range (0-10)
        if (entry.painScale < 0 || entry.painScale > 10) {
          debugPrint('PainHistory validation failed: Invalid pain scale ${entry.painScale}');
          return false;
        }
        
        // Validate pain level is not empty
        if (entry.painLevel.isEmpty) {
          debugPrint('PainHistory validation failed: Empty pain level');
          return false;
        }
        
        // Validate date is not in the future
        if (entry.date.isAfter(DateTime.now())) {
          debugPrint('PainHistory validation failed: Future date ${entry.date}');
          return false;
        }
      }
      return true;
    } catch (e) {
      debugPrint('PainHistory validation error: $e');
      return false;
    }
  }

  static Future<void> loadFromHive() async {
    try {
      if (!Hive.isBoxOpen('rehabBox')) {
        debugPrint('PainHistory.loadFromHive: Hive box not open, attempting to open...');
        await openRehabBox();
      }
      final box = Hive.box('rehabBox');
      final painHistoryData = box.get('painHistory', defaultValue: <Map<String, dynamic>>[]);
      
      if (painHistoryData is List<dynamic>) {
        entries.clear();
        entries.addAll(painHistoryData.map((entryData) {
          final entry = entryData as Map<String, dynamic>;
          return PainRecordEntry(
            date: DateTime.fromMillisecondsSinceEpoch(entry['date']),
            painScale: entry['painScale'] ?? 0,
            painLevel: entry['painLevel'] ?? '',
          );
        }));
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
    int? painScale,
    String? painLevel,
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
      painScale: painScale,
      painLevel: painLevel,
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

  // Firebase instances
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Firebase sync methods
  static Future<void> saveToFirebase() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('ExerciseHistory.saveToFirebase: No authenticated user found');
        return;
      }

      debugPrint('ExerciseHistory.saveToFirebase: Saving exercise history to Firebase');
      
      final List<Map<String, dynamic>> entriesData = entries.map((entry) => {
        'date': Timestamp.fromDate(entry.date),
        'exerciseId': entry.exerciseId,
        'exerciseName': entry.exerciseName,
        'sets': entry.sets,
        'reps': entry.reps,
        'durationSeconds': entry.durationSeconds,
        'status': entry.status,
        if (entry.painScale != null) 'painScale': entry.painScale,
        if (entry.painLevel != null) 'painLevel': entry.painLevel,
      }).toList();
      
      await _firestore.collection('exerciseHistory').doc(currentUser.uid).set({
        'entries': entriesData,
        'lastUpdated': FieldValue.serverTimestamp(),
        'userId': currentUser.uid,
      });
      
      debugPrint('ExerciseHistory.saveToFirebase: Successfully saved ${entries.length} exercise history entries to Firebase');
    } catch (e) {
      debugPrint('ExerciseHistory.saveToFirebase: Error saving to Firebase: $e');
      rethrow;
    }
  }

  static Future<void> loadFromFirebase() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('ExerciseHistory.loadFromFirebase: No authenticated user found');
        return;
      }

      debugPrint('ExerciseHistory.loadFromFirebase: Loading exercise history from Firebase');
      
      final DocumentSnapshot doc = await _firestore
          .collection('exerciseHistory')
          .doc(currentUser.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final List<dynamic> entriesData = data['entries'] ?? [];
        
        entries.clear();
        entries.addAll(entriesData.map((entryData) => ExerciseRecordEntry(
          date: (entryData['date'] as Timestamp).toDate(),
          exerciseId: entryData['exerciseId'] ?? '',
          exerciseName: entryData['exerciseName'] ?? '',
          sets: entryData['sets'] ?? 0,
          reps: entryData['reps'] ?? 0,
          durationSeconds: entryData['durationSeconds'] ?? 0,
          status: entryData['status'] ?? 'completed',
          painScale: entryData['painScale'] as int?,
          painLevel: entryData['painLevel'] as String?,
        )));
        
        debugPrint('ExerciseHistory.loadFromFirebase: Successfully loaded ${entries.length} exercise history entries from Firebase');
        
        // Save to Hive for offline access
        await saveToHive();
      } else {
        debugPrint('ExerciseHistory.loadFromFirebase: No exercise history document found in Firebase');
      }
    } catch (e) {
      debugPrint('ExerciseHistory.loadFromFirebase: Error loading from Firebase: $e');
      rethrow;
    }
  }

  // Hive persistence methods - Simplified using List of Maps
  static Future<void> saveToHive() async {
    int retryCount = 0;
    const maxRetries = 3;
    
    while (retryCount < maxRetries) {
      try {
        // Validate data before saving
        if (!_validateExerciseHistoryData()) {
          throw Exception('Exercise history data validation failed');
        }
        
        if (!Hive.isBoxOpen('rehabBox')) {
          debugPrint('ExerciseHistory.saveToHive: Hive box not open, attempting to open...');
          await openRehabBox();
        }
        final box = Hive.box('rehabBox');
        
        // Save exercise history as a simple List of Maps
        final exerciseHistoryList = entries.map((entry) => {
          'date': entry.date.millisecondsSinceEpoch,
          'exerciseId': entry.exerciseId,
          'exerciseName': entry.exerciseName,
          'sets': entry.sets,
          'reps': entry.reps,
          'durationSeconds': entry.durationSeconds,
          'status': entry.status,
          if (entry.painScale != null) 'painScale': entry.painScale,
          if (entry.painLevel != null) 'painLevel': entry.painLevel,
        }).toList();
        
        await box.put('exerciseHistory', exerciseHistoryList);
        debugPrint('Saved ${entries.length} exercise history entries to Hive');
        
        // Verify the save was successful
        final savedData = box.get('exerciseHistory');
        if (savedData == null || (savedData as List).length != entries.length) {
          throw Exception('Data verification failed after save');
        }
        
        // Trigger auto-save
        DataPersistenceService.instance.triggerSave(reason: 'Exercise history updated');
        return; // Success, exit retry loop
        
      } catch (e) {
        retryCount++;
        debugPrint('ExerciseHistory.saveToHive: Attempt $retryCount failed: $e');
        
        if (retryCount >= maxRetries) {
          debugPrint('ExerciseHistory.saveToHive: All retry attempts failed');
          rethrow;
        }
        
        // Wait before retry (exponential backoff)
        await Future.delayed(Duration(milliseconds: 500 * retryCount));
      }
    }
  }
  
  // Validate exercise history data integrity
  static bool _validateExerciseHistoryData() {
    try {
      for (final entry in entries) {
        // Validate exercise ID is not empty
        if (entry.exerciseId.isEmpty) {
          debugPrint('ExerciseHistory validation failed: Empty exercise ID');
          return false;
        }
        
        // Validate exercise name is not empty
        if (entry.exerciseName.isEmpty) {
          debugPrint('ExerciseHistory validation failed: Empty exercise name');
          return false;
        }
        
        // Validate sets and reps are positive
        if (entry.sets <= 0 || entry.reps <= 0) {
          debugPrint('ExerciseHistory validation failed: Invalid sets (${entry.sets}) or reps (${entry.reps})');
          return false;
        }
        
        // Validate duration is not negative
        if (entry.durationSeconds < 0) {
          debugPrint('ExerciseHistory validation failed: Negative duration ${entry.durationSeconds}');
          return false;
        }
        
        // Validate status is valid
        if (!['completed', 'incomplete', 'skipped'].contains(entry.status.toLowerCase())) {
          debugPrint('ExerciseHistory validation failed: Invalid status ${entry.status}');
          return false;
        }
        
        // Validate date is not in the future
        if (entry.date.isAfter(DateTime.now())) {
          debugPrint('ExerciseHistory validation failed: Future date ${entry.date}');
          return false;
        }
      }
      return true;
    } catch (e) {
      debugPrint('ExerciseHistory validation error: $e');
      return false;
    }
  }

  static Future<void> loadFromHive() async {
    try {
      if (!Hive.isBoxOpen('rehabBox')) {
        debugPrint('ExerciseHistory.loadFromHive: Hive box not open, attempting to open...');
        await openRehabBox();
      }
      final box = Hive.box('rehabBox');
      final exerciseHistoryData = box.get('exerciseHistory', defaultValue: <Map<String, dynamic>>[]);
      
      if (exerciseHistoryData is List<dynamic>) {
        entries.clear();
        entries.addAll(exerciseHistoryData.map((entryData) {
          final entry = entryData as Map<String, dynamic>;
          return ExerciseRecordEntry(
            date: DateTime.fromMillisecondsSinceEpoch(entry['date']),
            exerciseId: entry['exerciseId'] ?? '',
            exerciseName: entry['exerciseName'] ?? '',
            sets: entry['sets'] ?? 0,
            reps: entry['reps'] ?? 0,
            durationSeconds: entry['durationSeconds'] ?? 0,
            status: entry['status'] ?? 'completed',
            painScale: entry['painScale'] as int?,
            painLevel: entry['painLevel'] as String?,
          );
        }));
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
    int? painScale,
    String? painLevel,
    DateTime? now,
  }) async {
    recordToday(
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      sets: sets,
      reps: reps,
      durationSeconds: durationSeconds,
      status: status,
      painScale: painScale,
      painLevel: painLevel,
      now: now,
    );
    
    // Attempt to save to both Firebase and Hive simultaneously
    // Firebase failure is acceptable, but Hive must succeed for the operation to proceed
    
    // Start Firebase save (non-blocking, errors are acceptable)
    Future<void>? firebaseSaveFuture;
    if (!UserDetails.isGuest && _auth.currentUser != null) {
      firebaseSaveFuture = saveToFirebase().then((_) {
        debugPrint('ExerciseHistory.recordTodayAndSave: Successfully saved to Firebase');
      }).catchError((e) {
        debugPrint('ExerciseHistory.recordTodayAndSave: Firebase save failed (non-critical): $e');
        // Firebase failure is acceptable, operation will proceed if Hive succeeds
      });
    } else {
      debugPrint('ExerciseHistory.recordTodayAndSave: User is guest or not authenticated, saving to Hive only');
    }
    
    // Save to Hive - this must succeed for the operation to proceed
    // If Hive save fails, the exception will be thrown and operation will fail
    await saveToHive();
    debugPrint('ExerciseHistory.recordTodayAndSave: Successfully saved to Hive');
    
    // Reload from Hive to ensure in-memory state matches what's persisted
    // This ensures the data is immediately available for the calendar and other views
    // The reload ensures ExerciseHistory.entries is synchronized with Hive storage
    try {
      await loadFromHive();
      debugPrint('ExerciseHistory.recordTodayAndSave: Reloaded from Hive, ${entries.length} entries now in memory');
    } catch (e) {
      debugPrint('ExerciseHistory.recordTodayAndSave: Warning - failed to reload from Hive: $e');
      // Don't fail the operation if reload fails, data is already saved
      // The in-memory entries were already updated by recordToday() above
    }
    
    // Wait for Firebase save to complete (if it was started), but don't fail if it errors
    // At this point, Hive save has succeeded, so we can proceed regardless of Firebase status
    if (firebaseSaveFuture != null) {
      try {
        await firebaseSaveFuture;
      } catch (e) {
        // Already logged in the catchError above, just ensure we don't throw
        // Hive save succeeded, so operation can proceed even if Firebase failed
        debugPrint('ExerciseHistory.recordTodayAndSave: Firebase save completed with error (non-critical): $e');
      }
    }
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
          painScale: null,
          painLevel: null,
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
          painScale: null,
          painLevel: null,
        ),
      );
      
      if (exerciseRecord.status != 'completed') {
        // Return a placeholder exercise with the reference data
        // Note: The actual exercise name and details will be loaded from CSV in the UI
        return Exercise(
          exerciseId: exerciseRef.exerciseId,
          exerciseName: 'Exercise ${exerciseRef.exerciseId}', // Will be replaced with actual name in UI
          description: 'Exercise from plan',
          muscle: 'Unknown',
          painLevel: 'Unknown',
          goal: 'Unknown',
          repetitions: exerciseRef.repetitions,
          sets: exerciseRef.sets,
          imageUrl: '',
          videoUrl: '',
          otherMuscles: '',
        );
      }
    }
    
    // If all exercises are completed, return the last exercise
    if (plan.exerciseReferences.isNotEmpty) {
      final lastRef = plan.exerciseReferences.last;
      return Exercise(
        exerciseId: lastRef.exerciseId,
        exerciseName: 'Exercise ${lastRef.exerciseId}', // Will be replaced with actual name in UI
        description: 'Exercise from plan',
        muscle: 'Unknown',
        painLevel: 'Unknown',
        goal: 'Unknown',
        repetitions: lastRef.repetitions,
        sets: lastRef.sets,
        imageUrl: '',
        videoUrl: '',
        otherMuscles: '',
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
  final String otherMuscles;

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
    required this.otherMuscles,
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