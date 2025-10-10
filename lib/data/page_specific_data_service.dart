import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'globals.dart';
import 'rehabilitation_plan.dart';
import 'hive_models.dart';
import 'user_data_notifier.dart';

/// Service for page-specific data loading and caching
/// Only loads the data needed for each specific page
class PageSpecificDataService {
  static final PageSpecificDataService _instance = PageSpecificDataService._internal();
  static PageSpecificDataService get instance => _instance;
  PageSpecificDataService._internal();

  // Cache for page-specific data
  final Map<String, dynamic> _pageDataCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  final Map<String, Completer<dynamic>> _pendingRequests = {};
  
  // Cache configuration
  static const Duration _cacheExpiry = Duration(minutes: 10);
  static const int _maxCacheSize = 50;

  /// Load data specific to assessment pages
  Future<Map<String, dynamic>> loadAssessmentData() async {
    const cacheKey = 'assessment_data';
    
    // Check if request is already pending
    if (_pendingRequests.containsKey(cacheKey)) {
      return await _pendingRequests[cacheKey]!.future;
    }

    // Check cache first
    if (_pageDataCache.containsKey(cacheKey) && _isCacheValid(cacheKey)) {
      return _pageDataCache[cacheKey] as Map<String, dynamic>;
    }

    // Create pending request
    final completer = Completer<Map<String, dynamic>>();
    _pendingRequests[cacheKey] = completer;

    try {
      debugPrint('PageSpecificDataService: Loading assessment data...');
      
      // Load only assessment-related data from Hive
      final box = Hive.box('rehabBox');
      final hiveUserAssess = box.get('userAssess');
      
      Map<String, dynamic> assessmentData = {};
      
      if (hiveUserAssess is HiveUserAssess) {
        assessmentData = {
          'rehabGoal': hiveUserAssess.rehabGoal,
          'generalMuscle': hiveUserAssess.generalMuscle,
          'specificMuscle': hiveUserAssess.specificMuscle,
          'painScale': hiveUserAssess.painScale,
          'painLevel': hiveUserAssess.painLevel,
          'painType': hiveUserAssess.painType,
          'painDuration': hiveUserAssess.painDuration,
          'isInjured': hiveUserAssess.isInjured,
          'isAssessed': hiveUserAssess.isAssessed,
        };
        
        // Update global variables
        UserAssess.rehabGoal = hiveUserAssess.rehabGoal;
        UserAssess.generalMuscle = hiveUserAssess.generalMuscle;
        UserAssess.specificMuscle = hiveUserAssess.specificMuscle;
        UserAssess.painScale = hiveUserAssess.painScale;
        UserAssess.painLevel = hiveUserAssess.painLevel;
        UserAssess.painType = hiveUserAssess.painType;
        UserAssess.painDuration = hiveUserAssess.painDuration;
        UserAssess.isInjured = hiveUserAssess.isInjured;
        UserAssess.isAssessed = hiveUserAssess.isAssessed;
      }
      
      _cacheData(cacheKey, assessmentData);
      completer.complete(assessmentData);
      debugPrint('PageSpecificDataService: Assessment data loaded successfully');
      return assessmentData;
      
    } catch (e) {
      debugPrint('PageSpecificDataService: Error loading assessment data: $e');
      completer.completeError(e);
      rethrow;
    } finally {
      _pendingRequests.remove(cacheKey);
    }
  }

  /// Load data specific to dashboard page
  Future<Map<String, dynamic>> loadDashboardData() async {
    const cacheKey = 'dashboard_data';
    
    // Check if request is already pending
    if (_pendingRequests.containsKey(cacheKey)) {
      return await _pendingRequests[cacheKey]!.future;
    }

    // Check cache first
    if (_pageDataCache.containsKey(cacheKey) && _isCacheValid(cacheKey)) {
      return _pageDataCache[cacheKey] as Map<String, dynamic>;
    }

    // Create pending request
    final completer = Completer<Map<String, dynamic>>();
    _pendingRequests[cacheKey] = completer;

    try {
      debugPrint('PageSpecificDataService: Loading dashboard data...');
      
      final box = Hive.box('rehabBox');
      
      // Load only dashboard-relevant data in parallel
      final results = await Future.wait([
        _loadUserDetailsForDashboard(),
        _loadUserProgressForDashboard(),
        _loadRehabilitationPlansForDashboard(),
        _loadNotificationsForDashboard(),
      ]);
      
      final dashboardData = {
        'userDetails': results[0],
        'userProgress': results[1],
        'rehabilitationPlans': results[2],
        'notifications': results[3],
        'hasCompletedAssessment': box.get('hasCompletedAssessment', defaultValue: false),
      };
      
      _cacheData(cacheKey, dashboardData);
      completer.complete(dashboardData);
      debugPrint('PageSpecificDataService: Dashboard data loaded successfully');
      return dashboardData;
      
    } catch (e) {
      debugPrint('PageSpecificDataService: Error loading dashboard data: $e');
      completer.completeError(e);
      rethrow;
    } finally {
      _pendingRequests.remove(cacheKey);
    }
  }

  /// Load data specific to profile page
  Future<Map<String, dynamic>> loadProfileData() async {
    const cacheKey = 'profile_data';
    
    // Check if request is already pending
    if (_pendingRequests.containsKey(cacheKey)) {
      return await _pendingRequests[cacheKey]!.future;
    }

    // Check cache first
    if (_pageDataCache.containsKey(cacheKey) && _isCacheValid(cacheKey)) {
      return _pageDataCache[cacheKey] as Map<String, dynamic>;
    }

    // Create pending request
    final completer = Completer<Map<String, dynamic>>();
    _pendingRequests[cacheKey] = completer;

    try {
      debugPrint('PageSpecificDataService: Loading profile data...');
      
      final box = Hive.box('rehabBox');
      final hiveUserDetails = box.get('userDetails');
      final hiveUserSettings = box.get('userSettings');
      
      Map<String, dynamic> profileData = {};
      
      if (hiveUserDetails is HiveUserDetails) {
        profileData = {
          'firstName': hiveUserDetails.firstName,
          'lastName': hiveUserDetails.lastName,
          'email': hiveUserDetails.email,
          'profilePicture': hiveUserDetails.profilePicture,
          'isGuest': hiveUserDetails.isGuest,
          'guestSessionId': hiveUserDetails.guestSessionId,
        };
        
        // Update global variables
        UserDetails.firstName = hiveUserDetails.firstName;
        UserDetails.lastName = hiveUserDetails.lastName;
        UserDetails.email = hiveUserDetails.email;
        UserDetails.profilePicture = hiveUserDetails.profilePicture;
        UserDetails.isGuest = hiveUserDetails.isGuest;
        UserDetails.guestSessionId = hiveUserDetails.guestSessionId;
        
        // Notify UI of data changes
        UserDataNotifier.instance.updateUserData(
          firstName: UserDetails.firstName,
          lastName: UserDetails.lastName,
          email: UserDetails.email,
          profilePicture: UserDetails.profilePicture,
        );
      }
      
      if (hiveUserSettings is HiveUserSettings) {
        profileData['settings'] = {
          'isDailyReminder': hiveUserSettings.isDailyReminder,
          'isStreakAlert': hiveUserSettings.isStreakAlert,
          'isExerciseReminder': hiveUserSettings.isExerciseReminder,
          'exerciseReminderHour': hiveUserSettings.exerciseReminderHour,
          'exerciseReminderMinute': hiveUserSettings.exerciseReminderMinute,
        };
        
        // Update global variables
        UserSettings.isDailyReminder = hiveUserSettings.isDailyReminder;
        UserSettings.isStreakAlert = hiveUserSettings.isStreakAlert;
        UserSettings.isExerciseReminder = hiveUserSettings.isExerciseReminder;
        UserSettings.exerciseReminderTime = TimeOfDay(
          hour: hiveUserSettings.exerciseReminderHour,
          minute: hiveUserSettings.exerciseReminderMinute,
        );
      }
      
      _cacheData(cacheKey, profileData);
      completer.complete(profileData);
      debugPrint('PageSpecificDataService: Profile data loaded successfully');
      return profileData;
      
    } catch (e) {
      debugPrint('PageSpecificDataService: Error loading profile data: $e');
      completer.completeError(e);
      rethrow;
    } finally {
      _pendingRequests.remove(cacheKey);
    }
  }

  /// Load data specific to exercise pages
  Future<Map<String, dynamic>> loadExerciseData() async {
    const cacheKey = 'exercise_data';
    
    // Check if request is already pending
    if (_pendingRequests.containsKey(cacheKey)) {
      return await _pendingRequests[cacheKey]!.future;
    }

    // Check cache first
    if (_pageDataCache.containsKey(cacheKey) && _isCacheValid(cacheKey)) {
      return _pageDataCache[cacheKey] as Map<String, dynamic>;
    }

    // Create pending request
    final completer = Completer<Map<String, dynamic>>();
    _pendingRequests[cacheKey] = completer;

    try {
      debugPrint('PageSpecificDataService: Loading exercise data...');
      
      // Load only exercise-related data from Hive
      await UserRehabilitation.instance.loadPlansFromHive();
      
      final exerciseData = {
        'rehabilitationPlans': UserRehabilitation.instance.rehabPlans,
        'treatmentReferences': UserRehabilitation.instance.treatmentReferences,
        'selectedMuscle': UserRehabilitation.instance.selectedMuscle,
      };
      
      _cacheData(cacheKey, exerciseData);
      completer.complete(exerciseData);
      debugPrint('PageSpecificDataService: Exercise data loaded successfully');
      return exerciseData;
      
    } catch (e) {
      debugPrint('PageSpecificDataService: Error loading exercise data: $e');
      completer.completeError(e);
      rethrow;
    } finally {
      _pendingRequests.remove(cacheKey);
    }
  }

  /// Load data specific to reports page
  Future<Map<String, dynamic>> loadReportsData() async {
    const cacheKey = 'reports_data';
    
    // Check if request is already pending
    if (_pendingRequests.containsKey(cacheKey)) {
      return await _pendingRequests[cacheKey]!.future;
    }

    // Check cache first
    if (_pageDataCache.containsKey(cacheKey) && _isCacheValid(cacheKey)) {
      return _pageDataCache[cacheKey] as Map<String, dynamic>;
    }

    // Create pending request
    final completer = Completer<Map<String, dynamic>>();
    _pendingRequests[cacheKey] = completer;

    try {
      debugPrint('PageSpecificDataService: Loading reports data...');
      
      // Load reports-specific data in parallel
      final results = await Future.wait([
        _loadPainHistoryForReports(),
        _loadExerciseHistoryForReports(),
        _loadRehabilitationPlansForReports(),
        _loadUserProgressForReports(),
      ]);
      
      final reportsData = {
        'painHistory': results[0],
        'exerciseHistory': results[1],
        'rehabilitationPlans': results[2],
        'userProgress': results[3],
      };
      
      _cacheData(cacheKey, reportsData);
      completer.complete(reportsData);
      debugPrint('PageSpecificDataService: Reports data loaded successfully');
      return reportsData;
      
    } catch (e) {
      debugPrint('PageSpecificDataService: Error loading reports data: $e');
      completer.completeError(e);
      rethrow;
    } finally {
      _pendingRequests.remove(cacheKey);
    }
  }

  /// Load data specific to daily assessment page
  Future<Map<String, dynamic>> loadDailyAssessmentData() async {
    const cacheKey = 'daily_assessment_data';
    
    // Check if request is already pending
    if (_pendingRequests.containsKey(cacheKey)) {
      return await _pendingRequests[cacheKey]!.future;
    }

    // Check cache first
    if (_pageDataCache.containsKey(cacheKey) && _isCacheValid(cacheKey)) {
      return _pageDataCache[cacheKey] as Map<String, dynamic>;
    }

    // Create pending request
    final completer = Completer<Map<String, dynamic>>();
    _pendingRequests[cacheKey] = completer;

    try {
      debugPrint('PageSpecificDataService: Loading daily assessment data...');
      
      // Load only daily assessment-related data from Hive
      final box = Hive.box('rehabBox');
      final hiveUserAssess = box.get('userAssess');
      final hiveEntries = box.get('painHistory', defaultValue: <HivePainRecordEntry>[]);
      
      Map<String, dynamic> dailyAssessmentData = {};
      
      if (hiveUserAssess is HiveUserAssess) {
        dailyAssessmentData = {
          'currentPainScale': hiveUserAssess.painScale,
          'currentPainLevel': hiveUserAssess.painLevel,
          'targetMuscle': hiveUserAssess.specificMuscle,
        };
        
        // Update global variables
        UserAssess.painScale = hiveUserAssess.painScale;
        UserAssess.painLevel = hiveUserAssess.painLevel;
        UserAssess.specificMuscle = hiveUserAssess.specificMuscle;
      }
      
      if (hiveEntries is List<HivePainRecordEntry>) {
        PainHistory.entries.clear();
        PainHistory.entries.addAll(hiveEntries.map((he) => he.toPainRecordEntry()));
        dailyAssessmentData['painHistory'] = PainHistory.entries;
      }
      
      _cacheData(cacheKey, dailyAssessmentData);
      completer.complete(dailyAssessmentData);
      debugPrint('PageSpecificDataService: Daily assessment data loaded successfully');
      return dailyAssessmentData;
      
    } catch (e) {
      debugPrint('PageSpecificDataService: Error loading daily assessment data: $e');
      completer.completeError(e);
      rethrow;
    } finally {
      _pendingRequests.remove(cacheKey);
    }
  }

  /// Save assessment data with auto-sync to Firebase
  Future<void> saveAssessmentData(Map<String, dynamic> assessmentData) async {
    try {
      debugPrint('PageSpecificDataService: Saving assessment data...');
      
      // Update global variables
      if (assessmentData.containsKey('rehabGoal')) {
        UserAssess.rehabGoal = assessmentData['rehabGoal'];
      }
      if (assessmentData.containsKey('generalMuscle')) {
        UserAssess.generalMuscle = assessmentData['generalMuscle'];
      }
      if (assessmentData.containsKey('specificMuscle')) {
        UserAssess.specificMuscle = assessmentData['specificMuscle'];
      }
      if (assessmentData.containsKey('painScale')) {
        UserAssess.painScale = assessmentData['painScale'];
      }
      if (assessmentData.containsKey('painLevel')) {
        UserAssess.painLevel = assessmentData['painLevel'];
      }
      if (assessmentData.containsKey('painType')) {
        UserAssess.painType = assessmentData['painType'];
      }
      if (assessmentData.containsKey('painDuration')) {
        UserAssess.painDuration = assessmentData['painDuration'];
      }
      if (assessmentData.containsKey('isInjured')) {
        UserAssess.isInjured = assessmentData['isInjured'];
      }
      if (assessmentData.containsKey('isAssessed')) {
        UserAssess.isAssessed = assessmentData['isAssessed'];
      }
      
      // Save to Hive first
      await UserAssess.saveToHive();
      
      // Clear cache to force reload
      clearCache('assessment_data');
      
      // Auto-save to Firebase in background if authenticated
      if (UserDetails.isAuthenticated && !UserDetails.isGuest) {
        _autoSaveToFirebase();
      }
      
      debugPrint('PageSpecificDataService: Assessment data saved successfully');
      
    } catch (e) {
      debugPrint('PageSpecificDataService: Error saving assessment data: $e');
      rethrow;
    }
  }

  /// Save profile data with auto-sync to Firebase
  Future<void> saveProfileData(Map<String, dynamic> profileData) async {
    try {
      debugPrint('PageSpecificDataService: Saving profile data...');
      
      // Update global variables
      if (profileData.containsKey('firstName')) {
        UserDetails.firstName = profileData['firstName'];
      }
      if (profileData.containsKey('lastName')) {
        UserDetails.lastName = profileData['lastName'];
      }
      if (profileData.containsKey('email')) {
        UserDetails.email = profileData['email'];
      }
      if (profileData.containsKey('profilePicture')) {
        UserDetails.profilePicture = profileData['profilePicture'];
      }
      
      // Save to Hive first
      await UserDetails.saveToHive();
      
      // Clear cache to force reload
      clearCache('profile_data');
      
      // Auto-save to Firebase in background if authenticated
      if (UserDetails.isAuthenticated && !UserDetails.isGuest) {
        _autoSaveToFirebase();
      }
      
      debugPrint('PageSpecificDataService: Profile data saved successfully');
      
    } catch (e) {
      debugPrint('PageSpecificDataService: Error saving profile data: $e');
      rethrow;
    }
  }

  /// Auto-save to Firebase in background
  Future<void> _autoSaveToFirebase() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      // Save to Firebase without blocking UI
      unawaited(UserDetails.updateInFirebase());
      
    } catch (e) {
      debugPrint('PageSpecificDataService: Auto-save to Firebase failed: $e');
      // Don't rethrow - this is background operation
    }
  }

  /// Helper methods for loading specific data subsets
  
  Future<Map<String, dynamic>> _loadUserDetailsForDashboard() async {
    final box = Hive.box('rehabBox');
    final hiveUserDetails = box.get('userDetails');
    
    if (hiveUserDetails is HiveUserDetails) {
      return {
        'firstName': hiveUserDetails.firstName,
        'lastName': hiveUserDetails.lastName,
        'profilePicture': hiveUserDetails.profilePicture,
        'isGuest': hiveUserDetails.isGuest,
      };
    }
    return {};
  }

  Future<Map<String, dynamic>> _loadUserProgressForDashboard() async {
    final box = Hive.box('rehabBox');
    final hiveUserProgress = box.get('userProgress');
    
    if (hiveUserProgress is HiveUserProgress) {
      return {
        'title': hiveUserProgress.title,
        'streak': hiveUserProgress.streak,
        'totalDays': hiveUserProgress.totalDays,
        'totalExercises': hiveUserProgress.totalExercises,
        'totalSeconds': hiveUserProgress.totalSeconds,
      };
    }
    return {};
  }

  Future<List<dynamic>> _loadRehabilitationPlansForDashboard() async {
    await UserRehabilitation.instance.loadPlansFromHive();
    return UserRehabilitation.instance.rehabPlans;
  }

  Future<List<String>> _loadNotificationsForDashboard() async {
    final box = Hive.box('rehabBox');
    final hiveUserDetails = box.get('userDetails');
    
    if (hiveUserDetails is HiveUserDetails) {
      return List<String>.from(hiveUserDetails.notifications);
    }
    return [];
  }

  Future<List<PainRecordEntry>> _loadPainHistoryForReports() async {
    final box = Hive.box('rehabBox');
    final hiveEntries = box.get('painHistory', defaultValue: <HivePainRecordEntry>[]);
    
    if (hiveEntries is List<HivePainRecordEntry>) {
      return hiveEntries.map((he) => he.toPainRecordEntry()).toList();
    }
    return [];
  }

  Future<List<ExerciseRecordEntry>> _loadExerciseHistoryForReports() async {
    final box = Hive.box('rehabBox');
    final hiveEntries = box.get('exerciseHistory', defaultValue: <HiveExerciseRecordEntry>[]);
    
    if (hiveEntries is List<HiveExerciseRecordEntry>) {
      return hiveEntries.map((he) => he.toExerciseRecordEntry()).toList();
    }
    return [];
  }

  Future<List<dynamic>> _loadRehabilitationPlansForReports() async {
    await UserRehabilitation.instance.loadPlansFromHive();
    return UserRehabilitation.instance.rehabPlans;
  }

  Future<Map<String, dynamic>> _loadUserProgressForReports() async {
    final box = Hive.box('rehabBox');
    final hiveUserProgress = box.get('userProgress');
    
    if (hiveUserProgress is HiveUserProgress) {
      return {
        'title': hiveUserProgress.title,
        'streak': hiveUserProgress.streak,
        'totalDays': hiveUserProgress.totalDays,
        'totalExercises': hiveUserProgress.totalExercises,
        'totalSeconds': hiveUserProgress.totalSeconds,
        'notes': hiveUserProgress.notes,
        'lastExerciseDate': hiveUserProgress.lastExerciseDate,
      };
    }
    return {};
  }

  /// Cache management methods
  
  void _cacheData(String key, dynamic data) {
    _pageDataCache[key] = data;
    _cacheTimestamps[key] = DateTime.now();
    
    // Clean up old cache entries if needed
    if (_pageDataCache.length > _maxCacheSize) {
      _cleanupOldCache();
    }
  }

  bool _isCacheValid(String key) {
    if (!_cacheTimestamps.containsKey(key)) return false;
    
    final timestamp = _cacheTimestamps[key]!;
    return DateTime.now().difference(timestamp) < _cacheExpiry;
  }

  void _cleanupOldCache() {
    final now = DateTime.now();
    final keysToRemove = <String>[];
    
    for (final entry in _cacheTimestamps.entries) {
      if (now.difference(entry.value) > _cacheExpiry) {
        keysToRemove.add(entry.key);
      }
    }
    
    for (final key in keysToRemove) {
      _pageDataCache.remove(key);
      _cacheTimestamps.remove(key);
    }
  }

  void clearCache(String key) {
    _pageDataCache.remove(key);
    _cacheTimestamps.remove(key);
  }

  void clearAllCache() {
    _pageDataCache.clear();
    _cacheTimestamps.clear();
  }

  /// Get cached data without fetching
  T? getCachedData<T>(String key) {
    if (_pageDataCache.containsKey(key) && _isCacheValid(key)) {
      return _pageDataCache[key] as T?;
    }
    return null;
  }

  /// Preload data for better performance
  Future<void> preloadData(String pageType) async {
    switch (pageType) {
      case 'assessment':
        if (!_pageDataCache.containsKey('assessment_data') || !_isCacheValid('assessment_data')) {
          unawaited(loadAssessmentData());
        }
        break;
      case 'dashboard':
        if (!_pageDataCache.containsKey('dashboard_data') || !_isCacheValid('dashboard_data')) {
          unawaited(loadDashboardData());
        }
        break;
      case 'profile':
        if (!_pageDataCache.containsKey('profile_data') || !_isCacheValid('profile_data')) {
          unawaited(loadProfileData());
        }
        break;
      case 'exercise':
        if (!_pageDataCache.containsKey('exercise_data') || !_isCacheValid('exercise_data')) {
          unawaited(loadExerciseData());
        }
        break;
      case 'reports':
        if (!_pageDataCache.containsKey('reports_data') || !_isCacheValid('reports_data')) {
          unawaited(loadReportsData());
        }
        break;
      case 'daily_assessment':
        if (!_pageDataCache.containsKey('daily_assessment_data') || !_isCacheValid('daily_assessment_data')) {
          unawaited(loadDailyAssessmentData());
        }
        break;
    }
  }
}

/// Helper function to run async operations without awaiting
void unawaited(Future<void> future) {
  future.catchError((error) {
    debugPrint('Unawaited future error: $error');
  });
}
