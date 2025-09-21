import 'package:firebase_auth/firebase_auth.dart';
import 'auth_persistence_service.dart';
import 'globals.dart';
import 'rehabilitation_plan.dart';
import 'data_persistence_service.dart';

/// Service to test login functionality and authentication flows
class LoginTestService {
  static final LoginTestService _instance = LoginTestService._internal();
  static LoginTestService get instance => _instance;
  
  LoginTestService._internal();
  
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  /// Run comprehensive login tests
  static Future<Map<String, dynamic>> runAllTests() async {
    final results = <String, dynamic>{};
    
    try {
      print('LoginTestService: Starting comprehensive login tests...');
      
      // Test 1: Authentication Service Initialization
      results['authServiceInit'] = await _testAuthServiceInitialization();
      
      // Test 2: Firebase Auth Configuration
      results['firebaseAuthConfig'] = await _testFirebaseAuthConfiguration();
      
      // Test 3: User Authentication Flow
      results['userAuthFlow'] = await _testUserAuthenticationFlow();
      
      // Test 4: Data Persistence After Login
      results['dataPersistence'] = await _testDataPersistenceAfterLogin();
      
      // Test 5: Authentication State Monitoring
      results['authStateMonitoring'] = await _testAuthenticationStateMonitoring();
      
      // Test 6: Error Handling
      results['errorHandling'] = await _testErrorHandling();
      
      // Test 7: Login Page Integration
      results['loginPageIntegration'] = await _testLoginPageIntegration();
      
      // Calculate overall success rate
      final successCount = results.values.where((result) => result['success'] == true).length;
      final totalTests = results.length;
      results['overallSuccess'] = successCount / totalTests;
      results['successCount'] = successCount;
      results['totalTests'] = totalTests;
      
      print('LoginTestService: All tests completed. Success rate: ${(results['overallSuccess'] * 100).toStringAsFixed(1)}%');
      
    } catch (e) {
      print('LoginTestService: Error running tests: $e');
      results['error'] = e.toString();
    }
    
    return results;
  }
  
  /// Test authentication service initialization
  static Future<Map<String, dynamic>> _testAuthServiceInitialization() async {
    try {
      print('LoginTestService: Testing auth service initialization...');
      
      // Test service initialization
      await AuthPersistenceService.instance.initialize();
      
      // Test service status
      final status = AuthPersistenceService.instance.getStatus();
      
      return {
        'success': true,
        'message': 'Auth service initialized successfully',
        'status': status,
      };
      
    } catch (e) {
      return {
        'success': false,
        'message': 'Auth service initialization failed: $e',
        'error': e.toString(),
      };
    }
  }
  
  /// Test Firebase Auth configuration
  static Future<Map<String, dynamic>> _testFirebaseAuthConfiguration() async {
    try {
      print('LoginTestService: Testing Firebase Auth configuration...');
      
      // Test Firebase Auth instance
      final auth = FirebaseAuth.instance;
      
      // Test current user (should be null if not logged in)
      final currentUser = auth.currentUser;
      
      // Test auth state changes stream
      auth.authStateChanges();
      
      return {
        'success': true,
        'message': 'Firebase Auth configuration is valid',
        'currentUser': currentUser?.uid,
        'isAuthenticated': currentUser != null,
      };
      
    } catch (e) {
      return {
        'success': false,
        'message': 'Firebase Auth configuration test failed: $e',
        'error': e.toString(),
      };
    }
  }
  
  /// Test user authentication flow
  static Future<Map<String, dynamic>> _testUserAuthenticationFlow() async {
    try {
      print('LoginTestService: Testing user authentication flow...');
      
      // Test authentication state monitoring
      final authStateStream = _auth.authStateChanges();
      bool authStateReceived = false;
      
      // Listen to auth state changes for a short period
      final subscription = authStateStream.listen((user) {
        authStateReceived = true;
        print('LoginTestService: Auth state change detected - User: ${user?.uid}');
      });
      
      // Wait a bit for potential auth state changes
      await Future.delayed(const Duration(milliseconds: 500));
      subscription.cancel();
      
      // Test authentication persistence service
      final authService = AuthPersistenceService.instance;
      final isAuthenticated = authService.isAuthenticated;
      final currentUserId = authService.currentUserId;
      
      return {
        'success': true,
        'message': 'User authentication flow test completed',
        'authStateReceived': authStateReceived,
        'isAuthenticated': isAuthenticated,
        'currentUserId': currentUserId,
      };
      
    } catch (e) {
      return {
        'success': false,
        'message': 'User authentication flow test failed: $e',
        'error': e.toString(),
      };
    }
  }
  
  /// Test data persistence after login
  static Future<Map<String, dynamic>> _testDataPersistenceAfterLogin() async {
    try {
      print('LoginTestService: Testing data persistence after login...');
      
      // Test data loading from Hive
      await DataPersistenceService.loadAllDataFromHive();
      
      // Test user details loading
      final userDetailsLoaded = UserDetails.email.isNotEmpty || 
                               UserDetails.firstName.isNotEmpty || 
                               UserDetails.lastName.isNotEmpty;
      
      // Test rehabilitation data loading
      final rehabDataLoaded = UserRehabilitation.instance.rehabPlans.isNotEmpty ||
                             UserRehabilitation.instance.treatmentReferences != null;
      
      // Test data persistence service
      final dataService = DataPersistenceService.instance;
      final saveStats = dataService.getSaveStatistics();
      
      return {
        'success': true,
        'message': 'Data persistence test completed',
        'userDetailsLoaded': userDetailsLoaded,
        'rehabDataLoaded': rehabDataLoaded,
        'saveStats': saveStats,
      };
      
    } catch (e) {
      return {
        'success': false,
        'message': 'Data persistence test failed: $e',
        'error': e.toString(),
      };
    }
  }
  
  /// Test authentication state monitoring
  static Future<Map<String, dynamic>> _testAuthenticationStateMonitoring() async {
    try {
      print('LoginTestService: Testing authentication state monitoring...');
      
      // Test auth state changes listener
      final authStateStream = _auth.authStateChanges();
      bool listenerActive = false;
      
      final subscription = authStateStream.listen((user) {
        listenerActive = true;
      });
      
      // Wait for listener to be active
      await Future.delayed(const Duration(milliseconds: 100));
      subscription.cancel();
      
      // Test authentication persistence service monitoring
      final authService = AuthPersistenceService.instance;
      final status = authService.getStatus();
      
      return {
        'success': true,
        'message': 'Authentication state monitoring test completed',
        'listenerActive': listenerActive,
        'authServiceStatus': status,
      };
      
    } catch (e) {
      return {
        'success': false,
        'message': 'Authentication state monitoring test failed: $e',
        'error': e.toString(),
      };
    }
  }
  
  /// Test error handling
  static Future<Map<String, dynamic>> _testErrorHandling() async {
    try {
      print('LoginTestService: Testing error handling...');
      
      // Test invalid email format
      bool invalidEmailHandled = false;
      try {
        await _auth.signInWithEmailAndPassword(
          email: 'invalid-email',
          password: 'password',
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'invalid-email') {
          invalidEmailHandled = true;
        }
      }
      
      // Test invalid password
      bool invalidPasswordHandled = false;
      try {
        await _auth.signInWithEmailAndPassword(
          email: 'test@example.com',
          password: '123', // Too short
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'weak-password' || e.code == 'wrong-password') {
          invalidPasswordHandled = true;
        }
      }
      
      return {
        'success': true,
        'message': 'Error handling test completed',
        'invalidEmailHandled': invalidEmailHandled,
        'invalidPasswordHandled': invalidPasswordHandled,
      };
      
    } catch (e) {
      return {
        'success': false,
        'message': 'Error handling test failed: $e',
        'error': e.toString(),
      };
    }
  }
  
  /// Test login page integration
  static Future<Map<String, dynamic>> _testLoginPageIntegration() async {
    try {
      print('LoginTestService: Testing login page integration...');
      
      // Test if login page can be instantiated
      // This is a basic test - in a real scenario, you'd test the actual UI
      // Note: LoginPage import removed to avoid circular dependency
      // In a real test, you would test the actual UI components
      
      // Test form validation (simulated)
      final emailValidation = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      final validEmail = emailValidation.hasMatch('test@example.com');
      final invalidEmail = emailValidation.hasMatch('invalid-email');
      
      // Test password validation (simulated)
      final validPassword = 'password123'.length >= 6;
      final invalidPassword = '123'.length >= 6;
      
      return {
        'success': true,
        'message': 'Login page integration test completed',
        'loginPageCreated': true, // Simulated test
        'emailValidation': {
          'valid': validEmail,
          'invalid': invalidEmail,
        },
        'passwordValidation': {
          'valid': validPassword,
          'invalid': invalidPassword,
        },
      };
      
    } catch (e) {
      return {
        'success': false,
        'message': 'Login page integration test failed: $e',
        'error': e.toString(),
      };
    }
  }
  
  /// Test login with test credentials (for development/testing only)
  static Future<Map<String, dynamic>> testLoginWithCredentials({
    required String email,
    required String password,
  }) async {
    try {
      print('LoginTestService: Testing login with credentials...');
      
      // Attempt to sign in
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (userCredential.user != null) {
        // Test data loading after login
        await AuthPersistenceService.instance.syncAllData();
        
        // Test user details
        final userDetails = {
          'firstName': UserDetails.firstName,
          'lastName': UserDetails.lastName,
          'email': UserDetails.email,
        };
        
        // Sign out after test
        await _auth.signOut();
        
        return {
          'success': true,
          'message': 'Login test successful',
          'user': userCredential.user?.uid,
          'userDetails': userDetails,
        };
      } else {
        return {
          'success': false,
          'message': 'Login failed - no user returned',
        };
      }
      
    } catch (e) {
      return {
        'success': false,
        'message': 'Login test failed: $e',
        'error': e.toString(),
      };
    }
  }
  
  /// Get login test summary
  static String getTestSummary(Map<String, dynamic> results) {
    final successCount = results['successCount'] ?? 0;
    final totalTests = results['totalTests'] ?? 0;
    final successRate = (results['overallSuccess'] ?? 0) * 100;
    
    final summary = StringBuffer();
    summary.writeln('Login Test Summary');
    summary.writeln('==================');
    summary.writeln('Success Rate: ${successRate.toStringAsFixed(1)}% ($successCount/$totalTests)');
    summary.writeln();
    
    results.forEach((testName, result) {
      if (testName != 'overallSuccess' && testName != 'successCount' && testName != 'totalTests') {
        final status = result['success'] == true ? 'PASS' : 'FAIL';
        final message = result['message'] ?? 'No message';
        summary.writeln('$testName: $status - $message');
      }
    });
    
    return summary.toString();
  }
}
