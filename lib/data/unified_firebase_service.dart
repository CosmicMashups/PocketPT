import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'unified_data_models.dart';

/// Unified Firebase service that handles all Firebase operations with consistent schema
class UnifiedFirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user ID
  static String? get currentUserId => _auth.currentUser?.uid;

  /// Check if user is authenticated
  static bool get isAuthenticated => _auth.currentUser != null;

  /// Save UserDetails to Firebase
  static Future<bool> saveUserDetails(UnifiedUserDetails userDetails) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        debugPrint('UnifiedFirebaseService: No authenticated user');
        return false;
      }

      final firebaseMap = userDetails.toFirebaseMap();
      firebaseMap['userId'] = userId; // Ensure userId is set
      firebaseMap['lastUpdated'] = FieldValue.serverTimestamp();

      await _firestore.collection('users').doc(userId).set(firebaseMap, SetOptions(merge: true));
      
      debugPrint('UnifiedFirebaseService: Saved UserDetails to Firebase');
      return true;
    } catch (e) {
      debugPrint('UnifiedFirebaseService: Error saving UserDetails: $e');
      return false;
    }
  }

  /// Load UserDetails from Firebase
  static Future<UnifiedUserDetails?> loadUserDetails() async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        debugPrint('UnifiedFirebaseService: No authenticated user');
        return null;
      }

      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) {
        debugPrint('UnifiedFirebaseService: UserDetails document does not exist');
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      final userDetails = UnifiedUserDetails.fromFirebaseMap(data);
      
      debugPrint('UnifiedFirebaseService: Loaded UserDetails from Firebase');
      return userDetails;
    } catch (e) {
      debugPrint('UnifiedFirebaseService: Error loading UserDetails: $e');
      return null;
    }
  }

  /// Save UserProgress to Firebase
  static Future<bool> saveUserProgress(UnifiedUserProgress userProgress) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        debugPrint('UnifiedFirebaseService: No authenticated user');
        return false;
      }

      final firebaseMap = userProgress.toFirebaseMap();
      firebaseMap['userId'] = userId; // Ensure userId is set
      firebaseMap['lastUpdated'] = FieldValue.serverTimestamp();

      await _firestore.collection('progress').doc(userId).set(firebaseMap, SetOptions(merge: true));
      
      debugPrint('UnifiedFirebaseService: Saved UserProgress to Firebase');
      return true;
    } catch (e) {
      debugPrint('UnifiedFirebaseService: Error saving UserProgress: $e');
      return false;
    }
  }

  /// Load UserProgress from Firebase
  static Future<UnifiedUserProgress?> loadUserProgress() async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        debugPrint('UnifiedFirebaseService: No authenticated user');
        return null;
      }

      final doc = await _firestore.collection('progress').doc(userId).get();
      if (!doc.exists) {
        debugPrint('UnifiedFirebaseService: UserProgress document does not exist');
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      final userProgress = UnifiedUserProgress.fromFirebaseMap(data);
      
      debugPrint('UnifiedFirebaseService: Loaded UserProgress from Firebase');
      return userProgress;
    } catch (e) {
      debugPrint('UnifiedFirebaseService: Error loading UserProgress: $e');
      return null;
    }
  }

  /// Save UserSettings to Firebase
  static Future<bool> saveUserSettings(UnifiedUserSettings userSettings) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        debugPrint('UnifiedFirebaseService: No authenticated user');
        return false;
      }

      final firebaseMap = userSettings.toFirebaseMap();
      firebaseMap['userId'] = userId; // Ensure userId is set
      firebaseMap['lastUpdated'] = FieldValue.serverTimestamp();

      await _firestore.collection('settings').doc(userId).set(firebaseMap, SetOptions(merge: true));
      
      debugPrint('UnifiedFirebaseService: Saved UserSettings to Firebase');
      return true;
    } catch (e) {
      debugPrint('UnifiedFirebaseService: Error saving UserSettings: $e');
      return false;
    }
  }

  /// Load UserSettings from Firebase
  static Future<UnifiedUserSettings?> loadUserSettings() async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        debugPrint('UnifiedFirebaseService: No authenticated user');
        return null;
      }

      final doc = await _firestore.collection('settings').doc(userId).get();
      if (!doc.exists) {
        debugPrint('UnifiedFirebaseService: UserSettings document does not exist');
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      final userSettings = UnifiedUserSettings.fromFirebaseMap(data);
      
      debugPrint('UnifiedFirebaseService: Loaded UserSettings from Firebase');
      return userSettings;
    } catch (e) {
      debugPrint('UnifiedFirebaseService: Error loading UserSettings: $e');
      return null;
    }
  }

  /// Save PainHistory to Firebase
  static Future<bool> savePainHistory(List<UnifiedPainRecordEntry> painHistory) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        debugPrint('UnifiedFirebaseService: No authenticated user');
        return false;
      }

      // Convert to Firebase format
      final entriesData = painHistory.map((entry) => entry.toFirebaseMap()).toList();
      
      await _firestore.collection('painHistory').doc(userId).set({
        'userId': userId,
        'entries': entriesData,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      debugPrint('UnifiedFirebaseService: Saved PainHistory to Firebase (${painHistory.length} entries)');
      return true;
    } catch (e) {
      debugPrint('UnifiedFirebaseService: Error saving PainHistory: $e');
      return false;
    }
  }

  /// Load PainHistory from Firebase
  static Future<List<UnifiedPainRecordEntry>> loadPainHistory() async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        debugPrint('UnifiedFirebaseService: No authenticated user');
        return [];
      }

      final doc = await _firestore.collection('painHistory').doc(userId).get();
      if (!doc.exists) {
        debugPrint('UnifiedFirebaseService: PainHistory document does not exist');
        return [];
      }

      final data = doc.data() as Map<String, dynamic>;
      final entries = data['entries'] as List<dynamic>? ?? [];
      
      final painHistory = entries
          .where((entry) => entry is Map<String, dynamic>)
          .map((entry) => UnifiedPainRecordEntry.fromFirebaseMap(entry as Map<String, dynamic>))
          .toList();
      
      debugPrint('UnifiedFirebaseService: Loaded PainHistory from Firebase (${painHistory.length} entries)');
      return painHistory;
    } catch (e) {
      debugPrint('UnifiedFirebaseService: Error loading PainHistory: $e');
      return [];
    }
  }

  /// Save ExerciseHistory to Firebase
  static Future<bool> saveExerciseHistory(List<UnifiedExerciseRecordEntry> exerciseHistory) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        debugPrint('UnifiedFirebaseService: No authenticated user');
        return false;
      }

      // Convert to Firebase format
      final entriesData = exerciseHistory.map((entry) => entry.toFirebaseMap()).toList();
      
      await _firestore.collection('exerciseHistory').doc(userId).set({
        'userId': userId,
        'entries': entriesData,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      debugPrint('UnifiedFirebaseService: Saved ExerciseHistory to Firebase (${exerciseHistory.length} entries)');
      return true;
    } catch (e) {
      debugPrint('UnifiedFirebaseService: Error saving ExerciseHistory: $e');
      return false;
    }
  }

  /// Load ExerciseHistory from Firebase
  static Future<List<UnifiedExerciseRecordEntry>> loadExerciseHistory() async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        debugPrint('UnifiedFirebaseService: No authenticated user');
        return [];
      }

      final doc = await _firestore.collection('exerciseHistory').doc(userId).get();
      if (!doc.exists) {
        debugPrint('UnifiedFirebaseService: ExerciseHistory document does not exist');
        return [];
      }

      final data = doc.data() as Map<String, dynamic>;
      final entries = data['entries'] as List<dynamic>? ?? [];
      
      final exerciseHistory = entries
          .where((entry) => entry is Map<String, dynamic>)
          .map((entry) => UnifiedExerciseRecordEntry.fromFirebaseMap(entry as Map<String, dynamic>))
          .toList();
      
      debugPrint('UnifiedFirebaseService: Loaded ExerciseHistory from Firebase (${exerciseHistory.length} entries)');
      return exerciseHistory;
    } catch (e) {
      debugPrint('UnifiedFirebaseService: Error loading ExerciseHistory: $e');
      return [];
    }
  }

  /// Save RehabilitationPlans to Firebase
  static Future<bool> saveRehabilitationPlans(List<UnifiedRehabilitationPlan> plans) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        debugPrint('UnifiedFirebaseService: No authenticated user');
        return false;
      }

      // Convert to Firebase format
      final plansData = plans.map((plan) => plan.toFirebaseMap()).toList();
      
      await _firestore.collection('rehabilitation').doc(userId).set({
        'userId': userId,
        'plans': plansData,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      debugPrint('UnifiedFirebaseService: Saved RehabilitationPlans to Firebase (${plans.length} plans)');
      return true;
    } catch (e) {
      debugPrint('UnifiedFirebaseService: Error saving RehabilitationPlans: $e');
      return false;
    }
  }

  /// Load RehabilitationPlans from Firebase
  static Future<List<UnifiedRehabilitationPlan>> loadRehabilitationPlans() async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        debugPrint('UnifiedFirebaseService: No authenticated user');
        return [];
      }

      final doc = await _firestore.collection('rehabilitation').doc(userId).get();
      if (!doc.exists) {
        debugPrint('UnifiedFirebaseService: RehabilitationPlans document does not exist');
        return [];
      }

      final data = doc.data() as Map<String, dynamic>;
      final plans = data['plans'] as List<dynamic>? ?? [];
      
      final rehabilitationPlans = plans
          .where((plan) => plan is Map<String, dynamic>)
          .map((plan) => UnifiedRehabilitationPlan.fromFirebaseMap(plan as Map<String, dynamic>))
          .toList();
      
      debugPrint('UnifiedFirebaseService: Loaded RehabilitationPlans from Firebase (${rehabilitationPlans.length} plans)');
      return rehabilitationPlans;
    } catch (e) {
      debugPrint('UnifiedFirebaseService: Error loading RehabilitationPlans: $e');
      return [];
    }
  }

  /// Create default user document in Firebase
  static Future<bool> createDefaultUserDocument(String userId) async {
    try {
      final defaultUserDetails = UnifiedUserDetails(
        userId: userId,
        firstName: '',
        lastName: '',
        email: '',
        password: '', // Never store password in Firebase
        profilePicture: '01.jpg',
        hasCompletedAssessment: false,
        isGuest: false,
        guestSessionId: null,
        notifications: [],
        lastModified: DateTime.now(),
      );

      final defaultUserProgress = UnifiedUserProgress(
        userId: userId,
        title: 'Initiator',
        titleColor: '',
        streak: 0,
        totalDays: 0,
        totalExercises: 0,
        totalSeconds: 0,
        notes: null,
        lastExerciseDate: null,
        lastModified: DateTime.now(),
      );

      final defaultUserSettings = UnifiedUserSettings(
        userId: userId,
        isDailyReminder: true,
        isStreakAlert: true,
        isExerciseReminder: true,
        exerciseReminderHour: 8,
        exerciseReminderMinute: 0,
        lastModified: DateTime.now(),
      );

      // Save all default documents
      await saveUserDetails(defaultUserDetails);
      await saveUserProgress(defaultUserProgress);
      await saveUserSettings(defaultUserSettings);
      
      debugPrint('UnifiedFirebaseService: Created default user documents');
      return true;
    } catch (e) {
      debugPrint('UnifiedFirebaseService: Error creating default user documents: $e');
      return false;
    }
  }

  /// Check if user document exists in Firebase
  static Future<bool> userDocumentExists(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.exists;
    } catch (e) {
      debugPrint('UnifiedFirebaseService: Error checking user document existence: $e');
      return false;
    }
  }

  /// Delete user data from Firebase
  static Future<bool> deleteUserData(String userId) async {
    try {
      // Delete all user documents
      await _firestore.collection('users').doc(userId).delete();
      await _firestore.collection('progress').doc(userId).delete();
      await _firestore.collection('settings').doc(userId).delete();
      await _firestore.collection('painHistory').doc(userId).delete();
      await _firestore.collection('exerciseHistory').doc(userId).delete();
      await _firestore.collection('rehabilitation').doc(userId).delete();
      
      debugPrint('UnifiedFirebaseService: Deleted all user data from Firebase');
      return true;
    } catch (e) {
      debugPrint('UnifiedFirebaseService: Error deleting user data: $e');
      return false;
    }
  }

  /// Sync data between Hive and Firebase with conflict resolution
  static Future<bool> syncData({
    required UnifiedUserDetails? hiveUserDetails,
    required UnifiedUserDetails? firebaseUserDetails,
    required UnifiedUserProgress? hiveUserProgress,
    required UnifiedUserProgress? firebaseUserProgress,
    required UnifiedUserSettings? hiveUserSettings,
    required UnifiedUserSettings? firebaseUserSettings,
  }) async {
    try {
      // Resolve conflicts using last-write-wins strategy
      final resolvedUserDetails = _resolveUserDetailsConflict(hiveUserDetails, firebaseUserDetails);
      final resolvedUserProgress = _resolveUserProgressConflict(hiveUserProgress, firebaseUserProgress);
      final resolvedUserSettings = _resolveUserSettingsConflict(hiveUserSettings, firebaseUserSettings);

      // Save resolved data to both Hive and Firebase
      if (resolvedUserDetails != null) {
        await saveUserDetails(resolvedUserDetails);
      }
      if (resolvedUserProgress != null) {
        await saveUserProgress(resolvedUserProgress);
      }
      if (resolvedUserSettings != null) {
        await saveUserSettings(resolvedUserSettings);
      }

      debugPrint('UnifiedFirebaseService: Data sync completed');
      return true;
    } catch (e) {
      debugPrint('UnifiedFirebaseService: Error syncing data: $e');
      return false;
    }
  }

  /// Resolve UserDetails conflict using last-write-wins
  static UnifiedUserDetails? _resolveUserDetailsConflict(
    UnifiedUserDetails? hive,
    UnifiedUserDetails? firebase,
  ) {
    if (hive == null && firebase == null) return null;
    if (hive == null) return firebase;
    if (firebase == null) return hive;

    // Use lastModified to determine winner
    final hiveTime = hive.lastModified;
    final firebaseTime = firebase.lastModified;

    if (hiveTime == null && firebaseTime == null) return firebase; // Default to firebase
    if (hiveTime == null) return firebase;
    if (firebaseTime == null) return hive;

    return hiveTime.isAfter(firebaseTime) ? hive : firebase;
  }

  /// Resolve UserProgress conflict using last-write-wins
  static UnifiedUserProgress? _resolveUserProgressConflict(
    UnifiedUserProgress? hive,
    UnifiedUserProgress? firebase,
  ) {
    if (hive == null && firebase == null) return null;
    if (hive == null) return firebase;
    if (firebase == null) return hive;

    // Use lastModified to determine winner
    final hiveTime = hive.lastModified;
    final firebaseTime = firebase.lastModified;

    if (hiveTime == null && firebaseTime == null) return firebase; // Default to firebase
    if (hiveTime == null) return firebase;
    if (firebaseTime == null) return hive;

    return hiveTime.isAfter(firebaseTime) ? hive : firebase;
  }

  /// Resolve UserSettings conflict using last-write-wins
  static UnifiedUserSettings? _resolveUserSettingsConflict(
    UnifiedUserSettings? hive,
    UnifiedUserSettings? firebase,
  ) {
    if (hive == null && firebase == null) return null;
    if (hive == null) return firebase;
    if (firebase == null) return hive;

    // Use lastModified to determine winner
    final hiveTime = hive.lastModified;
    final firebaseTime = firebase.lastModified;

    if (hiveTime == null && firebaseTime == null) return firebase; // Default to firebase
    if (hiveTime == null) return firebase;
    if (firebaseTime == null) return hive;

    return hiveTime.isAfter(firebaseTime) ? hive : firebase;
  }
}
