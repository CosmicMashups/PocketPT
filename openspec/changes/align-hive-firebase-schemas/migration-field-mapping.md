# Migration Field Mapping Documentation

## Overview
This document provides the complete field mapping between existing Hive models, Firebase documents, and the new unified data models for migration purposes.

## 1. UserDetails Migration

### Current Hive Model → Unified Model
```dart
// Current HiveUserDetails
@HiveField(0) String firstName;           → UnifiedUserDetails.firstName
@HiveField(1) String lastName;            → UnifiedUserDetails.lastName
@HiveField(2) String email;               → UnifiedUserDetails.email
@HiveField(3) String password;            → UnifiedUserDetails.password
@HiveField(4) List<String> notifications; → UnifiedUserDetails.notifications
@HiveField(5) bool isGuest;               → UnifiedUserDetails.isGuest
@HiveField(6) String? guestSessionId;     → UnifiedUserDetails.guestSessionId
@HiveField(7) String profilePicture;      → UnifiedUserDetails.profilePicture

// Missing fields to add
userId: String                            → UnifiedUserDetails.userId (from Firebase)
hasCompletedAssessment: bool              → UnifiedUserDetails.hasCompletedAssessment (from Firebase)
lastModified: DateTime?                   → UnifiedUserDetails.lastModified (from static field)
```

### Current Firebase Document → Unified Model
```dart
// Current Firebase fields
'userId': String                          → UnifiedUserDetails.userId
'firstName': String                       → UnifiedUserDetails.firstName
'lastName': String                        → UnifiedUserDetails.lastName
'email': String                           → UnifiedUserDetails.email
'profilePicture': String                  → UnifiedUserDetails.profilePicture
'hasCompletedAssessment': bool            → UnifiedUserDetails.hasCompletedAssessment
'createdAt': Timestamp                    → UnifiedUserDetails.lastModified (converted)
'lastUpdated': Timestamp                  → UnifiedUserDetails.lastModified (converted)

// Missing fields to add
password: String                          → UnifiedUserDetails.password (from Hive)
isGuest: bool                             → UnifiedUserDetails.isGuest (from Hive)
guestSessionId: String?                   → UnifiedUserDetails.guestSessionId (from Hive)
notifications: List<String>               → UnifiedUserDetails.notifications (from Hive)
```

### Migration Strategy
1. **Hive → Unified**: Add missing `userId`, `hasCompletedAssessment`, `lastModified`
2. **Firebase → Unified**: Add missing `password`, `isGuest`, `guestSessionId`, `notifications`
3. **Timestamp Conversion**: Convert `createdAt`/`lastUpdated` to `lastModified`
4. **Default Values**: Apply consistent defaults for missing fields

## 2. UserProgress Migration

### Current Hive Model → Unified Model
```dart
// Current HiveUserProgress
@HiveField(0) String title;               → UnifiedUserProgress.title
@HiveField(1) String titleColor;          → UnifiedUserProgress.titleColor
@HiveField(2) int streak;                 → UnifiedUserProgress.streak
@HiveField(3) int totalDays;              → UnifiedUserProgress.totalDays
@HiveField(4) int totalExercises;         → UnifiedUserProgress.totalExercises
@HiveField(5) int totalSeconds;           → UnifiedUserProgress.totalSeconds
@HiveField(6) String? notes;              → UnifiedUserProgress.notes
@HiveField(7) DateTime? lastExerciseDate; → UnifiedUserProgress.lastExerciseDate

// Missing fields to add
userId: String                            → UnifiedUserProgress.userId (from Firebase)
lastModified: DateTime?                   → UnifiedUserProgress.lastModified (from static field)
```

### Current Firebase Document → Unified Model
```dart
// Current Firebase fields
'userId': String                          → UnifiedUserProgress.userId
'title': String                           → UnifiedUserProgress.title
'titleColor': String                      → UnifiedUserProgress.titleColor
'streak': int                             → UnifiedUserProgress.streak
'totalDays': int                          → UnifiedUserProgress.totalDays
'totalExercises': int                     → UnifiedUserProgress.totalExercises
'totalSeconds': int                       → UnifiedUserProgress.totalSeconds
'notes': String?                          → UnifiedUserProgress.notes
'lastExerciseDate': DateTime?             → UnifiedUserProgress.lastExerciseDate
'lastUpdated': Timestamp                  → UnifiedUserProgress.lastModified (converted)

// No missing fields - all present
```

### Migration Strategy
1. **Hive → Unified**: Add missing `userId`, `lastModified`
2. **Firebase → Unified**: Convert `lastUpdated` to `lastModified`
3. **Default Values**: Apply consistent defaults for missing fields

## 3. UserSettings Migration

### Current Hive Model → Unified Model
```dart
// Current HiveUserSettings
@HiveField(0) bool isDailyReminder;       → UnifiedUserSettings.isDailyReminder
@HiveField(1) bool isStreakAlert;         → UnifiedUserSettings.isStreakAlert
@HiveField(2) bool isExerciseReminder;    → UnifiedUserSettings.isExerciseReminder
@HiveField(3) int exerciseReminderHour;   → UnifiedUserSettings.exerciseReminderHour
@HiveField(4) int exerciseReminderMinute; → UnifiedUserSettings.exerciseReminderMinute

// Missing fields to add
userId: String                            → UnifiedUserSettings.userId (from Firebase)
lastModified: DateTime?                   → UnifiedUserSettings.lastModified (from static field)
```

### Current Firebase Document → Unified Model
```dart
// Current Firebase fields
'userId': String                          → UnifiedUserSettings.userId
'isDailyReminder': bool                   → UnifiedUserSettings.isDailyReminder
'isStreakAlert': bool                     → UnifiedUserSettings.isStreakAlert
'isExerciseReminder': bool                → UnifiedUserSettings.isExerciseReminder
'exerciseReminderHour': int               → UnifiedUserSettings.exerciseReminderHour
'exerciseReminderMinute': int             → UnifiedUserSettings.exerciseReminderMinute
'lastUpdated': Timestamp                  → UnifiedUserSettings.lastModified (converted)

// No missing fields - all present
```

### Migration Strategy
1. **Hive → Unified**: Add missing `userId`, `lastModified`
2. **Firebase → Unified**: Convert `lastUpdated` to `lastModified`
3. **Default Values**: Apply consistent defaults for missing fields

## 4. PainHistory Migration

### Current Hive Storage → Unified Model
```dart
// Current Hive storage (List<Map>)
'date': int (milliseconds)                → UnifiedPainRecordEntry.date (converted to DateTime)
'painScale': int                          → UnifiedPainRecordEntry.painScale
'painLevel': String                       → UnifiedPainRecordEntry.painLevel

// Missing fields to add
userId: String                            → UnifiedPainRecordEntry.userId (from Firebase)
lastModified: DateTime?                   → UnifiedPainRecordEntry.lastModified (from Firebase)
```

### Current Firebase Document → Unified Model
```dart
// Current Firebase fields
'userId': String                          → UnifiedPainRecordEntry.userId
'entries': List<Map>                      → UnifiedPainRecordEntry (per entry)
  'date': Timestamp                       → UnifiedPainRecordEntry.date (converted to DateTime)
  'painScale': int                        → UnifiedPainRecordEntry.painScale
  'painLevel': String                     → UnifiedPainRecordEntry.painLevel
'lastPromptedDate': Timestamp?            → UnifiedPainRecordEntry.lastModified (converted)
'lastUpdated': Timestamp                  → UnifiedPainRecordEntry.lastModified (converted)

// No missing fields - all present
```

### Migration Strategy
1. **Hive → Unified**: Add missing `userId`, `lastModified`; convert date format
2. **Firebase → Unified**: Convert Timestamp to DateTime; extract entries
3. **Structure Change**: Convert from List<Map> to List<UnifiedPainRecordEntry>

## 5. ExerciseHistory Migration

### Current Hive Storage → Unified Model
```dart
// Current Hive storage (List<Map>)
'date': int (milliseconds)                → UnifiedExerciseRecordEntry.date (converted to DateTime)
'exerciseId': String                      → UnifiedExerciseRecordEntry.exerciseId
'exerciseName': String                    → UnifiedExerciseRecordEntry.exerciseName
'sets': int                               → UnifiedExerciseRecordEntry.sets
'reps': int                               → UnifiedExerciseRecordEntry.reps
'durationSeconds': int                    → UnifiedExerciseRecordEntry.durationSeconds
'status': String                          → UnifiedExerciseRecordEntry.status

// Missing fields to add
userId: String                            → UnifiedExerciseRecordEntry.userId (from Firebase)
lastModified: DateTime?                   → UnifiedExerciseRecordEntry.lastModified (from Firebase)
```

### Current Firebase Document → Unified Model
```dart
// Current Firebase fields
'userId': String                          → UnifiedExerciseRecordEntry.userId
'entries': List<Map>                      → UnifiedExerciseRecordEntry (per entry)
  'date': Timestamp                       → UnifiedExerciseRecordEntry.date (converted to DateTime)
  'exerciseId': String                    → UnifiedExerciseRecordEntry.exerciseId
  'exerciseName': String                  → UnifiedExerciseRecordEntry.exerciseName
  'sets': int                             → UnifiedExerciseRecordEntry.sets
  'reps': int                             → UnifiedExerciseRecordEntry.reps
  'durationSeconds': int                  → UnifiedExerciseRecordEntry.durationSeconds
  'status': String                        → UnifiedExerciseRecordEntry.status
'lastUpdated': Timestamp                  → UnifiedExerciseRecordEntry.lastModified (converted)

// No missing fields - all present
```

### Migration Strategy
1. **Hive → Unified**: Add missing `userId`, `lastModified`; convert date format
2. **Firebase → Unified**: Convert Timestamp to DateTime; extract entries
3. **Structure Change**: Convert from List<Map> to List<UnifiedExerciseRecordEntry>

## 6. Rehabilitation Plans Migration

### Current Hive Storage → Unified Model
```dart
// Current Hive storage (ID-only)
HiveExerciseIds.exerciseIds: List<String> → UnifiedRehabilitationPlan.exerciseIds
HiveTreatmentIds.treatmentIds: List<String> → UnifiedRehabilitationPlan.treatmentIds

// Missing fields to add
userId: String                            → UnifiedRehabilitationPlan.userId (from Firebase)
weekNumber: int                           → UnifiedRehabilitationPlan.weekNumber (default: 1)
lastModified: DateTime?                   → UnifiedRehabilitationPlan.lastModified (from Firebase)
```

### Current Firebase Document → Unified Model
```dart
// Current Firebase fields (complex nested structure)
'userId': String                          → UnifiedRehabilitationPlan.userId
'Plan1': [exercisesMap, treatmentsMap]    → UnifiedRehabilitationPlan.exerciseIds, treatmentIds
'Plan2': [exercisesMap, treatmentsMap]    → Multiple UnifiedRehabilitationPlan instances
'lastUpdated': Timestamp                  → UnifiedRehabilitationPlan.lastModified (converted)

// Structure simplification needed
```

### Migration Strategy
1. **Hive → Unified**: Add missing `userId`, `weekNumber`, `lastModified`
2. **Firebase → Unified**: Simplify complex nested structure to flat ID lists
3. **Multiple Plans**: Handle multiple plans by creating separate UnifiedRehabilitationPlan instances
4. **ID Extraction**: Extract exercise and treatment IDs from nested maps

## 7. Data Type Conversion Rules

### DateTime Handling
```dart
// Hive → Unified
int milliseconds → DateTime.fromMillisecondsSinceEpoch(milliseconds)

// Firebase → Unified
Timestamp → timestamp.toDate()

// Unified → Hive
DateTime → dateTime.millisecondsSinceEpoch

// Unified → Firebase
DateTime → Timestamp.fromDate(dateTime)
```

### Null Safety Rules
```dart
// Default values for missing fields
String → ''
int → 0
bool → false
List → []
DateTime? → null
```

### Validation Rules
```dart
// Required fields
userId: must not be empty
firstName: must not be empty
lastName: must not be empty
email: must not be empty

// Range validation
painScale: 0-10
exerciseReminderHour: 0-23
exerciseReminderMinute: 0-59
streak: >= 0
totalDays: >= 0
totalExercises: >= 0
totalSeconds: >= 0

// Enum validation
status: ['completed', 'skipped', 'partial', 'not_started']
```

## 8. Migration Implementation Steps

### Step 1: Data Backup
1. Create backup of existing Hive data
2. Create backup of existing Firebase data
3. Verify backup integrity

### Step 2: Schema Migration
1. Update Hive models to include missing fields
2. Update Firebase documents to include missing fields
3. Apply consistent field naming (camelCase)

### Step 3: Data Conversion
1. Convert existing Hive data to unified format
2. Convert existing Firebase data to unified format
3. Merge data from both sources with conflict resolution

### Step 4: Validation
1. Validate all converted data
2. Check data integrity
3. Verify no data loss

### Step 5: Rollback Preparation
1. Prepare rollback scripts
2. Test rollback procedures
3. Document rollback steps

## 9. Error Handling

### Common Migration Errors
1. **Missing Fields**: Apply default values
2. **Type Mismatches**: Convert with validation
3. **Data Corruption**: Skip corrupted records, log errors
4. **Network Issues**: Retry with exponential backoff

### Recovery Procedures
1. **Partial Migration**: Resume from last successful point
2. **Complete Failure**: Restore from backup
3. **Data Corruption**: Repair or skip corrupted records
4. **Validation Failure**: Log and continue with warnings

## 10. Testing Strategy

### Unit Tests
1. Test individual field conversions
2. Test data validation
3. Test error handling

### Integration Tests
1. Test complete migration process
2. Test data integrity after migration
3. Test rollback procedures

### End-to-End Tests
1. Test with real user data
2. Test sync functionality after migration
3. Test app functionality with migrated data
