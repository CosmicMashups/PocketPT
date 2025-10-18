import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_auth_diagnostics.dart';

/// Helper class to manage Firebase collections and ensure they exist
class FirebaseHelper {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Ensure user is properly authenticated before Firestore operations
  static Future<User?> ensureAuthenticatedUser() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('FirebaseHelper: No authenticated user found');
        return null;
      }

      // Try to reload user, but don't fail if it doesn't work
      try {
        await currentUser.reload();
      } catch (reloadError) {
        print('FirebaseHelper: User reload failed, but continuing: $reloadError');
      }
      
      final freshUser = _auth.currentUser;
      if (freshUser == null) {
        print('FirebaseHelper: User authentication lost after reload');
        return null;
      }

      // Try to get token without forcing refresh first
      try {
        await freshUser.getIdToken(false);
        print('FirebaseHelper: User authentication verified with existing token');
        return freshUser;
      } catch (tokenError) {
        print('FirebaseHelper: Existing token failed, trying refresh: $tokenError');
        // Only try refresh if existing token fails
        try {
          await freshUser.getIdToken(true);
          print('FirebaseHelper: User authentication verified with refreshed token');
          return freshUser;
        } catch (refreshError) {
          print('FirebaseHelper: Token refresh also failed: $refreshError');
          // Even if token refresh fails, if we have a user, let's try to proceed
          // This handles cases where the user is authenticated but token operations fail
          print('FirebaseHelper: Proceeding with user despite token issues');
          return freshUser;
        }
      }
    } catch (e) {
      print('FirebaseHelper: Error ensuring authenticated user: $e');
      // Return the current user if available, even if there were errors
      final fallbackUser = _auth.currentUser;
      if (fallbackUser != null) {
        print('FirebaseHelper: Using fallback user despite errors');
        return fallbackUser;
      }
      return null;
    }
  }

  /// Ensure user document exists in Firebase
  static Future<void> ensureUserDocument() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('FirebaseHelper: No authenticated user found');
        throw Exception('No authenticated user found');
      }

      final String userId = currentUser.uid;
      
      // Check if user document exists
      final DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        print('FirebaseHelper: Creating user document for $userId');
        
        // Create user document
        await _firestore.collection('users').doc(userId).set({
          'userId': userId,
          'firstName': currentUser.displayName?.split(' ').first ?? '',
          'lastName': currentUser.displayName?.split(' ').skip(1).join(' ') ?? '',
          'email': currentUser.email ?? '',
          'createdAt': FieldValue.serverTimestamp(),
          'lastUpdated': FieldValue.serverTimestamp(),
        });
        
        print('FirebaseHelper: User document created successfully');
      } else {
        print('FirebaseHelper: User document already exists');
      }
    } catch (e) {
      print('FirebaseHelper: Error ensuring user document: $e');
      rethrow;
    }
  }

  /// Ensure rehabilitation plans subcollection exists
  static Future<void> ensureRehabilitationPlansCollection() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('FirebaseHelper: No authenticated user found');
        throw Exception('No authenticated user found');
      }

      final String userId = currentUser.uid;
      
      // Ensure user document exists first
      await ensureUserDocument();
      
      // Check if rehabilitation plans document exists
      final DocumentSnapshot plansDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('rehabilitationPlans')
          .doc('plans')
          .get();

      if (!plansDoc.exists) {
        print('FirebaseHelper: Creating rehabilitation plans document');
        
        // Create empty rehabilitation plans document
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('rehabilitationPlans')
            .doc('plans')
            .set({
          'plans': [],
          'lastUpdated': FieldValue.serverTimestamp(),
          'userId': userId,
        });
        
        print('FirebaseHelper: Rehabilitation plans document created successfully');
      } else {
        print('FirebaseHelper: Rehabilitation plans document already exists');
      }
    } catch (e) {
      print('FirebaseHelper: Error ensuring rehabilitation plans collection: $e');
      rethrow;
    }
  }

  /// Ensure treatments subcollection exists
  static Future<void> ensureTreatmentsCollection() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('FirebaseHelper: No authenticated user found');
        throw Exception('No authenticated user found');
      }

      final String userId = currentUser.uid;
      
      // Ensure user document exists first
      await ensureUserDocument();
      
      // Check if treatments document exists
      final DocumentSnapshot treatmentsDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('treatments')
          .doc('treatments')
          .get();

      if (!treatmentsDoc.exists) {
        print('FirebaseHelper: Creating treatments document');
        
        // Create empty treatments document
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('treatments')
            .doc('treatments')
            .set({
          'treatments': [],
          'lastUpdated': FieldValue.serverTimestamp(),
          'userId': userId,
        });
        
        print('FirebaseHelper: Treatments document created successfully');
      } else {
        print('FirebaseHelper: Treatments document already exists');
      }
    } catch (e) {
      print('FirebaseHelper: Error ensuring treatments collection: $e');
      rethrow;
    }
  }

  /// Ensure user progress collection exists (flat structure: progress/{userId})
  static Future<void> ensureUserProgressCollection() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('FirebaseHelper: No authenticated user found');
        throw Exception('No authenticated user found');
      }

      final String userId = currentUser.uid;
      
      // Check if user progress document exists in flat collection
      final DocumentSnapshot progressDoc = await _firestore
          .collection('progress')
          .doc(userId)
          .get();

      if (!progressDoc.exists) {
        print('FirebaseHelper: Creating user progress document in progress collection');
        
        // Create empty user progress document in flat collection
        await _firestore
            .collection('progress')
            .doc(userId)
            .set({
          'title': 'Initiator',
          'titleColor': '',
          'streak': 0,
          'totalDays': 0,
          'totalExercises': 0,
          'totalSeconds': 0,
          'notes': '',
          'lastExerciseDate': null,
          'lastUpdated': FieldValue.serverTimestamp(),
          'userId': userId,
        });
        
        print('FirebaseHelper: User progress document created successfully in progress collection');
      } else {
        print('FirebaseHelper: User progress document already exists in progress collection');
      }
    } catch (e) {
      print('FirebaseHelper: Error ensuring user progress collection: $e');
      rethrow;
    }
  }

  /// Ensure user assessment collection exists (flat structure: assessment/{userId})
  static Future<void> ensureUserAssessmentCollection() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('FirebaseHelper: No authenticated user found');
        throw Exception('No authenticated user found');
      }

      final String userId = currentUser.uid;
      
      // Check if user assessment document exists in flat collection
      final DocumentSnapshot assessmentDoc = await _firestore
          .collection('assessment')
          .doc(userId)
          .get();

      if (!assessmentDoc.exists) {
        print('FirebaseHelper: Creating user assessment document in assessment collection');
        
        // Create empty user assessment document in flat collection
        await _firestore
            .collection('assessment')
            .doc(userId)
            .set({
          'rehabGoal': '',
          'generalMuscle': '',
          'specificMuscle': '',
          'painScale': 0,
          'painLevel': '',
          'painType': '',
          'painDuration': '',
          'isInjured': false,
          'isAssessed': false,
          'lastUpdated': FieldValue.serverTimestamp(),
          'userId': userId,
        });
        
        print('FirebaseHelper: User assessment document created successfully in assessment collection');
      } else {
        print('FirebaseHelper: User assessment document already exists in assessment collection');
      }
    } catch (e) {
      print('FirebaseHelper: Error ensuring user assessment collection: $e');
      rethrow;
    }
  }

  /// Ensure user settings collection exists (flat structure: settings/{userId})
  static Future<void> ensureUserSettingsCollection() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('FirebaseHelper: No authenticated user found');
        throw Exception('No authenticated user found');
      }

      final String userId = currentUser.uid;
      
      // Check if user settings document exists in flat collection
      final DocumentSnapshot settingsDoc = await _firestore
          .collection('settings')
          .doc(userId)
          .get();

      if (!settingsDoc.exists) {
        print('FirebaseHelper: Creating user settings document in settings collection');
        
        // Create default user settings document in flat collection
        await _firestore
            .collection('settings')
            .doc(userId)
            .set({
          'isDailyReminder': true,
          'isStreakAlert': true,
          'isExerciseReminder': true,
          'exerciseReminderHour': 8,
          'exerciseReminderMinute': 0,
          'lastUpdated': FieldValue.serverTimestamp(),
          'userId': userId,
        });
        
        print('FirebaseHelper: User settings document created successfully in settings collection');
      } else {
        print('FirebaseHelper: User settings document already exists in settings collection');
      }
    } catch (e) {
      print('FirebaseHelper: Error ensuring user settings collection: $e');
      rethrow;
    }
  }

  /// Ensure pain history collection exists (flat structure: painHistory/{userId})
  static Future<void> ensurePainHistoryCollection() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('FirebaseHelper: No authenticated user found');
        throw Exception('No authenticated user found');
      }

      final String userId = currentUser.uid;
      
      // Check if pain history document exists in flat collection
      final DocumentSnapshot painHistoryDoc = await _firestore
          .collection('painHistory')
          .doc(userId)
          .get();

      if (!painHistoryDoc.exists) {
        print('FirebaseHelper: Creating pain history document in painHistory collection');
        
        // Create empty pain history document in flat collection
        await _firestore
            .collection('painHistory')
            .doc(userId)
            .set({
          'entries': [],
          'lastPromptedDate': null,
          'lastUpdated': FieldValue.serverTimestamp(),
          'userId': userId,
        });
        
        print('FirebaseHelper: Pain history document created successfully in painHistory collection');
      } else {
        print('FirebaseHelper: Pain history document already exists in painHistory collection');
      }
    } catch (e) {
      print('FirebaseHelper: Error ensuring pain history collection: $e');
      rethrow;
    }
  }

  /// Ensure exercise history collection exists (flat structure: exerciseHistory/{userId})
  static Future<void> ensureExerciseHistoryCollection() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('FirebaseHelper: No authenticated user found');
        throw Exception('No authenticated user found');
      }

      final String userId = currentUser.uid;
      
      // Check if exercise history document exists in flat collection
      final DocumentSnapshot exerciseHistoryDoc = await _firestore
          .collection('exerciseHistory')
          .doc(userId)
          .get();

      if (!exerciseHistoryDoc.exists) {
        print('FirebaseHelper: Creating exercise history document in exerciseHistory collection');
        
        // Create empty exercise history document in flat collection
        await _firestore
            .collection('exerciseHistory')
            .doc(userId)
            .set({
          'entries': [],
          'lastUpdated': FieldValue.serverTimestamp(),
          'userId': userId,
        });
        
        print('FirebaseHelper: Exercise history document created successfully in exerciseHistory collection');
      } else {
        print('FirebaseHelper: Exercise history document already exists in exerciseHistory collection');
      }
    } catch (e) {
      print('FirebaseHelper: Error ensuring exercise history collection: $e');
      rethrow;
    }
  }

  /// Ensure rehabilitation collection exists (flat structure: rehabilitation/{userId})
  static Future<void> ensureRehabilitationCollection() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('FirebaseHelper: No authenticated user found');
        throw Exception('No authenticated user found');
      }

      final String userId = currentUser.uid;

      // Ensure user document exists first (for metadata consistency)
      await ensureUserDocument();

      // Check if rehabilitation document exists in flat collection
      final DocumentSnapshot rehabDoc = await _firestore
          .collection('rehabilitation')
          .doc(userId)
          .get();

      if (!rehabDoc.exists) {
        print('FirebaseHelper: Creating rehabilitation document in rehabilitation collection');

        await _firestore
            .collection('rehabilitation')
            .doc(userId)
            .set({
          'userId': userId,
          'lastUpdated': FieldValue.serverTimestamp(),
        });

        print('FirebaseHelper: Rehabilitation document created successfully in rehabilitation collection');
      } else {
        print('FirebaseHelper: Rehabilitation document already exists in rehabilitation collection');
      }
    } catch (e) {
      print('FirebaseHelper: Error ensuring rehabilitation collection: $e');
      rethrow;
    }
  }

  /// Initialize all required collections for a user
  static Future<void> initializeUserCollections() async {
    try {
      print('FirebaseHelper: Initializing user collections...');
      
      await ensureUserDocument();
      await ensureRehabilitationPlansCollection();
      await ensureTreatmentsCollection();
      await ensureUserProgressCollection();
      await ensureUserAssessmentCollection();
      await ensureUserSettingsCollection();
      await ensurePainHistoryCollection();
      await ensureExerciseHistoryCollection();
      
      print('FirebaseHelper: All user collections initialized successfully');
    } catch (e) {
      print('FirebaseHelper: Error initializing user collections: $e');
      rethrow;
    }
  }

  /// Ensure all collections exist with comprehensive error handling
  static Future<Map<String, dynamic>> ensureAllCollectionsExist() async {
    final results = <String, dynamic>{
      'success': true,
      'createdCollections': <String>[],
      'existingCollections': <String>[],
      'errors': <String>[],
    };

    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        results['success'] = false;
        results['errors'].add('No authenticated user found');
        return results;
      }

      final String userId = currentUser.uid;
      print('FirebaseHelper: Ensuring all collections exist for user: $userId');

      // List of collection creation methods
      final List<Map<String, dynamic>> collectionMethods = [
        {'name': 'userDocument', 'method': ensureUserDocument},
        {'name': 'rehabilitationPlans', 'method': ensureRehabilitationPlansCollection},
        {'name': 'treatments', 'method': ensureTreatmentsCollection},
        {'name': 'rehabilitation', 'method': ensureRehabilitationCollection},
        {'name': 'userProgress', 'method': ensureUserProgressCollection},
        {'name': 'userAssessment', 'method': ensureUserAssessmentCollection},
        {'name': 'userSettings', 'method': ensureUserSettingsCollection},
        {'name': 'painHistory', 'method': ensurePainHistoryCollection},
        {'name': 'exerciseHistory', 'method': ensureExerciseHistoryCollection},
      ];

      for (final collectionInfo in collectionMethods) {
        try {
          await collectionInfo['method']();
          results['createdCollections'].add(collectionInfo['name']);
          print('FirebaseHelper: Successfully ensured ${collectionInfo['name']} collection exists');
        } catch (e) {
          print('FirebaseHelper: Error ensuring ${collectionInfo['name']} collection: $e');
          results['errors'].add('${collectionInfo['name']}: $e');
          results['success'] = false;
        }
      }

      // Check which collections actually exist
      await _checkExistingCollections(userId, results);

      print('FirebaseHelper: Collection creation completed');
      print('FirebaseHelper: Created: ${results['createdCollections']}');
      print('FirebaseHelper: Existing: ${results['existingCollections']}');
      if (results['errors'].isNotEmpty) {
        print('FirebaseHelper: Errors: ${results['errors']}');
      }

    } catch (e) {
      print('FirebaseHelper: Error in ensureAllCollectionsExist: $e');
      results['success'] = false;
      results['errors'].add('General error: $e');
    }

    return results;
  }

  /// Check which collections actually exist in Firebase (flat structure)
  static Future<void> _checkExistingCollections(String userId, Map<String, dynamic> results) async {
    try {
      // Check flat collections
      final List<String> flatCollectionNames = [
        'progress',
        'assessment',
        'settings',
        'painHistory',
        'exerciseHistory',
      ];

      for (final collectionName in flatCollectionNames) {
        try {
          final DocumentSnapshot snapshot = await _firestore
              .collection(collectionName)
              .doc(userId)
              .get();
          
          if (snapshot.exists) {
            results['existingCollections'].add(collectionName);
          }
        } catch (e) {
          print('FirebaseHelper: Error checking $collectionName collection: $e');
        }
      }

      // Check rehabilitation collection (also flat)
      try {
        final DocumentSnapshot rehabSnapshot = await _firestore
            .collection('rehabilitation')
            .doc(userId)
            .get();
        
        if (rehabSnapshot.exists) {
          results['existingCollections'].add('rehabilitation');
        }
      } catch (e) {
        print('FirebaseHelper: Error checking rehabilitation collection: $e');
      }

      // Check legacy nested collections (for backward compatibility)
      final List<String> legacyCollectionNames = [
        'rehabilitationPlans',
        'treatments',
      ];

      for (final collectionName in legacyCollectionNames) {
        try {
          final QuerySnapshot snapshot = await _firestore
              .collection('users')
              .doc(userId)
              .collection(collectionName)
              .limit(1)
              .get();
          
          if (snapshot.docs.isNotEmpty) {
            results['existingCollections'].add('legacy_$collectionName');
          }
        } catch (e) {
          print('FirebaseHelper: Error checking legacy $collectionName collection: $e');
        }
      }
    } catch (e) {
      print('FirebaseHelper: Error checking existing collections: $e');
    }
  }

  /// Check if user has any data in Firebase
  static Future<bool> hasUserData() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      final String userId = currentUser.uid;
      
      // Check if user document exists
      final DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      return userDoc.exists;
    } catch (e) {
      print('FirebaseHelper: Error checking user data: $e');
      return false;
    }
  }

  /// Get user's data summary
  static Future<Map<String, dynamic>> getUserDataSummary() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        return {'error': 'No authenticated user'};
      }

      final String userId = currentUser.uid;
      
      // Get user document
      final DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        return {'error': 'User document not found'};
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      
      // Check rehabilitation data (flat collection)
      final DocumentSnapshot rehabSnapshot = await _firestore
          .collection('rehabilitation')
          .doc(userId)
          .get();

      // Check progress data (flat collection)
      final DocumentSnapshot progressSnapshot = await _firestore
          .collection('progress')
          .doc(userId)
          .get();

      // Check assessment data (flat collection)
      final DocumentSnapshot assessmentSnapshot = await _firestore
          .collection('assessment')
          .doc(userId)
          .get();

      return {
        'userId': userId,
        'firstName': userData['firstName'] ?? '',
        'lastName': userData['lastName'] ?? '',
        'email': userData['email'] ?? '',
        'createdAt': userData['createdAt'],
        'lastUpdated': userData['lastUpdated'],
        'hasRehabilitationData': rehabSnapshot.exists,
        'hasProgressData': progressSnapshot.exists,
        'hasAssessmentData': assessmentSnapshot.exists,
      };
    } catch (e) {
      print('FirebaseHelper: Error getting user data summary: $e');
      return {'error': e.toString()};
    }
  }
}
