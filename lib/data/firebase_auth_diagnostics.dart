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
      // Test 1: Authentication Status
      results['tests']['authentication'] = await _testAuthentication();
      
      // Test 2: Token Validity
      results['tests']['tokenValidity'] = await _testTokenValidity();
      
      // Test 3: Firestore Access
      results['tests']['firestoreAccess'] = await _testFirestoreAccess();
      
      // Test 4: User Document Access
      results['tests']['userDocumentAccess'] = await _testUserDocumentAccess();
      
      // Test 5: Collection Access
      results['tests']['collectionAccess'] = await _testCollectionAccess();
      
      // Generate recommendations
      results['recommendations'] = _generateRecommendations(results['tests']);
      
      // Determine overall status
      results['overallStatus'] = _determineOverallStatus(results['tests']);
      
    } catch (e) {
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
        return {
          'passed': false,
          'message': 'No authenticated user to test Firestore access',
        };
      }

      // Try to read a test document
      final testDoc = await _firestore
          .collection('_test')
          .doc('test')
          .get();

      return {
        'passed': true,
        'testDocumentExists': testDoc.exists,
        'message': 'Firestore access test completed',
      };
    } catch (e) {
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
        return {
          'passed': false,
          'message': 'No authenticated user to test user document access',
        };
      }

      final userId = user.uid;
      
      // Try to read user document
      final userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      return {
        'passed': true,
        'userDocumentExists': userDoc.exists,
        'userDocumentData': userDoc.exists ? userDoc.data() : null,
        'message': 'User document access test completed',
      };
    } catch (e) {
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
        return {
          'passed': false,
          'message': 'No authenticated user to test collection access',
        };
      }

      final userId = user.uid;
      final results = <String, dynamic>{};
      
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
          final doc = await _firestore
              .collection(collection)
              .doc(userId)
              .get();
          
          results[collection] = {
            'accessible': true,
            'exists': doc.exists,
          };
        } catch (e) {
          results[collection] = {
            'accessible': false,
            'error': e.toString(),
            'errorCode': e is FirebaseException ? e.code : null,
          };
        }
      }

      final allAccessible = results.values.every((result) => result['accessible'] == true);
      
      return {
        'passed': allAccessible,
        'collectionResults': results,
        'message': allAccessible ? 'All collections accessible' : 'Some collections not accessible',
      };
    } catch (e) {
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
      final user = _auth.currentUser;
      
      if (user == null) {
        results['actions'].add('No authenticated user found. User needs to log in.');
        return results;
      }

      // Try to refresh the token
      try {
        await user.getIdToken(true);
        results['actions'].add('Authentication token refreshed successfully.');
        results['success'] = true;
      } catch (e) {
        results['actions'].add('Failed to refresh authentication token: $e');
      }

      // Try to reload user data
      try {
        await user.reload();
        results['actions'].add('User data reloaded successfully.');
        results['success'] = true;
      } catch (e) {
        results['actions'].add('Failed to reload user data: $e');
      }

    } catch (e) {
      results['error'] = e.toString();
    }

    return results;
  }
}

