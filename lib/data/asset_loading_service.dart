import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Service to handle optimized asset loading and caching
class AssetLoadingService {
  static final AssetLoadingService _instance = AssetLoadingService._internal();
  static AssetLoadingService get instance => _instance;
  
  AssetLoadingService._internal();
  
  // Cache for loaded images
  final Map<String, ui.Image> _imageCache = {};
  final Map<String, String> _textCache = {};
  
  // Preload critical assets
  static const List<String> _criticalAssets = [
    'assets/images/logo/logo.png',
    'assets/images/exercise/exercise.jpg',
    'assets/images/welcome_1.jpg',
    'assets/images/welcome_2.jpg',
  ];
  
  /// Initialize asset preloading
  Future<void> initialize() async {
    try {
      debugPrint('AssetLoadingService: Starting asset preloading...');
      
      // Defer preloading until after first frame to avoid jank
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _preloadCriticalAssets();
      });
      
      debugPrint('AssetLoadingService: Asset preloading initialized');
    } catch (e) {
      debugPrint('AssetLoadingService: Error initializing asset preloading: $e');
    }
  }
  
  /// Preload critical assets
  Future<void> _preloadCriticalAssets() async {
    final context = AssetNavigationService.navigatorKey.currentContext;
    if (context == null) {
      debugPrint('AssetLoadingService: Skipping precache, no context yet');
      return;
    }
    for (final assetPath in _criticalAssets) {
      try {
        await precacheImage(AssetImage(assetPath), context);
        debugPrint('AssetLoadingService: Preloaded $assetPath');
      } catch (e) {
        debugPrint('AssetLoadingService: Failed to preload $assetPath: $e');
      }
    }
  }
  
  /// Load and cache image
  Future<ui.Image?> loadImage(String assetPath) async {
    if (_imageCache.containsKey(assetPath)) {
      return _imageCache[assetPath];
    }
    
    try {
      final ByteData data = await rootBundle.load(assetPath);
      final ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image image = frameInfo.image;
      
      _imageCache[assetPath] = image;
      return image;
    } catch (e) {
      debugPrint('AssetLoadingService: Error loading image $assetPath: $e');
      return null;
    }
  }
  
  /// Load and cache text asset
  Future<String?> loadText(String assetPath) async {
    if (_textCache.containsKey(assetPath)) {
      return _textCache[assetPath];
    }
    
    try {
      final String content = await rootBundle.loadString(assetPath);
      _textCache[assetPath] = content;
      return content;
    } catch (e) {
      debugPrint('AssetLoadingService: Error loading text $assetPath: $e');
      return null;
    }
  }
  
  /// Clear cache
  void clearCache() {
    _imageCache.clear();
    _textCache.clear();
    debugPrint('AssetLoadingService: Cache cleared');
  }
  
  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'cachedImages': _imageCache.length,
      'cachedTexts': _textCache.length,
      'totalMemoryUsage': _imageCache.length + _textCache.length,
    };
  }
}

/// Navigation service for accessing context
class AssetNavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
}
