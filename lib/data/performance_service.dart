import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Service to monitor and optimize app performance
class PerformanceService {
  static final PerformanceService _instance = PerformanceService._internal();
  static PerformanceService get instance => _instance;
  
  PerformanceService._internal();
  
  final Map<String, DateTime> _operationStartTimes = {};
  final Map<String, Duration> _operationDurations = {};
  final List<String> _performanceLog = [];
  
  /// Start timing an operation
  void startTiming(String operationName) {
    _operationStartTimes[operationName] = DateTime.now();
    if (kDebugMode) {
      print('PerformanceService: Started timing $operationName');
    }
  }
  
  /// End timing an operation
  void endTiming(String operationName) {
    final startTime = _operationStartTimes[operationName];
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime);
      _operationDurations[operationName] = duration;
      _performanceLog.add('$operationName: ${duration.inMilliseconds}ms');
      
      if (kDebugMode) {
        print('PerformanceService: $operationName completed in ${duration.inMilliseconds}ms');
      }
      
      // Remove from start times
      _operationStartTimes.remove(operationName);
    }
  }
  
  /// Get performance statistics
  Map<String, dynamic> getPerformanceStats() {
    final totalOperations = _operationDurations.length;
    final averageDuration = totalOperations > 0 
        ? _operationDurations.values
            .map((d) => d.inMilliseconds)
            .reduce((a, b) => a + b) / totalOperations
        : 0.0;
    
    final slowOperations = _operationDurations.entries
        .where((e) => e.value.inMilliseconds > 1000)
        .map((e) => '${e.key}: ${e.value.inMilliseconds}ms')
        .toList();
    
    return {
      'totalOperations': totalOperations,
      'averageDuration': averageDuration,
      'slowOperations': slowOperations,
      'recentLogs': _performanceLog.length > 10 
          ? _performanceLog.sublist(_performanceLog.length - 10)
          : _performanceLog,
    };
  }
  
  /// Clear performance data
  void clearPerformanceData() {
    _operationStartTimes.clear();
    _operationDurations.clear();
    _performanceLog.clear();
    if (kDebugMode) {
      print('PerformanceService: Performance data cleared');
    }
  }
  
  /// Log performance warning
  void logWarning(String operation, String message) {
    final warning = 'WARNING: $operation - $message';
    _performanceLog.add(warning);
    if (kDebugMode) {
      print('PerformanceService: $warning');
    }
  }
}

/// Performance monitoring mixin for widgets
mixin PerformanceMixin<T extends StatefulWidget> on State<T> {
  String get performanceOperationName;
  
  void initPerformanceTiming() {
    PerformanceService.instance.startTiming(performanceOperationName);
  }
  
  void endPerformanceTiming() {
    PerformanceService.instance.endTiming(performanceOperationName);
  }
}

/// Optimized timer for performance monitoring
class PerformanceTimer {
  final String operationName;
  final DateTime startTime;
  
  PerformanceTimer(this.operationName) : startTime = DateTime.now();
  
  void end() {
    final duration = DateTime.now().difference(startTime);
    PerformanceService.instance._operationDurations[operationName] = duration;
    
    if (kDebugMode) {
      print('PerformanceTimer: $operationName completed in ${duration.inMilliseconds}ms');
    }
  }
}
