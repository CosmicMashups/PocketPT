import 'package:flutter/material.dart';
import '../data/comprehensive_data_loader.dart';
import '../data/user_data_notifier.dart';

/// Widget wrapper that ensures data is loaded before showing content
class DataLoadingWrapper extends StatefulWidget {
  final Widget child;
  final List<String> requiredDataTypes;
  final Widget? loadingWidget;
  final Widget? errorWidget;
  final bool showLoadingIndicator;
  final bool showProgressIndicator;
  final String? loadingMessage;
  
  const DataLoadingWrapper({
    super.key,
    required this.child,
    this.requiredDataTypes = const ['userData'],
    this.loadingWidget,
    this.errorWidget,
    this.showLoadingIndicator = true,
    this.showProgressIndicator = true,
    this.loadingMessage,
  });

  @override
  State<DataLoadingWrapper> createState() => _DataLoadingWrapperState();
}

class _DataLoadingWrapperState extends State<DataLoadingWrapper> {
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  Map<String, bool> _dataLoadingStatus = {};
  int _loadedCount = 0;
  
  @override
  void initState() {
    super.initState();
    _initializeLoadingStatus();
    _loadRequiredData();
  }
  
  void _initializeLoadingStatus() {
    for (final dataType in widget.requiredDataTypes) {
      _dataLoadingStatus[dataType] = false;
    }
  }
  
  Future<void> _loadRequiredData() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = null;
        _loadedCount = 0;
      });
      
      // Ensure comprehensive data loader is initialized
      await ComprehensiveDataLoader.instance.initialize();
      
      // Load all required data types with progress tracking
      for (final dataType in widget.requiredDataTypes) {
        if (mounted) {
          setState(() {
            _dataLoadingStatus[dataType] = false;
          });
        }
        
        await ComprehensiveDataLoader.instance.ensureDataLoaded(dataType);
        
        if (mounted) {
          setState(() {
            _dataLoadingStatus[dataType] = true;
            _loadedCount++;
          });
        }
      }
      
      // Ensure UserDataNotifier is properly initialized
      UserDataNotifier.instance.initialize();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      
    } catch (e) {
      debugPrint('DataLoadingWrapper: Error loading data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return widget.errorWidget ?? _buildDefaultErrorWidget();
    }
    
    if (_isLoading && widget.showLoadingIndicator) {
      return widget.loadingWidget ?? _buildDefaultLoadingWidget();
    }
    
    return widget.child;
  }
  
  Widget _buildDefaultLoadingWidget() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = widget.requiredDataTypes.isNotEmpty 
        ? _loadedCount / widget.requiredDataTypes.length 
        : 0.0;
    
    return Scaffold(
      backgroundColor: isDark ? Theme.of(context).scaffoldBackgroundColor : const Color(0xFFF8FAFC),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Main loading indicator
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: Stack(
                      children: [
                        // Background circle
                        CircularProgressIndicator(
                          value: 1.0,
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            const Color(0xFF8B2E2E).withOpacity(0.2),
                          ),
                        ),
                        // Progress circle
                        CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 3,
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8B2E2E)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Loading message
                  Text(
                    widget.loadingMessage ?? 'Loading Data',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Progress text
                  Text(
                    'Preparing your personalized experience',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  // Progress percentage
                  if (widget.showProgressIndicator) ...[
                    const SizedBox(height: 16),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF8B2E2E),
                      ),
                    ),
                  ],
                  
                  // Data loading status
                  if (widget.showProgressIndicator && widget.requiredDataTypes.length > 1) ...[
                    const SizedBox(height: 16),
                    _buildDataLoadingStatus(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDataLoadingStatus() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      children: widget.requiredDataTypes.map((dataType) {
        final isLoaded = _dataLoadingStatus[dataType] ?? false;
        final displayName = _getDataTypeDisplayName(dataType);
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: isLoaded
                    ? Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Colors.green[600],
                      )
                    : SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            const Color(0xFF8B2E2E).withOpacity(0.6),
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 8),
              Text(
                displayName,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
  
  String _getDataTypeDisplayName(String dataType) {
    switch (dataType) {
      case 'userData':
        return 'User Profile';
      case 'userProgress':
        return 'Progress Data';
      case 'userSettings':
        return 'Settings';
      case 'userAssessment':
        return 'Assessment';
      case 'rehabilitationPlans':
        return 'Rehabilitation Plans';
      case 'painHistory':
        return 'Pain History';
      case 'exerciseHistory':
        return 'Exercise History';
      default:
        return dataType;
    }
  }
  
  Widget _buildDefaultErrorWidget() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? Theme.of(context).scaffoldBackgroundColor : const Color(0xFFF8FAFC),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Data Loading Error',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Unable to load required data. Please try again.',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Error: $_errorMessage',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _hasError = false;
                        });
                        _loadRequiredData();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B2E2E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Convenience widget for pages that need user data
class UserDataLoadingWrapper extends StatelessWidget {
  final Widget child;
  final Widget? loadingWidget;
  final Widget? errorWidget;
  final bool showProgressIndicator;
  final String? loadingMessage;
  
  const UserDataLoadingWrapper({
    super.key,
    required this.child,
    this.loadingWidget,
    this.errorWidget,
    this.showProgressIndicator = true,
    this.loadingMessage,
  });

  @override
  Widget build(BuildContext context) {
    return DataLoadingWrapper(
      requiredDataTypes: const ['userData', 'userProgress', 'userSettings'],
      loadingWidget: loadingWidget,
      errorWidget: errorWidget,
      showProgressIndicator: showProgressIndicator,
      loadingMessage: loadingMessage ?? 'Loading User Data',
      child: child,
    );
  }
}

/// Convenience widget for pages that need rehabilitation data
class RehabDataLoadingWrapper extends StatelessWidget {
  final Widget child;
  final Widget? loadingWidget;
  final Widget? errorWidget;
  final bool showProgressIndicator;
  final String? loadingMessage;
  
  const RehabDataLoadingWrapper({
    super.key,
    required this.child,
    this.loadingWidget,
    this.errorWidget,
    this.showProgressIndicator = true,
    this.loadingMessage,
  });

  @override
  Widget build(BuildContext context) {
    return DataLoadingWrapper(
      requiredDataTypes: const [
        'userData',
        'userProgress',
        'userSettings',
        'userAssessment',
        'rehabilitationPlans',
        'painHistory',
        'exerciseHistory',
      ],
      loadingWidget: loadingWidget,
      errorWidget: errorWidget,
      showProgressIndicator: showProgressIndicator,
      loadingMessage: loadingMessage ?? 'Loading Rehabilitation Data',
      child: child,
    );
  }
}
