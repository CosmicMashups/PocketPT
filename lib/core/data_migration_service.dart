import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'result.dart';
import 'error_handler.dart';
import 'secure_auth_service.dart';
import 'repositories/user_repository.dart';
import 'repositories/hive_user_repository.dart';

/// Data migration service to help users migrate from old insecure system
/// This handles the transition from static global state to proper state management
class DataMigrationService {
  static final DataMigrationService _instance = DataMigrationService._internal();
  factory DataMigrationService() => _instance;
  DataMigrationService._internal();
  
  final ErrorHandler _errorHandler = ErrorHandler();
  final SecureAuthService _secureAuthService = SecureAuthService();
  
  /// Check if migration is needed
  Future<Result<bool>> isMigrationNeeded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if old data exists
      final hasOldUserData = prefs.containsKey('user_email') || 
                            prefs.containsKey('user_password') ||
                            prefs.containsKey('user_name');
      
      // Check if new secure data exists
      final hasNewSecureData = await _secureAuthService.isLoggedIn();
      
      return Result.success(hasOldUserData && !(hasNewSecureData.data ?? false));
    } catch (error, stackTrace) {
      _errorHandler.handleError('DataMigrationService.isMigrationNeeded', error, stackTrace);
      return Result.error('Failed to check migration status', error, stackTrace);
    }
  }
  
  /// Perform data migration from old system to new secure system
  Future<Result<void>> performMigration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get old user data
      final email = prefs.getString('user_email');
      final password = prefs.getString('user_password');
      final name = prefs.getString('user_name');
      
      if (email == null || password == null) {
        return Result.error('No user data found to migrate');
      }
      
      // Create user in new system
      final userRepository = HiveUserRepository();
      await userRepository.initialize();
      
      final user = User(
        id: _generateUserId(),
        email: email,
        name: name,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Create user in repository
      final createResult = await userRepository.create(user);
      if (createResult.isError) {
        return Result.error('Failed to create user: ${createResult.errorMessage}');
      }
      
      // Store password securely
      final passwordResult = await _secureAuthService.storePassword(password);
      if (passwordResult.isError) {
        return Result.error('Failed to store password securely: ${passwordResult.errorMessage}');
      }
      
      // Create session
      final sessionToken = _generateSessionToken();
      final sessionResult = await _secureAuthService.storeSession(user.id, sessionToken);
      if (sessionResult.isError) {
        return Result.error('Failed to create session: ${sessionResult.errorMessage}');
      }
      
      // Migrate other data if available
      await _migrateAdditionalData(prefs, user.id);
      
      // Clear old insecure data
      await _clearOldData(prefs);
      
      return Result.success(null);
    } catch (error, stackTrace) {
      _errorHandler.handleError('DataMigrationService.performMigration', error, stackTrace);
      return Result.error('Migration failed', error, stackTrace);
    }
  }
  
  /// Migrate additional user data
  Future<void> _migrateAdditionalData(SharedPreferences prefs, String userId) async {
    try {
      final userRepository = HiveUserRepository();
      await userRepository.initialize();
      
      // Migrate user preferences
      final preferences = <String, dynamic>{};
      
      // Migrate theme preferences
      final theme = prefs.getString('theme');
      if (theme != null) {
        preferences['theme'] = theme;
      }
      
      // Migrate notification preferences
      final notifications = prefs.getBool('notifications_enabled');
      if (notifications != null) {
        preferences['notifications_enabled'] = notifications;
      }
      
      // Migrate other preferences
      final language = prefs.getString('language');
      if (language != null) {
        preferences['language'] = language;
      }
      
      if (preferences.isNotEmpty) {
        await userRepository.updatePreferences(userId, preferences);
      }
      
      // Migrate Hive data if available
      await _migrateHiveData(userId);
    } catch (error, stackTrace) {
      _errorHandler.handleError('DataMigrationService._migrateAdditionalData', error, stackTrace);
      // Don't throw - this is not critical for migration
    }
  }
  
  /// Migrate Hive data
  Future<void> _migrateHiveData(String userId) async {
    try {
      // Check if old Hive box exists
      if (Hive.isBoxOpen('rehabBox')) {
        final box = Hive.box('rehabBox');
        
        // Migrate user progress data
        final userProgress = box.get('userProgress');
        if (userProgress != null) {
          // Convert to new format and store
          // This would need to be implemented based on the actual data structure
        }
        
        // Migrate assessment data
        final userAssess = box.get('userAssess');
        if (userAssess != null) {
          // Convert to new format and store
          // This would need to be implemented based on the actual data structure
        }
        
        // Migrate other data as needed
      }
    } catch (error, stackTrace) {
      _errorHandler.handleError('DataMigrationService._migrateHiveData', error, stackTrace);
      // Don't throw - this is not critical for migration
    }
  }
  
  /// Clear old insecure data
  Future<void> _clearOldData(SharedPreferences prefs) async {
    try {
      // Remove old user data
      await prefs.remove('user_email');
      await prefs.remove('user_password');
      await prefs.remove('user_name');
      await prefs.remove('user_id');
      await prefs.remove('is_logged_in');
      
      // Remove other old data
      await prefs.remove('last_login');
      await prefs.remove('login_count');
      
      // Mark migration as completed
      await prefs.setBool('migration_completed', true);
      await prefs.setString('migration_date', DateTime.now().toIso8601String());
    } catch (error, stackTrace) {
      _errorHandler.handleError('DataMigrationService._clearOldData', error, stackTrace);
      // Don't throw - this is not critical
    }
  }
  
  /// Generate a unique user ID
  String _generateUserId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp * 1000) % 1000000;
    return 'user_${timestamp}_$random';
  }
  
  /// Generate a session token
  String _generateSessionToken() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp * 1000) % 1000000;
    return 'session_${timestamp}_$random';
  }
  
  /// Check if migration was completed
  Future<Result<bool>> isMigrationCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final completed = prefs.getBool('migration_completed') ?? false;
      return Result.success(completed);
    } catch (error, stackTrace) {
      _errorHandler.handleError('DataMigrationService.isMigrationCompleted', error, stackTrace);
      return Result.error('Failed to check migration completion', error, stackTrace);
    }
  }
  
  /// Get migration date
  Future<Result<DateTime?>> getMigrationDate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dateString = prefs.getString('migration_date');
      if (dateString == null) {
        return Result.success(null);
      }
      
      final date = DateTime.parse(dateString);
      return Result.success(date);
    } catch (error, stackTrace) {
      _errorHandler.handleError('DataMigrationService.getMigrationDate', error, stackTrace);
      return Result.error('Failed to get migration date', error, stackTrace);
    }
  }
  
  /// Reset migration status (for testing)
  Future<Result<void>> resetMigrationStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('migration_completed');
      await prefs.remove('migration_date');
      return Result.success(null);
    } catch (error, stackTrace) {
      _errorHandler.handleError('DataMigrationService.resetMigrationStatus', error, stackTrace);
      return Result.error('Failed to reset migration status', error, stackTrace);
    }
  }
}

/// Global data migration service instance
final dataMigrationService = DataMigrationService();

