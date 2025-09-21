import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Helper class to manage Firebase collections and ensure they exist
class FirebaseHelper {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  /// Ensure user progress subcollection exists
  static Future<void> ensureUserProgressCollection() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('FirebaseHelper: No authenticated user found');
        throw Exception('No authenticated user found');
      }

      final String userId = currentUser.uid;
      
      // Ensure user document exists first
      await ensureUserDocument();
      
      // Check if user progress document exists
      final DocumentSnapshot progressDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('userProgress')
          .doc('progress')
          .get();

      if (!progressDoc.exists) {
        print('FirebaseHelper: Creating user progress document');
        
        // Create empty user progress document
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('userProgress')
            .doc('progress')
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
        
        print('FirebaseHelper: User progress document created successfully');
      } else {
        print('FirebaseHelper: User progress document already exists');
      }
    } catch (e) {
      print('FirebaseHelper: Error ensuring user progress collection: $e');
      rethrow;
    }
  }

  /// Ensure user assessment subcollection exists
  static Future<void> ensureUserAssessmentCollection() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('FirebaseHelper: No authenticated user found');
        throw Exception('No authenticated user found');
      }

      final String userId = currentUser.uid;
      
      // Ensure user document exists first
      await ensureUserDocument();
      
      // Check if user assessment document exists
      final DocumentSnapshot assessmentDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('userAssessment')
          .doc('assessment')
          .get();

      if (!assessmentDoc.exists) {
        print('FirebaseHelper: Creating user assessment document');
        
        // Create empty user assessment document
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('userAssessment')
            .doc('assessment')
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
        
        print('FirebaseHelper: User assessment document created successfully');
      } else {
        print('FirebaseHelper: User assessment document already exists');
      }
    } catch (e) {
      print('FirebaseHelper: Error ensuring user assessment collection: $e');
      rethrow;
    }
  }

  /// Ensure user settings subcollection exists
  static Future<void> ensureUserSettingsCollection() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('FirebaseHelper: No authenticated user found');
        throw Exception('No authenticated user found');
      }

      final String userId = currentUser.uid;
      
      // Ensure user document exists first
      await ensureUserDocument();
      
      // Check if user settings document exists
      final DocumentSnapshot settingsDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('userSettings')
          .doc('settings')
          .get();

      if (!settingsDoc.exists) {
        print('FirebaseHelper: Creating user settings document');
        
        // Create default user settings document
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('userSettings')
            .doc('settings')
            .set({
          'isDailyReminder': true,
          'isStreakAlert': true,
          'isExerciseReminder': true,
          'exerciseReminderHour': 8,
          'exerciseReminderMinute': 0,
          'lastUpdated': FieldValue.serverTimestamp(),
          'userId': userId,
        });
        
        print('FirebaseHelper: User settings document created successfully');
      } else {
        print('FirebaseHelper: User settings document already exists');
      }
    } catch (e) {
      print('FirebaseHelper: Error ensuring user settings collection: $e');
      rethrow;
    }
  }

  /// Ensure pain history subcollection exists
  static Future<void> ensurePainHistoryCollection() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('FirebaseHelper: No authenticated user found');
        throw Exception('No authenticated user found');
      }

      final String userId = currentUser.uid;
      
      // Ensure user document exists first
      await ensureUserDocument();
      
      // Check if pain history document exists
      final DocumentSnapshot painHistoryDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('painHistory')
          .doc('history')
          .get();

      if (!painHistoryDoc.exists) {
        print('FirebaseHelper: Creating pain history document');
        
        // Create empty pain history document
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('painHistory')
            .doc('history')
            .set({
          'entries': [],
          'lastPromptedDate': null,
          'lastUpdated': FieldValue.serverTimestamp(),
          'userId': userId,
        });
        
        print('FirebaseHelper: Pain history document created successfully');
      } else {
        print('FirebaseHelper: Pain history document already exists');
      }
    } catch (e) {
      print('FirebaseHelper: Error ensuring pain history collection: $e');
      rethrow;
    }
  }

  /// Ensure exercise history subcollection exists
  static Future<void> ensureExerciseHistoryCollection() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('FirebaseHelper: No authenticated user found');
        throw Exception('No authenticated user found');
      }

      final String userId = currentUser.uid;
      
      // Ensure user document exists first
      await ensureUserDocument();
      
      // Check if exercise history document exists
      final DocumentSnapshot exerciseHistoryDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('exerciseHistory')
          .doc('history')
          .get();

      if (!exerciseHistoryDoc.exists) {
        print('FirebaseHelper: Creating exercise history document');
        
        // Create empty exercise history document
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('exerciseHistory')
            .doc('history')
            .set({
          'entries': [],
          'lastUpdated': FieldValue.serverTimestamp(),
          'userId': userId,
        });
        
        print('FirebaseHelper: Exercise history document created successfully');
      } else {
        print('FirebaseHelper: Exercise history document already exists');
      }
    } catch (e) {
      print('FirebaseHelper: Error ensuring exercise history collection: $e');
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

  /// Check which collections actually exist in Firebase
  static Future<void> _checkExistingCollections(String userId, Map<String, dynamic> results) async {
    try {
      final List<String> collectionNames = [
        'rehabilitationPlans',
        'treatments',
        'userProgress',
        'userAssessment',
        'userSettings',
        'painHistory',
        'exerciseHistory',
      ];

      for (final collectionName in collectionNames) {
        try {
          final QuerySnapshot snapshot = await _firestore
              .collection('users')
              .doc(userId)
              .collection(collectionName)
              .limit(1)
              .get();
          
          if (snapshot.docs.isNotEmpty) {
            results['existingCollections'].add(collectionName);
          }
        } catch (e) {
          print('FirebaseHelper: Error checking $collectionName collection: $e');
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
      
      // Get rehabilitation plans count
      final QuerySnapshot plansSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('rehabilitationPlans')
          .get();

      // Get treatments count
      final QuerySnapshot treatmentsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('treatments')
          .get();

      return {
        'userId': userId,
        'firstName': userData['firstName'] ?? '',
        'lastName': userData['lastName'] ?? '',
        'email': userData['email'] ?? '',
        'createdAt': userData['createdAt'],
        'lastUpdated': userData['lastUpdated'],
        'rehabilitationPlansCount': plansSnapshot.docs.length,
        'treatmentsCount': treatmentsSnapshot.docs.length,
      };
    } catch (e) {
      print('FirebaseHelper: Error getting user data summary: $e');
      return {'error': e.toString()};
    }
  }
}
