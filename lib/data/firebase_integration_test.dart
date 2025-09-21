import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'globals.dart';
import 'rehabilitation_plan.dart';
import 'firebase_helper.dart';
import 'firebase_config_verifier.dart';

/// Comprehensive test class for Firebase integration
class FirebaseIntegrationTest {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Test all Firebase integration points
  static Future<Map<String, dynamic>> runAllTests() async {
    final results = <String, dynamic>{};
    
    print('=== FIREBASE INTEGRATION TEST STARTED ===');
    
    try {
      // Test 0: Firebase Configuration
      results['configuration'] = await _testConfiguration();
      
      // Test 1: Authentication Status
      results['authentication'] = await _testAuthentication();
      
      // Test 2: User Document Creation
      results['userDocument'] = await _testUserDocument();
      
      // Test 3: Collection Initialization
      results['collections'] = await _testCollectionInitialization();
      
      // Test 4: User Data Persistence
      results['userDataPersistence'] = await _testUserDataPersistence();
      
      // Test 5: Rehabilitation Data Persistence
      results['rehabDataPersistence'] = await _testRehabDataPersistence();
      
      // Test 6: Data Synchronization
      results['dataSync'] = await _testDataSynchronization();
      
      // Test 7: Error Handling
      results['errorHandling'] = await _testErrorHandling();
      
      print('=== FIREBASE INTEGRATION TEST COMPLETED ===');
      
    } catch (e) {
      print('Firebase Integration Test Error: $e');
      results['error'] = e.toString();
    }
    
    return results;
  }

  /// Test Firebase configuration
  static Future<Map<String, dynamic>> _testConfiguration() async {
    try {
      final configResults = await FirebaseConfigVerifier.verifyConfiguration();
      
      final allPassed = configResults.values
          .where((result) => result is Map<String, dynamic> && result['passed'] == true)
          .length == configResults.length - 1; // -1 for error field
      
      print('Configuration Test: ${allPassed ? "PASSED" : "FAILED"}');
      
      return {
        'passed': allPassed,
        'details': configResults,
        'message': allPassed ? 'Firebase configuration is correct' : 'Firebase configuration issues found'
      };
    } catch (e) {
      print('Configuration Test Error: $e');
      return {'passed': false, 'error': e.toString()};
    }
  }

  /// Test authentication status
  static Future<Map<String, dynamic>> _testAuthentication() async {
    try {
      final user = _auth.currentUser;
      final isAuthenticated = user != null;
      
      print('Authentication Test: ${isAuthenticated ? "PASSED" : "FAILED"}');
      print('  User ID: ${user?.uid ?? "None"}');
      print('  Email: ${user?.email ?? "None"}');
      
      return {
        'passed': isAuthenticated,
        'userId': user?.uid,
        'email': user?.email,
        'message': isAuthenticated ? 'User is authenticated' : 'No authenticated user'
      };
    } catch (e) {
      print('Authentication Test Error: $e');
      return {'passed': false, 'error': e.toString()};
    }
  }

  /// Test user document creation
  static Future<Map<String, dynamic>> _testUserDocument() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {'passed': false, 'message': 'No authenticated user'};
      }

      // Test user document creation
      await FirebaseHelper.ensureUserDocument();
      
      // Verify document exists
      final doc = await _firestore.collection('users').doc(user.uid).get();
      final exists = doc.exists;
      
      print('User Document Test: ${exists ? "PASSED" : "FAILED"}');
      print('  Document exists: $exists');
      
      if (exists) {
        final data = doc.data();
        print('  User data: ${data?.keys.join(", ")}');
      }
      
      return {
        'passed': exists,
        'message': exists ? 'User document created successfully' : 'User document creation failed'
      };
    } catch (e) {
      print('User Document Test Error: $e');
      return {'passed': false, 'error': e.toString()};
    }
  }

  /// Test collection initialization
  static Future<Map<String, dynamic>> _testCollectionInitialization() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {'passed': false, 'message': 'No authenticated user'};
      }

      // Initialize all collections
      await FirebaseHelper.initializeUserCollections();
      
      // Check if collections exist
      final userId = user.uid;
      
      // Check rehabilitation plans collection
      final rehabDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('rehabilitationPlans')
          .doc('plans')
          .get();
      
      // Check treatments collection
      final treatmentsDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('treatments')
          .doc('treatments')
          .get();
      
      final rehabExists = rehabDoc.exists;
      final treatmentsExists = treatmentsDoc.exists;
      
      print('Collection Initialization Test: ${rehabExists && treatmentsExists ? "PASSED" : "FAILED"}');
      print('  Rehabilitation Plans: $rehabExists');
      print('  Treatments: $treatmentsExists');
      
      return {
        'passed': rehabExists && treatmentsExists,
        'rehabilitationPlans': rehabExists,
        'treatments': treatmentsExists,
        'message': 'Collections initialized successfully'
      };
    } catch (e) {
      print('Collection Initialization Test Error: $e');
      return {'passed': false, 'error': e.toString()};
    }
  }

  /// Test user data persistence
  static Future<Map<String, dynamic>> _testUserDataPersistence() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {'passed': false, 'message': 'No authenticated user'};
      }

      // Test saving user data
      final originalFirstName = UserDetails.firstName;
      final originalLastName = UserDetails.lastName;
      final originalEmail = UserDetails.email;
      
      // Update user data
      UserDetails.firstName = 'Test';
      UserDetails.lastName = 'User';
      UserDetails.email = 'test@example.com';
      
      // Save to Firebase
      await UserDetails.updateInFirebase(
        newFirstName: 'Test',
        newLastName: 'User',
        newEmail: 'test@example.com',
      );
      
      // Load from Firebase
      await UserDetails.loadFromFirebase();
      
      final dataMatches = UserDetails.firstName == 'Test' && 
                         UserDetails.lastName == 'User' && 
                         UserDetails.email == 'test@example.com';
      
      print('User Data Persistence Test: ${dataMatches ? "PASSED" : "FAILED"}');
      print('  First Name: ${UserDetails.firstName}');
      print('  Last Name: ${UserDetails.lastName}');
      print('  Email: ${UserDetails.email}');
      
      // Restore original data
      UserDetails.firstName = originalFirstName;
      UserDetails.lastName = originalLastName;
      UserDetails.email = originalEmail;
      await UserDetails.updateInFirebase(
        newFirstName: originalFirstName,
        newLastName: originalLastName,
        newEmail: originalEmail,
      );
      
      return {
        'passed': dataMatches,
        'message': dataMatches ? 'User data persistence working' : 'User data persistence failed'
      };
    } catch (e) {
      print('User Data Persistence Test Error: $e');
      return {'passed': false, 'error': e.toString()};
    }
  }

  /// Test rehabilitation data persistence
  static Future<Map<String, dynamic>> _testRehabDataPersistence() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {'passed': false, 'message': 'No authenticated user'};
      }

      // Create test rehabilitation plan
      final testPlan = RehabilitationPlan(
        weekNumber: 1,
        exerciseReferences: [
          ExerciseReference(
            exerciseId: 'test_ex_001',
            repetitions: 10,
            sets: 3,
          ),
        ],
        daily: [
          DailyProgress(
            date: DateTime.now(),
            completedExercises: {'test_ex_001': true},
          ),
        ],
      );
      
      // Save test plan
      UserRehabilitation.instance.rehabPlans = [testPlan];
      await UserRehabilitation.instance.savePlansToFirebase();
      
      // Clear local data
      UserRehabilitation.instance.rehabPlans = [];
      
      // Load from Firebase
      await UserRehabilitation.instance.loadPlansFromFirebase();
      
      final planLoaded = UserRehabilitation.instance.rehabPlans.isNotEmpty;
      final exerciseMatches = planLoaded && 
                             UserRehabilitation.instance.rehabPlans.first.exerciseReferences.isNotEmpty &&
                             UserRehabilitation.instance.rehabPlans.first.exerciseReferences.first.exerciseId == 'test_ex_001';
      
      print('Rehabilitation Data Persistence Test: ${exerciseMatches ? "PASSED" : "FAILED"}');
      print('  Plans loaded: $planLoaded');
      print('  Exercise matches: $exerciseMatches');
      
      // Clean up test data
      UserRehabilitation.instance.rehabPlans = [];
      await UserRehabilitation.instance.savePlansToFirebase();
      
      return {
        'passed': exerciseMatches,
        'message': exerciseMatches ? 'Rehabilitation data persistence working' : 'Rehabilitation data persistence failed'
      };
    } catch (e) {
      print('Rehabilitation Data Persistence Test Error: $e');
      return {'passed': false, 'error': e.toString()};
    }
  }

  /// Test data synchronization
  static Future<Map<String, dynamic>> _testDataSynchronization() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {'passed': false, 'message': 'No authenticated user'};
      }

      // Test sync functionality
      await UserRehabilitation.instance.syncWithFirebase();
      
      print('Data Synchronization Test: PASSED');
      print('  Sync completed successfully');
      
      return {
        'passed': true,
        'message': 'Data synchronization working'
      };
    } catch (e) {
      print('Data Synchronization Test Error: $e');
      return {'passed': false, 'error': e.toString()};
    }
  }

  /// Test error handling
  static Future<Map<String, dynamic>> _testErrorHandling() async {
    try {
      // Test with invalid operations to ensure proper error handling
      final results = <String, bool>{};
      
      // Test 1: Try to access Firebase without authentication (should handle gracefully)
      try {
        await FirebaseHelper.ensureUserDocument();
        results['noAuthError'] = true;
      } catch (e) {
        results['noAuthError'] = false; // Expected to fail
      }
      
      // Test 2: Try to load data when not authenticated (should handle gracefully)
      try {
        await UserDetails.loadFromFirebase();
        results['loadWithoutAuth'] = true;
      } catch (e) {
        results['loadWithoutAuth'] = false; // Expected to fail
      }
      
      final allHandled = results.values.every((handled) => !handled);
      
      print('Error Handling Test: ${allHandled ? "PASSED" : "FAILED"}');
      print('  Errors handled properly: $allHandled');
      
      return {
        'passed': allHandled,
        'message': allHandled ? 'Error handling working properly' : 'Error handling needs improvement'
      };
    } catch (e) {
      print('Error Handling Test Error: $e');
      return {'passed': false, 'error': e.toString()};
    }
  }

  /// Get Firebase connection status
  static Future<bool> isFirebaseConnected() async {
    try {
      await _firestore.enableNetwork();
      return true;
    } catch (e) {
      print('Firebase connection error: $e');
      return false;
    }
  }

  /// Get user data summary from Firebase
  static Future<Map<String, dynamic>> getFirebaseDataSummary() async {
    try {
      return await FirebaseHelper.getUserDataSummary();
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}
