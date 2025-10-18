# Unified Data Models API Documentation

## Overview
This document provides comprehensive API documentation for the unified data models and services that align Hive and Firebase data handling in PocketPT.

## Table of Contents
1. [Unified Data Models](#unified-data-models)
2. [Unified Firebase Service](#unified-firebase-service)
3. [Unified Sync Service](#unified-sync-service)
4. [Migration Services](#migration-services)
5. [Error Handling](#error-handling)
6. [Usage Examples](#usage-examples)

## Unified Data Models

### UnifiedUserDetails
Represents user profile information with consistent schema across Hive and Firebase.

#### Properties
- `userId` (String): Unique user identifier
- `firstName` (String): User's first name
- `lastName` (String): User's last name
- `email` (String): User's email address
- `password` (String): User's password (Hive only)
- `profilePicture` (String): Profile picture filename
- `hasCompletedAssessment` (bool): Whether user completed assessment
- `isGuest` (bool): Whether user is in guest mode
- `guestSessionId` (String?): Guest session identifier
- `notifications` (List<String>): List of notifications
- `lastModified` (DateTime?): Last modification timestamp

#### Methods
- `toHiveMap()`: Convert to Hive storage format
- `toFirebaseMap()`: Convert to Firebase storage format
- `validate()`: Validate data integrity
- `copyWith()`: Create copy with modified fields

#### Example
```dart
final userDetails = UnifiedUserDetails(
  userId: 'user123',
  firstName: 'John',
  lastName: 'Doe',
  email: 'john@example.com',
  password: 'password123',
  profilePicture: '01.jpg',
  hasCompletedAssessment: true,
  isGuest: false,
  guestSessionId: null,
  notifications: ['welcome'],
  lastModified: DateTime.now(),
);

// Save to Hive
final hiveMap = userDetails.toHiveMap();

// Save to Firebase
final firebaseMap = userDetails.toFirebaseMap();

// Validate
if (userDetails.validate()) {
  print('User details are valid');
}
```

### UnifiedUserProgress
Represents user progress tracking with consistent schema.

#### Properties
- `userId` (String): Unique user identifier
- `title` (String): Progress title
- `titleColor` (String): Title color
- `streak` (int): Current streak count
- `totalDays` (int): Total days tracked
- `totalExercises` (int): Total exercises completed
- `totalSeconds` (int): Total exercise time in seconds
- `notes` (String?): Optional notes
- `lastExerciseDate` (DateTime?): Last exercise date
- `lastModified` (DateTime?): Last modification timestamp

#### Methods
- `toHiveMap()`: Convert to Hive storage format
- `toFirebaseMap()`: Convert to Firebase storage format
- `validate()`: Validate data integrity
- `copyWith()`: Create copy with modified fields

### UnifiedUserSettings
Represents user preferences and settings.

#### Properties
- `userId` (String): Unique user identifier
- `isDailyReminder` (bool): Daily reminder enabled
- `isStreakAlert` (bool): Streak alert enabled
- `isExerciseReminder` (bool): Exercise reminder enabled
- `exerciseReminderHour` (int): Reminder hour (0-23)
- `exerciseReminderMinute` (int): Reminder minute (0-59)
- `lastModified` (DateTime?): Last modification timestamp

#### Methods
- `toHiveMap()`: Convert to Hive storage format
- `toFirebaseMap()`: Convert to Firebase storage format
- `validate()`: Validate data integrity
- `copyWith()`: Create copy with modified fields
- `exerciseReminderTime`: Get TimeOfDay object

### UnifiedPainRecordEntry
Represents a single pain assessment entry.

#### Properties
- `userId` (String): Unique user identifier
- `date` (DateTime): Assessment date
- `painScale` (int): Pain scale (0-10)
- `painLevel` (String): Pain level description
- `lastModified` (DateTime?): Last modification timestamp

#### Methods
- `toHiveMap()`: Convert to Hive storage format
- `toFirebaseMap()`: Convert to Firebase storage format
- `validate()`: Validate data integrity
- `copyWith()`: Create copy with modified fields

### UnifiedExerciseRecordEntry
Represents a single exercise completion entry.

#### Properties
- `userId` (String): Unique user identifier
- `date` (DateTime): Exercise date
- `exerciseId` (String): Exercise identifier
- `exerciseName` (String): Exercise name
- `sets` (int): Number of sets
- `reps` (int): Number of repetitions
- `durationSeconds` (int): Exercise duration
- `status` (String): Completion status
- `lastModified` (DateTime?): Last modification timestamp

#### Methods
- `toHiveMap()`: Convert to Hive storage format
- `toFirebaseMap()`: Convert to Firebase storage format
- `validate()`: Validate data integrity
- `copyWith()`: Create copy with modified fields

### UnifiedRehabilitationPlan
Represents a rehabilitation plan with ID-only references.

#### Properties
- `userId` (String): Unique user identifier
- `exerciseIds` (List<String>): List of exercise IDs
- `treatmentIds` (List<String>): List of treatment IDs
- `weekNumber` (int): Week number
- `lastModified` (DateTime?): Last modification timestamp

#### Methods
- `toHiveMap()`: Convert to Hive storage format
- `toFirebaseMap()`: Convert to Firebase storage format
- `validate()`: Validate data integrity
- `copyWith()`: Create copy with modified fields

## Unified Firebase Service

### UnifiedFirebaseService
Handles all Firebase operations with consistent schema.

#### Methods

##### UserDetails Operations
- `saveUserDetails(UnifiedUserDetails)`: Save user details to Firebase
- `loadUserDetails()`: Load user details from Firebase

##### UserProgress Operations
- `saveUserProgress(UnifiedUserProgress)`: Save user progress to Firebase
- `loadUserProgress()`: Load user progress from Firebase

##### UserSettings Operations
- `saveUserSettings(UnifiedUserSettings)`: Save user settings to Firebase
- `loadUserSettings()`: Load user settings from Firebase

##### History Operations
- `savePainHistory(List<UnifiedPainRecordEntry>)`: Save pain history to Firebase
- `loadPainHistory()`: Load pain history from Firebase
- `saveExerciseHistory(List<UnifiedExerciseRecordEntry>)`: Save exercise history to Firebase
- `loadExerciseHistory()`: Load exercise history from Firebase

##### Rehabilitation Plans Operations
- `saveRehabilitationPlans(List<UnifiedRehabilitationPlan>)`: Save rehabilitation plans to Firebase
- `loadRehabilitationPlans()`: Load rehabilitation plans from Firebase

##### Utility Methods
- `createDefaultUserDocument(String)`: Create default user document
- `userDocumentExists(String)`: Check if user document exists
- `deleteUserData(String)`: Delete all user data
- `syncData()`: Sync data between Hive and Firebase

#### Example
```dart
// Save user details
final userDetails = UnifiedUserDetails(/* ... */);
final success = await UnifiedFirebaseService.saveUserDetails(userDetails);

// Load user details
final loadedUserDetails = await UnifiedFirebaseService.loadUserDetails();

// Create default user document
await UnifiedFirebaseService.createDefaultUserDocument('user123');
```

## Unified Sync Service

### UnifiedSyncService
Handles synchronization between Hive and Firebase with offline-first strategy.

#### Methods

##### Data Operations
- `saveUserDetails(UnifiedUserDetails)`: Save with automatic sync
- `loadUserDetails()`: Load with automatic sync
- `saveUserProgress(UnifiedUserProgress)`: Save with automatic sync
- `loadUserProgress()`: Load with automatic sync
- `saveUserSettings(UnifiedUserSettings)`: Save with automatic sync
- `loadUserSettings()`: Load with automatic sync

##### Sync Operations
- `performFullSync()`: Perform complete data sync
- `initialize()`: Initialize sync service
- `getSyncStatus()`: Get current sync status
- `setSyncStatus(SyncStatus)`: Set sync status
- `getLastSyncTimestamp()`: Get last sync timestamp

#### Sync Status
- `idle`: No sync in progress
- `syncing`: Sync in progress
- `error`: Sync error occurred
- `offline`: Device is offline

#### Example
```dart
// Initialize sync service
await UnifiedSyncService.initialize();

// Save data with automatic sync
final userDetails = UnifiedUserDetails(/* ... */);
await UnifiedSyncService.saveUserDetails(userDetails);

// Load data with automatic sync
final loadedUserDetails = await UnifiedSyncService.loadUserDetails();

// Perform full sync
await UnifiedSyncService.performFullSync();

// Check sync status
final status = await UnifiedSyncService.getSyncStatus();
```

## Migration Services

### HiveMigrationService
Handles migration of existing Hive data to unified schema.

#### Methods
- `isMigrationNeeded()`: Check if migration is needed
- `performMigration()`: Perform complete migration
- `validateMigration()`: Validate migrated data
- `rollbackMigration()`: Rollback migration

#### Example
```dart
// Check if migration is needed
if (await HiveMigrationService.isMigrationNeeded()) {
  // Perform migration
  final success = await HiveMigrationService.performMigration();
  if (success) {
    // Validate migration
    final valid = await HiveMigrationService.validateMigration();
    if (!valid) {
      // Rollback if validation fails
      await HiveMigrationService.rollbackMigration();
    }
  }
}
```

### FirebaseMigrationService
Handles migration of existing Firebase data to unified schema.

#### Methods
- `isMigrationNeeded()`: Check if migration is needed
- `performMigration()`: Perform complete migration
- `validateMigration()`: Validate migrated data
- `createBackup()`: Create backup before migration
- `restoreFromBackup(String)`: Restore from backup

#### Example
```dart
// Check if migration is needed
if (await FirebaseMigrationService.isMigrationNeeded()) {
  // Create backup
  await FirebaseMigrationService.createBackup();
  
  // Perform migration
  final success = await FirebaseMigrationService.performMigration();
  if (!success) {
    // Restore from backup
    await FirebaseMigrationService.restoreFromBackup('backup_id');
  }
}
```

## Error Handling

### ErrorHandlingService
Provides comprehensive error handling with user-friendly messages.

#### Error Types
- `networkError`: Network connectivity issues
- `dataCorruption`: Data corruption detected
- `syncFailure`: Synchronization failures
- `migrationError`: Migration failures
- `validationError`: Data validation failures
- `authenticationError`: Authentication issues
- `storageError`: Storage operation failures
- `unknownError`: Unknown errors

#### Error Severity
- `low`: Minor issues
- `medium`: Moderate issues
- `high`: Significant issues
- `critical`: Critical issues requiring immediate attention

#### Methods
- `handleError()`: Handle and log errors
- `showErrorDialog()`: Show error dialog to user
- `showErrorSnackBar()`: Show error snackbar
- `getRetrySuggestion()`: Get retry suggestion
- `getRecoveryActions()`: Get recovery actions

#### Example
```dart
try {
  await UnifiedSyncService.performFullSync();
} catch (e) {
  final errorInfo = ErrorHandlingService.handleError(
    e,
    context: 'Full sync operation',
  );
  
  // Show error to user
  ErrorHandlingService.showErrorSnackBar(context, errorInfo);
  
  // Get retry suggestion
  final suggestion = ErrorHandlingService.getRetrySuggestion(errorInfo.type);
  print('Retry suggestion: $suggestion');
}
```

## Usage Examples

### Complete Data Flow Example
```dart
// Initialize services
await UnifiedSyncService.initialize();

// Create user details
final userDetails = UnifiedUserDetails(
  userId: 'user123',
  firstName: 'John',
  lastName: 'Doe',
  email: 'john@example.com',
  password: 'password123',
  profilePicture: '01.jpg',
  hasCompletedAssessment: false,
  isGuest: false,
  guestSessionId: null,
  notifications: [],
  lastModified: DateTime.now(),
);

// Save with automatic sync
await UnifiedSyncService.saveUserDetails(userDetails);

// Load with automatic sync
final loadedUserDetails = await UnifiedSyncService.loadUserDetails();

// Update and save again
final updatedUserDetails = loadedUserDetails!.copyWith(
  hasCompletedAssessment: true,
  lastModified: DateTime.now(),
);

await UnifiedSyncService.saveUserDetails(updatedUserDetails);

// Perform full sync
await UnifiedSyncService.performFullSync();
```

### Error Handling Example
```dart
try {
  // Perform data operation
  await UnifiedSyncService.performFullSync();
} catch (e) {
  // Handle error
  final errorInfo = ErrorHandlingService.handleError(
    e,
    context: 'Full sync operation',
  );
  
  // Show appropriate error message
  if (errorInfo.severity == ErrorSeverity.critical) {
    ErrorHandlingService.showErrorDialog(context, errorInfo);
  } else {
    ErrorHandlingService.showErrorSnackBar(context, errorInfo);
  }
  
  // Get recovery actions
  final recoveryActions = ErrorHandlingService.getRecoveryActions(errorInfo.type);
  print('Available recovery actions: $recoveryActions');
}
```

### Migration Example
```dart
// Check and perform Hive migration
if (await HiveMigrationService.isMigrationNeeded()) {
  final success = await HiveMigrationService.performMigration();
  if (!success) {
    await HiveMigrationService.rollbackMigration();
  }
}

// Check and perform Firebase migration
if (await FirebaseMigrationService.isMigrationNeeded()) {
  await FirebaseMigrationService.createBackup();
  final success = await FirebaseMigrationService.performMigration();
  if (!success) {
    await FirebaseMigrationService.restoreFromBackup('backup_id');
  }
}
```

## Best Practices

### Data Validation
- Always validate data before saving
- Use the `validate()` method on all unified models
- Handle validation failures gracefully

### Error Handling
- Use ErrorHandlingService for all error handling
- Provide user-friendly error messages
- Implement appropriate recovery actions

### Synchronization
- Use UnifiedSyncService for all data operations
- Implement offline-first strategy
- Handle sync conflicts appropriately

### Migration
- Always create backups before migration
- Validate migrated data
- Implement rollback procedures

### Performance
- Use batch operations when possible
- Implement proper caching strategies
- Monitor sync performance

## Troubleshooting

### Common Issues

#### Sync Failures
- Check network connectivity
- Verify Firebase configuration
- Check for data validation errors

#### Migration Failures
- Ensure sufficient storage space
- Check for data corruption
- Verify backup integrity

#### Data Corruption
- Use data validation tools
- Implement repair procedures
- Restore from backups if necessary

#### Performance Issues
- Monitor sync queue size
- Implement proper caching
- Optimize data operations

### Debug Information
- Enable debug logging
- Monitor sync status
- Track error patterns
- Use performance monitoring tools
