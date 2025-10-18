# Data Type Mismatch Analysis

## 1. DateTime Handling Inconsistencies

### Current State:
- **Hive**: Uses `DateTime` objects stored as `millisecondsSinceEpoch` (int)
- **Firebase**: Uses `Timestamp` objects and `FieldValue.serverTimestamp()`

### Specific Issues:

#### 1.1 UserDetails.lastModified
```dart
// Hive Storage
'lastModified': lastModified?.millisecondsSinceEpoch, // int

// Firebase Storage  
'lastUpdated': FieldValue.serverTimestamp(), // Timestamp
```

#### 1.2 PainHistory.date
```dart
// Hive Storage
'date': entry.date.millisecondsSinceEpoch, // int

// Firebase Storage
'date': Timestamp.fromDate(entry.date), // Timestamp
```

#### 1.3 ExerciseHistory.date
```dart
// Hive Storage
'date': entry.date.millisecondsSinceEpoch, // int

// Firebase Storage
'date': Timestamp.fromDate(entry.date), // Timestamp
```

#### 1.4 ActiveProgram.startDate
```dart
// Hive Storage
'startDate': startDate?.millisecondsSinceEpoch, // int?

// Firebase Storage
// Not currently stored in Firebase
```

#### 1.5 UserProgress.lastExerciseDate
```dart
// Hive Storage
'lastExerciseDate': lastExerciseDate?.millisecondsSinceEpoch, // int?

// Firebase Storage
'lastExerciseDate': lastExerciseDate, // DateTime? (direct)
```

## 2. Nullable Field Handling Inconsistencies

### Current State:
- **Hive**: Uses nullable types with explicit null checks
- **Firebase**: Inconsistent null handling, some fields missing null checks

### Specific Issues:

#### 2.1 UserDetails.guestSessionId
```dart
// Hive Model
@HiveField(6) String? guestSessionId; // Nullable

// Firebase Storage
// Not stored in Firebase at all
```

#### 2.2 UserProgress.notes
```dart
// Hive Model
@HiveField(6) String? notes; // Nullable

// Firebase Storage
'notes': notes, // Direct assignment, no null check
```

#### 2.3 UserProgress.lastExerciseDate
```dart
// Hive Model
@HiveField(7) DateTime? lastExerciseDate; // Nullable

// Firebase Storage
'lastExerciseDate': lastExerciseDate, // Direct assignment, no null check
```

## 3. List and Map Type Inconsistencies

### Current State:
- **Hive**: Uses typed lists and maps with explicit casting
- **Firebase**: Uses dynamic lists and maps

### Specific Issues:

#### 3.1 UserDetails.notifications
```dart
// Hive Model
@HiveField(4) List<String> notifications; // Typed list

// Firebase Storage
// Not stored in Firebase
```

#### 3.2 PainHistory.entries
```dart
// Hive Storage
final painHistoryList = entries.map((entry) => {
  'date': entry.date.millisecondsSinceEpoch,
  'painScale': entry.painScale,
  'painLevel': entry.painLevel,
}).toList(); // List<Map<String, dynamic>>

// Firebase Storage
'entries': entriesData, // List<dynamic> (less type safety)
```

#### 3.3 ExerciseHistory.entries
```dart
// Hive Storage
final exerciseHistoryList = entries.map((entry) => {
  'date': entry.date.millisecondsSinceEpoch,
  'exerciseId': entry.exerciseId,
  'exerciseName': entry.exerciseName,
  'sets': entry.sets,
  'reps': entry.reps,
  'durationSeconds': entry.durationSeconds,
  'status': entry.status,
}).toList(); // List<Map<String, dynamic>>

// Firebase Storage
'entries': entriesData, // List<dynamic> (less type safety)
```

## 4. Default Value Inconsistencies

### Current State:
- **Hive**: Uses explicit default values in constructors
- **Firebase**: Uses inconsistent default values or missing defaults

### Specific Issues:

#### 4.1 UserDetails.profilePicture
```dart
// Hive Model
String profilePicture = '01.jpg'; // Default value

// Firebase Storage
'profilePicture': profilePicture, // Uses current value, no default
```

#### 4.2 UserProgress.title
```dart
// Hive Model
String title = 'Initiator'; // Default value

// Firebase Storage
'title': title, // Uses current value, no default
```

#### 4.3 UserSettings boolean fields
```dart
// Hive Model
bool isDailyReminder = true; // Default value
bool isStreakAlert = true; // Default value
bool isExerciseReminder = true; // Default value

// Firebase Storage
'isDailyReminder': isDailyReminder, // Uses current value, no default
'isStreakAlert': isStreakAlert, // Uses current value, no default
'isExerciseReminder': isExerciseReminder, // Uses current value, no default
```

## 5. Missing Field Type Definitions

### Current State:
- **Hive**: Has explicit type definitions for all fields
- **Firebase**: Some fields lack proper type definitions

### Specific Issues:

#### 5.1 Firebase userId field
```dart
// Firebase Storage
'userId': currentUser.uid, // String, but not consistently typed

// Hive Storage
// Missing userId field entirely
```

#### 5.2 Firebase lastUpdated field
```dart
// Firebase Storage
'lastUpdated': FieldValue.serverTimestamp(), // Timestamp, but not consistently typed

// Hive Storage
// Missing lastUpdated field entirely
```

## 6. Conversion Logic Inconsistencies

### Current State:
- **Hive**: Manual conversion between DateTime and milliseconds
- **Firebase**: Manual conversion between DateTime and Timestamp

### Specific Issues:

#### 6.1 DateTime to milliseconds conversion
```dart
// Hive Save
'lastModified': lastModified?.millisecondsSinceEpoch,

// Hive Load
if (lastModifiedTimestamp is int) {
  lastModified = DateTime.fromMillisecondsSinceEpoch(lastModifiedTimestamp);
}
```

#### 6.2 DateTime to Timestamp conversion
```dart
// Firebase Save
'date': Timestamp.fromDate(entry.date),

// Firebase Load
date: (entryData['date'] as Timestamp).toDate(),
```

## Summary of Required Changes

### 1. Standardize DateTime Handling
- Create unified DateTime conversion utilities
- Use consistent storage format (milliseconds for Hive, Timestamp for Firebase)
- Implement proper conversion methods

### 2. Implement Consistent Null Safety
- Add null checks for all nullable fields
- Use consistent default values across both systems
- Implement proper null handling in conversion methods

### 3. Standardize List and Map Types
- Use consistent typing for lists and maps
- Implement proper type casting and validation
- Add type safety checks in conversion methods

### 4. Add Missing Fields
- Add userId and lastUpdated fields to Hive models
- Add missing Hive-specific fields to Firebase where appropriate
- Ensure all fields are present in both systems

### 5. Implement Unified Conversion Logic
- Create centralized conversion utilities
- Implement consistent error handling
- Add validation for data integrity
