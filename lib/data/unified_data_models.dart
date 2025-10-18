import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Base interface for all unified data models
abstract class UnifiedDataModel {
  /// Convert to Map for Hive storage
  Map<String, dynamic> toHiveMap();
  
  /// Convert to Map for Firebase storage
  Map<String, dynamic> toFirebaseMap();
  
  /// Validate data integrity
  bool validate();
  
  /// Get last modified timestamp
  DateTime? get lastModified;
  
  /// Set last modified timestamp
  set lastModified(DateTime? value);
}

/// Unified UserDetails model
class UnifiedUserDetails implements UnifiedDataModel {
  final String userId;
  final String firstName;
  final String lastName;
  final String email;
  final String password;
  final String profilePicture;
  final bool hasCompletedAssessment;
  final bool isGuest;
  final String? guestSessionId;
  final List<String> notifications;
  DateTime? _lastModified;

  UnifiedUserDetails({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    required this.profilePicture,
    required this.hasCompletedAssessment,
    required this.isGuest,
    this.guestSessionId,
    required this.notifications,
    DateTime? lastModified,
  }) : _lastModified = lastModified;

  @override
  Map<String, dynamic> toHiveMap() {
    return {
      'userId': userId,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'password': password,
      'profilePicture': profilePicture,
      'hasCompletedAssessment': hasCompletedAssessment,
      'isGuest': isGuest,
      'guestSessionId': guestSessionId,
      'notifications': notifications,
      'lastModified': _lastModified?.millisecondsSinceEpoch,
    };
  }

  @override
  Map<String, dynamic> toFirebaseMap() {
    return {
      'userId': userId,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'profilePicture': profilePicture,
      'hasCompletedAssessment': hasCompletedAssessment,
      'isGuest': isGuest,
      'guestSessionId': guestSessionId,
      'notifications': notifications,
      'lastUpdated': _lastModified != null ? Timestamp.fromDate(_lastModified!) : FieldValue.serverTimestamp(),
    };
  }

  static UnifiedUserDetails fromHiveMap(Map<String, dynamic> map) {
    return UnifiedUserDetails(
      userId: map['userId'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      email: map['email'] ?? '',
      password: map['password'] ?? '',
      profilePicture: map['profilePicture'] ?? '01.jpg',
      hasCompletedAssessment: map['hasCompletedAssessment'] ?? false,
      isGuest: map['isGuest'] ?? false,
      guestSessionId: map['guestSessionId'],
      notifications: List<String>.from(map['notifications'] ?? []),
      lastModified: map['lastModified'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['lastModified'] as int)
          : null,
    );
  }

  static UnifiedUserDetails fromFirebaseMap(Map<String, dynamic> map) {
    return UnifiedUserDetails(
      userId: map['userId'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      email: map['email'] ?? '',
      password: '', // Never store password in Firebase
      profilePicture: map['profilePicture'] ?? '01.jpg',
      hasCompletedAssessment: map['hasCompletedAssessment'] ?? false,
      isGuest: map['isGuest'] ?? false,
      guestSessionId: map['guestSessionId'],
      notifications: List<String>.from(map['notifications'] ?? []),
      lastModified: map['lastUpdated'] != null 
          ? (map['lastUpdated'] as Timestamp).toDate()
          : null,
    );
  }

  @override
  bool validate() {
    return userId.isNotEmpty && 
           firstName.isNotEmpty && 
           lastName.isNotEmpty && 
           email.isNotEmpty;
  }

  @override
  DateTime? get lastModified => _lastModified;

  @override
  set lastModified(DateTime? value) => _lastModified = value;

  UnifiedUserDetails copyWith({
    String? userId,
    String? firstName,
    String? lastName,
    String? email,
    String? password,
    String? profilePicture,
    bool? hasCompletedAssessment,
    bool? isGuest,
    String? guestSessionId,
    List<String>? notifications,
    DateTime? lastModified,
  }) {
    return UnifiedUserDetails(
      userId: userId ?? this.userId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      password: password ?? this.password,
      profilePicture: profilePicture ?? this.profilePicture,
      hasCompletedAssessment: hasCompletedAssessment ?? this.hasCompletedAssessment,
      isGuest: isGuest ?? this.isGuest,
      guestSessionId: guestSessionId ?? this.guestSessionId,
      notifications: notifications ?? this.notifications,
      lastModified: lastModified ?? this.lastModified,
    );
  }
}

/// Unified UserProgress model
class UnifiedUserProgress implements UnifiedDataModel {
  final String userId;
  final String title;
  final String titleColor;
  final int streak;
  final int totalDays;
  final int totalExercises;
  final int totalSeconds;
  final String? notes;
  final DateTime? lastExerciseDate;
  DateTime? _lastModified;

  UnifiedUserProgress({
    required this.userId,
    required this.title,
    required this.titleColor,
    required this.streak,
    required this.totalDays,
    required this.totalExercises,
    required this.totalSeconds,
    this.notes,
    this.lastExerciseDate,
    DateTime? lastModified,
  }) : _lastModified = lastModified;

  @override
  Map<String, dynamic> toHiveMap() {
    return {
      'userId': userId,
      'title': title,
      'titleColor': titleColor,
      'streak': streak,
      'totalDays': totalDays,
      'totalExercises': totalExercises,
      'totalSeconds': totalSeconds,
      'notes': notes,
      'lastExerciseDate': lastExerciseDate?.millisecondsSinceEpoch,
      'lastModified': _lastModified?.millisecondsSinceEpoch,
    };
  }

  @override
  Map<String, dynamic> toFirebaseMap() {
    return {
      'userId': userId,
      'title': title,
      'titleColor': titleColor,
      'streak': streak,
      'totalDays': totalDays,
      'totalExercises': totalExercises,
      'totalSeconds': totalSeconds,
      'notes': notes,
      'lastExerciseDate': lastExerciseDate,
      'lastUpdated': _lastModified != null ? Timestamp.fromDate(_lastModified!) : FieldValue.serverTimestamp(),
    };
  }

  static UnifiedUserProgress fromHiveMap(Map<String, dynamic> map) {
    return UnifiedUserProgress(
      userId: map['userId'] ?? '',
      title: map['title'] ?? 'Initiator',
      titleColor: map['titleColor'] ?? '',
      streak: map['streak'] ?? 0,
      totalDays: map['totalDays'] ?? 0,
      totalExercises: map['totalExercises'] ?? 0,
      totalSeconds: map['totalSeconds'] ?? 0,
      notes: map['notes'],
      lastExerciseDate: map['lastExerciseDate'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['lastExerciseDate'] as int)
          : null,
      lastModified: map['lastModified'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['lastModified'] as int)
          : null,
    );
  }

  static UnifiedUserProgress fromFirebaseMap(Map<String, dynamic> map) {
    return UnifiedUserProgress(
      userId: map['userId'] ?? '',
      title: map['title'] ?? 'Initiator',
      titleColor: map['titleColor'] ?? '',
      streak: map['streak'] ?? 0,
      totalDays: map['totalDays'] ?? 0,
      totalExercises: map['totalExercises'] ?? 0,
      totalSeconds: map['totalSeconds'] ?? 0,
      notes: map['notes'],
      lastExerciseDate: map['lastExerciseDate']?.toDate(),
      lastModified: map['lastUpdated'] != null 
          ? (map['lastUpdated'] as Timestamp).toDate()
          : null,
    );
  }

  @override
  bool validate() {
    return userId.isNotEmpty && 
           title.isNotEmpty && 
           streak >= 0 && 
           totalDays >= 0 && 
           totalExercises >= 0 && 
           totalSeconds >= 0;
  }

  @override
  DateTime? get lastModified => _lastModified;

  @override
  set lastModified(DateTime? value) => _lastModified = value;

  UnifiedUserProgress copyWith({
    String? userId,
    String? title,
    String? titleColor,
    int? streak,
    int? totalDays,
    int? totalExercises,
    int? totalSeconds,
    String? notes,
    DateTime? lastExerciseDate,
    DateTime? lastModified,
  }) {
    return UnifiedUserProgress(
      userId: userId ?? this.userId,
      title: title ?? this.title,
      titleColor: titleColor ?? this.titleColor,
      streak: streak ?? this.streak,
      totalDays: totalDays ?? this.totalDays,
      totalExercises: totalExercises ?? this.totalExercises,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      notes: notes ?? this.notes,
      lastExerciseDate: lastExerciseDate ?? this.lastExerciseDate,
      lastModified: lastModified ?? this.lastModified,
    );
  }
}

/// Unified UserSettings model
class UnifiedUserSettings implements UnifiedDataModel {
  final String userId;
  final bool isDailyReminder;
  final bool isStreakAlert;
  final bool isExerciseReminder;
  final int exerciseReminderHour;
  final int exerciseReminderMinute;
  DateTime? _lastModified;

  UnifiedUserSettings({
    required this.userId,
    required this.isDailyReminder,
    required this.isStreakAlert,
    required this.isExerciseReminder,
    required this.exerciseReminderHour,
    required this.exerciseReminderMinute,
    DateTime? lastModified,
  }) : _lastModified = lastModified;

  @override
  Map<String, dynamic> toHiveMap() {
    return {
      'userId': userId,
      'isDailyReminder': isDailyReminder,
      'isStreakAlert': isStreakAlert,
      'isExerciseReminder': isExerciseReminder,
      'exerciseReminderHour': exerciseReminderHour,
      'exerciseReminderMinute': exerciseReminderMinute,
      'lastModified': _lastModified?.millisecondsSinceEpoch,
    };
  }

  @override
  Map<String, dynamic> toFirebaseMap() {
    return {
      'userId': userId,
      'isDailyReminder': isDailyReminder,
      'isStreakAlert': isStreakAlert,
      'isExerciseReminder': isExerciseReminder,
      'exerciseReminderHour': exerciseReminderHour,
      'exerciseReminderMinute': exerciseReminderMinute,
      'lastUpdated': _lastModified != null ? Timestamp.fromDate(_lastModified!) : FieldValue.serverTimestamp(),
    };
  }

  static UnifiedUserSettings fromHiveMap(Map<String, dynamic> map) {
    return UnifiedUserSettings(
      userId: map['userId'] ?? '',
      isDailyReminder: map['isDailyReminder'] ?? true,
      isStreakAlert: map['isStreakAlert'] ?? true,
      isExerciseReminder: map['isExerciseReminder'] ?? true,
      exerciseReminderHour: map['exerciseReminderHour'] ?? 8,
      exerciseReminderMinute: map['exerciseReminderMinute'] ?? 0,
      lastModified: map['lastModified'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['lastModified'] as int)
          : null,
    );
  }

  static UnifiedUserSettings fromFirebaseMap(Map<String, dynamic> map) {
    return UnifiedUserSettings(
      userId: map['userId'] ?? '',
      isDailyReminder: map['isDailyReminder'] ?? true,
      isStreakAlert: map['isStreakAlert'] ?? true,
      isExerciseReminder: map['isExerciseReminder'] ?? true,
      exerciseReminderHour: map['exerciseReminderHour'] ?? 8,
      exerciseReminderMinute: map['exerciseReminderMinute'] ?? 0,
      lastModified: map['lastUpdated'] != null 
          ? (map['lastUpdated'] as Timestamp).toDate()
          : null,
    );
  }

  @override
  bool validate() {
    return userId.isNotEmpty && 
           exerciseReminderHour >= 0 && 
           exerciseReminderHour <= 23 && 
           exerciseReminderMinute >= 0 && 
           exerciseReminderMinute <= 59;
  }

  @override
  DateTime? get lastModified => _lastModified;

  @override
  set lastModified(DateTime? value) => _lastModified = value;

  TimeOfDay get exerciseReminderTime => TimeOfDay(
    hour: exerciseReminderHour,
    minute: exerciseReminderMinute,
  );

  UnifiedUserSettings copyWith({
    String? userId,
    bool? isDailyReminder,
    bool? isStreakAlert,
    bool? isExerciseReminder,
    int? exerciseReminderHour,
    int? exerciseReminderMinute,
    DateTime? lastModified,
  }) {
    return UnifiedUserSettings(
      userId: userId ?? this.userId,
      isDailyReminder: isDailyReminder ?? this.isDailyReminder,
      isStreakAlert: isStreakAlert ?? this.isStreakAlert,
      isExerciseReminder: isExerciseReminder ?? this.isExerciseReminder,
      exerciseReminderHour: exerciseReminderHour ?? this.exerciseReminderHour,
      exerciseReminderMinute: exerciseReminderMinute ?? this.exerciseReminderMinute,
      lastModified: lastModified ?? this.lastModified,
    );
  }
}

/// Unified PainRecordEntry model
class UnifiedPainRecordEntry implements UnifiedDataModel {
  final String userId;
  final DateTime date;
  final int painScale;
  final String painLevel;
  DateTime? _lastModified;

  UnifiedPainRecordEntry({
    required this.userId,
    required this.date,
    required this.painScale,
    required this.painLevel,
    DateTime? lastModified,
  }) : _lastModified = lastModified;

  @override
  Map<String, dynamic> toHiveMap() {
    return {
      'userId': userId,
      'date': date.millisecondsSinceEpoch,
      'painScale': painScale,
      'painLevel': painLevel,
      'lastModified': _lastModified?.millisecondsSinceEpoch,
    };
  }

  @override
  Map<String, dynamic> toFirebaseMap() {
    return {
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'painScale': painScale,
      'painLevel': painLevel,
      'lastUpdated': _lastModified != null ? Timestamp.fromDate(_lastModified!) : FieldValue.serverTimestamp(),
    };
  }

  static UnifiedPainRecordEntry fromHiveMap(Map<String, dynamic> map) {
    return UnifiedPainRecordEntry(
      userId: map['userId'] ?? '',
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      painScale: map['painScale'] ?? 0,
      painLevel: map['painLevel'] ?? '',
      lastModified: map['lastModified'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['lastModified'] as int)
          : null,
    );
  }

  static UnifiedPainRecordEntry fromFirebaseMap(Map<String, dynamic> map) {
    return UnifiedPainRecordEntry(
      userId: map['userId'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      painScale: map['painScale'] ?? 0,
      painLevel: map['painLevel'] ?? '',
      lastModified: map['lastUpdated'] != null 
          ? (map['lastUpdated'] as Timestamp).toDate()
          : null,
    );
  }

  @override
  bool validate() {
    return userId.isNotEmpty && 
           painScale >= 0 && 
           painScale <= 10 && 
           painLevel.isNotEmpty;
  }

  @override
  DateTime? get lastModified => _lastModified;

  @override
  set lastModified(DateTime? value) => _lastModified = value;

  UnifiedPainRecordEntry copyWith({
    String? userId,
    DateTime? date,
    int? painScale,
    String? painLevel,
    DateTime? lastModified,
  }) {
    return UnifiedPainRecordEntry(
      userId: userId ?? this.userId,
      date: date ?? this.date,
      painScale: painScale ?? this.painScale,
      painLevel: painLevel ?? this.painLevel,
      lastModified: lastModified ?? this.lastModified,
    );
  }
}

/// Unified ExerciseRecordEntry model
class UnifiedExerciseRecordEntry implements UnifiedDataModel {
  final String userId;
  final DateTime date;
  final String exerciseId;
  final String exerciseName;
  final int sets;
  final int reps;
  final int durationSeconds;
  final String status;
  DateTime? _lastModified;

  UnifiedExerciseRecordEntry({
    required this.userId,
    required this.date,
    required this.exerciseId,
    required this.exerciseName,
    required this.sets,
    required this.reps,
    required this.durationSeconds,
    required this.status,
    DateTime? lastModified,
  }) : _lastModified = lastModified;

  @override
  Map<String, dynamic> toHiveMap() {
    return {
      'userId': userId,
      'date': date.millisecondsSinceEpoch,
      'exerciseId': exerciseId,
      'exerciseName': exerciseName,
      'sets': sets,
      'reps': reps,
      'durationSeconds': durationSeconds,
      'status': status,
      'lastModified': _lastModified?.millisecondsSinceEpoch,
    };
  }

  @override
  Map<String, dynamic> toFirebaseMap() {
    return {
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'exerciseId': exerciseId,
      'exerciseName': exerciseName,
      'sets': sets,
      'reps': reps,
      'durationSeconds': durationSeconds,
      'status': status,
      'lastUpdated': _lastModified != null ? Timestamp.fromDate(_lastModified!) : FieldValue.serverTimestamp(),
    };
  }

  static UnifiedExerciseRecordEntry fromHiveMap(Map<String, dynamic> map) {
    return UnifiedExerciseRecordEntry(
      userId: map['userId'] ?? '',
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      exerciseId: map['exerciseId'] ?? '',
      exerciseName: map['exerciseName'] ?? '',
      sets: map['sets'] ?? 0,
      reps: map['reps'] ?? 0,
      durationSeconds: map['durationSeconds'] ?? 0,
      status: map['status'] ?? 'completed',
      lastModified: map['lastModified'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['lastModified'] as int)
          : null,
    );
  }

  static UnifiedExerciseRecordEntry fromFirebaseMap(Map<String, dynamic> map) {
    return UnifiedExerciseRecordEntry(
      userId: map['userId'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      exerciseId: map['exerciseId'] ?? '',
      exerciseName: map['exerciseName'] ?? '',
      sets: map['sets'] ?? 0,
      reps: map['reps'] ?? 0,
      durationSeconds: map['durationSeconds'] ?? 0,
      status: map['status'] ?? 'completed',
      lastModified: map['lastUpdated'] != null 
          ? (map['lastUpdated'] as Timestamp).toDate()
          : null,
    );
  }

  @override
  bool validate() {
    return userId.isNotEmpty && 
           exerciseId.isNotEmpty && 
           exerciseName.isNotEmpty && 
           sets >= 0 && 
           reps >= 0 && 
           durationSeconds >= 0 && 
           ['completed', 'skipped', 'partial', 'not_started'].contains(status);
  }

  @override
  DateTime? get lastModified => _lastModified;

  @override
  set lastModified(DateTime? value) => _lastModified = value;

  UnifiedExerciseRecordEntry copyWith({
    String? userId,
    DateTime? date,
    String? exerciseId,
    String? exerciseName,
    int? sets,
    int? reps,
    int? durationSeconds,
    String? status,
    DateTime? lastModified,
  }) {
    return UnifiedExerciseRecordEntry(
      userId: userId ?? this.userId,
      date: date ?? this.date,
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      status: status ?? this.status,
      lastModified: lastModified ?? this.lastModified,
    );
  }
}

/// Unified Rehabilitation Plan model (ID-only storage)
class UnifiedRehabilitationPlan implements UnifiedDataModel {
  final String userId;
  final List<String> exerciseIds;
  final List<String> treatmentIds;
  final int weekNumber;
  DateTime? _lastModified;

  UnifiedRehabilitationPlan({
    required this.userId,
    required this.exerciseIds,
    required this.treatmentIds,
    required this.weekNumber,
    DateTime? lastModified,
  }) : _lastModified = lastModified;

  @override
  Map<String, dynamic> toHiveMap() {
    return {
      'userId': userId,
      'exerciseIds': exerciseIds,
      'treatmentIds': treatmentIds,
      'weekNumber': weekNumber,
      'lastModified': _lastModified?.millisecondsSinceEpoch,
    };
  }

  @override
  Map<String, dynamic> toFirebaseMap() {
    return {
      'userId': userId,
      'exerciseIds': exerciseIds,
      'treatmentIds': treatmentIds,
      'weekNumber': weekNumber,
      'lastUpdated': _lastModified != null ? Timestamp.fromDate(_lastModified!) : FieldValue.serverTimestamp(),
    };
  }

  static UnifiedRehabilitationPlan fromHiveMap(Map<String, dynamic> map) {
    return UnifiedRehabilitationPlan(
      userId: map['userId'] ?? '',
      exerciseIds: List<String>.from(map['exerciseIds'] ?? []),
      treatmentIds: List<String>.from(map['treatmentIds'] ?? []),
      weekNumber: map['weekNumber'] ?? 1,
      lastModified: map['lastModified'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['lastModified'] as int)
          : null,
    );
  }

  static UnifiedRehabilitationPlan fromFirebaseMap(Map<String, dynamic> map) {
    return UnifiedRehabilitationPlan(
      userId: map['userId'] ?? '',
      exerciseIds: List<String>.from(map['exerciseIds'] ?? []),
      treatmentIds: List<String>.from(map['treatmentIds'] ?? []),
      weekNumber: map['weekNumber'] ?? 1,
      lastModified: map['lastUpdated'] != null 
          ? (map['lastUpdated'] as Timestamp).toDate()
          : null,
    );
  }

  @override
  bool validate() {
    return userId.isNotEmpty && 
           weekNumber > 0 && 
           exerciseIds.every((id) => id.isNotEmpty) &&
           treatmentIds.every((id) => id.isNotEmpty);
  }

  @override
  DateTime? get lastModified => _lastModified;

  @override
  set lastModified(DateTime? value) => _lastModified = value;

  UnifiedRehabilitationPlan copyWith({
    String? userId,
    List<String>? exerciseIds,
    List<String>? treatmentIds,
    int? weekNumber,
    DateTime? lastModified,
  }) {
    return UnifiedRehabilitationPlan(
      userId: userId ?? this.userId,
      exerciseIds: exerciseIds ?? this.exerciseIds,
      treatmentIds: treatmentIds ?? this.treatmentIds,
      weekNumber: weekNumber ?? this.weekNumber,
      lastModified: lastModified ?? this.lastModified,
    );
  }
}
