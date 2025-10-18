import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';
import 'unified_data_models.dart';
import 'unified_firebase_service.dart';
import 'hive_migration_service.dart';
import 'firebase_migration_service.dart';

/// Sync status enumeration
enum SyncStatus {
  idle,
  syncing,
  error,
  offline,
}

/// Sync operation types
enum SyncOperation {
  save,
  load,
  delete,
  sync,
}

/// Sync queue item
class SyncQueueItem {
  final String id;
  final SyncOperation operation;
  final String dataType;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final int retryCount;

  SyncQueueItem({
    required this.id,
    required this.operation,
    required this.dataType,
    required this.data,
    required this.timestamp,
    this.retryCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'operation': operation.name,
      'dataType': dataType,
      'data': data,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'retryCount': retryCount,
    };
  }

  static SyncQueueItem fromMap(Map<String, dynamic> map) {
    return SyncQueueItem(
      id: map['id'] as String,
      operation: SyncOperation.values.firstWhere(
        (op) => op.name == map['operation'],
        orElse: () => SyncOperation.sync,
      ),
      dataType: map['dataType'] as String,
      data: Map<String, dynamic>.from(map['data'] as Map),
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      retryCount: map['retryCount'] as int? ?? 0,
    );
  }
}

/// Unified synchronization service that handles all data operations between Hive and Firebase
class UnifiedSyncService {
  static const String _syncQueueKey = 'sync_queue';
  static const String _lastSyncKey = 'last_sync';
  static const String _syncStatusKey = 'sync_status';

  /// Initialize the sync service
  static Future<void> initialize() async {
    try {
      // Check if migration is needed
      final hiveMigrationNeeded = await HiveMigrationService.isMigrationNeeded();
      final firebaseMigrationNeeded = await FirebaseMigrationService.isMigrationNeeded();

      if (hiveMigrationNeeded) {
        debugPrint('UnifiedSyncService: Performing Hive migration');
        await HiveMigrationService.performMigration();
      }

      if (firebaseMigrationNeeded) {
        debugPrint('UnifiedSyncService: Performing Firebase migration');
        await FirebaseMigrationService.performMigration();
      }

      // Process any pending sync operations
      await _processSyncQueue();

      debugPrint('UnifiedSyncService: Initialization completed');
    } catch (e) {
      debugPrint('UnifiedSyncService: Initialization failed: $e');
    }
  }

  /// Save UserDetails with automatic sync
  static Future<bool> saveUserDetails(UnifiedUserDetails userDetails) async {
    try {
      // Save to Hive first (offline-first)
      final success = await _saveToHive('userDetails', userDetails.toHiveMap());
      if (!success) {
        debugPrint('UnifiedSyncService: Failed to save UserDetails to Hive');
        return false;
      }

      // Queue for Firebase sync
      await _queueSyncOperation(
        SyncOperation.save,
        'userDetails',
        userDetails.toFirebaseMap(),
      );

      // Try immediate sync if online
      if (await _isOnline()) {
        await _syncUserDetails();
      }

      return true;
    } catch (e) {
      debugPrint('UnifiedSyncService: Error saving UserDetails: $e');
      return false;
    }
  }

  /// Load UserDetails with automatic sync
  static Future<UnifiedUserDetails?> loadUserDetails() async {
    try {
      // Try to load from Hive first
      final hiveData = await _loadFromHive('userDetails');
      UnifiedUserDetails? hiveUserDetails;

      if (hiveData != null) {
        hiveUserDetails = UnifiedUserDetails.fromHiveMap(hiveData);
      }

      // Try to load from Firebase if online
      UnifiedUserDetails? firebaseUserDetails;
      if (await _isOnline()) {
        firebaseUserDetails = await UnifiedFirebaseService.loadUserDetails();
      }

      // Resolve conflicts and return best data
      final resolvedUserDetails = _resolveUserDetailsConflict(hiveUserDetails, firebaseUserDetails);

      // Save resolved data back to both stores
      if (resolvedUserDetails != null) {
        await _saveToHive('userDetails', resolvedUserDetails.toHiveMap());
        if (await _isOnline()) {
          await UnifiedFirebaseService.saveUserDetails(resolvedUserDetails);
        }
      }

      return resolvedUserDetails;
    } catch (e) {
      debugPrint('UnifiedSyncService: Error loading UserDetails: $e');
      return null;
    }
  }

  /// Save UserProgress with automatic sync
  static Future<bool> saveUserProgress(UnifiedUserProgress userProgress) async {
    try {
      // Save to Hive first (offline-first)
      final success = await _saveToHive('userProgress', userProgress.toHiveMap());
      if (!success) {
        debugPrint('UnifiedSyncService: Failed to save UserProgress to Hive');
        return false;
      }

      // Queue for Firebase sync
      await _queueSyncOperation(
        SyncOperation.save,
        'userProgress',
        userProgress.toFirebaseMap(),
      );

      // Try immediate sync if online
      if (await _isOnline()) {
        await _syncUserProgress();
      }

      return true;
    } catch (e) {
      debugPrint('UnifiedSyncService: Error saving UserProgress: $e');
      return false;
    }
  }

  /// Load UserProgress with automatic sync
  static Future<UnifiedUserProgress?> loadUserProgress() async {
    try {
      // Try to load from Hive first
      final hiveData = await _loadFromHive('userProgress');
      UnifiedUserProgress? hiveUserProgress;

      if (hiveData != null) {
        hiveUserProgress = UnifiedUserProgress.fromHiveMap(hiveData);
      }

      // Try to load from Firebase if online
      UnifiedUserProgress? firebaseUserProgress;
      if (await _isOnline()) {
        firebaseUserProgress = await UnifiedFirebaseService.loadUserProgress();
      }

      // Resolve conflicts and return best data
      final resolvedUserProgress = _resolveUserProgressConflict(hiveUserProgress, firebaseUserProgress);

      // Save resolved data back to both stores
      if (resolvedUserProgress != null) {
        await _saveToHive('userProgress', resolvedUserProgress.toHiveMap());
        if (await _isOnline()) {
          await UnifiedFirebaseService.saveUserProgress(resolvedUserProgress);
        }
      }

      return resolvedUserProgress;
    } catch (e) {
      debugPrint('UnifiedSyncService: Error loading UserProgress: $e');
      return null;
    }
  }

  /// Save UserSettings with automatic sync
  static Future<bool> saveUserSettings(UnifiedUserSettings userSettings) async {
    try {
      // Save to Hive first (offline-first)
      final success = await _saveToHive('userSettings', userSettings.toHiveMap());
      if (!success) {
        debugPrint('UnifiedSyncService: Failed to save UserSettings to Hive');
        return false;
      }

      // Queue for Firebase sync
      await _queueSyncOperation(
        SyncOperation.save,
        'userSettings',
        userSettings.toFirebaseMap(),
      );

      // Try immediate sync if online
      if (await _isOnline()) {
        await _syncUserSettings();
      }

      return true;
    } catch (e) {
      debugPrint('UnifiedSyncService: Error saving UserSettings: $e');
      return false;
    }
  }

  /// Load UserSettings with automatic sync
  static Future<UnifiedUserSettings?> loadUserSettings() async {
    try {
      // Try to load from Hive first
      final hiveData = await _loadFromHive('userSettings');
      UnifiedUserSettings? hiveUserSettings;

      if (hiveData != null) {
        hiveUserSettings = UnifiedUserSettings.fromHiveMap(hiveData);
      }

      // Try to load from Firebase if online
      UnifiedUserSettings? firebaseUserSettings;
      if (await _isOnline()) {
        firebaseUserSettings = await UnifiedFirebaseService.loadUserSettings();
      }

      // Resolve conflicts and return best data
      final resolvedUserSettings = _resolveUserSettingsConflict(hiveUserSettings, firebaseUserSettings);

      // Save resolved data back to both stores
      if (resolvedUserSettings != null) {
        await _saveToHive('userSettings', resolvedUserSettings.toHiveMap());
        if (await _isOnline()) {
          await UnifiedFirebaseService.saveUserSettings(resolvedUserSettings);
        }
      }

      return resolvedUserSettings;
    } catch (e) {
      debugPrint('UnifiedSyncService: Error loading UserSettings: $e');
      return null;
    }
  }

  /// Perform full sync of all data
  static Future<bool> performFullSync() async {
    try {
      debugPrint('UnifiedSyncService: Starting full sync');
      
      if (!await _isOnline()) {
        debugPrint('UnifiedSyncService: Cannot sync - offline');
        return false;
      }

      // Sync all data types
      await _syncUserDetails();
      await _syncUserProgress();
      await _syncUserSettings();
      await _syncPainHistory();
      await _syncExerciseHistory();
      await _syncRehabilitationPlans();

      // Process any pending sync operations
      await _processSyncQueue();

      // Update last sync timestamp
      await _updateLastSyncTimestamp();

      debugPrint('UnifiedSyncService: Full sync completed');
      return true;
    } catch (e) {
      debugPrint('UnifiedSyncService: Full sync failed: $e');
      return false;
    }
  }

  /// Get sync status
  static Future<SyncStatus> getSyncStatus() async {
    try {
      final box = await Hive.openBox('syncBox');
      final status = box.get(_syncStatusKey, defaultValue: SyncStatus.idle.name) as String;
      await box.close();
      return SyncStatus.values.firstWhere(
        (s) => s.name == status,
        orElse: () => SyncStatus.idle,
      );
    } catch (e) {
      debugPrint('UnifiedSyncService: Error getting sync status: $e');
      return SyncStatus.error;
    }
  }

  /// Set sync status
  static Future<void> setSyncStatus(SyncStatus status) async {
    try {
      final box = await Hive.openBox('syncBox');
      await box.put(_syncStatusKey, status.name);
      await box.close();
    } catch (e) {
      debugPrint('UnifiedSyncService: Error setting sync status: $e');
    }
  }

  /// Get last sync timestamp
  static Future<DateTime?> getLastSyncTimestamp() async {
    try {
      final box = await Hive.openBox('syncBox');
      final timestamp = box.get(_lastSyncKey) as int?;
      await box.close();
      return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
    } catch (e) {
      debugPrint('UnifiedSyncService: Error getting last sync timestamp: $e');
      return null;
    }
  }

  /// Private helper methods

  static Future<bool> _isOnline() async {
    // Simple online check - in a real app, you might want to use connectivity_plus
    try {
      // Try to access a simple Firebase operation
      await UnifiedFirebaseService.currentUserId;
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> _saveToHive(String key, Map<String, dynamic> data) async {
    try {
      final box = await Hive.openBox('unifiedRehabBox');
      await box.put(key, data);
      await box.close();
      return true;
    } catch (e) {
      debugPrint('UnifiedSyncService: Error saving to Hive: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> _loadFromHive(String key) async {
    try {
      final box = await Hive.openBox('unifiedRehabBox');
      final data = box.get(key) as Map<String, dynamic>?;
      await box.close();
      return data;
    } catch (e) {
      debugPrint('UnifiedSyncService: Error loading from Hive: $e');
      return null;
    }
  }

  static Future<void> _queueSyncOperation(
    SyncOperation operation,
    String dataType,
    Map<String, dynamic> data,
  ) async {
    try {
      final box = await Hive.openBox('syncBox');
      final queue = box.get(_syncQueueKey, defaultValue: <Map<String, dynamic>>[]) as List<dynamic>;
      
      final item = SyncQueueItem(
        id: '${dataType}_${DateTime.now().millisecondsSinceEpoch}',
        operation: operation,
        dataType: dataType,
        data: data,
        timestamp: DateTime.now(),
      );
      
      queue.add(item.toMap());
      await box.put(_syncQueueKey, queue);
      await box.close();
    } catch (e) {
      debugPrint('UnifiedSyncService: Error queuing sync operation: $e');
    }
  }

  static Future<void> _processSyncQueue() async {
    try {
      final box = await Hive.openBox('syncBox');
      final queue = box.get(_syncQueueKey, defaultValue: <Map<String, dynamic>>[]) as List<dynamic>;
      
      final List<Map<String, dynamic>> processedItems = [];
      final List<Map<String, dynamic>> failedItems = [];
      
      for (final itemData in queue) {
        final item = SyncQueueItem.fromMap(itemData as Map<String, dynamic>);
        
        try {
          await _processSyncItem(item);
          processedItems.add(itemData);
        } catch (e) {
          debugPrint('UnifiedSyncService: Failed to process sync item: $e');
          if (item.retryCount < 3) {
            // Retry failed items
            final retryItem = SyncQueueItem(
              id: item.id,
              operation: item.operation,
              dataType: item.dataType,
              data: item.data,
              timestamp: item.timestamp,
              retryCount: item.retryCount + 1,
            );
            failedItems.add(retryItem.toMap());
          }
        }
      }
      
      // Update queue with remaining items
      await box.put(_syncQueueKey, failedItems);
      await box.close();
      
      debugPrint('UnifiedSyncService: Processed ${processedItems.length} sync items, ${failedItems.length} failed');
    } catch (e) {
      debugPrint('UnifiedSyncService: Error processing sync queue: $e');
    }
  }

  static Future<void> _processSyncItem(SyncQueueItem item) async {
    switch (item.operation) {
      case SyncOperation.save:
        await _processSaveOperation(item);
        break;
      case SyncOperation.load:
        await _processLoadOperation(item);
        break;
      case SyncOperation.delete:
        await _processDeleteOperation(item);
        break;
      case SyncOperation.sync:
        await _processSyncOperation(item);
        break;
    }
  }

  static Future<void> _processSaveOperation(SyncQueueItem item) async {
    switch (item.dataType) {
      case 'userDetails':
        final userDetails = UnifiedUserDetails.fromFirebaseMap(item.data);
        await UnifiedFirebaseService.saveUserDetails(userDetails);
        break;
      case 'userProgress':
        final userProgress = UnifiedUserProgress.fromFirebaseMap(item.data);
        await UnifiedFirebaseService.saveUserProgress(userProgress);
        break;
      case 'userSettings':
        final userSettings = UnifiedUserSettings.fromFirebaseMap(item.data);
        await UnifiedFirebaseService.saveUserSettings(userSettings);
        break;
      default:
        throw Exception('Unknown data type: ${item.dataType}');
    }
  }

  static Future<void> _processLoadOperation(SyncQueueItem item) async {
    // Load operations are handled synchronously, so this is mainly for logging
    debugPrint('UnifiedSyncService: Processed load operation for ${item.dataType}');
  }

  static Future<void> _processDeleteOperation(SyncQueueItem item) async {
    // Delete operations would be implemented here
    debugPrint('UnifiedSyncService: Processed delete operation for ${item.dataType}');
  }

  static Future<void> _processSyncOperation(SyncQueueItem item) async {
    // Sync operations would be implemented here
    debugPrint('UnifiedSyncService: Processed sync operation for ${item.dataType}');
  }

  static Future<void> _updateLastSyncTimestamp() async {
    try {
      final box = await Hive.openBox('syncBox');
      await box.put(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
      await box.close();
    } catch (e) {
      debugPrint('UnifiedSyncService: Error updating last sync timestamp: $e');
    }
  }

  // Sync methods for individual data types
  static Future<void> _syncUserDetails() async {
    final hiveData = await _loadFromHive('userDetails');
    if (hiveData != null) {
      final userDetails = UnifiedUserDetails.fromHiveMap(hiveData);
      await UnifiedFirebaseService.saveUserDetails(userDetails);
    }
  }

  static Future<void> _syncUserProgress() async {
    final hiveData = await _loadFromHive('userProgress');
    if (hiveData != null) {
      final userProgress = UnifiedUserProgress.fromHiveMap(hiveData);
      await UnifiedFirebaseService.saveUserProgress(userProgress);
    }
  }

  static Future<void> _syncUserSettings() async {
    final hiveData = await _loadFromHive('userSettings');
    if (hiveData != null) {
      final userSettings = UnifiedUserSettings.fromHiveMap(hiveData);
      await UnifiedFirebaseService.saveUserSettings(userSettings);
    }
  }

  static Future<void> _syncPainHistory() async {
    // Implementation for pain history sync
    debugPrint('UnifiedSyncService: Syncing pain history');
  }

  static Future<void> _syncExerciseHistory() async {
    // Implementation for exercise history sync
    debugPrint('UnifiedSyncService: Syncing exercise history');
  }

  static Future<void> _syncRehabilitationPlans() async {
    // Implementation for rehabilitation plans sync
    debugPrint('UnifiedSyncService: Syncing rehabilitation plans');
  }

  // Conflict resolution methods
  static UnifiedUserDetails? _resolveUserDetailsConflict(
    UnifiedUserDetails? hive,
    UnifiedUserDetails? firebase,
  ) {
    if (hive == null && firebase == null) return null;
    if (hive == null) return firebase;
    if (firebase == null) return hive;

    // Use lastModified to determine winner
    final hiveTime = hive.lastModified;
    final firebaseTime = firebase.lastModified;

    if (hiveTime == null && firebaseTime == null) return firebase;
    if (hiveTime == null) return firebase;
    if (firebaseTime == null) return hive;

    return hiveTime.isAfter(firebaseTime) ? hive : firebase;
  }

  static UnifiedUserProgress? _resolveUserProgressConflict(
    UnifiedUserProgress? hive,
    UnifiedUserProgress? firebase,
  ) {
    if (hive == null && firebase == null) return null;
    if (hive == null) return firebase;
    if (firebase == null) return hive;

    // Use lastModified to determine winner
    final hiveTime = hive.lastModified;
    final firebaseTime = firebase.lastModified;

    if (hiveTime == null && firebaseTime == null) return firebase;
    if (hiveTime == null) return firebase;
    if (firebaseTime == null) return hive;

    return hiveTime.isAfter(firebaseTime) ? hive : firebase;
  }

  static UnifiedUserSettings? _resolveUserSettingsConflict(
    UnifiedUserSettings? hive,
    UnifiedUserSettings? firebase,
  ) {
    if (hive == null && firebase == null) return null;
    if (hive == null) return firebase;
    if (firebase == null) return hive;

    // Use lastModified to determine winner
    final hiveTime = hive.lastModified;
    final firebaseTime = firebase.lastModified;

    if (hiveTime == null && firebaseTime == null) return firebase;
    if (hiveTime == null) return firebase;
    if (firebaseTime == null) return hive;

    return hiveTime.isAfter(firebaseTime) ? hive : firebase;
  }
}
