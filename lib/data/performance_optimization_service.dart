import 'package:flutter/material.dart';
import 'dart:async';

/// Performance optimization service for widget lifecycle management
class PerformanceOptimizationService {
  static final PerformanceOptimizationService _instance = PerformanceOptimizationService._internal();
  factory PerformanceOptimizationService() => _instance;
  PerformanceOptimizationService._internal();

  // Widget lifecycle tracking
  final Map<String, WidgetLifecycleTracker> _lifecycleTrackers = {};
  final Map<String, Timer> _debounceTimers = {};

  /// Track widget lifecycle for optimization
  void trackWidgetLifecycle(String widgetId, WidgetLifecycleTracker tracker) {
    _lifecycleTrackers[widgetId] = tracker;
  }

  /// Remove widget lifecycle tracking
  void removeWidgetLifecycle(String widgetId) {
    _lifecycleTrackers.remove(widgetId);
    _debounceTimers[widgetId]?.cancel();
    _debounceTimers.remove(widgetId);
  }

  /// Debounce function calls to prevent excessive operations
  void debounce(String key, VoidCallback callback, {Duration delay = const Duration(milliseconds: 300)}) {
    _debounceTimers[key]?.cancel();
    _debounceTimers[key] = Timer(delay, callback);
  }

  /// Optimize list building with lazy loading
  Widget buildOptimizedList<T>({
    required List<T> items,
    required Widget Function(BuildContext context, T item, int index) itemBuilder,
    required String listKey,
    int initialItemCount = 10,
    int loadMoreThreshold = 5,
  }) {
    return _OptimizedListView<T>(
      items: items,
      itemBuilder: itemBuilder,
      listKey: listKey,
      initialItemCount: initialItemCount,
      loadMoreThreshold: loadMoreThreshold,
    );
  }

  /// Optimize image loading with caching
  Widget buildOptimizedImage({
    required String imagePath,
    required String imageKey,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    return _OptimizedImage(
      imagePath: imagePath,
      imageKey: imageKey,
      width: width,
      height: height,
      fit: fit,
      placeholder: placeholder,
      errorWidget: errorWidget,
    );
  }

  /// Clear all tracking data
  void clearAll() {
    _lifecycleTrackers.clear();
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();
  }
}

/// Widget lifecycle tracker
class WidgetLifecycleTracker {
  final String widgetId;
  final VoidCallback? onInit;
  final VoidCallback? onDispose;
  final VoidCallback? onPause;
  final VoidCallback? onResume;

  WidgetLifecycleTracker({
    required this.widgetId,
    this.onInit,
    this.onDispose,
    this.onPause,
    this.onResume,
  });

  void init() => onInit?.call();
  void dispose() => onDispose?.call();
  void pause() => onPause?.call();
  void resume() => onResume?.call();
}

/// Optimized list view with lazy loading
class _OptimizedListView<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final String listKey;
  final int initialItemCount;
  final int loadMoreThreshold;

  const _OptimizedListView({
    required this.items,
    required this.itemBuilder,
    required this.listKey,
    this.initialItemCount = 10,
    this.loadMoreThreshold = 5,
  });

  @override
  State<_OptimizedListView<T>> createState() => _OptimizedListViewState<T>();
}

class _OptimizedListViewState<T> extends State<_OptimizedListView<T>> {
  int _visibleItemCount = 0;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _visibleItemCount = widget.initialItemCount;
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreItems();
    }
  }

  void _loadMoreItems() {
    if (_visibleItemCount < widget.items.length) {
      setState(() {
        _visibleItemCount = (_visibleItemCount + widget.loadMoreThreshold)
            .clamp(0, widget.items.length);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: _visibleItemCount,
      itemBuilder: (context, index) {
        if (index < widget.items.length) {
          return widget.itemBuilder(context, widget.items[index], index);
        }
        return const SizedBox.shrink();
      },
    );
  }
}

/// Optimized image widget with caching
class _OptimizedImage extends StatefulWidget {
  final String imagePath;
  final String imageKey;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const _OptimizedImage({
    required this.imagePath,
    required this.imageKey,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  State<_OptimizedImage> createState() => _OptimizedImageState();
}

class _OptimizedImageState extends State<_OptimizedImage> {
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      // Pre-cache the image for better performance
      await precacheImage(AssetImage(widget.imagePath), context);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.placeholder ?? 
             Container(
               width: widget.width,
               height: widget.height,
               color: Colors.grey[300],
               child: const Center(child: CircularProgressIndicator()),
             );
    }

    if (_hasError) {
      return widget.errorWidget ?? 
             Container(
               width: widget.width,
               height: widget.height,
               color: Colors.grey[300],
               child: const Icon(Icons.error),
             );
    }

    return Image.asset(
      widget.imagePath,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      cacheWidth: widget.width?.toInt(),
      cacheHeight: widget.height?.toInt(),
      errorBuilder: (context, error, stackTrace) {
        return widget.errorWidget ?? 
               Container(
                 width: widget.width,
                 height: widget.height,
                 color: Colors.grey[300],
                 child: const Icon(Icons.error),
               );
      },
    );
  }
}

/// Optimized page wrapper for better performance
class OptimizedPageWrapper extends StatefulWidget {
  final Widget child;
  final String pageKey;
  final bool enableLifecycleTracking;
  final VoidCallback? onPageInit;
  final VoidCallback? onPageDispose;

  const OptimizedPageWrapper({
    super.key,
    required this.child,
    required this.pageKey,
    this.enableLifecycleTracking = true,
    this.onPageInit,
    this.onPageDispose,
  });

  @override
  State<OptimizedPageWrapper> createState() => _OptimizedPageWrapperState();
}

class _OptimizedPageWrapperState extends State<OptimizedPageWrapper>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    if (widget.enableLifecycleTracking) {
      WidgetsBinding.instance.addObserver(this);
      PerformanceOptimizationService().trackWidgetLifecycle(
        widget.pageKey,
        WidgetLifecycleTracker(
          widgetId: widget.pageKey,
          onInit: widget.onPageInit,
          onDispose: widget.onPageDispose,
        ),
      );
      widget.onPageInit?.call();
    }
  }

  @override
  void dispose() {
    if (widget.enableLifecycleTracking) {
      WidgetsBinding.instance.removeObserver(this);
      PerformanceOptimizationService().removeWidgetLifecycle(widget.pageKey);
      widget.onPageDispose?.call();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (widget.enableLifecycleTracking) {
      final tracker = PerformanceOptimizationService()._lifecycleTrackers[widget.pageKey];
      switch (state) {
        case AppLifecycleState.paused:
          tracker?.pause();
          break;
        case AppLifecycleState.resumed:
          tracker?.resume();
          break;
        default:
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
