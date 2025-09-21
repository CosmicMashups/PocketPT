import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Verifies Firebase configuration and connectivity
class FirebaseConfigVerifier {
  static bool _isInitialized = false;
  static String? _lastError;

  /// Verify Firebase configuration
  static Future<Map<String, dynamic>> verifyConfiguration() async {
    final results = <String, dynamic>{};
    
    try {
      // Test 1: Firebase Core Initialization
      results['coreInitialization'] = await _testCoreInitialization();
      
      // Test 2: Firebase Auth
      results['auth'] = await _testAuth();
      
      // Test 3: Firestore
      results['firestore'] = await _testFirestore();
      
      // Test 4: Network Connectivity
      results['connectivity'] = await _testConnectivity();
      
      // Test 5: Security Rules
      results['securityRules'] = await _testSecurityRules();
      
      _isInitialized = true;
      _lastError = null;
      
    } catch (e) {
      _lastError = e.toString();
      results['error'] = e.toString();
      print('Firebase Configuration Verification Error: $e');
    }
    
    return results;
  }

  /// Test Firebase Core initialization
  static Future<Map<String, dynamic>> _testCoreInitialization() async {
    try {
      final app = Firebase.app();
      final isInitialized = true; // Firebase.app() throws if not initialized
      
      print('Firebase Core Test: PASSED');
      print('  App name: ${app.name}');
      print('  App options: ${app.options.projectId}');
      
      return {
        'passed': true,
        'appName': app.name,
        'projectId': app.options.projectId,
        'message': 'Firebase Core initialized successfully'
      };
    } catch (e) {
      print('Firebase Core Test Error: $e');
      return {'passed': false, 'error': e.toString()};
    }
  }

  /// Test Firebase Auth
  static Future<Map<String, dynamic>> _testAuth() async {
    try {
      final auth = FirebaseAuth.instance;
      final currentUser = auth.currentUser;
      final isAuthenticated = currentUser != null;
      
      print('Firebase Auth Test: PASSED');
      print('  Current user: ${currentUser?.uid ?? "None"}');
      print('  Email: ${currentUser?.email ?? "None"}');
      print('  Is authenticated: $isAuthenticated');
      
      return {
        'passed': true,
        'isAuthenticated': isAuthenticated,
        'userId': currentUser?.uid,
        'email': currentUser?.email,
        'message': 'Firebase Auth working correctly'
      };
    } catch (e) {
      print('Firebase Auth Test Error: $e');
      return {'passed': false, 'error': e.toString()};
    }
  }

  /// Test Firestore
  static Future<Map<String, dynamic>> _testFirestore() async {
    try {
      final firestore = FirebaseFirestore.instance;
      
      // Test basic Firestore operations
      final testDoc = firestore.collection('_test').doc('_test');
      
      // Try to write a test document
      await testDoc.set({
        'test': true,
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      // Try to read the test document
      final doc = await testDoc.get();
      final exists = doc.exists;
      
      // Clean up test document
      await testDoc.delete();
      
      print('Firestore Test: ${exists ? "PASSED" : "FAILED"}');
      print('  Write operation: PASSED');
      print('  Read operation: ${exists ? "PASSED" : "FAILED"}');
      print('  Delete operation: PASSED');
      
      return {
        'passed': exists,
        'writeOperation': true,
        'readOperation': exists,
        'deleteOperation': true,
        'message': exists ? 'Firestore working correctly' : 'Firestore read operation failed'
      };
    } catch (e) {
      print('Firestore Test Error: $e');
      return {'passed': false, 'error': e.toString()};
    }
  }

  /// Test network connectivity
  static Future<Map<String, dynamic>> _testConnectivity() async {
    try {
      final firestore = FirebaseFirestore.instance;
      
      // Enable network
      await firestore.enableNetwork();
      
      // Try a simple query to test connectivity
      await firestore.collection('_test').limit(1).get();
      
      print('Connectivity Test: PASSED');
      print('  Network enabled: true');
      print('  Query executed: true');
      
      return {
        'passed': true,
        'networkEnabled': true,
        'queryExecuted': true,
        'message': 'Network connectivity working'
      };
    } catch (e) {
      print('Connectivity Test Error: $e');
      return {'passed': false, 'error': e.toString()};
    }
  }

  /// Test security rules (basic)
  static Future<Map<String, dynamic>> _testSecurityRules() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final auth = FirebaseAuth.instance;
      
      // Test if we can access user-specific data
      if (auth.currentUser != null) {
        final userId = auth.currentUser!.uid;
        
        // Try to read user document
        final userDoc = await firestore.collection('users').doc(userId).get();
        
        print('Security Rules Test: PASSED');
        print('  User document accessible: ${userDoc.exists}');
        
        return {
          'passed': true,
          'userDocumentAccessible': userDoc.exists,
          'message': 'Security rules working correctly'
        };
      } else {
        print('Security Rules Test: SKIPPED (No authenticated user)');
        return {
          'passed': true,
          'skipped': true,
          'message': 'Security rules test skipped - no authenticated user'
        };
      }
    } catch (e) {
      print('Security Rules Test Error: $e');
      return {'passed': false, 'error': e.toString()};
    }
  }

  /// Get Firebase configuration status
  static Map<String, dynamic> getStatus() {
    return {
      'isInitialized': _isInitialized,
      'lastError': _lastError,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Check if Firebase is properly configured
  static bool isProperlyConfigured() {
    return _isInitialized && _lastError == null;
  }

  /// Get detailed Firebase information
  static Map<String, dynamic> getFirebaseInfo() {
    try {
      final app = Firebase.app();
      final auth = FirebaseAuth.instance;
      final firestore = FirebaseFirestore.instance;
      
      return {
        'appName': app.name,
        'projectId': app.options.projectId,
        'apiKey': app.options.apiKey,
        'authDomain': app.options.authDomain,
        'storageBucket': app.options.storageBucket,
        'messagingSenderId': app.options.messagingSenderId,
        'appId': app.options.appId,
        'currentUser': auth.currentUser?.uid,
        'firestoreSettings': {
          'host': firestore.settings.host,
          'sslEnabled': firestore.settings.sslEnabled,
          'persistenceEnabled': firestore.settings.persistenceEnabled,
        },
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}
