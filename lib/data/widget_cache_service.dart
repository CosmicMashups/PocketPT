import 'package:flutter/material.dart';

/// Service to cache expensive widgets and improve performance
class WidgetCacheService {
  static final WidgetCacheService _instance = WidgetCacheService._internal();
  static WidgetCacheService get instance => _instance;
  
  WidgetCacheService._internal();
  
  // Cache for expensive widgets
  final Map<String, Widget> _widgetCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  
  // Cache expiration time (5 minutes)
  static const Duration _cacheExpiration = Duration(minutes: 5);
  
  /// Get cached widget or create new one
  Widget getCachedWidget(String key, Widget Function() builder) {
    // Check if cache exists and is not expired
    if (_widgetCache.containsKey(key) && 
        _cacheTimestamps.containsKey(key) &&
        DateTime.now().difference(_cacheTimestamps[key]!) < _cacheExpiration) {
      return _widgetCache[key]!;
    }
    
    // Create new widget and cache it
    final widget = builder();
    _widgetCache[key] = widget;
    _cacheTimestamps[key] = DateTime.now();
    
    return widget;
  }
  
  /// Clear expired cache entries
  void clearExpiredCache() {
    final now = DateTime.now();
    final expiredKeys = <String>[];
    
    for (final entry in _cacheTimestamps.entries) {
      if (now.difference(entry.value) >= _cacheExpiration) {
        expiredKeys.add(entry.key);
      }
    }
    
    for (final key in expiredKeys) {
      _widgetCache.remove(key);
      _cacheTimestamps.remove(key);
    }
    
    if (expiredKeys.isNotEmpty) {
      print('WidgetCacheService: Cleared ${expiredKeys.length} expired cache entries');
    }
  }
  
  /// Clear all cache
  void clearAllCache() {
    _widgetCache.clear();
    _cacheTimestamps.clear();
    print('WidgetCacheService: All cache cleared');
  }
  
  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'cachedWidgets': _widgetCache.length,
      'cacheSize': _widgetCache.length,
    };
  }
}

/// Optimized FutureBuilder that caches results
class CachedFutureBuilder<T> extends StatelessWidget {
  final String cacheKey;
  final Future<T> future;
  final Widget Function(BuildContext context, T data) builder;
  final Widget Function(BuildContext context, Object error) errorBuilder;
  final Widget Function(BuildContext context) loadingBuilder;
  
  const CachedFutureBuilder({
    super.key,
    required this.cacheKey,
    required this.future,
    required this.builder,
    required this.errorBuilder,
    required this.loadingBuilder,
  });
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadingBuilder(context);
        } else if (snapshot.hasError) {
          return errorBuilder(context, snapshot.error!);
        } else if (snapshot.hasData) {
          return WidgetCacheService.instance.getCachedWidget(
            cacheKey,
            () => builder(context, snapshot.data!),
          );
        } else {
          return loadingBuilder(context);
        }
      },
    );
  }
}

/// Optimized ListView with item caching
class CachedListView extends StatelessWidget {
  final String cacheKey;
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;
  
  const CachedListView({
    super.key,
    required this.cacheKey,
    required this.itemCount,
    required this.itemBuilder,
    this.controller,
    this.padding,
  });
  
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      padding: padding,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return WidgetCacheService.instance.getCachedWidget(
          '$cacheKey-$index',
          () => itemBuilder(context, index),
        );
      },
    );
  }
}
