import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Diagnostic service for Firebase authentication and permission issues
class FirebaseAuthDiagnostics {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Comprehensive authentication and permission diagnostics
  static Future<Map<String, dynamic>> runDiagnostics() async {
    final results = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'tests': <String, dynamic>{},
      'recommendations': <String>[],
      'overallStatus': 'unknown',
    };

    try {
      debugPrint('FirebaseAuthDiagnostics: Starting diagnostics...');
      
      // Test 1: Authentication Status
      debugPrint('FirebaseAuthDiagnostics: Testing authentication...');
      results['tests']['authentication'] = await _testAuthentication();
      
      // Test 2: Token Validity
      debugPrint('FirebaseAuthDiagnostics: Testing token validity...');
      results['tests']['tokenValidity'] = await _testTokenValidity();
      
      // Test 3: Firestore Access
      debugPrint('FirebaseAuthDiagnostics: Testing Firestore access...');
      results['tests']['firestoreAccess'] = await _testFirestoreAccess();
      
      // Test 4: User Document Access
      debugPrint('FirebaseAuthDiagnostics: Testing user document access...');
      results['tests']['userDocumentAccess'] = await _testUserDocumentAccess();
      
      // Test 5: Collection Access
      debugPrint('FirebaseAuthDiagnostics: Testing collection access...');
      results['tests']['collectionAccess'] = await _testCollectionAccess();
      
      // Generate recommendations
      debugPrint('FirebaseAuthDiagnostics: Generating recommendations...');
      results['recommendations'] = _generateRecommendations(results['tests']);
      
      // Determine overall status
      debugPrint('FirebaseAuthDiagnostics: Determining overall status...');
      results['overallStatus'] = _determineOverallStatus(results['tests']);
      
      debugPrint('FirebaseAuthDiagnostics: Diagnostics completed with status: ${results['overallStatus']}');
      
    } catch (e) {
      debugPrint('FirebaseAuthDiagnostics: Error during diagnostics: $e');
      results['error'] = e.toString();
      results['overallStatus'] = 'error';
    }

    return results;
  }

  /// Test authentication status
  static Future<Map<String, dynamic>> _testAuthentication() async {
    try {
      final user = _auth.currentUser;
      final isAuthenticated = user != null;
      
      debugPrint('FirebaseAuthDiagnostics: Authentication test - User authenticated: $isAuthenticated');
      if (user != null) {
        debugPrint('FirebaseAuthDiagnostics: User ID: ${user.uid}');
        debugPrint('FirebaseAuthDiagnostics: Email verified: ${user.emailVerified}');
      }
      
      return {
        'passed': isAuthenticated,
        'userId': user?.uid,
        'email': user?.email,
        'emailVerified': user?.emailVerified,
        'isAnonymous': user?.isAnonymous,
        'creationTime': user?.metadata.creationTime?.toIso8601String(),
        'lastSignInTime': user?.metadata.lastSignInTime?.toIso8601String(),
        'message': isAuthenticated ? 'User is authenticated' : 'No authenticated user found',
      };
    } catch (e) {
      debugPrint('FirebaseAuthDiagnostics: Authentication test failed: $e');
      return {
        'passed': false,
        'error': e.toString(),
        'message': 'Authentication test failed',
      };
    }
  }

  /// Test token validity
  static Future<Map<String, dynamic>> _testTokenValidity() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('FirebaseAuthDiagnostics: No authenticated user for token test');
        return {
          'passed': false,
          'message': 'No authenticated user to test token',
        };
      }

      // Test getting token without forcing refresh
      final tokenResult = await user.getIdTokenResult(false);
      final expirationTime = tokenResult.expirationTime;
      final issuedAtTime = tokenResult.issuedAtTime;
      
      final now = DateTime.now();
      final isExpired = expirationTime != null && now.isAfter(expirationTime);
      final timeUntilExpiry = expirationTime?.difference(now);
      
      debugPrint('FirebaseAuthDiagnostics: Token test - Expired: $isExpired, Time until expiry: ${timeUntilExpiry?.inMinutes} minutes');
      
      return {
        'passed': !isExpired,
        'isExpired': isExpired,
        'expirationTime': expirationTime?.toIso8601String(),
        'issuedAtTime': issuedAtTime?.toIso8601String(),
        'timeUntilExpiry': timeUntilExpiry?.inMinutes,
        'tokenClaims': tokenResult.claims,
        'message': isExpired ? 'Token is expired' : 'Token is valid',
      };
    } catch (e) {
      debugPrint('FirebaseAuthDiagnostics: Token validity test failed: $e');
      return {
        'passed': false,
        'error': e.toString(),
        'message': 'Token validity test failed',
      };
    }
  }

  /// Test basic Firestore access
  static Future<Map<String, dynamic>> _testFirestoreAccess() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('FirebaseAuthDiagnostics: No authenticated user for Firestore test');
        return {
          'passed': false,
          'message': 'No authenticated user to test Firestore access',
        };
      }

      // Try to read a test document
      debugPrint('FirebaseAuthDiagnostics: Testing Firestore access with test document...');
      final testDoc = await _firestore
          .collection('_test')
          .doc('test')
          .get();

      debugPrint('FirebaseAuthDiagnostics: Firestore access test completed - Document exists: ${testDoc.exists}');

      return {
        'passed': true,
        'testDocumentExists': testDoc.exists,
        'message': 'Firestore access test completed',
      };
    } catch (e) {
      debugPrint('FirebaseAuthDiagnostics: Firestore access test failed: $e');
      return {
        'passed': false,
        'error': e.toString(),
        'errorCode': e is FirebaseException ? e.code : null,
        'message': 'Firestore access test failed',
      };
    }
  }

  /// Test user document access
  static Future<Map<String, dynamic>> _testUserDocumentAccess() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('FirebaseAuthDiagnostics: No authenticated user for user document test');
        return {
          'passed': false,
          'message': 'No authenticated user to test user document access',
        };
      }

      final userId = user.uid;
      debugPrint('FirebaseAuthDiagnostics: Testing user document access for user: $userId');
      
      // Try to read user document
      final userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      debugPrint('FirebaseAuthDiagnostics: User document access test completed - Document exists: ${userDoc.exists}');

      return {
        'passed': true,
        'userDocumentExists': userDoc.exists,
        'userDocumentData': userDoc.exists ? userDoc.data() : null,
        'message': 'User document access test completed',
      };
    } catch (e) {
      debugPrint('FirebaseAuthDiagnostics: User document access test failed: $e');
      return {
        'passed': false,
        'error': e.toString(),
        'errorCode': e is FirebaseException ? e.code : null,
        'message': 'User document access test failed',
      };
    }
  }

  /// Test collection access
  static Future<Map<String, dynamic>> _testCollectionAccess() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('FirebaseAuthDiagnostics: No authenticated user for collection access test');
        return {
          'passed': false,
          'message': 'No authenticated user to test collection access',
        };
      }

      final userId = user.uid;
      final results = <String, dynamic>{};
      
      debugPrint('FirebaseAuthDiagnostics: Testing collection access for user: $userId');
      
      // Test access to various collections
      final collections = [
        'rehabilitation',
        'progress',
        'assessment',
        'settings',
        'painHistory',
        'exerciseHistory',
      ];

      for (final collection in collections) {
        try {
          debugPrint('FirebaseAuthDiagnostics: Testing access to collection: $collection');
          final doc = await _firestore
              .collection(collection)
              .doc(userId)
              .get();
          
          results[collection] = {
            'accessible': true,
            'exists': doc.exists,
          };
          debugPrint('FirebaseAuthDiagnostics: Collection $collection accessible, document exists: ${doc.exists}');
        } catch (e) {
          debugPrint('FirebaseAuthDiagnostics: Collection $collection access failed: $e');
          results[collection] = {
            'accessible': false,
            'error': e.toString(),
            'errorCode': e is FirebaseException ? e.code : null,
          };
        }
      }

      final allAccessible = results.values.every((result) => result['accessible'] == true);
      debugPrint('FirebaseAuthDiagnostics: Collection access test completed - All accessible: $allAccessible');
      
      return {
        'passed': allAccessible,
        'collectionResults': results,
        'message': allAccessible ? 'All collections accessible' : 'Some collections not accessible',
      };
    } catch (e) {
      debugPrint('FirebaseAuthDiagnostics: Collection access test failed: $e');
      return {
        'passed': false,
        'error': e.toString(),
        'message': 'Collection access test failed',
      };
    }
  }

  /// Generate recommendations based on test results
  static List<String> _generateRecommendations(Map<String, dynamic> tests) {
    final recommendations = <String>[];

    // Authentication recommendations
    final authTest = tests['authentication'] as Map<String, dynamic>?;
    if (authTest != null && !authTest['passed']) {
      recommendations.add('User is not authenticated. Please log in again.');
    }

    // Token recommendations
    final tokenTest = tests['tokenValidity'] as Map<String, dynamic>?;
    if (tokenTest != null && !tokenTest['passed']) {
      if (tokenTest['isExpired'] == true) {
        recommendations.add('Authentication token is expired. Please log in again.');
      } else {
        recommendations.add('Authentication token is invalid. Please log in again.');
      }
    }

    // Firestore access recommendations
    final firestoreTest = tests['firestoreAccess'] as Map<String, dynamic>?;
    if (firestoreTest != null && !firestoreTest['passed']) {
      final errorCode = firestoreTest['errorCode'] as String?;
      if (errorCode == 'permission-denied') {
        recommendations.add('Firestore permission denied. Check security rules and ensure user is authenticated.');
      } else {
        recommendations.add('Firestore access failed. Check network connection and Firebase configuration.');
      }
    }

    // User document recommendations
    final userDocTest = tests['userDocumentAccess'] as Map<String, dynamic>?;
    if (userDocTest != null && !userDocTest['passed']) {
      final errorCode = userDocTest['errorCode'] as String?;
      if (errorCode == 'permission-denied') {
        recommendations.add('User document access denied. Check Firestore security rules.');
      } else {
        recommendations.add('User document access failed. The document may not exist.');
      }
    }

    // Collection access recommendations
    final collectionTest = tests['collectionAccess'] as Map<String, dynamic>?;
    if (collectionTest != null && !collectionTest['passed']) {
      recommendations.add('Some collections are not accessible. Check Firestore security rules.');
    }

    if (recommendations.isEmpty) {
      recommendations.add('All tests passed. No issues detected.');
    }

    return recommendations;
  }

  /// Determine overall status based on test results
  static String _determineOverallStatus(Map<String, dynamic> tests) {
    final authTest = tests['authentication'] as Map<String, dynamic>?;
    final tokenTest = tests['tokenValidity'] as Map<String, dynamic>?;
    final firestoreTest = tests['firestoreAccess'] as Map<String, dynamic>?;

    if (authTest != null && !authTest['passed']) {
      return 'authentication_required';
    }

    if (tokenTest != null && !tokenTest['passed']) {
      return 'token_invalid';
    }

    if (firestoreTest != null && !firestoreTest['passed']) {
      return 'firestore_access_denied';
    }

    return 'healthy';
  }

  /// Quick fix for common authentication issues
  static Future<Map<String, dynamic>> attemptQuickFix() async {
    final results = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'actions': <String>[],
      'success': false,
    };

    try {
      debugPrint('FirebaseAuthDiagnostics: Attempting quick fix...');
      final user = _auth.currentUser;
      
      if (user == null) {
        debugPrint('FirebaseAuthDiagnostics: No authenticated user found for quick fix');
        results['actions'].add('No authenticated user found. User needs to log in.');
        return results;
      }

      debugPrint('FirebaseAuthDiagnostics: Quick fix for user: ${user.uid}');

      // Try to refresh the token
      try {
        debugPrint('FirebaseAuthDiagnostics: Refreshing authentication token...');
        await user.getIdToken(true);
        results['actions'].add('Authentication token refreshed successfully.');
        results['success'] = true;
        debugPrint('FirebaseAuthDiagnostics: Token refresh successful');
      } catch (e) {
        debugPrint('FirebaseAuthDiagnostics: Token refresh failed: $e');
        results['actions'].add('Failed to refresh authentication token: $e');
      }

      // Try to reload user data
      try {
        debugPrint('FirebaseAuthDiagnostics: Reloading user data...');
        await user.reload();
        results['actions'].add('User data reloaded successfully.');
        results['success'] = true;
        debugPrint('FirebaseAuthDiagnostics: User data reload successful');
      } catch (e) {
        debugPrint('FirebaseAuthDiagnostics: User data reload failed: $e');
        results['actions'].add('Failed to reload user data: $e');
      }

      debugPrint('FirebaseAuthDiagnostics: Quick fix completed - Success: ${results['success']}');

    } catch (e) {
      debugPrint('FirebaseAuthDiagnostics: Quick fix error: $e');
      results['error'] = e.toString();
    }

    return results;
  }
}

