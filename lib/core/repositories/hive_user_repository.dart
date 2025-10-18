import 'package:hive_flutter/hive_flutter.dart';
import '../result.dart';
import '../error_handler.dart';
import 'user_repository.dart';

/// Hive implementation of UserRepository
/// This provides local storage for user data with proper error handling
class HiveUserRepository implements UserRepository {
  static const String _boxName = 'users';
  static const String _preferencesBoxName = 'user_preferences';
  
  late Box<User> _userBox;
  late Box<Map> _preferencesBox;
  bool _initialized = false;
  
  /// Initialize the repository
  Future<Result<void>> initialize() async {
    if (_initialized) {
      return Result.success(null);
    }
    
    try {
      _userBox = await Hive.openBox<User>(_boxName);
      _preferencesBox = await Hive.openBox<Map>(_preferencesBoxName);
      _initialized = true;
      return Result.success(null);
    } catch (error, stackTrace) {
      errorHandler.handleError('HiveUserRepository.initialize', error, stackTrace);
      return Result.error('Failed to initialize user repository', error, stackTrace);
    }
  }
  
  @override
  Future<Result<User?>> getById(String id) async {
    try {
      await _ensureInitialized();
      final user = _userBox.get(id);
      return Result.success(user);
    } catch (error, stackTrace) {
      errorHandler.handleError('HiveUserRepository.getById', error, stackTrace, {'id': id});
      return Result.error('Failed to get user by ID', error, stackTrace);
    }
  }
  
  @override
  Future<Result<List<User>>> getAll() async {
    try {
      await _ensureInitialized();
      final users = _userBox.values.toList();
      return Result.success(users);
    } catch (error, stackTrace) {
      errorHandler.handleError('HiveUserRepository.getAll', error, stackTrace);
      return Result.error('Failed to get all users', error, stackTrace);
    }
  }
  
  @override
  Future<Result<User>> create(User user) async {
    try {
      await _ensureInitialized();
      
      // Check if user already exists
      if (_userBox.containsKey(user.id)) {
        return Result.error('User with ID ${user.id} already exists');
      }
      
      // Check if email already exists
      final existingUser = await getByEmail(user.email);
      if (existingUser.isSuccess && existingUser.data != null) {
        return Result.error('User with email ${user.email} already exists');
      }
      
      await _userBox.put(user.id, user);
      return Result.success(user);
    } catch (error, stackTrace) {
      errorHandler.handleError('HiveUserRepository.create', error, stackTrace, {'user': user.toJson()});
      return Result.error('Failed to create user', error, stackTrace);
    }
  }
  
  @override
  Future<Result<User>> update(User user) async {
    try {
      await _ensureInitialized();
      
      // Check if user exists
      if (!_userBox.containsKey(user.id)) {
        return Result.error('User with ID ${user.id} does not exist');
      }
      
      // Update the user
      final updatedUser = user.copyWith(updatedAt: DateTime.now());
      await _userBox.put(user.id, updatedUser);
      return Result.success(updatedUser);
    } catch (error, stackTrace) {
      errorHandler.handleError('HiveUserRepository.update', error, stackTrace, {'user': user.toJson()});
      return Result.error('Failed to update user', error, stackTrace);
    }
  }
  
  @override
  Future<Result<void>> deleteById(String id) async {
    try {
      await _ensureInitialized();
      
      if (!_userBox.containsKey(id)) {
        return Result.error('User with ID $id does not exist');
      }
      
      await _userBox.delete(id);
      await _preferencesBox.delete(id);
      return Result.success(null);
    } catch (error, stackTrace) {
      errorHandler.handleError('HiveUserRepository.deleteById', error, stackTrace, {'id': id});
      return Result.error('Failed to delete user', error, stackTrace);
    }
  }
  
  @override
  Future<Result<bool>> existsById(String id) async {
    try {
      await _ensureInitialized();
      return Result.success(_userBox.containsKey(id));
    } catch (error, stackTrace) {
      errorHandler.handleError('HiveUserRepository.existsById', error, stackTrace, {'id': id});
      return Result.error('Failed to check if user exists', error, stackTrace);
    }
  }
  
  @override
  Future<Result<int>> count() async {
    try {
      await _ensureInitialized();
      return Result.success(_userBox.length);
    } catch (error, stackTrace) {
      errorHandler.handleError('HiveUserRepository.count', error, stackTrace);
      return Result.error('Failed to count users', error, stackTrace);
    }
  }
  
  @override
  Future<Result<User?>> getByEmail(String email) async {
    try {
      await _ensureInitialized();
      
      for (final user in _userBox.values) {
        if (user.email.toLowerCase() == email.toLowerCase()) {
          return Result.success(user);
        }
      }
      
      return Result.success(null);
    } catch (error, stackTrace) {
      errorHandler.handleError('HiveUserRepository.getByEmail', error, stackTrace, {'email': email});
      return Result.error('Failed to get user by email', error, stackTrace);
    }
  }
  
  @override
  Future<Result<User>> updatePreferences(String userId, Map<String, dynamic> preferences) async {
    try {
      await _ensureInitialized();
      
      final userResult = await getById(userId);
      if (userResult.isError) {
        return Result.error(userResult.errorMessage ?? 'Failed to get user');
      }
      
      final user = userResult.data;
      if (user == null) {
        return Result.error('User with ID $userId does not exist');
      }
      
      final updatedUser = user.copyWith(
        preferences: preferences,
        updatedAt: DateTime.now(),
      );
      
      await _userBox.put(userId, updatedUser);
      await _preferencesBox.put(userId, preferences);
      
      return Result.success(updatedUser);
    } catch (error, stackTrace) {
      errorHandler.handleError('HiveUserRepository.updatePreferences', error, stackTrace, {
        'userId': userId,
        'preferences': preferences,
      });
      return Result.error('Failed to update user preferences', error, stackTrace);
    }
  }
  
  @override
  Future<Result<Map<String, dynamic>?>> getPreferences(String userId) async {
    try {
      await _ensureInitialized();
      
      final preferences = _preferencesBox.get(userId);
      return Result.success(preferences?.cast<String, dynamic>());
    } catch (error, stackTrace) {
      errorHandler.handleError('HiveUserRepository.getPreferences', error, stackTrace, {'userId': userId});
      return Result.error('Failed to get user preferences', error, stackTrace);
    }
  }
  
  @override
  Future<Result<bool>> emailExists(String email) async {
    try {
      final userResult = await getByEmail(email);
      if (userResult.isError) {
        return Result.error(userResult.errorMessage ?? 'Failed to check email');
      }
      
      return Result.success(userResult.data != null);
    } catch (error, stackTrace) {
      errorHandler.handleError('HiveUserRepository.emailExists', error, stackTrace, {'email': email});
      return Result.error('Failed to check if email exists', error, stackTrace);
    }
  }
  
  @override
  Future<Result<User>> updateProfile(String userId, {String? name, String? email}) async {
    try {
      await _ensureInitialized();
      
      final userResult = await getById(userId);
      if (userResult.isError) {
        return Result.error(userResult.errorMessage ?? 'Failed to get user');
      }
      
      final user = userResult.data;
      if (user == null) {
        return Result.error('User with ID $userId does not exist');
      }
      
      // Check if email is being changed and if it already exists
      if (email != null && email != user.email) {
        final emailExistsResult = await emailExists(email);
        if (emailExistsResult.isError) {
          return Result.error(emailExistsResult.errorMessage ?? 'Failed to check email');
        }
        
        if (emailExistsResult.data == true) {
          return Result.error('Email $email already exists');
        }
      }
      
      final updatedUser = user.copyWith(
        name: name ?? user.name,
        email: email ?? user.email,
        updatedAt: DateTime.now(),
      );
      
      await _userBox.put(userId, updatedUser);
      return Result.success(updatedUser);
    } catch (error, stackTrace) {
      errorHandler.handleError('HiveUserRepository.updateProfile', error, stackTrace, {
        'userId': userId,
        'name': name,
        'email': email,
      });
      return Result.error('Failed to update user profile', error, stackTrace);
    }
  }
  
  /// Ensure the repository is initialized
  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      final initResult = await initialize();
      if (initResult.isError) {
        throw Exception('Failed to initialize repository: ${initResult.errorMessage}');
      }
    }
  }
  
  /// Close the repository and clean up resources
  Future<Result<void>> close() async {
    try {
      if (_initialized) {
        await _userBox.close();
        await _preferencesBox.close();
        _initialized = false;
      }
      return Result.success(null);
    } catch (error, stackTrace) {
      errorHandler.handleError('HiveUserRepository.close', error, stackTrace);
      return Result.error('Failed to close repository', error, stackTrace);
    }
  }
}

