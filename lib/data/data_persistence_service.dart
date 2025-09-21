import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'globals.dart';
import 'rehabilitation_plan.dart';

/// Service to manage automatic data persistence
class DataPersistenceService {
  static final DataPersistenceService _instance = DataPersistenceService._internal();
  static DataPersistenceService get instance => _instance;
  DataPersistenceService._internal();

  Timer? _autoSaveTimer;
  bool _isSaving = false;
  DateTime? _lastSaveTime;
  int _saveCount = 0;
  
  // Debounce settings
  static const Duration _autoSaveDelay = Duration(seconds: 2);
  static const Duration _maxSaveInterval = Duration(minutes: 5);
  
  /// Initialize the auto-save service
  void initialize() {
    print('DataPersistenceService: Initializing auto-save service');
    _startAutoSaveTimer();
  }
  
  /// Dispose the service
  void dispose() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = null;
  }
  
  /// Start the auto-save timer
  void _startAutoSaveTimer() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(_maxSaveInterval, (timer) {
      _performAutoSave();
    });
  }
  
  /// Trigger an immediate save (with debouncing)
  void triggerSave({String? reason}) {
    if (kDebugMode && reason != null) {
      print('DataPersistenceService: Save triggered - $reason');
    }
    
    // Cancel existing timer and start a new one
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(_autoSaveDelay, () {
      _performAutoSave();
    });
  }
  
  /// Perform the actual save operation
  Future<void> _performAutoSave() async {
    if (_isSaving) {
      print('DataPersistenceService: Save already in progress, skipping');
      return;
    }
    
    _isSaving = true;
    _saveCount++;
    
    try {
      final startTime = DateTime.now();
      print('DataPersistenceService: Starting auto-save #$_saveCount');
      
      await saveAllDataToHive();
      
      _lastSaveTime = DateTime.now();
      final duration = _lastSaveTime!.difference(startTime);
      
      print('DataPersistenceService: Auto-save #$_saveCount completed in ${duration.inMilliseconds}ms');
      
      // Restart the periodic timer
      _startAutoSaveTimer();
      
    } catch (e) {
      print('DataPersistenceService: Error during auto-save: $e');
    } finally {
      _isSaving = false;
    }
  }
  
  /// Force an immediate save (bypasses debouncing)
  Future<void> forceSave({String? reason}) async {
    if (kDebugMode && reason != null) {
      print('DataPersistenceService: Force save triggered - $reason');
    }
    
    // Cancel any pending auto-save
    _autoSaveTimer?.cancel();
    
    if (_isSaving) {
      print('DataPersistenceService: Save already in progress, waiting...');
      // Wait for current save to complete
      while (_isSaving) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
    
    await _performAutoSave();
  }
  
  /// Get save statistics
  Map<String, dynamic> getSaveStatistics() {
    return {
      'saveCount': _saveCount,
      'lastSaveTime': _lastSaveTime?.toIso8601String(),
      'isSaving': _isSaving,
      'autoSaveEnabled': _autoSaveTimer?.isActive ?? false,
    };
  }
  
  /// Save all data to Hive with enhanced error handling
  static Future<void> saveAllDataToHive() async {
    try {
      print('DataPersistenceService: Saving all data to Hive...');
      
      // Verify Hive box is open
      if (!Hive.isBoxOpen('rehabBox')) {
        print('DataPersistenceService: Hive box not open, attempting to open...');
        await Hive.openBox('rehabBox');
      }
      
      final box = Hive.box('rehabBox');
      
      // Save rehabilitation plans and treatments
      await UserRehabilitation.instance.savePlansToHive();
      
      // Save pain history
      await PainHistory.saveToHive();
      
      // Save exercise history
      await ExerciseHistory.saveToHive();
      
      // Save user data
      await UserDetails.saveToHive();
      await UserProgress.saveToHive();
      await UserAssess.saveToHive();
      await UserSettings.saveToHive();
      await ActiveProgram.saveToHive();
      
      // Save metadata about the save operation
      await box.put('lastSaveTimestamp', DateTime.now().toIso8601String());
      await box.put('saveVersion', '1.0');
      
      print('DataPersistenceService: Successfully saved all data to Hive');
      
    } catch (e) {
      print('DataPersistenceService: Error saving data to Hive: $e');
      print('DataPersistenceService: Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }
  
  /// Load all data from Hive with enhanced error handling and parallel loading
  static Future<void> loadAllDataFromHive() async {
    try {
      print('DataPersistenceService: Loading all data from Hive...');
      
      // Verify Hive box is open
      if (!Hive.isBoxOpen('rehabBox')) {
        print('DataPersistenceService: Hive box not open, attempting to open...');
        await Hive.openBox('rehabBox');
      }
      
      final box = Hive.box('rehabBox');
      
      // Load all data in parallel for faster startup
      await Future.wait([
        // Load rehabilitation plans and treatments
        UserRehabilitation.instance.loadPlansFromHive(),
        
        // Load user data in parallel
        UserDetails.loadFromHive(),
        UserProgress.loadFromHive(),
        UserAssess.loadFromHive(),
        UserSettings.loadFromHive(),
        ActiveProgram.loadFromHive(),
        
        // Load history data in parallel
        PainHistory.loadFromHive(),
        ExerciseHistory.loadFromHive(),
      ]);
      
      // Load and verify metadata
      final lastSaveTimestamp = box.get('lastSaveTimestamp');
      final saveVersion = box.get('saveVersion', defaultValue: 'unknown');
      
      print('DataPersistenceService: Successfully loaded all data from Hive');
      print('DataPersistenceService: Last save: $lastSaveTimestamp, Version: $saveVersion');
      
    } catch (e) {
      print('DataPersistenceService: Error loading data from Hive: $e');
      print('DataPersistenceService: Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }
  
  /// Create a backup of all data
  static Future<Map<String, dynamic>> createBackup() async {
    try {
      print('DataPersistenceService: Creating data backup...');
      
      final box = Hive.box('rehabBox');
      final backup = <String, dynamic>{};
      
      // Backup all keys in the box
      for (final key in box.keys) {
        backup[key.toString()] = box.get(key);
      }
      
      // Add backup metadata
      backup['backupTimestamp'] = DateTime.now().toIso8601String();
      backup['backupVersion'] = '1.0';
      
      print('DataPersistenceService: Backup created with ${backup.length} entries');
      return backup;
      
    } catch (e) {
      print('DataPersistenceService: Error creating backup: $e');
      rethrow;
    }
  }
  
  /// Restore data from backup
  static Future<void> restoreFromBackup(Map<String, dynamic> backup) async {
    try {
      print('DataPersistenceService: Restoring data from backup...');
      
      final box = Hive.box('rehabBox');
      
      // Clear existing data
      await box.clear();
      
      // Restore all data from backup
      for (final entry in backup.entries) {
        if (entry.key != 'backupTimestamp' && entry.key != 'backupVersion') {
          await box.put(entry.key, entry.value);
        }
      }
      
      // Reload all data into memory
      await loadAllDataFromHive();
      
      print('DataPersistenceService: Successfully restored data from backup');
      
    } catch (e) {
      print('DataPersistenceService: Error restoring from backup: $e');
      rethrow;
    }
  }
  
  /// Validate data integrity
  static Future<bool> validateDataIntegrity() async {
    try {
      print('DataPersistenceService: Validating data integrity...');
      
      final box = Hive.box('rehabBox');
      
      // Check if critical data exists
      final hasUserDetails = box.containsKey('userDetails');
      final hasUserProgress = box.containsKey('userProgress');
      final hasUserAssess = box.containsKey('userAssess');
      final hasUserSettings = box.containsKey('userSettings');
      
      // Check data consistency
      final rehabIntegrity = await UserRehabilitation.instance.verifyDataIntegrity();
      
      final isValid = hasUserDetails && hasUserProgress && hasUserAssess && 
                     hasUserSettings && rehabIntegrity;
      
      print('DataPersistenceService: Data integrity validation ${isValid ? 'passed' : 'failed'}');
      return isValid;
      
    } catch (e) {
      print('DataPersistenceService: Error validating data integrity: $e');
      return false;
    }
  }
}
