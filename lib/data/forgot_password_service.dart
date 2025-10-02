import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'dart:math';
import 'dart:io';

/// Service for handling forgot password functionality with secure verification
class ForgotPasswordService {
  static final ForgotPasswordService _instance = ForgotPasswordService._internal();
  static ForgotPasswordService get instance => _instance;
  
  ForgotPasswordService._internal();
  
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Timeout duration for operations
  static const Duration _timeout = Duration(seconds: 20);
  
  // Verification code expiration time (10 minutes)
  static const Duration _codeExpiration = Duration(minutes: 10);
  
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
  
  /// Check if email exists in Firebase users collection
  Future<ForgotPasswordResult> checkEmailExists(String email) async {
    try {
      print('ForgotPasswordService: Checking if email exists...');
      
      // Check network
      if (!await hasNetworkConnection()) {
        return ForgotPasswordResult.error('No internet connection. Please check your network and try again.');
      }
      
      // Validate email format
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email.trim())) {
        return ForgotPasswordResult.error('Please enter a valid email address');
      }
      
      // Check if user exists in Firebase Auth
      final signInMethods = await _auth.fetchSignInMethodsForEmail(email.trim()).timeout(_timeout);
      
      if (signInMethods.isEmpty) {
        return ForgotPasswordResult.error('No account found with this email address');
      }
      
      // Check if user exists in Firestore users collection
      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.trim())
          .limit(1)
          .get()
          .timeout(_timeout);
      
      if (userQuery.docs.isEmpty) {
        return ForgotPasswordResult.error('No account found with this email address');
      }
      
      print('ForgotPasswordService: Email exists, generating verification code...');
      
      // Generate and send verification code
      return await _generateAndSendVerificationCode(email.trim());
      
    } on FirebaseAuthException catch (e) {
      return ForgotPasswordResult.error(_getAuthErrorMessage(e));
    } catch (e) {
      if (e.toString().contains('timeout')) {
        return ForgotPasswordResult.error('Connection timeout. Please check your internet connection and try again.');
      }
      return ForgotPasswordResult.error('An error occurred while checking your email. Please try again.');
    }
  }
  
  /// Generate and send verification code
  Future<ForgotPasswordResult> _generateAndSendVerificationCode(String email) async {
    try {
      // Generate 6-digit verification code
      final verificationCode = _generateVerificationCode();
      final expirationTime = DateTime.now().add(_codeExpiration);
      
      // Store verification code in Firestore with expiration
      await _firestore
          .collection('password_reset_codes')
          .doc(email)
          .set({
        'code': verificationCode,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(expirationTime),
        'used': false,
      })
          .timeout(_timeout);
      
      print('ForgotPasswordService: Verification code stored in Firestore');
      
      // Send verification email using Firebase Auth
      await _sendVerificationEmail(email, verificationCode);
      
      return ForgotPasswordResult.codeSent(email);
      
    } catch (e) {
      print('ForgotPasswordService: Error generating/sending code: $e');
      return ForgotPasswordResult.error('Failed to send verification code. Please try again.');
    }
  }
  
  /// Send verification email (simulated - in production, use email service)
  Future<void> _sendVerificationEmail(String email, String code) async {
    try {
      // In a real implementation, you would integrate with an email service
      // For now, we'll simulate the email sending
      print('ForgotPasswordService: Sending verification email to $email');
      print('ForgotPasswordService: Verification code: $code');
      
      // You can integrate with services like:
      // - SendGrid
      // - AWS SES
      // - Firebase Functions with email service
      // - Custom email API
      
      // For development/testing purposes, the code is logged
      // In production, remove this logging for security
      
    } catch (e) {
      print('ForgotPasswordService: Error sending email: $e');
      rethrow;
    }
  }
  
  /// Verify the entered code
  Future<ForgotPasswordResult> verifyCode(String email, String enteredCode) async {
    try {
      print('ForgotPasswordService: Verifying code for $email');
      
      // Check network
      if (!await hasNetworkConnection()) {
        return ForgotPasswordResult.error('No internet connection. Please check your network and try again.');
      }
      
      // Get stored verification code
      final doc = await _firestore
          .collection('password_reset_codes')
          .doc(email.trim())
          .get()
          .timeout(_timeout);
      
      if (!doc.exists) {
        return ForgotPasswordResult.error('Verification code not found. Please request a new code.');
      }
      
      final data = doc.data()!;
      final storedCode = data['code'] as String;
      final expiresAt = (data['expiresAt'] as Timestamp).toDate();
      final used = data['used'] as bool;
      
      // Check if code is expired
      if (DateTime.now().isAfter(expiresAt)) {
        // Clean up expired code
        await _cleanupVerificationCode(email.trim());
        return ForgotPasswordResult.error('Verification code has expired. Please request a new code.');
      }
      
      // Check if code is already used
      if (used) {
        return ForgotPasswordResult.error('This verification code has already been used. Please request a new code.');
      }
      
      // Verify the code
      if (enteredCode.trim() != storedCode) {
        return ForgotPasswordResult.error('Invalid verification code. Please check and try again.');
      }
      
      // Mark code as used
      await _firestore
          .collection('password_reset_codes')
          .doc(email.trim())
          .update({'used': true})
          .timeout(_timeout);
      
      print('ForgotPasswordService: Code verified successfully');
      return ForgotPasswordResult.codeVerified(email.trim());
      
    } catch (e) {
      if (e.toString().contains('timeout')) {
        return ForgotPasswordResult.error('Connection timeout. Please check your internet connection and try again.');
      }
      return ForgotPasswordResult.error('An error occurred while verifying the code. Please try again.');
    }
  }
  
  /// Reset password with new password
  Future<ForgotPasswordResult> resetPassword(String email, String newPassword) async {
    try {
      print('ForgotPasswordService: Resetting password for $email');
      
      // Check network
      if (!await hasNetworkConnection()) {
        return ForgotPasswordResult.error('No internet connection. Please check your network and try again.');
      }
      
      // Validate password strength
      final passwordValidation = _validatePasswordStrength(newPassword);
      if (!passwordValidation['valid']) {
        return ForgotPasswordResult.error(passwordValidation['error']);
      }
      
      // Get the user by email
      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.trim())
          .limit(1)
          .get()
          .timeout(_timeout);
      
      if (userQuery.docs.isEmpty) {
        return ForgotPasswordResult.error('User not found. Please try again.');
      }
      
      // Update password in Firebase Auth
      // Note: This requires the user to be signed in or using admin SDK
      // For security, we'll use Firebase Auth's sendPasswordResetEmail instead
      await _auth.sendPasswordResetEmail(email: email.trim()).timeout(_timeout);
      
      // Clean up verification code
      await _cleanupVerificationCode(email.trim());
      
      print('ForgotPasswordService: Password reset email sent successfully');
      return ForgotPasswordResult.passwordResetSent(email.trim());
      
    } on FirebaseAuthException catch (e) {
      return ForgotPasswordResult.error(_getPasswordResetErrorMessage(e));
    } catch (e) {
      if (e.toString().contains('timeout')) {
        return ForgotPasswordResult.error('Connection timeout. Please check your internet connection and try again.');
      }
      return ForgotPasswordResult.error('An error occurred while resetting your password. Please try again.');
    }
  }
  
  /// Alternative method: Reset password with verification code
  Future<ForgotPasswordResult> resetPasswordWithCode(String email, String newPassword) async {
    try {
      print('ForgotPasswordService: Resetting password with code for $email');
      
      // Check network
      if (!await hasNetworkConnection()) {
        return ForgotPasswordResult.error('No internet connection. Please check your network and try again.');
      }
      
      // Validate password strength
      final passwordValidation = _validatePasswordStrength(newPassword);
      if (!passwordValidation['valid']) {
        return ForgotPasswordResult.error(passwordValidation['error']);
      }
      
      // Verify that the code was used (additional security check)
      final doc = await _firestore
          .collection('password_reset_codes')
          .doc(email.trim())
          .get()
          .timeout(_timeout);
      
      if (!doc.exists || !(doc.data()?['used'] ?? false)) {
        return ForgotPasswordResult.error('Please verify your code first before resetting password.');
      }
      
      // For security, we'll send a password reset email instead of directly changing password
      // This ensures the user has control over their account
      await _auth.sendPasswordResetEmail(email: email.trim()).timeout(_timeout);
      
      // Clean up verification code
      await _cleanupVerificationCode(email.trim());
      
      print('ForgotPasswordService: Password reset email sent successfully');
      return ForgotPasswordResult.passwordResetSent(email.trim());
      
    } on FirebaseAuthException catch (e) {
      return ForgotPasswordResult.error(_getPasswordResetErrorMessage(e));
    } catch (e) {
      if (e.toString().contains('timeout')) {
        return ForgotPasswordResult.error('Connection timeout. Please check your internet connection and try again.');
      }
      return ForgotPasswordResult.error('An error occurred while resetting your password. Please try again.');
    }
  }
  
  /// Clean up verification code
  Future<void> _cleanupVerificationCode(String email) async {
    try {
      await _firestore
          .collection('password_reset_codes')
          .doc(email)
          .delete()
          .timeout(_timeout);
      print('ForgotPasswordService: Verification code cleaned up');
    } catch (e) {
      print('ForgotPasswordService: Error cleaning up verification code: $e');
    }
  }
  
  /// Generate 6-digit verification code
  String _generateVerificationCode() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
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
  
  /// Get authentication error message
  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email address';
      case 'invalid-email':
        return 'Invalid email address';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      default:
        return e.message ?? 'An error occurred. Please try again.';
    }
  }
  
  /// Get password reset error message
  String _getPasswordResetErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email address';
      case 'invalid-email':
        return 'Invalid email address';
      case 'too-many-requests':
        return 'Too many password reset attempts. Please try again later';
      default:
        return e.message ?? 'Failed to reset password. Please try again.';
    }
  }
}

/// Forgot password result class
class ForgotPasswordResult {
  final bool success;
  final String? error;
  final String? email;
  final ForgotPasswordStep step;
  
  ForgotPasswordResult._({
    required this.success,
    this.error,
    this.email,
    required this.step,
  });
  
  factory ForgotPasswordResult.error(String error) => ForgotPasswordResult._(
    success: false,
    error: error,
    step: ForgotPasswordStep.error,
  );
  
  factory ForgotPasswordResult.codeSent(String email) => ForgotPasswordResult._(
    success: true,
    email: email,
    step: ForgotPasswordStep.codeSent,
  );
  
  factory ForgotPasswordResult.codeVerified(String email) => ForgotPasswordResult._(
    success: true,
    email: email,
    step: ForgotPasswordStep.codeVerified,
  );
  
  factory ForgotPasswordResult.passwordResetSent(String email) => ForgotPasswordResult._(
    success: true,
    email: email,
    step: ForgotPasswordStep.passwordResetSent,
  );
}

/// Forgot password flow steps
enum ForgotPasswordStep {
  error,
  codeSent,
  codeVerified,
  passwordResetSent,
}
