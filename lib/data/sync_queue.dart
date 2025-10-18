import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'globals.dart';

/// Represents a pending sync operation
class PendingSyncOperation {
  final String operation;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final int retryCount;
  final String? error;

  PendingSyncOperation({
    required this.operation,
    required this.data,
    required this.timestamp,
    this.retryCount = 0,
    this.error,
  });

  Map<String, dynamic> toMap() {
    return {
      'operation': operation,
      'data': data,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'retryCount': retryCount,
      'error': error,
    };
  }

  factory PendingSyncOperation.fromMap(Map<String, dynamic> map) {
    return PendingSyncOperation(
      operation: map['operation'] ?? '',
      data: Map<String, dynamic>.from(map['data'] ?? {}),
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      retryCount: map['retryCount'] ?? 0,
      error: map['error'],
    );
  }

  PendingSyncOperation copyWith({
    String? operation,
    Map<String, dynamic>? data,
    DateTime? timestamp,
    int? retryCount,
    String? error,
  }) {
    return PendingSyncOperation(
      operation: operation ?? this.operation,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
      retryCount: retryCount ?? this.retryCount,
      error: error ?? this.error,
    );
  }
}

/// Service to manage sync queue for offline operations
class SyncQueue {
  static final List<PendingSyncOperation> _queue = [];
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(minutes: 5);

  /// Add an operation to the sync queue
  static void enqueue(String operation, Map<String, dynamic> data) {
    final syncOperation = PendingSyncOperation(
      operation: operation,
      data: data,
      timestamp: DateTime.now(),
    );
    
    _queue.add(syncOperation);
    debugPrint('SyncQueue: Added operation to queue - $operation (queue size: ${_queue.length})');
    
    // Persist queue to Hive
    _saveQueueToHive();
  }

  /// Get the current queue size
  static int get length => _queue.length;

  /// Check if queue is empty
  static bool get isEmpty => _queue.isEmpty;

  /// Check if queue has operations
  static bool get isNotEmpty => _queue.isNotEmpty;

  /// Get all pending operations
  static List<PendingSyncOperation> get pendingOperations => List.unmodifiable(_queue);

  /// Process all queued operations
  static Future<void> flushQueue() async {
    if (_queue.isEmpty) {
      debugPrint('SyncQueue: No operations to flush');
      return;
    }

    debugPrint('SyncQueue: Starting to flush ${_queue.length} operations');

    final operationsToRetry = <PendingSyncOperation>[];
    
    for (final operation in List.from(_queue)) {
      try {
        debugPrint('SyncQueue: Processing operation - ${operation.operation}');
        await _executeSyncOperation(operation);
        _queue.remove(operation);
        debugPrint('SyncQueue: Successfully processed operation - ${operation.operation}');
      } catch (e) {
        debugPrint('SyncQueue: Failed to process operation - ${operation.operation}: $e');
        
        if (operation.retryCount < maxRetries) {
          final retryOperation = operation.copyWith(
            retryCount: operation.retryCount + 1,
            error: e.toString(),
          );
          operationsToRetry.add(retryOperation);
        } else {
          debugPrint('SyncQueue: Max retries reached for operation - ${operation.operation}');
        }
        
        _queue.remove(operation);
      }
    }

    // Add retry operations back to queue
    _queue.addAll(operationsToRetry);
    
    // Save updated queue to Hive
    _saveQueueToHive();
    
    debugPrint('SyncQueue: Queue flush completed. Remaining operations: ${_queue.length}');
  }

  /// Execute a specific sync operation
  static Future<void> _executeSyncOperation(PendingSyncOperation operation) async {
    switch (operation.operation) {
      case 'updateUserDetails':
        await _executeUpdateUserDetails(operation.data);
        break;
      case 'updateUserProgress':
        await _executeUpdateUserProgress(operation.data);
        break;
      case 'updateUserAssess':
        await _executeUpdateUserAssess(operation.data);
        break;
      case 'updateUserSettings':
        await _executeUpdateUserSettings(operation.data);
        break;
      case 'updatePainHistory':
        await _executeUpdatePainHistory(operation.data);
        break;
      case 'updateExerciseHistory':
        await _executeUpdateExerciseHistory(operation.data);
        break;
      default:
        throw Exception('Unknown sync operation: ${operation.operation}');
    }
  }

  /// Execute user details update
  static Future<void> _executeUpdateUserDetails(Map<String, dynamic> data) async {
    // Update in-memory data
    if (data.containsKey('firstName')) UserDetails.firstName = data['firstName'];
    if (data.containsKey('lastName')) UserDetails.lastName = data['lastName'];
    if (data.containsKey('email')) UserDetails.email = data['email'];
    if (data.containsKey('profilePicture')) UserDetails.profilePicture = data['profilePicture'];
    if (data.containsKey('hasCompletedAssessment')) UserDetails.hasCompletedAssessment = data['hasCompletedAssessment'];
    
    // Save to Firebase
    await UserDetails.updateInFirebase(
      newFirstName: data['firstName'],
      newLastName: data['lastName'],
      newEmail: data['email'],
      newProfilePicture: data['profilePicture'],
    );
  }

  /// Execute user progress update
  static Future<void> _executeUpdateUserProgress(Map<String, dynamic> data) async {
    // Update in-memory data
    if (data.containsKey('title')) UserProgress.title = data['title'];
    if (data.containsKey('titleColor')) UserProgress.titleColor = data['titleColor'];
    if (data.containsKey('streak')) UserProgress.streak = data['streak'];
    if (data.containsKey('totalDays')) UserProgress.totalDays = data['totalDays'];
    if (data.containsKey('totalExercises')) UserProgress.totalExercises = data['totalExercises'];
    if (data.containsKey('totalSeconds')) UserProgress.totalSeconds = data['totalSeconds'];
    if (data.containsKey('notes')) UserProgress.notes = data['notes'];
    if (data.containsKey('lastExerciseDate')) {
      final timestamp = data['lastExerciseDate'];
      if (timestamp is int) {
        UserProgress.lastExerciseDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
    }
    
    // Save to Firebase
    await UserProgress.saveToFirebase();
  }

  /// Execute user assessment update
  static Future<void> _executeUpdateUserAssess(Map<String, dynamic> data) async {
    // Update in-memory data
    if (data.containsKey('rehabGoal')) UserAssess.rehabGoal = data['rehabGoal'];
    if (data.containsKey('generalMuscle')) UserAssess.generalMuscle = data['generalMuscle'];
    if (data.containsKey('specificMuscle')) UserAssess.specificMuscle = data['specificMuscle'];
    if (data.containsKey('painScale')) UserAssess.painScale = data['painScale'];
    if (data.containsKey('painLevel')) UserAssess.painLevel = data['painLevel'];
    if (data.containsKey('painType')) UserAssess.painType = data['painType'];
    if (data.containsKey('painDuration')) UserAssess.painDuration = data['painDuration'];
    if (data.containsKey('isInjured')) UserAssess.isInjured = data['isInjured'];
    if (data.containsKey('isAssessed')) UserAssess.isAssessed = data['isAssessed'];
    
    // Save to Firebase
    await UserAssess.saveToFirebase();
  }

  /// Execute user settings update
  static Future<void> _executeUpdateUserSettings(Map<String, dynamic> data) async {
    // Update in-memory data
    if (data.containsKey('isDailyReminder')) UserSettings.isDailyReminder = data['isDailyReminder'];
    if (data.containsKey('isStreakAlert')) UserSettings.isStreakAlert = data['isStreakAlert'];
    if (data.containsKey('isExerciseReminder')) UserSettings.isExerciseReminder = data['isExerciseReminder'];
    if (data.containsKey('exerciseReminderHour') && data.containsKey('exerciseReminderMinute')) {
      UserSettings.exerciseReminderTime = TimeOfDay(
        hour: data['exerciseReminderHour'],
        minute: data['exerciseReminderMinute'],
      );
    }
    
    // Save to Firebase
    await UserSettings.saveToFirebase();
  }

  /// Execute pain history update
  static Future<void> _executeUpdatePainHistory(Map<String, dynamic> data) async {
    // Save to Firebase
    await PainHistory.saveToFirebase();
  }

  /// Execute exercise history update
  static Future<void> _executeUpdateExerciseHistory(Map<String, dynamic> data) async {
    // Save to Firebase
    await ExerciseHistory.saveToFirebase();
  }

  /// Load queue from Hive
  static Future<void> loadQueueFromHive() async {
    try {
      if (!Hive.isBoxOpen('rehabBox')) {
        await openRehabBox();
      }
      
      final box = Hive.box('rehabBox');
      final queueData = box.get('syncQueue', defaultValue: <Map<String, dynamic>>[]);
      
      if (queueData is List<dynamic>) {
        _queue.clear();
        _queue.addAll(queueData.map((item) => PendingSyncOperation.fromMap(item)));
        debugPrint('SyncQueue: Loaded ${_queue.length} operations from Hive');
      }
    } catch (e) {
      debugPrint('SyncQueue: Error loading queue from Hive: $e');
    }
  }

  /// Save queue to Hive
  static Future<void> _saveQueueToHive() async {
    try {
      if (!Hive.isBoxOpen('rehabBox')) {
        await openRehabBox();
      }
      
      final box = Hive.box('rehabBox');
      final queueData = _queue.map((op) => op.toMap()).toList();
      await box.put('syncQueue', queueData);
      debugPrint('SyncQueue: Saved ${_queue.length} operations to Hive');
    } catch (e) {
      debugPrint('SyncQueue: Error saving queue to Hive: $e');
    }
  }

  /// Clear all operations from queue
  static void clearQueue() {
    _queue.clear();
    _saveQueueToHive();
    debugPrint('SyncQueue: Cleared all operations from queue');
  }

  /// Get queue statistics
  static Map<String, dynamic> getQueueStatistics() {
    final now = DateTime.now();
    final recentOperations = _queue.where((op) => 
      now.difference(op.timestamp).inHours < 24).length;
    
    return {
      'totalOperations': _queue.length,
      'recentOperations': recentOperations,
      'operationsWithErrors': _queue.where((op) => op.error != null).length,
      'oldestOperation': _queue.isEmpty ? null : _queue.map((op) => op.timestamp).reduce((a, b) => a.isBefore(b) ? a : b).toIso8601String(),
    };
  }
}
