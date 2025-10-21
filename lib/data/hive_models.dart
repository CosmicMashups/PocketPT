import 'package:hive/hive.dart';
import '../data/rehabilitation_plan.dart';
import '../data/treatment.dart';
import '../data/globals.dart';

part 'hive_models.g.dart';


@HiveType(typeId: 0)
class HiveDailyProgress extends HiveObject {
  @HiveField(0)
  DateTime date;
  @HiveField(1)
  Map<String, bool> completedExercises;

  HiveDailyProgress({
    required this.date,
    required this.completedExercises,
  });

  factory HiveDailyProgress.fromDailyProgress(DailyProgress progress) => HiveDailyProgress(
    date: progress.date,
    completedExercises: Map<String, bool>.from(progress.completedExercises),
  );

  DailyProgress toDailyProgress() => DailyProgress(
    date: date,
    completedExercises: Map<String, bool>.from(completedExercises),
  );
}

@HiveType(typeId: 8)
class HiveRehabilitationPlan extends HiveObject {
  @HiveField(0)
  int weekNumber;
  @HiveField(1)
  List<HiveExerciseReference> exerciseReferences;
  @HiveField(2)
  List<HiveDailyProgress> daily;

  HiveRehabilitationPlan({
    required this.weekNumber,
    required this.exerciseReferences,
    required this.daily,
  });

  factory HiveRehabilitationPlan.fromPlan(RehabilitationPlan plan) => HiveRehabilitationPlan(
    weekNumber: plan.weekNumber,
    exerciseReferences: plan.exerciseReferences.map(HiveExerciseReference.fromExerciseReference).toList(),
    daily: plan.daily.map(HiveDailyProgress.fromDailyProgress).toList(),
  );

  RehabilitationPlan toPlan() => RehabilitationPlan(
    weekNumber: weekNumber,
    exerciseReferences: exerciseReferences.map((e) => e.toExerciseReference()).toList(),
    daily: daily.map((d) => d.toDailyProgress()).toList(),
  );
}


@HiveType(typeId: 1)
class HivePainRecordEntry extends HiveObject {
  @HiveField(0)
  DateTime date;
  @HiveField(1)
  int painScale;
  @HiveField(2)
  String painLevel;

  HivePainRecordEntry({
    required this.date,
    required this.painScale,
    required this.painLevel,
  });

  factory HivePainRecordEntry.fromPainRecordEntry(PainRecordEntry entry) => HivePainRecordEntry(
    date: entry.date,
    painScale: entry.painScale,
    painLevel: entry.painLevel,
  );

  PainRecordEntry toPainRecordEntry() => PainRecordEntry(
    date: date,
    painScale: painScale,
    painLevel: painLevel,
  );
}

@HiveType(typeId: 2)
class HiveExerciseRecordEntry extends HiveObject {
  @HiveField(0)
  DateTime date;
  @HiveField(1)
  String exerciseId;
  @HiveField(2)
  String exerciseName;
  @HiveField(3)
  int sets;
  @HiveField(4)
  int reps;
  @HiveField(5)
  int durationSeconds;
  @HiveField(6)
  String status; // 'completed', 'skipped', 'partial'

  HiveExerciseRecordEntry({
    required this.date,
    required this.exerciseId,
    required this.exerciseName,
    required this.sets,
    required this.reps,
    required this.durationSeconds,
    required this.status,
  });

  factory HiveExerciseRecordEntry.fromExerciseRecordEntry(ExerciseRecordEntry entry) => HiveExerciseRecordEntry(
    date: entry.date,
    exerciseId: entry.exerciseId,
    exerciseName: entry.exerciseName,
    sets: entry.sets,
    reps: entry.reps,
    durationSeconds: entry.durationSeconds,
    status: entry.status,
  );

  ExerciseRecordEntry toExerciseRecordEntry() => ExerciseRecordEntry(
    date: date,
    exerciseId: exerciseId,
    exerciseName: exerciseName,
    sets: sets,
    reps: reps,
    durationSeconds: durationSeconds,
    status: status,
  );
}

@HiveType(typeId: 3)
class HiveUserProgress extends HiveObject {
  @HiveField(0)
  String title;
  @HiveField(1)
  String titleColor;
  @HiveField(2)
  int streak;
  @HiveField(3)
  int totalDays;
  @HiveField(4)
  int totalExercises;
  @HiveField(5)
  int totalSeconds;
  @HiveField(6)
  String? notes;
  @HiveField(7)
  DateTime? lastExerciseDate;

  HiveUserProgress({
    required this.title,
    required this.titleColor,
    required this.streak,
    required this.totalDays,
    required this.totalExercises,
    required this.totalSeconds,
    this.notes,
    this.lastExerciseDate,
  });
}

@HiveType(typeId: 4)
class HiveUserAssess extends HiveObject {
  @HiveField(0)
  String rehabGoal;
  @HiveField(1)
  String generalMuscle;
  @HiveField(2)
  String specificMuscle;
  @HiveField(3)
  int painScale;
  @HiveField(4)
  String painLevel;
  @HiveField(5)
  String painType;
  @HiveField(6)
  String painDuration;
  @HiveField(7)
  bool isInjured;
  @HiveField(8)
  bool isAssessed;

  HiveUserAssess({
    required this.rehabGoal,
    required this.generalMuscle,
    required this.specificMuscle,
    required this.painScale,
    required this.painLevel,
    required this.painType,
    required this.painDuration,
    required this.isInjured,
    required this.isAssessed,
  });
}

@HiveType(typeId: 5)
class HiveUserSettings extends HiveObject {
  @HiveField(0)
  bool isDailyReminder;
  @HiveField(1)
  bool isStreakAlert;
  @HiveField(2)
  bool isExerciseReminder;
  @HiveField(3)
  int exerciseReminderHour;
  @HiveField(4)
  int exerciseReminderMinute;

  HiveUserSettings({
    required this.isDailyReminder,
    required this.isStreakAlert,
    required this.isExerciseReminder,
    required this.exerciseReminderHour,
    required this.exerciseReminderMinute,
  });
}

@HiveType(typeId: 6)
class HiveUserDetails extends HiveObject {
  @HiveField(0)
  String firstName;
  @HiveField(1)
  String lastName;
  @HiveField(2)
  String email;
  @HiveField(3)
  String password;
  @HiveField(4)
  List<String> notifications;
  @HiveField(5)
  bool isGuest;
  @HiveField(6)
  String? guestSessionId;
  @HiveField(7)
  String profilePicture;

  HiveUserDetails({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
    required this.notifications,
    this.isGuest = false,
    this.guestSessionId,
    required this.profilePicture,
  });
}

@HiveType(typeId: 7)
class HiveActiveProgram extends HiveObject {
  @HiveField(0)
  DateTime? startDate;

  HiveActiveProgram({
    this.startDate,
  });
}

@HiveType(typeId: 9)
class HiveExerciseReference extends HiveObject {
  @HiveField(0)
  String exerciseId;
  @HiveField(1)
  int repetitions;
  @HiveField(2)
  int sets;

  HiveExerciseReference({
    required this.exerciseId,
    required this.repetitions,
    required this.sets,
  });

  factory HiveExerciseReference.fromExerciseReference(ExerciseReference ref) => HiveExerciseReference(
    exerciseId: ref.exerciseId,
    repetitions: ref.repetitions,
    sets: ref.sets,
  );

  ExerciseReference toExerciseReference() => ExerciseReference(
    exerciseId: exerciseId,
    repetitions: repetitions,
    sets: sets,
  );
}

@HiveType(typeId: 10)
class HiveTreatmentReference extends HiveObject {
  @HiveField(0)
  String treatmentId;

  HiveTreatmentReference({
    required this.treatmentId,
  });

  factory HiveTreatmentReference.fromTreatmentReference(TreatmentReference ref) => HiveTreatmentReference(
    treatmentId: ref.treatmentId,
  );

  TreatmentReference toTreatmentReference() => TreatmentReference(
    treatmentId: treatmentId,
  );
}

// New Hive models for ID-only storage (matching Firebase structure)
@HiveType(typeId: 11)
class HiveExerciseIds extends HiveObject {
  @HiveField(0)
  List<String> exerciseIds;

  HiveExerciseIds({
    required this.exerciseIds,
  });
}

@HiveType(typeId: 12)
class HiveTreatmentIds extends HiveObject {
  @HiveField(0)
  List<String> treatmentIds;

  HiveTreatmentIds({
    required this.treatmentIds,
  });
}

@HiveType(typeId: 13)
class HiveCustomExercise extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  String name;
  @HiveField(2)
  String description;
  @HiveField(3)
  String muscle;
  @HiveField(4)
  String painLevel;
  @HiveField(5)
  String goal;
  @HiveField(6)
  int rep;
  @HiveField(7)
  int set;
  @HiveField(8)
  String imageUrl;
  @HiveField(9)
  String videoUrl;
  @HiveField(10)
  String otherMuscles;
  @HiveField(11)
  DateTime createdAt;
  @HiveField(12)
  DateTime lastModified;

  HiveCustomExercise({
    required this.id,
    required this.name,
    required this.description,
    required this.muscle,
    required this.painLevel,
    required this.goal,
    required this.rep,
    required this.set,
    required this.imageUrl,
    required this.videoUrl,
    required this.otherMuscles,
    required this.createdAt,
    required this.lastModified,
  });
}