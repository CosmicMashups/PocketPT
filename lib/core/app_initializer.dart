import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'result.dart';
import 'error_handler.dart';
import 'repositories/user_repository.dart';
import 'repositories/user_hive_adapter.dart';
import 'repositories/hive_user_repository.dart';

/// Application initialization service
/// This handles the setup of all core components and services
class AppInitializer {
  static final AppInitializer _instance = AppInitializer._internal();
  factory AppInitializer() => _instance;
  AppInitializer._internal();
  
  bool _initialized = false;
  final ErrorHandler _errorHandler = ErrorHandler();
  
  /// Initialize the application
  Future<Result<void>> initialize() async {
    if (_initialized) {
      return Result.success(null);
    }
    
    try {
      // Initialize Hive
      await _initializeHive();
      
      // Initialize repositories
      await _initializeRepositories();
      
      _initialized = true;
      
      if (kDebugMode) {
        print('App initialization completed successfully');
      }
      
      return Result.success(null);
    } catch (error, stackTrace) {
      _errorHandler.handleError('AppInitializer.initialize', error, stackTrace);
      return Result.error('Failed to initialize application', error, stackTrace);
    }
  }
  
  /// Initialize Hive database
  Future<void> _initializeHive() async {
    try {
      // Initialize Hive
      await Hive.initFlutter();
      
      // Register adapters
      Hive.registerAdapter(UserAdapter());
      
      if (kDebugMode) {
        print('Hive initialized successfully');
      }
    } catch (error, stackTrace) {
      _errorHandler.handleError('AppInitializer._initializeHive', error, stackTrace);
      rethrow;
    }
  }
  
  /// Initialize repositories
  Future<void> _initializeRepositories() async {
    try {
      // Initialize user repository
      final userRepository = HiveUserRepository();
      final initResult = await userRepository.initialize();
      
      if (initResult.isError) {
        throw Exception('Failed to initialize user repository: ${initResult.errorMessage}');
      }
      
      if (kDebugMode) {
        print('Repositories initialized successfully');
      }
    } catch (error, stackTrace) {
      _errorHandler.handleError('AppInitializer._initializeRepositories', error, stackTrace);
      rethrow;
    }
  }
  
  /// Check if the application is initialized
  bool get isInitialized => _initialized;
  
  /// Reset initialization state (for testing)
  void reset() {
    _initialized = false;
  }
}

/// Global app initializer instance
final appInitializer = AppInitializer();

