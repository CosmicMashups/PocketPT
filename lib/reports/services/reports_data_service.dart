import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/globals.dart';
import '../../data/rehabilitation_plan.dart';
import 'reports_repository.dart';

/// Service for managing reports data with proper error handling and caching
class ReportsDataService {
  static final ReportsDataService _instance = ReportsDataService._internal();
  static ReportsDataService get instance => _instance;
  ReportsDataService._internal();

  final ReportsRepository _repository = ReportsRepository.instance;
  
  // Cache for reports data
  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  
  // Cache duration (5 minutes)
  static const Duration _cacheDuration = Duration(minutes: 5);
  
  // Loading states
  bool _isLoadingRehabPlans = false;
  bool _isLoadingExerciseHistory = false;
  bool _isLoadingPainHistory = false;
  bool _isLoadingAssessmentData = false;
  
  // Error states
  String? _rehabPlansError;
  String? _exerciseHistoryError;
  String? _painHistoryError;
  String? _assessmentDataError;

  // Getters for loading states
  bool get isLoadingRehabPlans => _isLoadingRehabPlans;
  bool get isLoadingExerciseHistory => _isLoadingExerciseHistory;
  bool get isLoadingPainHistory => _isLoadingPainHistory;
  bool get isLoadingAssessmentData => _isLoadingAssessmentData;
  bool get isLoading => _isLoadingRehabPlans || _isLoadingExerciseHistory || _isLoadingPainHistory || _isLoadingAssessmentData;

  // Getters for error states
  String? get rehabPlansError => _rehabPlansError;
  String? get exerciseHistoryError => _exerciseHistoryError;
  String? get painHistoryError => _painHistoryError;
  String? get assessmentDataError => _assessmentDataError;

  /// Load rehabilitation plans with error handling and caching
  Future<List<RehabilitationPlan>> loadRehabPlans({bool forceRefresh = false}) async {
    const cacheKey = 'rehab_plans';
    
    // Check cache first
    if (!forceRefresh && _isCacheValid(cacheKey)) {
      return _cache[cacheKey] as List<RehabilitationPlan>;
    }

    _isLoadingRehabPlans = true;
    _rehabPlansError = null;

    try {
      final plans = await _repository.getRehabilitationPlans();
      
      // Update cache
      _cache[cacheKey] = plans;
      _cacheTimestamps[cacheKey] = DateTime.now();
      
      _isLoadingRehabPlans = false;
      return plans;
      
    } catch (e) {
      _rehabPlansError = 'Failed to load rehabilitation plans: ${e.toString()}';
      _isLoadingRehabPlans = false;
      
      // Return cached data if available
      if (_cache.containsKey(cacheKey)) {
        return _cache[cacheKey] as List<RehabilitationPlan>;
      }
      
      rethrow;
    }
  }

  /// Load exercise history with error handling and caching
  Future<List<ExerciseRecordEntry>> loadExerciseHistory({bool forceRefresh = false}) async {
    const cacheKey = 'exercise_history';
    
    // Check cache first (but skip if forceRefresh is true)
    if (!forceRefresh && _isCacheValid(cacheKey)) {
      return _cache[cacheKey] as List<ExerciseRecordEntry>;
    }

    _isLoadingExerciseHistory = true;
    _exerciseHistoryError = null;

    try {
      // Pass forceRefresh to repository to ensure Firebase is loaded
      final history = await _repository.getExerciseHistory(forceRefresh: forceRefresh);
      
      // Update cache
      _cache[cacheKey] = history;
      _cacheTimestamps[cacheKey] = DateTime.now();
      
      _isLoadingExerciseHistory = false;
      return history;
      
    } catch (e) {
      _exerciseHistoryError = 'Failed to load exercise history: ${e.toString()}';
      _isLoadingExerciseHistory = false;
      
      // Return cached data if available
      if (_cache.containsKey(cacheKey)) {
        return _cache[cacheKey] as List<ExerciseRecordEntry>;
      }
      
      rethrow;
    }
  }

  /// Load pain history with error handling and caching
  Future<List<PainRecordEntry>> loadPainHistory({bool forceRefresh = false}) async {
    const cacheKey = 'pain_history';
    
    // Check cache first (but skip if forceRefresh is true)
    if (!forceRefresh && _isCacheValid(cacheKey)) {
      return _cache[cacheKey] as List<PainRecordEntry>;
    }

    _isLoadingPainHistory = true;
    _painHistoryError = null;

    try {
      // Pass forceRefresh to repository to ensure Firebase is loaded
      final history = await _repository.getPainHistory(forceRefresh: forceRefresh);
      
      // Update cache
      _cache[cacheKey] = history;
      _cacheTimestamps[cacheKey] = DateTime.now();
      
      _isLoadingPainHistory = false;
      return history;
      
    } catch (e) {
      _painHistoryError = 'Failed to load pain history: ${e.toString()}';
      _isLoadingPainHistory = false;
      
      // Return cached data if available
      if (_cache.containsKey(cacheKey)) {
        return _cache[cacheKey] as List<PainRecordEntry>;
      }
      
      rethrow;
    }
  }

  /// Load assessment data from Firebase with error handling and caching
  Future<Map<String, dynamic>?> loadAssessmentData({bool forceRefresh = false}) async {
    const cacheKey = 'assessment_data';
    
    // Check cache first (but skip if forceRefresh is true)
    if (!forceRefresh && _isCacheValid(cacheKey)) {
      return _cache[cacheKey] as Map<String, dynamic>?;
    }

    _isLoadingAssessmentData = true;
    _assessmentDataError = null;

    try {
      final assessmentData = await _repository.getAssessmentDataFromFirebase(forceRefresh: forceRefresh);
      
      // Update cache
      _cache[cacheKey] = assessmentData;
      _cacheTimestamps[cacheKey] = DateTime.now();
      
      _isLoadingAssessmentData = false;
      return assessmentData;
      
    } catch (e) {
      _assessmentDataError = 'Failed to load assessment data: ${e.toString()}';
      _isLoadingAssessmentData = false;
      
      // Return cached data if available
      if (_cache.containsKey(cacheKey)) {
        return _cache[cacheKey] as Map<String, dynamic>?;
      }
      
      rethrow;
    }
  }

  /// Load all reports data
  Future<ReportsData> loadAllReportsData({bool forceRefresh = false}) async {
    try {
      final results = await Future.wait([
        loadRehabPlans(forceRefresh: forceRefresh),
        loadExerciseHistory(forceRefresh: forceRefresh),
        loadPainHistory(forceRefresh: forceRefresh),
      ]);

      return ReportsData(
        rehabPlans: results[0] as List<RehabilitationPlan>,
        exerciseHistory: results[1] as List<ExerciseRecordEntry>,
        painHistory: results[2] as List<PainRecordEntry>,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      debugPrint('ReportsDataService: Error loading all reports data: $e');
      rethrow;
    }
  }

  /// Clear cache
  void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }

  /// Clear specific cache entry
  void clearCacheEntry(String key) {
    _cache.remove(key);
    _cacheTimestamps.remove(key);
  }

  /// Check if cache is valid
  bool _isCacheValid(String key) {
    if (!_cache.containsKey(key) || !_cacheTimestamps.containsKey(key)) {
      return false;
    }
    
    final timestamp = _cacheTimestamps[key]!;
    return DateTime.now().difference(timestamp) < _cacheDuration;
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStatistics() {
    return {
      'cacheSize': _cache.length,
      'cacheKeys': _cache.keys.toList(),
      'cacheTimestamps': _cacheTimestamps.map((key, value) => MapEntry(key, value.toIso8601String())),
      'isLoading': isLoading,
      'errors': {
        'rehabPlans': _rehabPlansError,
        'exerciseHistory': _exerciseHistoryError,
        'painHistory': _painHistoryError,
      },
    };
  }
}

/// Data model for reports data
class ReportsData {
  final List<RehabilitationPlan> rehabPlans;
  final List<ExerciseRecordEntry> exerciseHistory;
  final List<PainRecordEntry> painHistory;
  final DateTime lastUpdated;

  ReportsData({
    required this.rehabPlans,
    required this.exerciseHistory,
    required this.painHistory,
    required this.lastUpdated,
  });

  /// Get total number of completed exercises
  int get totalCompletedExercises => exerciseHistory
      .where((entry) => entry.status.toLowerCase() == 'completed')
      .length;

  /// Get average pain level
  double get averagePainLevel => painHistory.isNotEmpty
      ? painHistory.map((entry) => entry.painScale).reduce((a, b) => a + b) / painHistory.length
      : 0.0;

  /// Get exercise completion rate
  double get exerciseCompletionRate => exerciseHistory.isNotEmpty
      ? totalCompletedExercises / exerciseHistory.length
      : 0.0;

  /// Get pain trend (positive = increasing, negative = decreasing)
  double get painTrend {
    if (painHistory.length < 2) return 0.0;
    
    final recent = painHistory.take(7).map((e) => e.painScale).toList();
    final older = painHistory.skip(painHistory.length - 7).take(7).map((e) => e.painScale).toList();
    
    if (recent.isEmpty || older.isEmpty) return 0.0;
    
    final recentAvg = recent.reduce((a, b) => a + b) / recent.length;
    final olderAvg = older.reduce((a, b) => a + b) / older.length;
    
    return recentAvg - olderAvg;
  }
}

/// Provider for ReportsDataService
final reportsDataServiceProvider = Provider<ReportsDataService>((ref) {
  return ReportsDataService.instance;
});

/// Provider for reports data
final reportsDataProvider = FutureProvider<ReportsData>((ref) async {
  final service = ref.read(reportsDataServiceProvider);
  return await service.loadAllReportsData();
});

/// Provider for rehabilitation plans
final rehabPlansProvider = FutureProvider<List<RehabilitationPlan>>((ref) async {
  final service = ref.read(reportsDataServiceProvider);
  return await service.loadRehabPlans();
});

/// Provider for exercise history
final exerciseHistoryProvider = FutureProvider<List<ExerciseRecordEntry>>((ref) async {
  final service = ref.read(reportsDataServiceProvider);
  return await service.loadExerciseHistory();
});

/// Provider for pain history
final painHistoryProvider = FutureProvider<List<PainRecordEntry>>((ref) async {
  final service = ref.read(reportsDataServiceProvider);
  return await service.loadPainHistory();
});

/// Provider for assessment data
final assessmentDataProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final service = ref.read(reportsDataServiceProvider);
  return await service.loadAssessmentData();
});
