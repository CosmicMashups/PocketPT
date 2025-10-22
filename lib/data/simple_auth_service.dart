import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'simple_data_sync_service.dart';

/// Simplified authentication service with unified error handling
class SimpleAuthService {
  static final SimpleAuthService _instance = SimpleAuthService._internal();
  static SimpleAuthService get instance => _instance;
  
  SimpleAuthService._internal();
  
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    // Add web client ID for web platform
    clientId: kIsWeb ? '679886971863-85d1ahqil53vbn97mfe52i69if2ofv61.apps.googleusercontent.com' : null,
    // Specify scopes for better user experience
    scopes: ['email', 'profile'],
    // Enable server auth code for better security
    serverClientId: '679886971863-85d1ahqil53vbn97mfe52i69if2ofv61.apps.googleusercontent.com',
  );
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Unified timeout duration
  static const Duration _timeout = Duration(seconds: 20);
  
  /// Check network connectivity
  Future<bool> hasNetworkConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
  
  /// Register new user with email and password
  Future<AuthResult> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      print('SimpleAuthService: Starting user registration...');
      
      // Check network
      if (!await hasNetworkConnection()) {
        return AuthResult.error('No internet connection. Please check your network and try again.');
      }
      
      // Validate password strength
      final passwordValidation = _validatePasswordStrength(password);
      if (!passwordValidation['valid']) {
        return AuthResult.error(passwordValidation['error']);
      }
      
      // Create user with Firebase Auth
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email.trim(), password: password.trim())
          .timeout(_timeout);
      
      print('SimpleAuthService: User registration successful');
      
      // Send email verification
      await userCredential.user?.sendEmailVerification();
      print('SimpleAuthService: Verification email sent');
      
      // Create user document in Firestore
      await _createUserDocument(
        userCredential.user!,
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        email: email.trim(),
      );
      
      return AuthResult.emailVerificationRequired(email);
      
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_getRegistrationErrorMessage(e));
    } catch (e) {
      if (e.toString().contains('timeout')) {
        return AuthResult.error('Connection timeout. Please check your internet connection and try again.');
      }
      return AuthResult.error('Registration failed: ${e.toString()}');
    }
  }

  /// Sign in with email and password
  Future<AuthResult> signInWithEmailAndPassword(String email, String password) async {
    try {
      print('SimpleAuthService: Starting email/password sign in...');
      
      // Check network
      if (!await hasNetworkConnection()) {
        return AuthResult.error('No internet connection. Please check your network and try again.');
      }
      
      // Authenticate with Firebase
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email.trim(), password: password.trim())
          .timeout(_timeout);
      
      print('SimpleAuthService: Authentication successful');
      
      // Check email verification
      if (userCredential.user != null && !userCredential.user!.emailVerified) {
        return AuthResult.emailVerificationRequired(userCredential.user!.email ?? '');
      }
      
      // Sync user data
      final syncResult = await SimpleDataSyncService.instance.syncUserData();
      if (!syncResult['success']) {
        return AuthResult.error('Failed to load user data: ${syncResult['error']}');
      }
      
      return AuthResult.success();
      
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_getAuthErrorMessage(e));
    } catch (e) {
      if (e.toString().contains('timeout')) {
        return AuthResult.error('Connection timeout. Please check your internet connection and try again.');
      }
      return AuthResult.error('Sign in failed: ${e.toString()}');
    }
  }
  
  /// Sign in with Google with retry logic
  Future<AuthResult> signInWithGoogle({int maxRetries = 3}) async {
    for (int i = 0; i < maxRetries; i++) {
      try {
        final result = await _performGoogleSignIn();
        if (result.success) return result;
        
        if (i < maxRetries - 1) {
          // Exponential backoff: wait 2, 4, 6 seconds
          await Future.delayed(Duration(seconds: 2 * (i + 1)));
          print('SimpleAuthService: Retrying Google sign-in attempt ${i + 2} of $maxRetries');
        }
      } catch (e) {
        if (i == maxRetries - 1) {
          return AuthResult.error('Google sign-in failed after $maxRetries attempts. Please try again later.');
        }
        // Wait before retry
        await Future.delayed(Duration(seconds: 2 * (i + 1)));
      }
    }
    return AuthResult.error('Google sign-in failed. Please try again.');
  }

  /// Perform the actual Google Sign-In operation
  Future<AuthResult> _performGoogleSignIn() async {
    try {
      print('SimpleAuthService: Starting Google sign in...');
      
      // Check network
      if (!await hasNetworkConnection()) {
        return AuthResult.error('No internet connection. Please check your network and try again.');
      }
      
      // Google Sign-In
      final GoogleSignInAccount? googleUser = await _googleSignIn
          .signIn()
          .timeout(_timeout);
      
      if (googleUser == null) {
        return AuthResult.cancelled();
      }
      
      // Get Google authentication
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      // Firebase authentication
      final UserCredential userCredential = await _auth
          .signInWithCredential(credential)
          .timeout(_timeout);
      
      print('SimpleAuthService: Google authentication successful');
      
      // Handle account linking check for existing users
      final linkingResult = await _handleAccountLinking(googleUser.email);
      if (!linkingResult.success) {
        return linkingResult;
      }
      
      // Handle new user creation
      if (userCredential.additionalUserInfo?.isNewUser == true) {
        await _createNewUserDocument(userCredential.user!, googleUser);
      }
      
      // Sync user data
      final syncResult = await SimpleDataSyncService.instance.syncUserData();
      if (!syncResult['success']) {
        return AuthResult.error('Failed to load user data: ${syncResult['error']}');
      }
      
      return AuthResult.success();
      
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_getGoogleSignInErrorMessage(e));
    } catch (e) {
      if (e.toString().contains('timeout')) {
        return AuthResult.error('Connection timeout. Please check your internet connection and try again.');
      }
      return AuthResult.error('Google sign in failed: ${e.toString()}');
    }
  }
  
  /// Handle account linking for existing email/password users
  Future<AuthResult> _handleAccountLinking(String email) async {
    try {
      // Check if user exists with email/password
      final existingUser = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      
      if (existingUser.docs.isNotEmpty) {
        // User exists with email/password, provide guidance
        return AuthResult.error(
          'An account already exists with this email using email/password authentication. '
          'Please sign in with your email and password, or contact support to link your Google account.'
        );
      }
      
      return AuthResult.success();
    } catch (e) {
      print('SimpleAuthService: Error checking account linking: $e');
      return AuthResult.success(); // Continue with Google Sign-In if check fails
    }
  }

  /// Create user document in Firestore
  Future<void> _createUserDocument(
    User user, {
    required String firstName,
    required String lastName,
    required String email,
  }) async {
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'userId': user.uid,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'emailVerified': user.emailVerified,
        'createdAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      
      print('SimpleAuthService: User document created successfully');
    } catch (e) {
      print('SimpleAuthService: Error creating user document: $e');
      rethrow;
    }
  }

  /// Create new user document in Firestore for Google Sign-In
  Future<void> _createNewUserDocument(User user, GoogleSignInAccount googleUser) async {
    try {
      final nameParts = googleUser.displayName?.split(' ') ?? [];
      final firstName = nameParts.isNotEmpty ? nameParts.first : '';
      final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
      
      await _createUserDocument(
        user,
        firstName: firstName,
        lastName: lastName,
        email: user.email ?? '',
      );
      
      print('SimpleAuthService: Google user document created');
    } catch (e) {
      print('SimpleAuthService: Error creating Google user document: $e');
    }
  }
  
  /// Send email verification
  Future<bool> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      
      await user.sendEmailVerification().timeout(_timeout);
      return true;
    } catch (e) {
      print('SimpleAuthService: Error sending verification email: $e');
      return false;
    }
  }
  
  /// Check if email is verified
  Future<bool> isEmailVerified() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      
      await user.reload();
      return user.emailVerified;
    } catch (e) {
      print('SimpleAuthService: Error checking email verification: $e');
      return false;
    }
  }
  
  /// Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
      await SimpleDataSyncService.instance.clearUserData();
      print('SimpleAuthService: Sign out successful');
    } catch (e) {
      print('SimpleAuthService: Error during sign out: $e');
    }
  }
  
  /// Get authentication error message
  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many attempts. Try again later';
      default:
        return e.message ?? 'An error occurred during sign in';
    }
  }
  
  /// Get Google Sign-In error message
  String _getGoogleSignInErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'account-exists-with-different-credential':
        return 'An account already exists with this email. Please sign in with your original method first.';
      case 'invalid-credential':
        return 'Invalid Google credentials. Please try again.';
      case 'operation-not-allowed':
        return 'Google Sign-In is not enabled. Please contact support.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'user-disabled':
        return 'This Google account has been disabled. Please contact support.';
      case 'user-not-found':
        return 'No Google account found. Please try again or create a new account.';
      case 'wrong-password':
        return 'Invalid Google authentication. Please try again.';
      default:
        return 'Google sign-in failed. Please try again or use email/password.';
    }
  }

  /// Get registration error message
  String _getRegistrationErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already registered. Please use a different email or sign in.';
      case 'invalid-email':
        return 'Please enter a valid email address';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      default:
        return e.message ?? 'Registration failed. Please try again.';
    }
  }

  /// Validate password strength
  Map<String, dynamic> _validatePasswordStrength(String password) {
    if (password.length < 8) {
      return {
        'valid': false,
        'error': 'Password must be at least 8 characters long',
      };
    }
    
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return {
        'valid': false,
        'error': 'Password must contain at least one uppercase letter',
      };
    }
    
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return {
        'valid': false,
        'error': 'Password must contain at least one lowercase letter',
      };
    }
    
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return {
        'valid': false,
        'error': 'Password must contain at least one number',
      };
    }
    
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      return {
        'valid': false,
        'error': 'Password must contain at least one special character',
      };
    }
    
    return {'valid': true};
  }
  
  /// Get current user
  User? get currentUser => _auth.currentUser;
  
  /// Check if user is authenticated
  bool get isAuthenticated => _auth.currentUser != null;
}

/// Authentication result class
class AuthResult {
  final bool success;
  final String? error;
  final String? email;
  final bool requiresEmailVerification;
  final bool cancelled;
  
  AuthResult._({
    required this.success,
    this.error,
    this.email,
    this.requiresEmailVerification = false,
    this.cancelled = false,
  });
  
  factory AuthResult.success() => AuthResult._(success: true);
  
  factory AuthResult.error(String error) => AuthResult._(success: false, error: error);
  
  factory AuthResult.emailVerificationRequired(String email) => AuthResult._(
    success: false,
    email: email,
    requiresEmailVerification: true,
  );
  
  factory AuthResult.cancelled() => AuthResult._(
    success: false,
    cancelled: true,
  );
}
