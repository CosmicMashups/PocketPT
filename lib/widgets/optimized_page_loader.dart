import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../data/page_specific_data_service.dart';

/// Widget that provides optimized data loading for specific page types
class OptimizedPageLoader extends StatefulWidget {
  final String pageType;
  final Widget Function(BuildContext context, Map<String, dynamic> data) builder;
  final Widget Function(BuildContext context)? loadingBuilder;
  final Widget Function(BuildContext context, String error)? errorBuilder;
  final bool enableCache;

  const OptimizedPageLoader({
    super.key,
    required this.pageType,
    required this.builder,
    this.loadingBuilder,
    this.errorBuilder,
    this.enableCache = true,
  });

  @override
  State<OptimizedPageLoader> createState() => _OptimizedPageLoaderState();
}

class _OptimizedPageLoaderState extends State<OptimizedPageLoader> {
  Map<String, dynamic>? _data;
  String? _error;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      Map<String, dynamic> data;
      
      switch (widget.pageType) {
        case 'assessment':
          data = await PageSpecificDataService.instance.loadAssessmentData();
          break;
        case 'dashboard':
          data = await PageSpecificDataService.instance.loadDashboardData();
          break;
        case 'profile':
          data = await PageSpecificDataService.instance.loadProfileData();
          break;
        case 'exercise':
          data = await PageSpecificDataService.instance.loadExerciseData();
          break;
        case 'reports':
          data = await PageSpecificDataService.instance.loadReportsData();
          break;
        case 'daily_assessment':
          data = await PageSpecificDataService.instance.loadDailyAssessmentData();
          break;
        default:
          throw Exception('Unknown page type: ${widget.pageType}');
      }

      if (!mounted) return;

      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> refresh() async {
    // Clear cache for this page type
    switch (widget.pageType) {
      case 'assessment':
        PageSpecificDataService.instance.clearCache('assessment_data');
        break;
      case 'dashboard':
        PageSpecificDataService.instance.clearCache('dashboard_data');
        break;
      case 'profile':
        PageSpecificDataService.instance.clearCache('profile_data');
        break;
      case 'exercise':
        PageSpecificDataService.instance.clearCache('exercise_data');
        break;
      case 'reports':
        PageSpecificDataService.instance.clearCache('reports_data');
        break;
      case 'daily_assessment':
        PageSpecificDataService.instance.clearCache('daily_assessment_data');
        break;
    }
    
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.loadingBuilder?.call(context) ?? 
             const Center(
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   CircularProgressIndicator(),
                   SizedBox(height: 16),
                   Text('Loading data...'),
                 ],
               ),
             );
    }

    if (_error != null) {
      return widget.errorBuilder?.call(context, _error!) ??
             Center(
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   const Icon(Icons.error, size: 48, color: Colors.red),
                   const SizedBox(height: 16),
                   Text('Error: $_error'),
                   const SizedBox(height: 16),
                   ElevatedButton(
                     onPressed: _loadData,
                     child: const Text('Retry'),
                   ),
                 ],
               ),
             );
    }

    if (_data != null) {
      return widget.builder(context, _data!);
    }

    return const Center(child: Text('No data available'));
  }
}

/// Optimized data saving widget for pages that need to save data
class OptimizedDataSaver extends StatelessWidget {
  final String pageType;
  final Map<String, dynamic> data;
  final Widget child;
  final VoidCallback? onSaveComplete;
  final VoidCallback? onSaveError;

  const OptimizedDataSaver({
    super.key,
    required this.pageType,
    required this.data,
    required this.child,
    this.onSaveComplete,
    this.onSaveError,
  });

  Future<void> saveData() async {
    try {
      switch (pageType) {
        case 'assessment':
          await PageSpecificDataService.instance.saveAssessmentData(data);
          break;
        case 'profile':
          await PageSpecificDataService.instance.saveProfileData(data);
          break;
        default:
          debugPrint('OptimizedDataSaver: Unknown page type for saving: $pageType');
      }
      
      onSaveComplete?.call();
    } catch (e) {
      debugPrint('OptimizedDataSaver: Error saving data: $e');
      onSaveError?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

/// Hook for pages to easily access optimized data loading
class OptimizedPageData {
  static Future<Map<String, dynamic>> loadPageData(String pageType) async {
    switch (pageType) {
      case 'assessment':
        return await PageSpecificDataService.instance.loadAssessmentData();
      case 'dashboard':
        return await PageSpecificDataService.instance.loadDashboardData();
      case 'profile':
        return await PageSpecificDataService.instance.loadProfileData();
      case 'exercise':
        return await PageSpecificDataService.instance.loadExerciseData();
      case 'reports':
        return await PageSpecificDataService.instance.loadReportsData();
      case 'daily_assessment':
        return await PageSpecificDataService.instance.loadDailyAssessmentData();
      default:
        throw Exception('Unknown page type: $pageType');
    }
  }

  static Future<void> savePageData(String pageType, Map<String, dynamic> data) async {
    switch (pageType) {
      case 'assessment':
        await PageSpecificDataService.instance.saveAssessmentData(data);
        break;
      case 'profile':
        await PageSpecificDataService.instance.saveProfileData(data);
        break;
      default:
        debugPrint('OptimizedPageData: Unknown page type for saving: $pageType');
    }
  }

  static Future<void> preloadPageData(String pageType) async {
    await PageSpecificDataService.instance.preloadData(pageType);
  }
}

