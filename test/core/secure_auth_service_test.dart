import 'package:flutter_test/flutter_test.dart';
import '../../lib/core/secure_auth_service.dart';
import '../../lib/core/testing/test_helpers.dart';

void main() {
  group('SecureAuthService', () {
    late SecureAuthService authService;
    
    setUp(() async {
      await TestSetup.setUp();
      authService = SecureAuthService();
    });
    
    tearDown(() async {
      await TestSetup.tearDown();
    });
    
    test('should store and verify password', () async {
      const password = 'TestPassword123!';
      
      // Store password
      final storeResult = await authService.storePassword(password);
      ResultAssertions.expectSuccess(storeResult);
      
      // Verify password
      final verifyResult = await authService.verifyPassword(password);
      ResultAssertions.expectSuccess(verifyResult);
      expect(verifyResult.data, true);
    });
    
    test('should reject incorrect password', () async {
      const correctPassword = 'TestPassword123!';
      const incorrectPassword = 'WrongPassword123!';
      
      // Store correct password
      final storeResult = await authService.storePassword(correctPassword);
      ResultAssertions.expectSuccess(storeResult);
      
      // Verify incorrect password
      final verifyResult = await authService.verifyPassword(incorrectPassword);
      ResultAssertions.expectSuccess(verifyResult);
      expect(verifyResult.data, false);
    });
    
    test('should store and retrieve session', () async {
      const userId = 'test_user_123';
      const sessionToken = 'test_session_token';
      
      // Store session
      final storeResult = await authService.storeSession(userId, sessionToken);
      ResultAssertions.expectSuccess(storeResult);
      
      // Retrieve session
      final getResult = await authService.getSession();
      ResultAssertions.expectSuccess(getResult);
      
      final session = getResult.data!;
      expect(session['userId'], userId);
      expect(session['sessionToken'], sessionToken);
      expect(session['isLoggedIn'], 'true');
    });
    
    test('should check login status', () async {
      // Initially not logged in
      final isLoggedInResult = await authService.isLoggedIn();
      ResultAssertions.expectSuccess(isLoggedInResult);
      expect(isLoggedInResult.data, false);
      
      // Store session
      const userId = 'test_user_123';
      const sessionToken = 'test_session_token';
      await authService.storeSession(userId, sessionToken);
      
      // Now should be logged in
      final isLoggedInResult2 = await authService.isLoggedIn();
      ResultAssertions.expectSuccess(isLoggedInResult2);
      expect(isLoggedInResult2.data, true);
    });
    
    test('should clear session', () async {
      const userId = 'test_user_123';
      const sessionToken = 'test_session_token';
      
      // Store session
      await authService.storeSession(userId, sessionToken);
      
      // Verify logged in
      final isLoggedInResult = await authService.isLoggedIn();
      ResultAssertions.expectSuccess(isLoggedInResult);
      expect(isLoggedInResult.data, true);
      
      // Clear session
      final clearResult = await authService.clearSession();
      ResultAssertions.expectSuccess(clearResult);
      
      // Verify logged out
      final isLoggedInResult2 = await authService.isLoggedIn();
      ResultAssertions.expectSuccess(isLoggedInResult2);
      expect(isLoggedInResult2.data, false);
    });
    
    test('should validate password strength', () {
      // Valid password
      final validResult = authService.validatePasswordStrength('TestPassword123!');
      ResultAssertions.expectSuccess(validResult);
      expect(validResult.data, true);
      
      // Too short
      final shortResult = authService.validatePasswordStrength('Test1!');
      ResultAssertions.expectError(shortResult, 'Password must be at least 8 characters long');
      
      // No uppercase
      final noUpperResult = authService.validatePasswordStrength('testpassword123!');
      ResultAssertions.expectError(noUpperResult, 'Password must contain at least one uppercase letter');
      
      // No lowercase
      final noLowerResult = authService.validatePasswordStrength('TESTPASSWORD123!');
      ResultAssertions.expectError(noLowerResult, 'Password must contain at least one lowercase letter');
      
      // No number
      final noNumberResult = authService.validatePasswordStrength('TestPassword!');
      ResultAssertions.expectError(noNumberResult, 'Password must contain at least one number');
      
      // No special character
      final noSpecialResult = authService.validatePasswordStrength('TestPassword123');
      ResultAssertions.expectError(noSpecialResult, 'Password must contain at least one special character');
    });
    
    test('should generate secure password', () {
      final password = authService.generateSecurePassword();
      
      expect(password.length, 16);
      expect(password, isNot(equals('')));
      
      // Should pass validation
      final validationResult = authService.validatePasswordStrength(password);
      ResultAssertions.expectSuccess(validationResult);
      expect(validationResult.data, true);
    });
    
    test('should generate secure password with custom length', () {
      const length = 20;
      final password = authService.generateSecurePassword(length: length);
      
      expect(password.length, length);
      expect(password, isNot(equals('')));
    });
  });
}
