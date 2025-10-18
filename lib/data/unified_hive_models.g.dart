// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unified_hive_models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UnifiedHiveUserDetailsAdapter
    extends TypeAdapter<UnifiedHiveUserDetails> {
  @override
  final int typeId = 0;

  @override
  UnifiedHiveUserDetails read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UnifiedHiveUserDetails(
      userId: fields[0] as String,
      firstName: fields[1] as String,
      lastName: fields[2] as String,
      email: fields[3] as String,
      password: fields[4] as String,
      profilePicture: fields[5] as String,
      hasCompletedAssessment: fields[6] as bool,
      isGuest: fields[7] as bool,
      guestSessionId: fields[8] as String?,
      notifications: (fields[9] as List).cast<String>(),
      lastModified: fields[10] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, UnifiedHiveUserDetails obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.firstName)
      ..writeByte(2)
      ..write(obj.lastName)
      ..writeByte(3)
      ..write(obj.email)
      ..writeByte(4)
      ..write(obj.password)
      ..writeByte(5)
      ..write(obj.profilePicture)
      ..writeByte(6)
      ..write(obj.hasCompletedAssessment)
      ..writeByte(7)
      ..write(obj.isGuest)
      ..writeByte(8)
      ..write(obj.guestSessionId)
      ..writeByte(9)
      ..write(obj.notifications)
      ..writeByte(10)
      ..write(obj.lastModified);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UnifiedHiveUserDetailsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UnifiedHiveUserProgressAdapter
    extends TypeAdapter<UnifiedHiveUserProgress> {
  @override
  final int typeId = 1;

  @override
  UnifiedHiveUserProgress read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UnifiedHiveUserProgress(
      userId: fields[0] as String,
      title: fields[1] as String,
      titleColor: fields[2] as String,
      streak: fields[3] as int,
      totalDays: fields[4] as int,
      totalExercises: fields[5] as int,
      totalSeconds: fields[6] as int,
      notes: fields[7] as String?,
      lastExerciseDate: fields[8] as int?,
      lastModified: fields[9] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, UnifiedHiveUserProgress obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.titleColor)
      ..writeByte(3)
      ..write(obj.streak)
      ..writeByte(4)
      ..write(obj.totalDays)
      ..writeByte(5)
      ..write(obj.totalExercises)
      ..writeByte(6)
      ..write(obj.totalSeconds)
      ..writeByte(7)
      ..write(obj.notes)
      ..writeByte(8)
      ..write(obj.lastExerciseDate)
      ..writeByte(9)
      ..write(obj.lastModified);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UnifiedHiveUserProgressAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UnifiedHiveUserSettingsAdapter
    extends TypeAdapter<UnifiedHiveUserSettings> {
  @override
  final int typeId = 2;

  @override
  UnifiedHiveUserSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UnifiedHiveUserSettings(
      userId: fields[0] as String,
      isDailyReminder: fields[1] as bool,
      isStreakAlert: fields[2] as bool,
      isExerciseReminder: fields[3] as bool,
      exerciseReminderHour: fields[4] as int,
      exerciseReminderMinute: fields[5] as int,
      lastModified: fields[6] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, UnifiedHiveUserSettings obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.isDailyReminder)
      ..writeByte(2)
      ..write(obj.isStreakAlert)
      ..writeByte(3)
      ..write(obj.isExerciseReminder)
      ..writeByte(4)
      ..write(obj.exerciseReminderHour)
      ..writeByte(5)
      ..write(obj.exerciseReminderMinute)
      ..writeByte(6)
      ..write(obj.lastModified);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UnifiedHiveUserSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UnifiedHivePainRecordEntryAdapter
    extends TypeAdapter<UnifiedHivePainRecordEntry> {
  @override
  final int typeId = 3;

  @override
  UnifiedHivePainRecordEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UnifiedHivePainRecordEntry(
      userId: fields[0] as String,
      date: fields[1] as int,
      painScale: fields[2] as int,
      painLevel: fields[3] as String,
      lastModified: fields[4] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, UnifiedHivePainRecordEntry obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.painScale)
      ..writeByte(3)
      ..write(obj.painLevel)
      ..writeByte(4)
      ..write(obj.lastModified);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UnifiedHivePainRecordEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UnifiedHiveExerciseRecordEntryAdapter
    extends TypeAdapter<UnifiedHiveExerciseRecordEntry> {
  @override
  final int typeId = 4;

  @override
  UnifiedHiveExerciseRecordEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UnifiedHiveExerciseRecordEntry(
      userId: fields[0] as String,
      date: fields[1] as int,
      exerciseId: fields[2] as String,
      exerciseName: fields[3] as String,
      sets: fields[4] as int,
      reps: fields[5] as int,
      durationSeconds: fields[6] as int,
      status: fields[7] as String,
      lastModified: fields[8] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, UnifiedHiveExerciseRecordEntry obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.exerciseId)
      ..writeByte(3)
      ..write(obj.exerciseName)
      ..writeByte(4)
      ..write(obj.sets)
      ..writeByte(5)
      ..write(obj.reps)
      ..writeByte(6)
      ..write(obj.durationSeconds)
      ..writeByte(7)
      ..write(obj.status)
      ..writeByte(8)
      ..write(obj.lastModified);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UnifiedHiveExerciseRecordEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UnifiedHiveRehabilitationPlanAdapter
    extends TypeAdapter<UnifiedHiveRehabilitationPlan> {
  @override
  final int typeId = 5;

  @override
  UnifiedHiveRehabilitationPlan read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UnifiedHiveRehabilitationPlan(
      userId: fields[0] as String,
      exerciseIds: (fields[1] as List).cast<String>(),
      treatmentIds: (fields[2] as List).cast<String>(),
      weekNumber: fields[3] as int,
      lastModified: fields[4] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, UnifiedHiveRehabilitationPlan obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.exerciseIds)
      ..writeByte(2)
      ..write(obj.treatmentIds)
      ..writeByte(3)
      ..write(obj.weekNumber)
      ..writeByte(4)
      ..write(obj.lastModified);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UnifiedHiveRehabilitationPlanAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class UnifiedHiveActiveProgramAdapter
    extends TypeAdapter<UnifiedHiveActiveProgram> {
  @override
  final int typeId = 6;

  @override
  UnifiedHiveActiveProgram read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UnifiedHiveActiveProgram(
      userId: fields[0] as String,
      startDate: fields[1] as int?,
      lastModified: fields[2] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, UnifiedHiveActiveProgram obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.startDate)
      ..writeByte(2)
      ..write(obj.lastModified);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UnifiedHiveActiveProgramAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
