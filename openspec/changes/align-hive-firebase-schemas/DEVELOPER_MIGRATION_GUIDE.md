# Developer Migration Guide

## Overview
This guide provides step-by-step instructions for migrating existing PocketPT code to use the unified data models and services.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Migration Steps](#migration-steps)
3. [Code Changes](#code-changes)
4. [Testing](#testing)
5. [Deployment](#deployment)
6. [Troubleshooting](#troubleshooting)

## Prerequisites

### Required Dependencies
Ensure the following dependencies are added to `pubspec.yaml`:

```yaml
dependencies:
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  firebase_core: ^2.24.2
  firebase_auth: ^4.15.3
  cloud_firestore: ^4.13.6
  flutter:
    sdk: flutter

dev_dependencies:
  hive_generator: ^2.0.1
  build_runner: ^2.4.7
```

### Required Files
Ensure the following files are present in your project:
- `lib/data/unified_data_models.dart`
- `lib/data/unified_hive_models.dart`
- `lib/data/unified_firebase_service.dart`
- `lib/data/unified_sync_service.dart`
- `lib/data/hive_migration_service.dart`
- `lib/data/firebase_migration_service.dart`
- `lib/data/error_handling_service.dart`
- `lib/data/migration_test_service.dart`

## Migration Steps

### Step 1: Generate Hive Adapters
Run the following command to generate Hive adapters:

```bash
flutter packages pub run build_runner build
```

### Step 2: Update Imports
Replace existing imports with unified service imports:

```dart
// Old imports
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// New imports
import 'package:PocketPT/data/unified_sync_service.dart';
import 'package:PocketPT/data/error_handling_service.dart';
```

### Step 3: Initialize Services
Add service initialization to your app startup:

```dart
// In main.dart or app initialization
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Initialize unified sync service
  await UnifiedSyncService.initialize();
  
  runApp(MyApp());
}
```

### Step 4: Update Data Operations
Replace existing data operations with unified service calls.

## Code Changes

### UserDetails Migration

#### Before (Old Code)
```dart
// Old Hive operations
final box = await Hive.openBox('rehabBox');
final userDetails = box.get('userDetails');
if (userDetails != null) {
  UserDetails.firstName = userDetails['firstName'];
  UserDetails.lastName = userDetails['lastName'];
  // ... other fields
}

// Old Firebase operations
await _firestore.collection('users').doc(userId).set({
  'firstName': UserDetails.firstName,
  'lastName': UserDetails.lastName,
  // ... other fields
});
```

#### After (New Code)
```dart
// New unified operations
try {
  // Load user details with automatic sync
  final userDetails = await UnifiedSyncService.loadUserDetails();
  if (userDetails != null) {
    // Use unified model
    print('User: ${userDetails.firstName} ${userDetails.lastName}');
  }
  
  // Save user details with automatic sync
  final updatedUserDetails = userDetails?.copyWith(
    firstName: 'New Name',
    lastModified: DateTime.now(),
  );
  if (updatedUserDetails != null) {
    await UnifiedSyncService.saveUserDetails(updatedUserDetails);
  }
} catch (e) {
  // Handle errors with user-friendly messages
  final errorInfo = ErrorHandlingService.handleError(
    e,
    context: 'User details operation',
  );
  ErrorHandlingService.showErrorSnackBar(context, errorInfo);
}
```

### UserProgress Migration

#### Before (Old Code)
```dart
// Old Hive operations
final box = await Hive.openBox('rehabBox');
final userProgress = box.get('userProgress');
if (userProgress != null) {
  UserProgress.title = userProgress['title'];
  UserProgress.streak = userProgress['streak'];
  // ... other fields
}
```

#### After (New Code)
```dart
// New unified operations
try {
  // Load user progress with automatic sync
  final userProgress = await UnifiedSyncService.loadUserProgress();
  if (userProgress != null) {
    // Use unified model
    print('Progress: ${userProgress.title} - Streak: ${userProgress.streak}');
  }
  
  // Save user progress with automatic sync
  final updatedProgress = userProgress?.copyWith(
    streak: userProgress.streak + 1,
    lastModified: DateTime.now(),
  );
  if (updatedProgress != null) {
    await UnifiedSyncService.saveUserProgress(updatedProgress);
  }
} catch (e) {
  // Handle errors
  final errorInfo = ErrorHandlingService.handleError(
    e,
    context: 'User progress operation',
  );
  ErrorHandlingService.showErrorSnackBar(context, errorInfo);
}
```

### UserSettings Migration

#### Before (Old Code)
```dart
// Old Hive operations
final box = await Hive.openBox('rehabBox');
final userSettings = box.get('userSettings');
if (userSettings != null) {
  UserSettings.isDailyReminder = userSettings['isDailyReminder'];
  UserSettings.exerciseReminderTime = TimeOfDay(
    hour: userSettings['exerciseReminderHour'],
    minute: userSettings['exerciseReminderMinute'],
  );
  // ... other fields
}
```

#### After (New Code)
```dart
// New unified operations
try {
  // Load user settings with automatic sync
  final userSettings = await UnifiedSyncService.loadUserSettings();
  if (userSettings != null) {
    // Use unified model
    print('Daily reminder: ${userSettings.isDailyReminder}');
    print('Exercise reminder: ${userSettings.exerciseReminderTime}');
  }
  
  // Save user settings with automatic sync
  final updatedSettings = userSettings?.copyWith(
    isDailyReminder: !userSettings.isDailyReminder,
    lastModified: DateTime.now(),
  );
  if (updatedSettings != null) {
    await UnifiedSyncService.saveUserSettings(updatedSettings);
  }
} catch (e) {
  // Handle errors
  final errorInfo = ErrorHandlingService.handleError(
    e,
    context: 'User settings operation',
  );
  ErrorHandlingService.showErrorSnackBar(context, errorInfo);
}
```

### Pain History Migration

#### Before (Old Code)
```dart
// Old Hive operations
final box = await Hive.openBox('rehabBox');
final painHistory = box.get('painHistory', defaultValue: <Map<String, dynamic>>[]);
painHistory.add({
  'date': DateTime.now().millisecondsSinceEpoch,
  'painScale': painScale,
  'painLevel': painLevel,
});
await box.put('painHistory', painHistory);
```

#### After (New Code)
```dart
// New unified operations
try {
  // Load pain history with automatic sync
  final painHistory = await UnifiedFirebaseService.loadPainHistory();
  
  // Create new pain entry
  final newEntry = UnifiedPainRecordEntry(
    userId: 'current_user_id',
    date: DateTime.now(),
    painScale: painScale,
    painLevel: painLevel,
    lastModified: DateTime.now(),
  );
  
  // Add to history
  final updatedHistory = [...painHistory, newEntry];
  
  // Save with automatic sync
  await UnifiedFirebaseService.savePainHistory(updatedHistory);
} catch (e) {
  // Handle errors
  final errorInfo = ErrorHandlingService.handleError(
    e,
    context: 'Pain history operation',
  );
  ErrorHandlingService.showErrorSnackBar(context, errorInfo);
}
```

### Exercise History Migration

#### Before (Old Code)
```dart
// Old Hive operations
final box = await Hive.openBox('rehabBox');
final exerciseHistory = box.get('exerciseHistory', defaultValue: <Map<String, dynamic>>[]);
exerciseHistory.add({
  'date': DateTime.now().millisecondsSinceEpoch,
  'exerciseId': exerciseId,
  'exerciseName': exerciseName,
  'sets': sets,
  'reps': reps,
  'durationSeconds': durationSeconds,
  'status': status,
});
await box.put('exerciseHistory', exerciseHistory);
```

#### After (New Code)
```dart
// New unified operations
try {
  // Load exercise history with automatic sync
  final exerciseHistory = await UnifiedFirebaseService.loadExerciseHistory();
  
  // Create new exercise entry
  final newEntry = UnifiedExerciseRecordEntry(
    userId: 'current_user_id',
    date: DateTime.now(),
    exerciseId: exerciseId,
    exerciseName: exerciseName,
    sets: sets,
    reps: reps,
    durationSeconds: durationSeconds,
    status: status,
    lastModified: DateTime.now(),
  );
  
  // Add to history
  final updatedHistory = [...exerciseHistory, newEntry];
  
  // Save with automatic sync
  await UnifiedFirebaseService.saveExerciseHistory(updatedHistory);
} catch (e) {
  // Handle errors
  final errorInfo = ErrorHandlingService.handleError(
    e,
    context: 'Exercise history operation',
  );
  ErrorHandlingService.showErrorSnackBar(context, errorInfo);
}
```

### Rehabilitation Plans Migration

#### Before (Old Code)
```dart
// Old Hive operations
final box = await Hive.openBox('rehabBox');
final exerciseIds = box.get('exerciseIds', defaultValue: <String>[]);
final treatmentIds = box.get('treatmentIds', defaultValue: <String>[]);
```

#### After (New Code)
```dart
// New unified operations
try {
  // Load rehabilitation plans with automatic sync
  final rehabilitationPlans = await UnifiedFirebaseService.loadRehabilitationPlans();
  
  // Create new plan
  final newPlan = UnifiedRehabilitationPlan(
    userId: 'current_user_id',
    exerciseIds: exerciseIds,
    treatmentIds: treatmentIds,
    weekNumber: 1,
    lastModified: DateTime.now(),
  );
  
  // Add to plans
  final updatedPlans = [...rehabilitationPlans, newPlan];
  
  // Save with automatic sync
  await UnifiedFirebaseService.saveRehabilitationPlans(updatedPlans);
} catch (e) {
  // Handle errors
  final errorInfo = ErrorHandlingService.handleError(
    e,
    context: 'Rehabilitation plans operation',
  );
  ErrorHandlingService.showErrorSnackBar(context, errorInfo);
}
```

## Testing

### Unit Tests
Create unit tests for your migrated code:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:PocketPT/data/migration_test_service.dart';

void main() {
  group('Migration Tests', () {
    test('Hive migration test', () async {
      final result = await MigrationTestService.testHiveMigration();
      expect(result, true);
    });
    
    test('Firebase migration test', () async {
      final result = await MigrationTestService.testFirebaseMigration();
      expect(result, true);
    });
    
    test('Unified sync service test', () async {
      final result = await MigrationTestService.testUnifiedSyncService();
      expect(result, true);
    });
    
    test('Data validation test', () async {
      final result = await MigrationTestService.testDataValidationAndRepair();
      expect(result, true);
    });
    
    test('Conflict resolution test', () async {
      final result = await MigrationTestService.testConflictResolution();
      expect(result, true);
    });
  });
}
```

### Integration Tests
Test the complete migration process:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:PocketPT/data/migration_test_service.dart';

void main() {
  group('Integration Tests', () {
    test('Complete migration test', () async {
      final result = await MigrationTestService.runAllTests();
      expect(result, true);
    });
  });
}
```

## Deployment

### Pre-deployment Checklist
- [ ] All unit tests pass
- [ ] Integration tests pass
- [ ] Migration tests pass
- [ ] Error handling is implemented
- [ ] User data is backed up
- [ ] Rollback procedures are tested

### Deployment Steps
1. **Backup User Data**
   ```dart
   // Create backup before deployment
   await FirebaseMigrationService.createBackup();
   ```

2. **Deploy Code**
   - Deploy the updated code to production
   - Monitor for any immediate issues

3. **Monitor Migration**
   - Check migration logs
   - Monitor error rates
   - Verify data integrity

4. **Validate Deployment**
   - Run post-deployment tests
   - Verify user data integrity
   - Check sync functionality

### Rollback Procedures
If issues occur during deployment:

1. **Immediate Rollback**
   ```dart
   // Rollback Hive migration
   await HiveMigrationService.rollbackMigration();
   
   // Restore Firebase from backup
   await FirebaseMigrationService.restoreFromBackup('backup_id');
   ```

2. **Code Rollback**
   - Revert to previous code version
   - Restart application
   - Verify functionality

## Troubleshooting

### Common Issues

#### Migration Failures
**Problem**: Migration fails during deployment
**Solution**: 
- Check error logs
- Verify data integrity
- Use rollback procedures
- Contact support if needed

#### Sync Issues
**Problem**: Data not syncing between Hive and Firebase
**Solution**:
- Check network connectivity
- Verify Firebase configuration
- Check sync status
- Perform manual sync

#### Data Corruption
**Problem**: Data becomes corrupted after migration
**Solution**:
- Use data validation tools
- Restore from backup
- Repair corrupted data
- Contact support if needed

#### Performance Issues
**Problem**: App performance degrades after migration
**Solution**:
- Monitor sync queue size
- Optimize data operations
- Implement proper caching
- Use performance monitoring tools

### Debug Information
Enable debug logging to troubleshoot issues:

```dart
// Enable debug logging
import 'package:flutter/foundation.dart';

void main() {
  if (kDebugMode) {
    // Enable debug logging
    debugPrint('Debug mode enabled');
  }
  runApp(MyApp());
}
```

### Support
If you encounter issues during migration:

1. Check the error logs
2. Review the troubleshooting guide
3. Test with sample data
4. Contact the development team
5. Provide detailed error information

## Best Practices

### Code Organization
- Keep unified services in separate files
- Use consistent naming conventions
- Implement proper error handling
- Add comprehensive logging

### Data Management
- Always validate data before saving
- Implement proper backup procedures
- Use offline-first strategy
- Handle sync conflicts appropriately

### Performance
- Use batch operations when possible
- Implement proper caching
- Monitor sync performance
- Optimize data operations

### Security
- Never store sensitive data in plain text
- Use proper authentication
- Implement data encryption
- Follow security best practices

## Conclusion

This migration guide provides comprehensive instructions for migrating to the unified data models and services. Follow the steps carefully and test thoroughly before deployment. If you encounter any issues, refer to the troubleshooting section or contact the development team for support.
