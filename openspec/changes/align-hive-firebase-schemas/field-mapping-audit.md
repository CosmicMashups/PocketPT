# Field Mapping Audit - Hive vs Firebase Inconsistencies

## 1. UserDetails Model

### Hive Model (HiveUserDetails)
```dart
@HiveField(0) String firstName;
@HiveField(1) String lastName;
@HiveField(2) String email;
@HiveField(3) String password;
@HiveField(4) List<String> notifications;
@HiveField(5) bool isGuest;
@HiveField(6) String? guestSessionId;
@HiveField(7) String profilePicture;
```

### Firebase Fields
```dart
'userId': currentUser.uid,
'firstName': firstName,
'lastName': lastName,
'email': email,
'createdAt': FieldValue.serverTimestamp(),
'lastUpdated': FieldValue.serverTimestamp(),
'hasCompletedAssessment': hasCompletedAssessment,
'profilePicture': profilePicture,
```

### Issues Found:
1. **Missing in Firebase**: `password`, `notifications`, `isGuest`, `guestSessionId`
2. **Missing in Hive**: `userId`, `createdAt`, `lastUpdated`, `hasCompletedAssessment`
3. **Field naming**: Generally consistent (camelCase)

## 2. UserProgress Model

### Hive Model (HiveUserProgress)
```dart
@HiveField(0) String title;
@HiveField(1) String titleColor;
@HiveField(2) int streak;
@HiveField(3) int totalDays;
@HiveField(4) int totalExercises;
@HiveField(5) int totalSeconds;
@HiveField(6) String? notes;
@HiveField(7) DateTime? lastExerciseDate;
```

### Firebase Fields
```dart
'title': title,
'titleColor': titleColor,
'streak': streak,
'totalDays': totalDays,
'totalExercises': totalExercises,
'totalSeconds': totalSeconds,
'notes': notes,
'lastExerciseDate': lastExerciseDate,
'lastUpdated': FieldValue.serverTimestamp(),
'userId': currentUser.uid,
```

### Issues Found:
1. **Missing in Hive**: `lastUpdated`, `userId`
2. **Field naming**: Consistent (camelCase)

## 3. UserSettings Model

### Hive Model (HiveUserSettings)
```dart
@HiveField(0) bool isDailyReminder;
@HiveField(1) bool isStreakAlert;
@HiveField(2) bool isExerciseReminder;
@HiveField(3) int exerciseReminderHour;
@HiveField(4) int exerciseReminderMinute;
```

### Firebase Fields
```dart
'isDailyReminder': isDailyReminder,
'isStreakAlert': isStreakAlert,
'isExerciseReminder': isExerciseReminder,
'exerciseReminderHour': exerciseReminderHour,
'exerciseReminderMinute': exerciseReminderMinute,
'lastUpdated': FieldValue.serverTimestamp(),
'userId': currentUser.uid,
```

### Issues Found:
1. **Missing in Hive**: `lastUpdated`, `userId`
2. **Field naming**: Consistent (camelCase)

## 4. UserAssess Model

### Hive Model (HiveUserAssess)
```dart
@HiveField(0) String rehabGoal;
@HiveField(1) String generalMuscle;
@HiveField(2) String specificMuscle;
@HiveField(3) int painScale;
@HiveField(4) String painLevel;
@HiveField(5) String painType;
@HiveField(6) String painDuration;
@HiveField(7) bool isInjured;
@HiveField(8) bool isAssessed;
```

### Firebase Fields
```dart
'rehabGoal': '',
'generalMuscle': '',
'specificMuscle': '',
'painScale': 0,
'painLevel': '',
'painType': '',
'painDuration': '',
'isInjured': false,
'isAssessed': false,
'lastUpdated': FieldValue.serverTimestamp(),
'userId': userId,
```

### Issues Found:
1. **Missing in Hive**: `lastUpdated`, `userId`
2. **Field naming**: Consistent (camelCase)

## 5. PainHistory Model

### Hive Storage (List of Maps)
```dart
final painHistoryList = entries.map((entry) => {
  'date': entry.date.millisecondsSinceEpoch,
  'painScale': entry.painScale,
  'painLevel': entry.painLevel,
}).toList();
```

### Firebase Fields
```dart
'entries': entriesData, // List of maps with date, painScale, painLevel
'lastPromptedDate': _lastPromptedDate != null ? Timestamp.fromDate(_lastPromptedDate!) : null,
'lastUpdated': FieldValue.serverTimestamp(),
'userId': currentUser.uid,
```

### Issues Found:
1. **Data type mismatch**: Hive uses `millisecondsSinceEpoch`, Firebase uses `Timestamp.fromDate()`
2. **Missing in Hive**: `lastPromptedDate`, `lastUpdated`, `userId`
3. **Structure difference**: Hive stores as List<Map>, Firebase stores as document with entries array

## 6. ExerciseHistory Model

### Hive Storage (List of Maps)
```dart
final exerciseHistoryList = entries.map((entry) => {
  'date': entry.date.millisecondsSinceEpoch,
  'exerciseId': entry.exerciseId,
  'exerciseName': entry.exerciseName,
  'sets': entry.sets,
  'reps': entry.reps,
  'durationSeconds': entry.durationSeconds,
  'status': entry.status,
}).toList();
```

### Firebase Fields
```dart
'entries': entriesData, // List of maps with all exercise fields
'lastUpdated': FieldValue.serverTimestamp(),
'userId': currentUser.uid,
```

### Issues Found:
1. **Data type mismatch**: Hive uses `millisecondsSinceEpoch`, Firebase uses `Timestamp.fromDate()`
2. **Missing in Hive**: `lastUpdated`, `userId`
3. **Structure difference**: Hive stores as List<Map>, Firebase stores as document with entries array

## 7. Rehabilitation Plans Model

### Hive Storage (ID-only)
```dart
// HiveExerciseIds
@HiveField(0) List<String> exerciseIds;

// HiveTreatmentIds  
@HiveField(0) List<String> treatmentIds;
```

### Firebase Fields
```dart
'userId': userId,
'lastUpdated': FieldValue.serverTimestamp(),
'Plan1': [exercisesMap, treatmentsMap], // Complex nested structure
```

### Issues Found:
1. **Structure mismatch**: Hive uses simple ID lists, Firebase uses complex nested Plan structure
2. **Missing in Hive**: `userId`, `lastUpdated`, plan metadata
3. **Complexity difference**: Firebase has much more complex structure for multiple plans

## Summary of Critical Issues

### 1. Field Naming
- **Status**: Generally consistent (camelCase)
- **Action**: No changes needed

### 2. Data Type Mismatches
- **DateTime handling**: Hive uses `millisecondsSinceEpoch`, Firebase uses `Timestamp`
- **Action**: Standardize conversion methods

### 3. Missing Fields
- **Hive missing**: `userId`, `lastUpdated`, `createdAt` in most models
- **Firebase missing**: Some Hive-specific fields like `password`, `notifications`
- **Action**: Add missing fields to both systems

### 4. Storage Structure Differences
- **Hive**: Simple flat structures or ID lists
- **Firebase**: Complex nested documents with metadata
- **Action**: Align structures for 1:1 mapping

### 5. Null Safety Issues
- **Inconsistent defaults**: Different default values between systems
- **Missing null checks**: Some fields lack proper null handling
- **Action**: Implement consistent null-safety patterns
