import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'result.dart';
import 'error_handler.dart';

/// Secure authentication service that properly handles password storage and authentication
/// This fixes the critical security vulnerability of storing passwords in plain text
class SecureAuthService {
  static final SecureAuthService _instance = SecureAuthService._internal();
  factory SecureAuthService() => _instance;
  SecureAuthService._internal();
  
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  
  // Keys for secure storage
  static const String _passwordKey = 'user_password_hash';
  static const String _saltKey = 'user_password_salt';
  static const String _sessionTokenKey = 'session_token';
  static const String _userIdKey = 'user_id';
  static const String _isLoggedInKey = 'is_logged_in';
  
  /// Store user password securely using PBKDF2 with salt
  Future<Result<void>> storePassword(String password) async {
    try {
      // Generate a random salt
      final salt = _generateSalt();
      
      // Hash the password with salt using PBKDF2
      final hashedPassword = _hashPassword(password, salt);
      
      // Store salt and hashed password securely
      await _secureStorage.write(key: _saltKey, value: base64Encode(salt));
      await _secureStorage.write(key: _passwordKey, value: hashedPassword);
      
      return Result.success(null);
    } catch (error, stackTrace) {
      errorHandler.handleError('SecureAuthService.storePassword', error, stackTrace);
      return Result.error('Failed to store password securely', error, stackTrace);
    }
  }
  
  /// Verify user password against stored hash
  Future<Result<bool>> verifyPassword(String password) async {
    try {
      // Get stored salt and hash
      final saltBase64 = await _secureStorage.read(key: _saltKey);
      final storedHash = await _secureStorage.read(key: _passwordKey);
      
      if (saltBase64 == null || storedHash == null) {
        return Result.success(false);
      }
      
      // Decode salt and hash the provided password
      final salt = base64Decode(saltBase64);
      final hashedPassword = _hashPassword(password, salt);
      
      // Compare hashes
      final isValid = hashedPassword == storedHash;
      return Result.success(isValid);
    } catch (error, stackTrace) {
      errorHandler.handleError('SecureAuthService.verifyPassword', error, stackTrace);
      return Result.error('Failed to verify password', error, stackTrace);
    }
  }
  
  /// Store user session information securely
  Future<Result<void>> storeSession(String userId, String sessionToken) async {
    try {
      await _secureStorage.write(key: _userIdKey, value: userId);
      await _secureStorage.write(key: _sessionTokenKey, value: sessionToken);
      await _secureStorage.write(key: _isLoggedInKey, value: 'true');
      return Result.success(null);
    } catch (error, stackTrace) {
      errorHandler.handleError('SecureAuthService.storeSession', error, stackTrace);
      return Result.error('Failed to store session', error, stackTrace);
    }
  }
  
  /// Get current user session
  Future<Result<Map<String, String>?>> getSession() async {
    try {
      final userId = await _secureStorage.read(key: _userIdKey);
      final sessionToken = await _secureStorage.read(key: _sessionTokenKey);
      final isLoggedIn = await _secureStorage.read(key: _isLoggedInKey);
      
      if (userId == null || sessionToken == null || isLoggedIn != 'true') {
        return Result.success(null);
      }
      
      return Result.success({
        'userId': userId,
        'sessionToken': sessionToken,
        'isLoggedIn': isLoggedIn ?? 'false',
      });
    } catch (error, stackTrace) {
      errorHandler.handleError('SecureAuthService.getSession', error, stackTrace);
      return Result.error('Failed to get session', error, stackTrace);
    }
  }
  
  /// Clear user session and logout
  Future<Result<void>> clearSession() async {
    try {
      await _secureStorage.delete(key: _userIdKey);
      await _secureStorage.delete(key: _sessionTokenKey);
      await _secureStorage.delete(key: _isLoggedInKey);
      return Result.success(null);
    } catch (error, stackTrace) {
      errorHandler.handleError('SecureAuthService.clearSession', error, stackTrace);
      return Result.error('Failed to clear session', error, stackTrace);
    }
  }
  
  /// Check if user is currently logged in
  Future<Result<bool>> isLoggedIn() async {
    try {
      final isLoggedIn = await _secureStorage.read(key: _isLoggedInKey);
      return Result.success(isLoggedIn == 'true');
    } catch (error, stackTrace) {
      errorHandler.handleError('SecureAuthService.isLoggedIn', error, stackTrace);
      return Result.error('Failed to check login status', error, stackTrace);
    }
  }
  
  /// Generate a cryptographically secure random salt
  Uint8List _generateSalt() {
    final random = math.Random.secure();
    final salt = Uint8List(32); // 256-bit salt
    for (int i = 0; i < salt.length; i++) {
      salt[i] = random.nextInt(256);
    }
    return salt;
  }
  
  /// Hash password using PBKDF2 with SHA-256
  String _hashPassword(String password, Uint8List salt) {
    // Use PBKDF2 with 100,000 iterations (recommended minimum)
    const iterations = 100000;
    const keyLength = 32; // 256-bit key
    
    // Convert password to bytes
    final passwordBytes = utf8.encode(password);
    
    // Perform PBKDF2 key derivation manually
    final derivedKey = _pbkdf2(passwordBytes, salt, iterations, keyLength);
    
    // Return base64 encoded hash
    return base64Encode(derivedKey);
  }
  
  /// Manual PBKDF2 implementation
  Uint8List _pbkdf2(List<int> password, Uint8List salt, int iterations, int keyLength) {
    final hmac = Hmac(sha256, password);
    final result = Uint8List(keyLength);
    int resultOffset = 0;
    
    for (int blockIndex = 1; resultOffset < keyLength; blockIndex++) {
      // Create block
      final block = Uint8List(salt.length + 4);
      block.setRange(0, salt.length, salt);
      block[salt.length] = (blockIndex >> 24) & 0xFF;
      block[salt.length + 1] = (blockIndex >> 16) & 0xFF;
      block[salt.length + 2] = (blockIndex >> 8) & 0xFF;
      block[salt.length + 3] = blockIndex & 0xFF;
      
      // First iteration
      var u = hmac.convert(block).bytes;
      final t = Uint8List.fromList(u);
      
      // Remaining iterations
      for (int i = 1; i < iterations; i++) {
        u = hmac.convert(u).bytes;
        for (int j = 0; j < u.length; j++) {
          t[j] ^= u[j];
        }
      }
      
      // Copy to result
      final bytesToCopy = math.min(t.length, keyLength - resultOffset);
      result.setRange(resultOffset, resultOffset + bytesToCopy, t);
      resultOffset += bytesToCopy;
    }
    
    return result;
  }
  
  /// Validate password strength
  Result<bool> validatePasswordStrength(String password) {
    if (password.length < 8) {
      return Result.error('Password must be at least 8 characters long');
    }
    
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return Result.error('Password must contain at least one uppercase letter');
    }
    
    if (!password.contains(RegExp(r'[a-z]'))) {
      return Result.error('Password must contain at least one lowercase letter');
    }
    
    if (!password.contains(RegExp(r'[0-9]'))) {
      return Result.error('Password must contain at least one number');
    }
    
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return Result.error('Password must contain at least one special character');
    }
    
    return Result.success(true);
  }
  
  /// Generate a secure random password
  String generateSecurePassword({int length = 16}) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#\$%^&*()';
    final random = math.Random.secure();
    return String.fromCharCodes(
      Iterable.generate(length, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
  }
}

/// Global secure auth service instance
final secureAuthService = SecureAuthService();

