# PocketPT Database Structure Documentation

## Overview

The PocketPT application uses a dual-database architecture combining **Hive** (local storage) and **Firebase** (cloud storage) to provide both offline functionality and cloud synchronization. This document provides a comprehensive overview of how data is structured, saved, and loaded in both systems.

## Architecture Summary

- **Hive**: Local NoSQL database for offline access and fast data retrieval
- **Firebase**: Cloud Firestore for data persistence and cross-device synchronization
- **Data Sync**: Automatic synchronization between local and cloud storage
- **Offline Support**: Full functionality available without internet connection

---

## Hive Database Structure

### Storage Configuration
- **Box Name**: `rehabBox`
- **Type**: NoSQL key-value store
- **Location**: Local device storage
- **Adapters**: 13 registered adapters with unique type IDs

### Hive Models and Data Types

#### 1. HiveUserDetails (typeId: 6)
**Purpose**: Stores user account information
```dart
@HiveType(typeId: 6)
class HiveUserDetails extends HiveObject {
  @HiveField(0) String firstName;        // String
  @HiveField(1) String lastName;         // String
  @HiveField(2) String email;            // String
  @HiveField(3) String password;         // String (stored but not used in Firebase)
  @HiveField(4) List<String> notifications; // List<String>
  @HiveField(5) bool isGuest;            // Boolean
  @HiveField(6) String? guestSessionId;  // String (nullable)
  @HiveField(7) String profilePicture;   // String
}
```
**Storage Key**: `userDetails`

#### 2. HiveUserProgress (typeId: 3)
**Purpose**: Tracks user's fitness progress and statistics
```dart
@HiveType(typeId: 3)
class HiveUserProgress extends HiveObject {
  @HiveField(0) String title;            // String
  @HiveField(1) String titleColor;       // String
  @HiveField(2) int streak;              // Integer
  @HiveField(3) int totalDays;           // Integer
  @HiveField(4) int totalExercises;      // Integer
  @HiveField(5) int totalSeconds;        // Integer
  @HiveField(6) String? notes;           // String (nullable)
  @HiveField(7) DateTime? lastExerciseDate; // DateTime (nullable)
}
```
**Storage Key**: `userProgress`

#### 3. HiveUserAssess (typeId: 4)
**Purpose**: Stores initial assessment data
```dart
@HiveType(typeId: 4)
class HiveUserAssess extends HiveObject {
  @HiveField(0) String rehabGoal;        // String
  @HiveField(1) String generalMuscle;    // String
  @HiveField(2) String specificMuscle;   // String
  @HiveField(3) int painScale;           // Integer (0-10)
  @HiveField(4) String painLevel;        // String
  @HiveField(5) String painType;         // String
  @HiveField(6) String painDuration;     // String
  @HiveField(7) bool isInjured;          // Boolean
  @HiveField(8) bool isAssessed;         // Boolean
}
```
**Storage Key**: `userAssess`

#### 4. HiveUserSettings (typeId: 5)
**Purpose**: User preferences and notification settings
```dart
@HiveType(typeId: 5)
class HiveUserSettings extends HiveObject {
  @HiveField(0) bool isDailyReminder;    // Boolean
  @HiveField(1) bool isStreakAlert;      // Boolean
  @HiveField(2) bool isExerciseReminder; // Boolean
  @HiveField(3) int exerciseReminderHour; // Integer (0-23)
  @HiveField(4) int exerciseReminderMinute; // Integer (0-59)
}
```
**Storage Key**: `userSettings`

#### 5. HiveActiveProgram (typeId: 7)
**Purpose**: Tracks the currently active rehabilitation program
```dart
@HiveType(typeId: 7)
class HiveActiveProgram extends HiveObject {
  @HiveField(0) DateTime? startDate;     // DateTime (nullable)
}
```
**Storage Key**: `activeProgram`

#### 6. HivePainRecordEntry (typeId: 1)
**Purpose**: Individual pain assessment entries
```dart
@HiveType(typeId: 1)
class HivePainRecordEntry extends HiveObject {
  @HiveField(0) DateTime date;           // DateTime
  @HiveField(1) int painScale;           // Integer (0-10)
  @HiveField(2) String painLevel;        // String
}
```
**Storage Key**: `painHistory` (List<HivePainRecordEntry>)

#### 7. HiveExerciseRecordEntry (typeId: 2)
**Purpose**: Individual exercise completion records
```dart
@HiveType(typeId: 2)
class HiveExerciseRecordEntry extends HiveObject {
  @HiveField(0) DateTime date;           // DateTime
  @HiveField(1) String exerciseId;       // String
  @HiveField(2) String exerciseName;     // String
  @HiveField(3) int sets;                // Integer
  @HiveField(4) int reps;                // Integer
  @HiveField(5) int durationSeconds;     // Integer
  @HiveField(6) String status;           // String ('completed', 'skipped', 'partial')
}
```
**Storage Key**: `exerciseHistory` (List<HiveExerciseRecordEntry>)

#### 8. HiveExerciseIds (typeId: 11)
**Purpose**: Stores exercise IDs for rehabilitation plans (ID-only storage)
```dart
@HiveType(typeId: 11)
class HiveExerciseIds extends HiveObject {
  @HiveField(0) List<String> exerciseIds; // List<String>
}
```
**Storage Key**: `exerciseIds`

#### 9. HiveTreatmentIds (typeId: 12)
**Purpose**: Stores treatment IDs (ID-only storage)
```dart
@HiveType(typeId: 12)
class HiveTreatmentIds extends HiveObject {
  @HiveField(0) List<String> treatmentIds; // List<String>
}
```
**Storage Key**: `treatmentIds`

#### 10. HiveDailyProgress (typeId: 0)
**Purpose**: Daily exercise completion tracking
```dart
@HiveType(typeId: 0)
class HiveDailyProgress extends HiveObject {
  @HiveField(0) DateTime date;           // DateTime
  @HiveField(1) Map<String, bool> completedExercises; // Map<String, bool>
}
```

#### 11. HiveRehabilitationPlan (typeId: 8)
**Purpose**: Complete rehabilitation plan structure
```dart
@HiveType(typeId: 8)
class HiveRehabilitationPlan extends HiveObject {
  @HiveField(0) int weekNumber;          // Integer
  @HiveField(1) List<HiveExerciseReference> exerciseReferences; // List<HiveExerciseReference>
  @HiveField(2) List<HiveDailyProgress> daily; // List<HiveDailyProgress>
}
```

#### 12. HiveExerciseReference (typeId: 9)
**Purpose**: Exercise reference within rehabilitation plans
```dart
@HiveType(typeId: 9)
class HiveExerciseReference extends HiveObject {
  @HiveField(0) String exerciseId;       // String
  @HiveField(1) int repetitions;         // Integer
  @HiveField(2) int sets;                // Integer
}
```

#### 13. HiveTreatmentReference (typeId: 10)
**Purpose**: Treatment reference
```dart
@HiveType(typeId: 10)
class HiveTreatmentReference extends HiveObject {
  @HiveField(0) String treatmentId;      // String
}
```

### Hive Data Operations

#### Save Operations
```dart
// Individual model saves
await UserDetails.saveToHive();
await UserProgress.saveToHive();
await UserAssess.saveToHive();
await UserSettings.saveToHive();
await ActiveProgram.saveToHive();
await PainHistory.saveToHive();
await ExerciseHistory.saveToHive();
await UserRehabilitation.instance.savePlansToHive();

// Bulk save
await DataPersistenceService.saveAllDataToHive();
```

#### Load Operations
```dart
// Individual model loads
await UserDetails.loadFromHive();
await UserProgress.loadFromHive();
await UserAssess.loadFromHive();
await UserSettings.loadFromHive();
await ActiveProgram.loadFromHive();
await PainHistory.loadFromHive();
await ExerciseHistory.loadFromHive();
await UserRehabilitation.instance.loadPlansFromHive();

// Bulk load
await DataPersistenceService.loadAllDataFromHive();
```

---

## Firebase Database Structure

### Firestore Collections

#### Collection Structure (ACTUAL IMPLEMENTATION)
```
users/
  └── {userId}/
      └── (user document)

rehabilitation/
  └── {userId}/
      └── (rehabilitation plans document)

progress/
  └── {userId}/
      └── (user progress document)

assessment/
  └── {userId}/
      └── (assessment data document)

settings/
  └── {userId}/
      └── (user settings document)

painHistory/
  └── {userId}/
      └── (pain history document)

exerciseHistory/
  └── {userId}/
      └── (exercise history document)
```

#### Main Collections

##### 1. users/{userId} (Main User Document)
**Collection**: `users`
**Document**: `{userId}`
```json
{
  "userId": "string",
  "firstName": "string",
  "lastName": "string", 
  "email": "string",
  "profilePicture": "string (optional)",
  "hasCompletedAssessment": "boolean (optional)",
  "createdAt": "timestamp",
  "lastUpdated": "timestamp"
}
```

**Note**: This is the primary user document. Other user data (progress, assessment, settings, history) is stored locally in Hive and not actively synced to Firebase subcollections.

##### 2. rehabilitation/{userId} (Rehabilitation Plans)
**Collection**: `rehabilitation`
**Document**: `{userId}`
```json
{
  "userId": "string",
  "lastUpdated": "timestamp",
  "Plan1": [
    {
      "exercise1": "string (exerciseId)",
      "exercise2": "string (exerciseId)",
      "exercise3": "string (exerciseId)"
    },
    {
      "treatment1": "string (treatmentId)",
      "treatment2": "string (treatmentId)",
      "treatment3": "string (treatmentId)"
    }
  ],
  "Plan2": [
    {
      "exercise1": "string (exerciseId)",
      "exercise2": "string (exerciseId)",
      "exercise3": "string (exerciseId)"
    },
    {
      "treatment1": "string (treatmentId)",
      "treatment2": "string (treatmentId)"
    }
  ]
}
```

**Note**: 
- Plans are incrementally numbered: `Plan1`, `Plan2`, `Plan3`, etc.
- Each plan contains an array with two maps:
  - Map 0: Exercises with incremental keys `exercise1`, `exercise2`, `exercise3`, etc.
  - Map 1: Treatments with incremental keys `treatment1`, `treatment2`, `treatment3`, etc.
- Values are exercise IDs and treatment IDs respectively
- Exercise and treatment counters are independent and can have gaps (e.g., `exercise4`, `treatment5`)

#### Rehabilitation Data Structure Details

**Storage Pattern**:
- **Collection**: `rehabilitation`
- **Document ID**: `{userId}` (Firebase Auth UID)
- **Plan Structure**: Each plan is stored as `Plan{number}` where number starts from 1
- **Exercise Storage**: Exercises are stored as `exercise{number}: exerciseId`
- **Treatment Storage**: Treatments are stored as `treatment{number}: treatmentId`

**Example Real Data**:
```json
{
  "userId": "abc123def456",
  "lastUpdated": "2024-01-15T10:30:00Z",
  "Plan1": [
    {
      "exercise1": "EX001",
      "exercise2": "EX005", 
      "exercise3": "EX012"
    },
    {
      "treatment1": "TR003",
      "treatment2": "TR007"
    }
  ],
  "Plan2": [
    {
      "exercise1": "EX008",
      "exercise2": "EX015",
      "exercise3": "EX022"
    },
    {
      "treatment1": "TR005",
      "treatment2": "TR009"
    }
  ]
}
```

**Data Loading Process**:
1. Load exercise IDs from Firebase (`exercise1`, `exercise2`, etc.)
2. Fetch full exercise data from CSV using exercise IDs
3. Load treatment IDs from Firebase (`treatment1`, `treatment2`, etc.)
4. Fetch full treatment data from CSV using treatment IDs
5. Reconstruct RehabilitationPlan objects with ExerciseReference and TreatmentReference objects

### Additional Firebase Collections (YOUR IMPLEMENTATION)

**Note**: The following collections are **YOUR CUSTOM FIREBASE IMPLEMENTATION** and are not actively used by the current PocketPT application code. The application currently only syncs to `users/{userId}` and `rehabilitation/{userId}` collections. However, your Firebase structure provides a complete cloud storage solution for all user data.

**Your Firebase Structure vs Application Implementation**:
- **Your Structure**: Flat top-level collections (`progress/{userId}`, `assessment/{userId}`, etc.)
- **Application Code**: Only uses `users/{userId}` and `rehabilitation/{userId}`
- **Data Storage**: Application stores other data locally in Hive only
- **Sync Gap**: Application would need code updates to sync with your additional collections

##### 4. progress/{userId} (User Progress)
**Collection**: `progress`
**Document**: `{userId}`
```json
{
  "title": "string",
  "titleColor": "string",
  "streak": "number",
  "totalDays": "number",
  "totalExercises": "number",
  "totalSeconds": "number",
  "notes": "string",
  "lastExerciseDate": "timestamp",
  "lastUpdated": "timestamp",
  "userId": "string"
}
```

##### 5. assessment/{userId} (Assessment Data)
**Collection**: `assessment`
**Document**: `{userId}`
```json
{
  "rehabGoal": "string",
  "generalMuscle": "string",
  "specificMuscle": "string",
  "painScale": "number",
  "painLevel": "string",
  "painType": "string",
  "painDuration": "string",
  "isInjured": "boolean",
  "isAssessed": "boolean",
  "lastUpdated": "timestamp",
  "userId": "string"
}
```

##### 6. settings/{userId} (User Settings)
**Collection**: `settings`
**Document**: `{userId}`
```json
{
  "isDailyReminder": "boolean",
  "isStreakAlert": "boolean",
  "isExerciseReminder": "boolean",
  "exerciseReminderHour": "number",
  "exerciseReminderMinute": "number",
  "lastUpdated": "timestamp",
  "userId": "string"
}
```

##### 7. painHistory/{userId} (Pain History)
**Collection**: `painHistory`
**Document**: `{userId}`
```json
{
  "entries": [
    {
      "date": "timestamp",
      "painScale": "number",
      "painLevel": "string"
    }
  ],
  "lastPromptedDate": "timestamp",
  "lastUpdated": "timestamp",
  "userId": "string"
}
```

##### 8. exerciseHistory/{userId} (Exercise History)
**Collection**: `exerciseHistory`
**Document**: `{userId}`
```json
{
  "entries": [
    {
      "date": "timestamp",
      "exerciseId": "string",
      "exerciseName": "string",
      "sets": "number",
      "reps": "number",
      "durationSeconds": "number",
      "status": "string"
    }
  ],
  "lastUpdated": "timestamp",
  "userId": "string"
}
```

### Firebase Data Operations

#### Active Save Operations
```dart
// User data (ACTIVE)
await UserDetails.updateInFirebase();
await UserDetails.loadFromFirebase();

// Rehabilitation data (ACTIVE)
await UserRehabilitation.instance.savePlansToFirebase();
await UserRehabilitation.instance.loadPlansFromFirebase();

// Collection management (ACTIVE)
await FirebaseHelper.ensureUserDocument();
await FirebaseHelper.ensureAllCollectionsExist();
```

#### Sync Operations (ACTIVE)
```dart
// Comprehensive sync
await DataSyncService.instance.syncAllData();

// Force operations
await DataSyncService.instance.forceSaveToFirebase();
await DataSyncService.instance.loadAllFromFirebase();
```

#### Legacy Operations (NOT ACTIVE)
```dart
// These methods exist but are not actively used:
await FirebaseHelper.ensureRehabilitationPlansCollection(); // Legacy
await FirebaseHelper.ensureTreatmentsCollection(); // Legacy
await FirebaseHelper.ensureUserProgressCollection(); // Not implemented
await FirebaseHelper.ensureUserAssessmentCollection(); // Not implemented
await FirebaseHelper.ensureUserSettingsCollection(); // Not implemented
await FirebaseHelper.ensurePainHistoryCollection(); // Not implemented
await FirebaseHelper.ensureExerciseHistoryCollection(); // Not implemented
```

---

## Data Synchronization Strategy

### Sync Flow
1. **Authentication Check**: Verify user is authenticated
2. **Collection Creation**: Ensure all Firebase collections exist
3. **Data Sync**: Sync between Hive (local) and Firebase (cloud)
4. **Conflict Resolution**: Local data takes precedence when conflicts occur
5. **Offline Fallback**: Use Hive data when Firebase is unavailable

### Sync Triggers
- **Automatic**: Every 5 minutes via `DataPersistenceService`
- **Manual**: User actions trigger immediate sync
- **App Startup**: Load from Hive first, then sync with Firebase
- **Authentication**: Full sync when user logs in

### Data Integrity
- **Validation**: All data structures are validated before saving
- **Backup**: Automatic backup creation before major operations
- **Error Handling**: Graceful fallback to local data on sync failures
- **Consistency Checks**: Regular integrity verification

---

## Exercise and Treatment Data

### CSV Data Sources
- **Exercises**: `assets/data/exercises.csv`
- **Treatments**: `assets/data/treatment.csv`

### Exercise Data Structure
```dart
class Exercise {
  final String exerciseId;        // Primary key
  final String exerciseName;      // Display name
  final String description;       // Detailed description
  final String muscle;            // Target muscle group
  final String painLevel;         // Recommended pain level
  final String goal;              // Functional goal
  final int repetitions;          // Default repetitions
  final int sets;                 // Default sets
  final String imageUrl;          // Exercise image
  final String videoUrl;          // Exercise video
}
```

### Treatment Data Structure
```dart
class Treatment {
  final String treatmentId;       // Primary key
  final String treatmentName;     // Display name
  final String description;       // Detailed description
  final String musclesInvolved;   // Target muscles
  final String painLevel;         // Recommended pain level
  final String painDuration;      // Recommended duration
}
```

---

## Key Differences: Hive vs Firebase

### Hive (Local Storage)
- **Purpose**: Fast local access and offline functionality
- **Storage**: Complete data objects with all fields
- **Performance**: Instant access, no network latency
- **Limitations**: Device-specific, limited storage space
- **Use Cases**: App startup, offline mode, frequent reads

### Firebase (Cloud Storage)
- **Purpose**: Data persistence and cross-device synchronization
- **Storage**: ID-only storage for exercises/treatments, full objects for user data
- **Performance**: Network-dependent, but scalable
- **Advantages**: Cross-device sync, backup, analytics
- **Use Cases**: Data backup, multi-device access, user management

### Storage Strategy Comparison

#### Application's Current Implementation
- **User Data**: 
  - **Firebase**: Basic user info only (`users/{userId}`)
  - **Hive**: Complete user data with all fields
- **Exercise/Treatment Data**: 
  - **Firebase**: Stored as IDs in `rehabilitation/{userId}` collection with incremental keys (`exercise1`, `exercise2`, etc.)
  - **Hive**: Stored as ID lists (`HiveExerciseIds`, `HiveTreatmentIds`)
  - **Full Data**: Loaded from CSV files using the stored IDs
- **Progress/Assessment/Settings/History Data**: 
  - **Firebase**: NOT IMPLEMENTED (application doesn't sync these)
  - **Hive**: Complete data stored locally only

#### Your Firebase Implementation
- **User Data**: 
  - **Firebase**: Basic user info (`users/{userId}`)
  - **Hive**: Complete user data with all fields
- **Exercise/Treatment Data**: 
  - **Firebase**: Stored as IDs in `rehabilitation/{userId}` collection
  - **Hive**: Stored as ID lists (`HiveExerciseIds`, `HiveTreatmentIds`)
- **Progress/Assessment/Settings/History Data**: 
  - **Firebase**: Complete data in dedicated collections (`progress/{userId}`, `assessment/{userId}`, etc.)
  - **Hive**: Complete data stored locally
- **Sync Gap**: Application would need updates to sync with your additional Firebase collections

#### Recommended Integration
To fully utilize your Firebase structure, the application would need:
1. **Firebase Helper Updates**: Add methods to sync with your collections
2. **Data Sync Service Updates**: Include progress, assessment, settings, and history in sync operations
3. **Model Updates**: Add Firebase sync methods to UserProgress, UserAssess, UserSettings, PainHistory, and ExerciseHistory classes

---

## Data Flow Examples

### User Login Flow
1. Firebase Authentication → User ID
2. Load user data from Firebase → UserDetails
3. Save to Hive → Local backup
4. Load rehabilitation plans from Firebase
5. Save exercise/treatment IDs to Hive
6. App ready with full data access

### Exercise Completion Flow
1. User completes exercise → ExerciseRecordEntry
2. Save to Hive immediately → Fast local storage
3. Update progress statistics → UserProgress
4. Save to Hive → Local backup
5. Sync to Firebase (if authenticated) → Cloud backup
6. Trigger auto-save → DataPersistenceService

### Offline Usage Flow
1. App loads → Read from Hive
2. User interactions → Save to Hive
3. Background sync → Attempt Firebase sync
4. Network restored → Full sync with Firebase
5. Conflict resolution → Local data preferred

---

## Security Considerations

### Data Protection
- **Passwords**: Stored in Hive but not synced to Firebase
- **User Authentication**: Handled by Firebase Auth
- **Data Encryption**: Hive supports encryption, Firebase uses TLS
- **Access Control**: Firebase rules control data access

### Privacy
- **Local Data**: Remains on device unless explicitly synced
- **Cloud Data**: Protected by Firebase security rules
- **Guest Mode**: Local-only data storage
- **Data Deletion**: Both local and cloud data can be cleared

---

## Performance Optimization

### Hive Optimizations
- **Lazy Loading**: Data loaded on demand
- **Batch Operations**: Multiple saves combined
- **Parallel Loading**: Concurrent data loading
- **Caching**: Frequently accessed data cached

### Firebase Optimizations
- **Collection Structure**: Optimized for query patterns
- **Batch Writes**: Multiple operations combined
- **Offline Persistence**: Firebase handles offline caching
- **Connection Management**: Automatic reconnection

---

## Maintenance and Monitoring

### Data Integrity Checks
- **Regular Validation**: Automated integrity verification
- **Backup Creation**: Periodic backup generation
- **Error Logging**: Comprehensive error tracking
- **Sync Status**: Monitor sync success/failure rates

### Performance Monitoring
- **Load Times**: Track data loading performance
- **Sync Times**: Monitor cloud synchronization
- **Storage Usage**: Monitor local storage consumption
- **Error Rates**: Track and analyze errors

---

This documentation provides a comprehensive overview of the PocketPT database architecture. The dual-database approach ensures both excellent offline performance and reliable cloud synchronization, making the app robust and user-friendly across different network conditions.
