import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/rehabilitation_plan.dart';

/// Service for caching exercise data to avoid redundant API calls
/// Implements singleton pattern for global access and memory efficiency
class ExerciseCacheService {
  ExerciseCacheService._privateConstructor();
  static final ExerciseCacheService _instance = ExerciseCacheService._privateConstructor();
  static ExerciseCacheService get instance => _instance;

  // Cache storage
  final Map<String, Exercise> _exerciseCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  final Duration _cacheExpiry = const Duration(minutes: 30);
  
  // Loading state tracking to prevent duplicate requests
  final Set<String> _loadingExercises = {};
  
  // Getters
  Map<String, Exercise> get cache => Map.unmodifiable(_exerciseCache);
  int get cacheSize => _exerciseCache.length;

  /// Get exercise by ID with caching
  Future<Exercise?> getExerciseById(String exerciseId) async {
    // Check cache first
    if (_exerciseCache.containsKey(exerciseId)) {
      final timestamp = _cacheTimestamps[exerciseId];
      if (timestamp != null && DateTime.now().difference(timestamp) < _cacheExpiry) {
        debugPrint('ExerciseCacheService: Cache hit for exercise $exerciseId');
        return _exerciseCache[exerciseId];
      } else {
        // Cache expired, remove it
        _exerciseCache.remove(exerciseId);
        _cacheTimestamps.remove(exerciseId);
      }
    }

    // Check if already loading
    if (_loadingExercises.contains(exerciseId)) {
      debugPrint('ExerciseCacheService: Exercise $exerciseId already loading, waiting...');
      // Wait for loading to complete
      while (_loadingExercises.contains(exerciseId)) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      // Return from cache after loading completes
      return _exerciseCache[exerciseId];
    }

    // Load from service and cache
    _loadingExercises.add(exerciseId);
    try {
      debugPrint('ExerciseCacheService: Loading exercise $exerciseId from service');
      final exercise = await ExerciseDataService.getExerciseById(exerciseId);
      
      if (exercise != null) {
        _exerciseCache[exerciseId] = exercise;
        _cacheTimestamps[exerciseId] = DateTime.now();
        debugPrint('ExerciseCacheService: Cached exercise $exerciseId');
      }
      
      return exercise;
    } catch (e) {
      debugPrint('ExerciseCacheService: Error loading exercise $exerciseId: $e');
      return null;
    } finally {
      _loadingExercises.remove(exerciseId);
    }
  }

  /// Get multiple exercises by IDs with batch loading
  Future<List<Exercise>> getExercisesByIds(List<String> exerciseIds) async {
    final List<Exercise> results = [];
    final List<String> missingIds = [];
    
    // Check cache first
    for (final id in exerciseIds) {
      if (_exerciseCache.containsKey(id)) {
        final timestamp = _cacheTimestamps[id];
        if (timestamp != null && DateTime.now().difference(timestamp) < _cacheExpiry) {
          results.add(_exerciseCache[id]!);
        } else {
          // Cache expired
          _exerciseCache.remove(id);
          _cacheTimestamps.remove(id);
          missingIds.add(id);
        }
      } else {
        missingIds.add(id);
      }
    }

    // Load missing exercises
    if (missingIds.isNotEmpty) {
      debugPrint('ExerciseCacheService: Loading ${missingIds.length} missing exercises');
      final missingExercises = await ExerciseDataService.getExercisesByIds(missingIds);
      
      for (final exercise in missingExercises) {
        _exerciseCache[exercise.exerciseId] = exercise;
        _cacheTimestamps[exercise.exerciseId] = DateTime.now();
      }
      
      results.addAll(missingExercises);
    }

    return results;
  }

  /// Preload exercises for better performance
  Future<void> preloadExercises(List<String> exerciseIds) async {
    debugPrint('ExerciseCacheService: Preloading ${exerciseIds.length} exercises');
    await getExercisesByIds(exerciseIds);
  }

  /// Clear expired cache entries
  void clearExpiredCache() {
    final now = DateTime.now();
    final expiredKeys = <String>[];
    
    for (final entry in _cacheTimestamps.entries) {
      if (now.difference(entry.value) >= _cacheExpiry) {
        expiredKeys.add(entry.key);
      }
    }
    
    for (final key in expiredKeys) {
      _exerciseCache.remove(key);
      _cacheTimestamps.remove(key);
    }
    
    if (expiredKeys.isNotEmpty) {
      debugPrint('ExerciseCacheService: Cleared ${expiredKeys.length} expired cache entries');
    }
  }

  /// Clear all cache
  void clearCache() {
    _exerciseCache.clear();
    _cacheTimestamps.clear();
    _loadingExercises.clear();
    debugPrint('ExerciseCacheService: Cleared all cache');
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'cacheSize': _exerciseCache.length,
      'loadingCount': _loadingExercises.length,
      'loadingExercises': List.from(_loadingExercises),
      'cacheKeys': List.from(_exerciseCache.keys),
    };
  }

  /// Check if exercise is in cache and not expired
  bool isCached(String exerciseId) {
    if (!_exerciseCache.containsKey(exerciseId)) return false;
    
    final timestamp = _cacheTimestamps[exerciseId];
    return timestamp != null && DateTime.now().difference(timestamp) < _cacheExpiry;
  }

  /// Remove specific exercise from cache
  void removeFromCache(String exerciseId) {
    _exerciseCache.remove(exerciseId);
    _cacheTimestamps.remove(exerciseId);
    debugPrint('ExerciseCacheService: Removed exercise $exerciseId from cache');
  }
}
