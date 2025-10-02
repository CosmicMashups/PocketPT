import 'package:flutter/material.dart';
import 'dart:async';

/// Optimized data service for smooth data handling across all pages
class OptimizedDataService {
  static final OptimizedDataService _instance = OptimizedDataService._internal();
  factory OptimizedDataService() => _instance;
  OptimizedDataService._internal();

  // Data caches
  final Map<String, dynamic> _dataCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  final Map<String, Completer<dynamic>> _pendingRequests = {};
  
  // Cache configuration
  static const Duration _cacheExpiry = Duration(minutes: 5);
  static const int _maxCacheSize = 100;

  /// Get data with caching and error handling
  Future<T?> getData<T>(String key, Future<T> Function() dataFetcher) async {
    try {
      // Check if request is already pending
      if (_pendingRequests.containsKey(key)) {
        return await _pendingRequests[key]!.future as T?;
      }

      // Check cache first
      if (_dataCache.containsKey(key) && _isCacheValid(key)) {
        return _dataCache[key] as T?;
      }

      // Create pending request
      final completer = Completer<T?>();
      _pendingRequests[key] = completer;

      try {
        // Fetch fresh data
        final data = await dataFetcher();
        
        // Cache the data
        _cacheData(key, data);
        
        // Complete the request
        completer.complete(data);
        return data;
      } catch (e) {
        // Return cached data if available, even if expired
        if (_dataCache.containsKey(key)) {
          final cachedData = _dataCache[key] as T?;
          completer.complete(cachedData);
          return cachedData;
        }
        
        // Complete with null if no cached data
        completer.complete(null);
        return null;
      } finally {
        _pendingRequests.remove(key);
      }
    } catch (e) {
      debugPrint('Error in getData for key $key: $e');
      return null;
    }
  }

  /// Cache data with timestamp
  void _cacheData(String key, dynamic data) {
    _dataCache[key] = data;
    _cacheTimestamps[key] = DateTime.now();
    
    // Clean up old cache entries if needed
    if (_dataCache.length > _maxCacheSize) {
      _cleanupOldCache();
    }
  }

  /// Check if cache is still valid
  bool _isCacheValid(String key) {
    if (!_cacheTimestamps.containsKey(key)) return false;
    
    final timestamp = _cacheTimestamps[key]!;
    return DateTime.now().difference(timestamp) < _cacheExpiry;
  }

  /// Clean up old cache entries
  void _cleanupOldCache() {
    final now = DateTime.now();
    final keysToRemove = <String>[];
    
    for (final entry in _cacheTimestamps.entries) {
      if (now.difference(entry.value) > _cacheExpiry) {
        keysToRemove.add(entry.key);
      }
    }
    
    for (final key in keysToRemove) {
      _dataCache.remove(key);
      _cacheTimestamps.remove(key);
    }
  }

  /// Clear specific cache entry
  void clearCache(String key) {
    _dataCache.remove(key);
    _cacheTimestamps.remove(key);
  }

  /// Clear all cache
  void clearAllCache() {
    _dataCache.clear();
    _cacheTimestamps.clear();
  }

  /// Get cached data without fetching
  T? getCachedData<T>(String key) {
    if (_dataCache.containsKey(key) && _isCacheValid(key)) {
      return _dataCache[key] as T?;
    }
    return null;
  }

  /// Preload data for better performance
  Future<void> preloadData(String key, Future<dynamic> Function() dataFetcher) async {
    if (!_dataCache.containsKey(key) || !_isCacheValid(key)) {
      try {
        final data = await dataFetcher();
        _cacheData(key, data);
      } catch (e) {
        debugPrint('Error preloading data for key $key: $e');
      }
    }
  }
}

/// Data loading state enum
enum DataLoadingState {
  initial,
  loading,
  loaded,
  error,
  refreshing,
}

/// Data loading widget with optimized state management
class OptimizedDataLoader<T> extends StatefulWidget {
  final String dataKey;
  final Future<T> Function() dataFetcher;
  final Widget Function(BuildContext context, T data) builder;
  final Widget Function(BuildContext context)? loadingBuilder;
  final Widget Function(BuildContext context, String error)? errorBuilder;
  final bool enableCache;
  final Duration? cacheExpiry;

  const OptimizedDataLoader({
    super.key,
    required this.dataKey,
    required this.dataFetcher,
    required this.builder,
    this.loadingBuilder,
    this.errorBuilder,
    this.enableCache = true,
    this.cacheExpiry,
  });

  @override
  State<OptimizedDataLoader<T>> createState() => _OptimizedDataLoaderState<T>();
}

class _OptimizedDataLoaderState<T> extends State<OptimizedDataLoader<T>> {
  DataLoadingState _state = DataLoadingState.initial;
  T? _data;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _state = DataLoadingState.loading;
      _error = null;
    });

    try {
      T? data;
      
      if (widget.enableCache) {
        data = await OptimizedDataService().getData(
          widget.dataKey,
          widget.dataFetcher,
        );
      } else {
        data = await widget.dataFetcher();
      }

      if (!mounted) return;

      setState(() {
        _data = data;
        _state = DataLoadingState.loaded;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _state = DataLoadingState.error;
      });
    }
  }

  Future<void> refresh() async {
    if (widget.enableCache) {
      OptimizedDataService().clearCache(widget.dataKey);
    }
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    switch (_state) {
      case DataLoadingState.loading:
        return widget.loadingBuilder?.call(context) ?? 
               const Center(child: CircularProgressIndicator());
      
      case DataLoadingState.loaded:
        if (_data != null) {
          return widget.builder(context, _data!);
        } else {
          return widget.errorBuilder?.call(context, 'No data available') ??
                 const Center(child: Text('No data available'));
        }
      
      case DataLoadingState.error:
        return widget.errorBuilder?.call(context, _error ?? 'Unknown error') ??
               Center(
                 child: Column(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     const Icon(Icons.error, size: 48, color: Colors.red),
                     const SizedBox(height: 16),
                     Text(_error ?? 'Unknown error'),
                     const SizedBox(height: 16),
                     ElevatedButton(
                       onPressed: _loadData,
                       child: const Text('Retry'),
                     ),
                   ],
                 ),
               );
      
      default:
        return const SizedBox.shrink();
    }
  }
}

/// Optimized navigation with data preloading
class OptimizedNavigation {
  static Future<T?> navigateWithDataPreload<T extends Object?>(
    BuildContext context,
    Widget page, {
    String? dataKey,
    Future<dynamic> Function()? dataPreloader,
    bool replace = false,
    bool clearStack = false,
  }) async {
    // Preload data if specified
    if (dataKey != null && dataPreloader != null) {
      OptimizedDataService().preloadData(dataKey, dataPreloader);
    }

    // Navigate with optimized transition
    if (replace) {
      return Navigator.of(context).pushReplacement(
        PageRouteBuilder<T>(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;

            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        ),
      );
    } else if (clearStack) {
      return Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder<T>(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;

            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        ),
        (route) => false,
      );
    } else {
      return Navigator.of(context).push(
        PageRouteBuilder<T>(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;

            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        ),
      );
    }
  }
}

/// Optimized data persistence service using in-memory storage
class OptimizedDataPersistence {
  static final Map<String, dynamic> _memoryStorage = {};

  static Future<bool> saveData(String key, dynamic data) async {
    try {
      _memoryStorage[key] = data;
      return true;
    } catch (e) {
      debugPrint('Error saving data for key $key: $e');
      return false;
    }
  }

  static Future<T?> loadData<T>(String key) async {
    try {
      return _memoryStorage[key] as T?;
    } catch (e) {
      debugPrint('Error loading data for key $key: $e');
      return null;
    }
  }

  static Future<bool> removeData(String key) async {
    try {
      _memoryStorage.remove(key);
      return true;
    } catch (e) {
      debugPrint('Error removing data for key $key: $e');
      return false;
    }
  }

  static Future<bool> clearAllData() async {
    try {
      _memoryStorage.clear();
      return true;
    } catch (e) {
      debugPrint('Error clearing all data: $e');
      return false;
    }
  }
}
