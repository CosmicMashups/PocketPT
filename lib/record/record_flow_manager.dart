import 'package:flutter/material.dart';
import 'camera_service.dart';
import 'stopwatch_service.dart';

/// Centralized navigation and state management for the exercise recording workflow
/// Handles exercise progression, state cleanup, and navigation coordination
class RecordFlowManager {
  RecordFlowManager._privateConstructor();
  static final RecordFlowManager _instance = RecordFlowManager._privateConstructor();
  static RecordFlowManager get instance => _instance;

  final CameraService _cameraService = CameraService.instance;
  final StopwatchService _stopwatchService = StopwatchService.instance;
  
  // Navigation state
  int _currentExerciseIndex = 0;
  List<String> _exerciseIds = [];
  bool _isNavigating = false;
  
  // Getters
  int get currentExerciseIndex => _currentExerciseIndex;
  List<String> get exerciseIds => List.unmodifiable(_exerciseIds);
  bool get isNavigating => _isNavigating;

  /// Initialize the recording flow with exercise data
  Future<void> initializeFlow(List<String> exerciseIds) async {
    _exerciseIds = List.from(exerciseIds);
    _currentExerciseIndex = 0;
    _isNavigating = false;
    
    debugPrint('RecordFlowManager: Initialized flow with ${_exerciseIds.length} exercises');
  }

  /// Navigate to next exercise with proper state management
  Future<bool> navigateToNext(BuildContext context) async {
    if (_isNavigating) {
      debugPrint('RecordFlowManager: Navigation already in progress, ignoring request');
      return false;
    }

    if (_currentExerciseIndex >= _exerciseIds.length - 1) {
      debugPrint('RecordFlowManager: Already at last exercise');
      return false;
    }

    _isNavigating = true;
    
    try {
      _currentExerciseIndex++;
      debugPrint('RecordFlowManager: Navigating to exercise index $_currentExerciseIndex');
      return true;
    } catch (e) {
      debugPrint('RecordFlowManager: Error navigating to next exercise: $e');
      _currentExerciseIndex--; // Revert on error
      return false;
    } finally {
      _isNavigating = false;
    }
  }

  /// Navigate to previous exercise with proper state management
  Future<bool> navigateToPrevious(BuildContext context) async {
    if (_isNavigating) {
      debugPrint('RecordFlowManager: Navigation already in progress, ignoring request');
      return false;
    }

    if (_currentExerciseIndex <= 0) {
      debugPrint('RecordFlowManager: Already at first exercise');
      return false;
    }

    _isNavigating = true;
    
    try {
      _currentExerciseIndex--;
      debugPrint('RecordFlowManager: Navigating to exercise index $_currentExerciseIndex');
      return true;
    } catch (e) {
      debugPrint('RecordFlowManager: Error navigating to previous exercise: $e');
      _currentExerciseIndex++; // Revert on error
      return false;
    } finally {
      _isNavigating = false;
    }
  }

  /// Get current exercise ID
  String? getCurrentExerciseId() {
    if (_currentExerciseIndex >= 0 && _currentExerciseIndex < _exerciseIds.length) {
      return _exerciseIds[_currentExerciseIndex];
    }
    return null;
  }

  /// Check if there's a next exercise
  bool hasNext() {
    return _currentExerciseIndex < _exerciseIds.length - 1;
  }

  /// Check if there's a previous exercise
  bool hasPrevious() {
    return _currentExerciseIndex > 0;
  }

  /// Check if current exercise is the last one
  bool isLastExercise() {
    return _currentExerciseIndex >= _exerciseIds.length - 1;
  }

  /// Check if current exercise is the first one
  bool isFirstExercise() {
    return _currentExerciseIndex <= 0;
  }

  /// Get progress information
  Map<String, dynamic> getProgress() {
    return {
      'currentIndex': _currentExerciseIndex,
      'totalExercises': _exerciseIds.length,
      'progress': _currentExerciseIndex / (_exerciseIds.length - 1),
      'isFirst': isFirstExercise(),
      'isLast': isLastExercise(),
      'hasNext': hasNext(),
      'hasPrevious': hasPrevious(),
    };
  }

  /// Pause the recording flow
  Future<void> pauseFlow() async {
    debugPrint('RecordFlowManager: Pausing recording flow');
    _stopwatchService.pause();
    // Camera service remains active for quick resume
  }

  /// Resume the recording flow
  Future<void> resumeFlow() async {
    debugPrint('RecordFlowManager: Resuming recording flow');
    _stopwatchService.start();
  }

  /// Complete the recording flow
  Future<void> completeFlow() async {
    debugPrint('RecordFlowManager: Completing recording flow');
    _stopwatchService.pause();
    // Don't dispose camera service here - let the parent handle it
  }

  /// Reset the flow for new session
  Future<void> resetFlow() async {
    debugPrint('RecordFlowManager: Resetting recording flow');
    _currentExerciseIndex = 0;
    _exerciseIds.clear();
    _isNavigating = false;
    _stopwatchService.reset();
  }

  /// Dispose all resources
  Future<void> dispose() async {
    debugPrint('RecordFlowManager: Disposing flow manager');
    await _cameraService.dispose();
    await resetFlow();
  }

  /// Handle app lifecycle changes
  Future<void> handleAppLifecycleChange(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.paused:
        debugPrint('RecordFlowManager: App paused, pausing flow');
        await pauseFlow();
        break;
      case AppLifecycleState.resumed:
        debugPrint('RecordFlowManager: App resumed, resuming flow');
        await resumeFlow();
        break;
      case AppLifecycleState.detached:
        debugPrint('RecordFlowManager: App detached, disposing flow');
        await dispose();
        break;
      case AppLifecycleState.inactive:
        // Don't do anything for inactive state
        break;
      case AppLifecycleState.hidden:
        // Don't do anything for hidden state
        break;
    }
  }
}
