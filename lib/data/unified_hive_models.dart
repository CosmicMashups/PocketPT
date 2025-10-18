import 'package:hive/hive.dart';
import 'unified_data_models.dart';

part 'unified_hive_models.g.dart';

/// Updated Hive model for UserDetails using unified schema
@HiveType(typeId: 0)
class UnifiedHiveUserDetails extends HiveObject {
  @HiveField(0)
  String userId;
  
  @HiveField(1)
  String firstName;
  
  @HiveField(2)
  String lastName;
  
  @HiveField(3)
  String email;
  
  @HiveField(4)
  String password;
  
  @HiveField(5)
  String profilePicture;
  
  @HiveField(6)
  bool hasCompletedAssessment;
  
  @HiveField(7)
  bool isGuest;
  
  @HiveField(8)
  String? guestSessionId;
  
  @HiveField(9)
  List<String> notifications;
  
  @HiveField(10)
  int? lastModified; // milliseconds since epoch

  UnifiedHiveUserDetails({
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
    this.lastModified,
  });

  /// Convert from unified model
  factory UnifiedHiveUserDetails.fromUnified(UnifiedUserDetails unified) {
    return UnifiedHiveUserDetails(
      userId: unified.userId,
      firstName: unified.firstName,
      lastName: unified.lastName,
      email: unified.email,
      password: unified.password,
      profilePicture: unified.profilePicture,
      hasCompletedAssessment: unified.hasCompletedAssessment,
      isGuest: unified.isGuest,
      guestSessionId: unified.guestSessionId,
      notifications: List<String>.from(unified.notifications),
      lastModified: unified.lastModified?.millisecondsSinceEpoch,
    );
  }

  /// Convert to unified model
  UnifiedUserDetails toUnified() {
    return UnifiedUserDetails(
      userId: userId,
      firstName: firstName,
      lastName: lastName,
      email: email,
      password: password,
      profilePicture: profilePicture,
      hasCompletedAssessment: hasCompletedAssessment,
      isGuest: isGuest,
      guestSessionId: guestSessionId,
      notifications: List<String>.from(notifications),
      lastModified: lastModified != null 
          ? DateTime.fromMillisecondsSinceEpoch(lastModified!)
          : null,
    );
  }
}

/// Updated Hive model for UserProgress using unified schema
@HiveType(typeId: 1)
class UnifiedHiveUserProgress extends HiveObject {
  @HiveField(0)
  String userId;
  
  @HiveField(1)
  String title;
  
  @HiveField(2)
  String titleColor;
  
  @HiveField(3)
  int streak;
  
  @HiveField(4)
  int totalDays;
  
  @HiveField(5)
  int totalExercises;
  
  @HiveField(6)
  int totalSeconds;
  
  @HiveField(7)
  String? notes;
  
  @HiveField(8)
  int? lastExerciseDate; // milliseconds since epoch
  
  @HiveField(9)
  int? lastModified; // milliseconds since epoch

  UnifiedHiveUserProgress({
    required this.userId,
    required this.title,
    required this.titleColor,
    required this.streak,
    required this.totalDays,
    required this.totalExercises,
    required this.totalSeconds,
    this.notes,
    this.lastExerciseDate,
    this.lastModified,
  });

  /// Convert from unified model
  factory UnifiedHiveUserProgress.fromUnified(UnifiedUserProgress unified) {
    return UnifiedHiveUserProgress(
      userId: unified.userId,
      title: unified.title,
      titleColor: unified.titleColor,
      streak: unified.streak,
      totalDays: unified.totalDays,
      totalExercises: unified.totalExercises,
      totalSeconds: unified.totalSeconds,
      notes: unified.notes,
      lastExerciseDate: unified.lastExerciseDate?.millisecondsSinceEpoch,
      lastModified: unified.lastModified?.millisecondsSinceEpoch,
    );
  }

  /// Convert to unified model
  UnifiedUserProgress toUnified() {
    return UnifiedUserProgress(
      userId: userId,
      title: title,
      titleColor: titleColor,
      streak: streak,
      totalDays: totalDays,
      totalExercises: totalExercises,
      totalSeconds: totalSeconds,
      notes: notes,
      lastExerciseDate: lastExerciseDate != null 
          ? DateTime.fromMillisecondsSinceEpoch(lastExerciseDate!)
          : null,
      lastModified: lastModified != null 
          ? DateTime.fromMillisecondsSinceEpoch(lastModified!)
          : null,
    );
  }
}

/// Updated Hive model for UserSettings using unified schema
@HiveType(typeId: 2)
class UnifiedHiveUserSettings extends HiveObject {
  @HiveField(0)
  String userId;
  
  @HiveField(1)
  bool isDailyReminder;
  
  @HiveField(2)
  bool isStreakAlert;
  
  @HiveField(3)
  bool isExerciseReminder;
  
  @HiveField(4)
  int exerciseReminderHour;
  
  @HiveField(5)
  int exerciseReminderMinute;
  
  @HiveField(6)
  int? lastModified; // milliseconds since epoch

  UnifiedHiveUserSettings({
    required this.userId,
    required this.isDailyReminder,
    required this.isStreakAlert,
    required this.isExerciseReminder,
    required this.exerciseReminderHour,
    required this.exerciseReminderMinute,
    this.lastModified,
  });

  /// Convert from unified model
  factory UnifiedHiveUserSettings.fromUnified(UnifiedUserSettings unified) {
    return UnifiedHiveUserSettings(
      userId: unified.userId,
      isDailyReminder: unified.isDailyReminder,
      isStreakAlert: unified.isStreakAlert,
      isExerciseReminder: unified.isExerciseReminder,
      exerciseReminderHour: unified.exerciseReminderHour,
      exerciseReminderMinute: unified.exerciseReminderMinute,
      lastModified: unified.lastModified?.millisecondsSinceEpoch,
    );
  }

  /// Convert to unified model
  UnifiedUserSettings toUnified() {
    return UnifiedUserSettings(
      userId: userId,
      isDailyReminder: isDailyReminder,
      isStreakAlert: isStreakAlert,
      isExerciseReminder: isExerciseReminder,
      exerciseReminderHour: exerciseReminderHour,
      exerciseReminderMinute: exerciseReminderMinute,
      lastModified: lastModified != null 
          ? DateTime.fromMillisecondsSinceEpoch(lastModified!)
          : null,
    );
  }
}

/// Updated Hive model for PainRecordEntry using unified schema
@HiveType(typeId: 3)
class UnifiedHivePainRecordEntry extends HiveObject {
  @HiveField(0)
  String userId;
  
  @HiveField(1)
  int date; // milliseconds since epoch
  
  @HiveField(2)
  int painScale;
  
  @HiveField(3)
  String painLevel;
  
  @HiveField(4)
  int? lastModified; // milliseconds since epoch

  UnifiedHivePainRecordEntry({
    required this.userId,
    required this.date,
    required this.painScale,
    required this.painLevel,
    this.lastModified,
  });

  /// Convert from unified model
  factory UnifiedHivePainRecordEntry.fromUnified(UnifiedPainRecordEntry unified) {
    return UnifiedHivePainRecordEntry(
      userId: unified.userId,
      date: unified.date.millisecondsSinceEpoch,
      painScale: unified.painScale,
      painLevel: unified.painLevel,
      lastModified: unified.lastModified?.millisecondsSinceEpoch,
    );
  }

  /// Convert to unified model
  UnifiedPainRecordEntry toUnified() {
    return UnifiedPainRecordEntry(
      userId: userId,
      date: DateTime.fromMillisecondsSinceEpoch(date),
      painScale: painScale,
      painLevel: painLevel,
      lastModified: lastModified != null 
          ? DateTime.fromMillisecondsSinceEpoch(lastModified!)
          : null,
    );
  }
}

/// Updated Hive model for ExerciseRecordEntry using unified schema
@HiveType(typeId: 4)
class UnifiedHiveExerciseRecordEntry extends HiveObject {
  @HiveField(0)
  String userId;
  
  @HiveField(1)
  int date; // milliseconds since epoch
  
  @HiveField(2)
  String exerciseId;
  
  @HiveField(3)
  String exerciseName;
  
  @HiveField(4)
  int sets;
  
  @HiveField(5)
  int reps;
  
  @HiveField(6)
  int durationSeconds;
  
  @HiveField(7)
  String status;
  
  @HiveField(8)
  int? lastModified; // milliseconds since epoch

  UnifiedHiveExerciseRecordEntry({
    required this.userId,
    required this.date,
    required this.exerciseId,
    required this.exerciseName,
    required this.sets,
    required this.reps,
    required this.durationSeconds,
    required this.status,
    this.lastModified,
  });

  /// Convert from unified model
  factory UnifiedHiveExerciseRecordEntry.fromUnified(UnifiedExerciseRecordEntry unified) {
    return UnifiedHiveExerciseRecordEntry(
      userId: unified.userId,
      date: unified.date.millisecondsSinceEpoch,
      exerciseId: unified.exerciseId,
      exerciseName: unified.exerciseName,
      sets: unified.sets,
      reps: unified.reps,
      durationSeconds: unified.durationSeconds,
      status: unified.status,
      lastModified: unified.lastModified?.millisecondsSinceEpoch,
    );
  }

  /// Convert to unified model
  UnifiedExerciseRecordEntry toUnified() {
    return UnifiedExerciseRecordEntry(
      userId: userId,
      date: DateTime.fromMillisecondsSinceEpoch(date),
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      sets: sets,
      reps: reps,
      durationSeconds: durationSeconds,
      status: status,
      lastModified: lastModified != null 
          ? DateTime.fromMillisecondsSinceEpoch(lastModified!)
          : null,
    );
  }
}

/// Updated Hive model for RehabilitationPlan using unified schema (ID-only storage)
@HiveType(typeId: 5)
class UnifiedHiveRehabilitationPlan extends HiveObject {
  @HiveField(0)
  String userId;
  
  @HiveField(1)
  List<String> exerciseIds;
  
  @HiveField(2)
  List<String> treatmentIds;
  
  @HiveField(3)
  int weekNumber;
  
  @HiveField(4)
  int? lastModified; // milliseconds since epoch

  UnifiedHiveRehabilitationPlan({
    required this.userId,
    required this.exerciseIds,
    required this.treatmentIds,
    required this.weekNumber,
    this.lastModified,
  });

  /// Convert from unified model
  factory UnifiedHiveRehabilitationPlan.fromUnified(UnifiedRehabilitationPlan unified) {
    return UnifiedHiveRehabilitationPlan(
      userId: unified.userId,
      exerciseIds: List<String>.from(unified.exerciseIds),
      treatmentIds: List<String>.from(unified.treatmentIds),
      weekNumber: unified.weekNumber,
      lastModified: unified.lastModified?.millisecondsSinceEpoch,
    );
  }

  /// Convert to unified model
  UnifiedRehabilitationPlan toUnified() {
    return UnifiedRehabilitationPlan(
      userId: userId,
      exerciseIds: List<String>.from(exerciseIds),
      treatmentIds: List<String>.from(treatmentIds),
      weekNumber: weekNumber,
      lastModified: lastModified != null 
          ? DateTime.fromMillisecondsSinceEpoch(lastModified!)
          : null,
    );
  }
}

/// Updated Hive model for ActiveProgram using unified schema
@HiveType(typeId: 6)
class UnifiedHiveActiveProgram extends HiveObject {
  @HiveField(0)
  String userId;
  
  @HiveField(1)
  int? startDate; // milliseconds since epoch
  
  @HiveField(2)
  int? lastModified; // milliseconds since epoch

  UnifiedHiveActiveProgram({
    required this.userId,
    this.startDate,
    this.lastModified,
  });

  /// Convert from unified model (if we create one)
  factory UnifiedHiveActiveProgram.fromUnified({
    required String userId,
    DateTime? startDate,
    DateTime? lastModified,
  }) {
    return UnifiedHiveActiveProgram(
      userId: userId,
      startDate: startDate?.millisecondsSinceEpoch,
      lastModified: lastModified?.millisecondsSinceEpoch,
    );
  }

  /// Convert to unified model (if we create one)
  Map<String, dynamic> toUnified() {
    return {
      'userId': userId,
      'startDate': startDate != null 
          ? DateTime.fromMillisecondsSinceEpoch(startDate!)
          : null,
      'lastModified': lastModified != null 
          ? DateTime.fromMillisecondsSinceEpoch(lastModified!)
          : null,
    };
  }
}
