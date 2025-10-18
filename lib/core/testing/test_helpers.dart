import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../result.dart';
import '../error_handler.dart';
import '../secure_auth_service.dart';
import '../repositories/user_repository.dart';
import '../repositories/hive_user_repository.dart';
import '../data_migration_service.dart';

/// Test helpers for comprehensive testing infrastructure
/// This provides utilities for testing the new architecture

/// Mock data for testing
class TestData {
  static const String testUserId = 'test_user_123';
  static const String testEmail = 'test@example.com';
  static const String testPassword = 'TestPassword123!';
  static const String testName = 'Test User';
  
  static User get testUser => User(
    id: testUserId,
    email: testEmail,
    name: testName,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
    preferences: {'theme': 'light', 'notifications': true},
  );
  
  static Map<String, dynamic> get testPreferences => {
    'theme': 'dark',
    'notifications': false,
    'language': 'en',
  };
}

/// Test setup and teardown utilities
class TestSetup {
  /// Set up test environment
  static Future<void> setUp() async {
    // Initialize Hive for testing
    await Hive.initFlutter();
    
    // Clear any existing test data
    await clearTestData();
  }
  
  /// Tear down test environment
  static Future<void> tearDown() async {
    // Clear test data
    await clearTestData();
    
    // Close Hive boxes
    await Hive.close();
  }
  
  /// Clear all test data
  static Future<void> clearTestData() async {
    try {
      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      // Clear Hive boxes
      if (Hive.isBoxOpen('users')) {
        await Hive.box('users').clear();
      }
      if (Hive.isBoxOpen('user_preferences')) {
        await Hive.box('user_preferences').clear();
      }
      if (Hive.isBoxOpen('rehabBox')) {
        await Hive.box('rehabBox').clear();
      }
    } catch (e) {
      // Ignore errors during cleanup
    }
  }
}

/// Mock implementations for testing
class MockUserRepository implements UserRepository {
  final List<User> _users = [];
  final Map<String, Map<String, dynamic>> _preferences = {};
  
  @override
  Future<Result<User?>> getById(String id) async {
    try {
      final user = _users.firstWhere((u) => u.id == id);
      return Result.success(user);
    } catch (e) {
      return Result.success(null);
    }
  }
  
  @override
  Future<Result<List<User>>> getAll() async {
    return Result.success(_users);
  }
  
  @override
  Future<Result<User>> create(User user) async {
    if (_users.any((u) => u.id == user.id)) {
      return Result.error('User with ID ${user.id} already exists');
    }
    if (_users.any((u) => u.email == user.email)) {
      return Result.error('User with email ${user.email} already exists');
    }
    
    _users.add(user);
    return Result.success(user);
  }
  
  @override
  Future<Result<User>> update(User user) async {
    final index = _users.indexWhere((u) => u.id == user.id);
    if (index == -1) {
      return Result.error('User with ID ${user.id} does not exist');
    }
    
    _users[index] = user;
    return Result.success(user);
  }
  
  @override
  Future<Result<void>> deleteById(String id) async {
    _users.removeWhere((u) => u.id == id);
    _preferences.remove(id);
    return Result.success(null);
  }
  
  @override
  Future<Result<bool>> existsById(String id) async {
    return Result.success(_users.any((u) => u.id == id));
  }
  
  @override
  Future<Result<int>> count() async {
    return Result.success(_users.length);
  }
  
  @override
  Future<Result<User?>> getByEmail(String email) async {
    try {
      final user = _users.firstWhere((u) => u.email == email);
      return Result.success(user);
    } catch (e) {
      return Result.success(null);
    }
  }
  
  @override
  Future<Result<User>> updatePreferences(String userId, Map<String, dynamic> preferences) async {
    final userResult = await getById(userId);
    if (userResult.isError || userResult.data == null) {
      return Result.error('User not found');
    }
    
    _preferences[userId] = preferences;
    final updatedUser = userResult.data!.copyWith(
      preferences: preferences,
      updatedAt: DateTime.now(),
    );
    
    return update(updatedUser);
  }
  
  @override
  Future<Result<Map<String, dynamic>?>> getPreferences(String userId) async {
    return Result.success(_preferences[userId]);
  }
  
  @override
  Future<Result<bool>> emailExists(String email) async {
    return Result.success(_users.any((u) => u.email == email));
  }
  
  @override
  Future<Result<User>> updateProfile(String userId, {String? name, String? email}) async {
    final userResult = await getById(userId);
    if (userResult.isError || userResult.data == null) {
      return Result.error('User not found');
    }
    
    final user = userResult.data!;
    final updatedUser = user.copyWith(
      name: name ?? user.name,
      email: email ?? user.email,
      updatedAt: DateTime.now(),
    );
    
    return update(updatedUser);
  }
}

/// Test assertions for Result types
class ResultAssertions {
  static void expectSuccess<T>(Result<T> result, [T? expectedData]) {
    expect(result.isSuccess, true, reason: 'Expected success but got error: ${result.errorMessage}');
    if (expectedData != null) {
      expect(result.data, expectedData);
    }
  }
  
  static void expectError<T>(Result<T> result, [String? expectedMessage]) {
    expect(result.isError, true, reason: 'Expected error but got success');
    if (expectedMessage != null) {
      expect(result.errorMessage, expectedMessage);
    }
  }
  
  static void expectData<T>(Result<T> result, T expectedData) {
    expectSuccess(result);
    expect(result.data, expectedData);
  }
}

/// Test utilities for async operations
class AsyncTestUtils {
  /// Wait for a condition to be true
  static Future<void> waitForCondition(
    bool Function() condition, {
    Duration timeout = const Duration(seconds: 5),
    Duration interval = const Duration(milliseconds: 100),
  }) async {
    final endTime = DateTime.now().add(timeout);
    
    while (DateTime.now().isBefore(endTime)) {
      if (condition()) {
        return;
      }
      await Future.delayed(interval);
    }
    
    throw TimeoutException('Condition not met within timeout', timeout);
  }
  
  /// Wait for a Result to be successful
  static Future<Result<T>> waitForSuccess<T>(
    Future<Result<T>> Function() operation, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final endTime = DateTime.now().add(timeout);
    
    while (DateTime.now().isBefore(endTime)) {
      final result = await operation();
      if (result.isSuccess) {
        return result;
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    throw TimeoutException('Operation did not succeed within timeout', timeout);
  }
}

/// Test data builders
class TestDataBuilder {
  static User buildUser({
    String? id,
    String? email,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? preferences,
  }) {
    return User(
      id: id ?? TestData.testUserId,
      email: email ?? TestData.testEmail,
      name: name ?? TestData.testName,
      createdAt: createdAt ?? DateTime(2024, 1, 1),
      updatedAt: updatedAt ?? DateTime(2024, 1, 1),
      preferences: preferences ?? TestData.testPreferences,
    );
  }
  
  static Map<String, dynamic> buildPreferences({
    String? theme,
    bool? notifications,
    String? language,
  }) {
    return {
      'theme': theme ?? 'light',
      'notifications': notifications ?? true,
      'language': language ?? 'en',
    };
  }
}

