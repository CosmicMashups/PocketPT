import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
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
  
  /// Send password reset email using Firebase Auth
  /// This method directly sends a password reset email to the provided email address
  Future<ForgotPasswordResult> checkEmailExists(String email) async {
    try {
      print('ForgotPasswordService: Sending password reset email to $email');
      
      // Check network
      if (!await hasNetworkConnection()) {
        return ForgotPasswordResult.error('No internet connection. Please check your network and try again.');
      }
      
      // Validate email format
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email.trim())) {
        return ForgotPasswordResult.error('Please enter a valid email address');
      }
      
      // Normalize email (lowercase) to avoid case-sensitivity issues
      final String normalizedEmail = email.trim().toLowerCase();
      
      // Send password reset email directly using Firebase Auth
      // Firebase will handle email validation and only send if the email exists
      // This prevents email enumeration attacks
      await _auth.sendPasswordResetEmail(email: normalizedEmail).timeout(_timeout);
      
      print('ForgotPasswordService: Password reset email sent successfully to $normalizedEmail');
      
      // Return success - Firebase doesn't disclose whether email exists for security
      return ForgotPasswordResult.passwordResetSent(normalizedEmail);
      
    } on FirebaseAuthException catch (e) {
      print('ForgotPasswordService: FirebaseAuthException: ${e.code} - ${e.message}');
      return ForgotPasswordResult.error(_getPasswordResetErrorMessage(e));
    } on TimeoutException {
      print('ForgotPasswordService: Timeout sending password reset email');
      return ForgotPasswordResult.error('Connection timeout. Please check your internet connection and try again.');
    } catch (e) {
      print('ForgotPasswordService: Unexpected error: $e');
      if (e.toString().contains('timeout')) {
        return ForgotPasswordResult.error('Connection timeout. Please check your internet connection and try again.');
      }
      return ForgotPasswordResult.error('An error occurred while sending the password reset email. Please try again.');
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
      
      final String normalizedEmail = email.trim().toLowerCase();
      
      // Get stored verification code
      final doc = await _firestore
          .collection('password_reset_codes')
          .doc(normalizedEmail)
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
        await _cleanupVerificationCode(normalizedEmail);
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
          .doc(normalizedEmail)
          .update({'used': true})
          .timeout(_timeout);
      
      print('ForgotPasswordService: Code verified successfully');
      return ForgotPasswordResult.codeVerified(normalizedEmail);
      
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
      final String normalizedEmail = email.trim().toLowerCase();
      
      // Update password in Firebase Auth
      // Note: This requires the user to be signed in or using admin SDK
      // For security, we'll use Firebase Auth's sendPasswordResetEmail instead
      await _auth.sendPasswordResetEmail(email: normalizedEmail).timeout(_timeout);
      
      // Clean up verification code
      await _cleanupVerificationCode(normalizedEmail);
      
      print('ForgotPasswordService: Password reset email sent successfully');
      return ForgotPasswordResult.passwordResetSent(normalizedEmail);
      
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
      
      final String normalizedEmail = email.trim().toLowerCase();
      
      // Verify that the code was used (additional security check)
      final doc = await _firestore
          .collection('password_reset_codes')
          .doc(normalizedEmail)
          .get()
          .timeout(_timeout);
      
      if (!doc.exists || !(doc.data()?['used'] ?? false)) {
        return ForgotPasswordResult.error('Please verify your code first before resetting password.');
      }
      
      // For security, we'll send a password reset email instead of directly changing password
      // This ensures the user has control over their account
      await _auth.sendPasswordResetEmail(email: normalizedEmail).timeout(_timeout);
      
      // Clean up verification code
      await _cleanupVerificationCode(normalizedEmail);
      
      print('ForgotPasswordService: Password reset email sent successfully');
      return ForgotPasswordResult.passwordResetSent(normalizedEmail);
      
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
  
  /// Get password reset error message
  String _getPasswordResetErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        // For security, don't disclose if email exists - use generic message
        return 'If an account exists for this email, you will receive a password reset link shortly.';
      case 'invalid-email':
        return 'Invalid email address. Please check and try again.';
      case 'too-many-requests':
        return 'Too many password reset attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection and try again.';
      default:
        // For security, use generic message that doesn't reveal email existence
        return 'If an account exists for this email, you will receive a password reset link shortly.';
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
