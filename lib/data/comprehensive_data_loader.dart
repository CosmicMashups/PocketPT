import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'globals.dart';
import 'rehabilitation_plan.dart';
import 'user_data_notifier.dart';
import 'auth_persistence_service.dart';

/// Comprehensive data loader to ensure all pages have proper data
class ComprehensiveDataLoader {
  static final ComprehensiveDataLoader _instance = ComprehensiveDataLoader._internal();
  static ComprehensiveDataLoader get instance => _instance;
  
  ComprehensiveDataLoader._internal();
  
  bool _isInitialized = false;
  bool _isLoading = false;
  final Map<String, bool> _dataLoadedFlags = {};
  final Map<String, Completer<void>> _loadingCompleters = {};
  
  /// Initialize the comprehensive data loader
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      debugPrint('ComprehensiveDataLoader: Initializing...');
      
      // Start loading all critical data
      await _loadAllCriticalData();
      
      _isInitialized = true;
      debugPrint('ComprehensiveDataLoader: Initialized successfully');
      
    } catch (e) {
      debugPrint('ComprehensiveDataLoader: Error during initialization: $e');
      rethrow;
    }
  }
  
  /// Load all critical data for the app
  Future<void> _loadAllCriticalData() async {
    if (_isLoading) return;
    
    _isLoading = true;
    try {
      debugPrint('ComprehensiveDataLoader: Loading all critical data...');
      
      // Load data in parallel with timeout to prevent hanging
      await Future.wait([
        _loadUserData(),
        _loadUserProgress(),
        _loadUserSettings(),
        _loadUserAssessment(),
        _loadRehabilitationPlans(),
        _loadPainHistory(),
        _loadExerciseHistory(),
      ]).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          debugPrint('ComprehensiveDataLoader: Data loading timed out, continuing with available data');
          throw TimeoutException('Data loading timed out', const Duration(seconds: 15));
        },
      );
      
      // Initialize UserDataNotifier with loaded data
      UserDataNotifier.instance.initialize();
      
      debugPrint('ComprehensiveDataLoader: All critical data loaded successfully');
      
    } catch (e) {
      debugPrint('ComprehensiveDataLoader: Error loading critical data: $e');
      // Initialize with empty data to prevent blank screen
      UserDataNotifier.instance.initialize();
    } finally {
      _isLoading = false;
    }
  }
  
  /// Load user data with fallback mechanisms
  Future<void> _loadUserData() async {
    try {
      debugPrint('ComprehensiveDataLoader: Loading user data...');
      
      // Try to load from Hive first (fastest)
      await UserDetails.loadFromHive().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('ComprehensiveDataLoader: Hive loading timed out');
        },
      );
      
      // If data is still empty, try Firebase
      if (UserDetails.firstName.isEmpty && UserDetails.lastName.isEmpty && UserDetails.email.isEmpty) {
        debugPrint('ComprehensiveDataLoader: User data empty from Hive, trying Firebase...');
        await UserDetails.loadFromFirebase().timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            debugPrint('ComprehensiveDataLoader: Firebase loading timed out');
          },
        );
      }
      
      // If still empty and user is authenticated, try to sync
      if (UserDetails.firstName.isEmpty && UserDetails.lastName.isEmpty && UserDetails.email.isEmpty) {
        if (AuthPersistenceService.instance.isAuthenticated) {
          debugPrint('ComprehensiveDataLoader: User data still empty, attempting sync...');
          await AuthPersistenceService.instance.syncAllData().timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              debugPrint('ComprehensiveDataLoader: Sync timed out');
            },
          );
        }
      }
      
      _dataLoadedFlags['userData'] = true;
      debugPrint('ComprehensiveDataLoader: User data loaded - firstName: "${UserDetails.firstName}", lastName: "${UserDetails.lastName}", email: "${UserDetails.email}"');
      
    } catch (e) {
      debugPrint('ComprehensiveDataLoader: Error loading user data: $e');
      // Set default values to prevent blank screen
      UserDetails.firstName = 'User';
      UserDetails.lastName = '';
      UserDetails.email = 'user@example.com';
      UserDetails.hasCompletedAssessment = false;
      _dataLoadedFlags['userData'] = false;
    }
  }
  
  /// Load user progress data
  Future<void> _loadUserProgress() async {
    try {
      debugPrint('ComprehensiveDataLoader: Loading user progress...');
      await UserProgress.loadFromHive();
      _dataLoadedFlags['userProgress'] = true;
      debugPrint('ComprehensiveDataLoader: User progress loaded');
    } catch (e) {
      debugPrint('ComprehensiveDataLoader: Error loading user progress: $e');
      _dataLoadedFlags['userProgress'] = false;
    }
  }
  
  /// Load user settings
  Future<void> _loadUserSettings() async {
    try {
      debugPrint('ComprehensiveDataLoader: Loading user settings...');
      await UserSettings.loadFromHive();
      _dataLoadedFlags['userSettings'] = true;
      debugPrint('ComprehensiveDataLoader: User settings loaded');
    } catch (e) {
      debugPrint('ComprehensiveDataLoader: Error loading user settings: $e');
      _dataLoadedFlags['userSettings'] = false;
    }
  }
  
  /// Load user assessment data
  Future<void> _loadUserAssessment() async {
    try {
      debugPrint('ComprehensiveDataLoader: Loading user assessment...');
      await UserAssess.loadFromHive();
      _dataLoadedFlags['userAssessment'] = true;
      debugPrint('ComprehensiveDataLoader: User assessment loaded');
    } catch (e) {
      debugPrint('ComprehensiveDataLoader: Error loading user assessment: $e');
      _dataLoadedFlags['userAssessment'] = false;
    }
  }
  
  /// Load rehabilitation plans
  Future<void> _loadRehabilitationPlans() async {
    try {
      debugPrint('ComprehensiveDataLoader: Loading rehabilitation plans...');
      await UserRehabilitation.instance.loadPlansFromHive();
      _dataLoadedFlags['rehabilitationPlans'] = true;
      debugPrint('ComprehensiveDataLoader: Rehabilitation plans loaded');
    } catch (e) {
      debugPrint('ComprehensiveDataLoader: Error loading rehabilitation plans: $e');
      _dataLoadedFlags['rehabilitationPlans'] = false;
    }
  }
  
  /// Load pain history
  Future<void> _loadPainHistory() async {
    try {
      debugPrint('ComprehensiveDataLoader: Loading pain history...');
      await PainHistory.loadFromHive();
      _dataLoadedFlags['painHistory'] = true;
      debugPrint('ComprehensiveDataLoader: Pain history loaded');
    } catch (e) {
      debugPrint('ComprehensiveDataLoader: Error loading pain history: $e');
      _dataLoadedFlags['painHistory'] = false;
    }
  }
  
  /// Load exercise history
  Future<void> _loadExerciseHistory() async {
    try {
      debugPrint('ComprehensiveDataLoader: Loading exercise history...');
      await ExerciseHistory.loadFromHive();
      _dataLoadedFlags['exerciseHistory'] = true;
      debugPrint('ComprehensiveDataLoader: Exercise history loaded');
    } catch (e) {
      debugPrint('ComprehensiveDataLoader: Error loading exercise history: $e');
      _dataLoadedFlags['exerciseHistory'] = false;
    }
  }
  
  /// Ensure specific data is loaded before proceeding
  Future<void> ensureDataLoaded(String dataType) async {
    if (_dataLoadedFlags[dataType] == true) {
      return;
    }
    
    // Check if loading is already in progress
    if (_loadingCompleters.containsKey(dataType)) {
      return _loadingCompleters[dataType]!.future;
    }
    
    // Start loading
    final completer = Completer<void>();
    _loadingCompleters[dataType] = completer;
    
    try {
      switch (dataType) {
        case 'userData':
          await _loadUserData();
          break;
        case 'userProgress':
          await _loadUserProgress();
          break;
        case 'userSettings':
          await _loadUserSettings();
          break;
        case 'userAssessment':
          await _loadUserAssessment();
          break;
        case 'rehabilitationPlans':
          await _loadRehabilitationPlans();
          break;
        case 'painHistory':
          await _loadPainHistory();
          break;
        case 'exerciseHistory':
          await _loadExerciseHistory();
          break;
        default:
          debugPrint('ComprehensiveDataLoader: Unknown data type: $dataType');
      }
      
      completer.complete();
    } catch (e) {
      debugPrint('ComprehensiveDataLoader: Error loading $dataType: $e');
      completer.completeError(e);
    } finally {
      _loadingCompleters.remove(dataType);
    }
    
    return completer.future;
  }
  
  /// Check if specific data is loaded
  bool isDataLoaded(String dataType) {
    return _dataLoadedFlags[dataType] == true;
  }
  
  /// Check if all critical data is loaded
  bool get isAllDataLoaded {
    const criticalDataTypes = [
      'userData',
      'userProgress', 
      'userSettings',
      'userAssessment',
      'rehabilitationPlans',
      'painHistory',
      'exerciseHistory',
    ];
    
    return criticalDataTypes.every((type) => _dataLoadedFlags[type] == true);
  }
  
  /// Get loading status
  bool get isLoading => _isLoading;
  
  /// Get data loading status for debugging
  Map<String, bool> get dataStatus => Map.from(_dataLoadedFlags);
  
  /// Force reload all data
  Future<void> reloadAllData() async {
    debugPrint('ComprehensiveDataLoader: Force reloading all data...');
    _dataLoadedFlags.clear();
    _loadingCompleters.clear();
    await _loadAllCriticalData();
  }
  
  /// Dispose of the service
  void dispose() {
    _isInitialized = false;
    _isLoading = false;
    _dataLoadedFlags.clear();
    _loadingCompleters.clear();
    debugPrint('ComprehensiveDataLoader: Disposed');
  }
}
