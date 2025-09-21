// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiveDailyProgressAdapter extends TypeAdapter<HiveDailyProgress> {
  @override
  final int typeId = 0;

  @override
  HiveDailyProgress read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveDailyProgress(
      date: fields[0] as DateTime,
      completedExercises: (fields[1] as Map).cast<String, bool>(),
    );
  }

  @override
  void write(BinaryWriter writer, HiveDailyProgress obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.completedExercises);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveDailyProgressAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HiveRehabilitationPlanAdapter
    extends TypeAdapter<HiveRehabilitationPlan> {
  @override
  final int typeId = 8;

  @override
  HiveRehabilitationPlan read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveRehabilitationPlan(
      weekNumber: fields[0] as int,
      exerciseReferences: (fields[1] as List).cast<HiveExerciseReference>(),
      daily: (fields[2] as List).cast<HiveDailyProgress>(),
    );
  }

  @override
  void write(BinaryWriter writer, HiveRehabilitationPlan obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.weekNumber)
      ..writeByte(1)
      ..write(obj.exerciseReferences)
      ..writeByte(2)
      ..write(obj.daily);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveRehabilitationPlanAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HivePainRecordEntryAdapter extends TypeAdapter<HivePainRecordEntry> {
  @override
  final int typeId = 1;

  @override
  HivePainRecordEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HivePainRecordEntry(
      date: fields[0] as DateTime,
      painScale: fields[1] as int,
      painLevel: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, HivePainRecordEntry obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.painScale)
      ..writeByte(2)
      ..write(obj.painLevel);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HivePainRecordEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HiveExerciseRecordEntryAdapter
    extends TypeAdapter<HiveExerciseRecordEntry> {
  @override
  final int typeId = 2;

  @override
  HiveExerciseRecordEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveExerciseRecordEntry(
      date: fields[0] as DateTime,
      exerciseId: fields[1] as String,
      exerciseName: fields[2] as String,
      sets: fields[3] as int,
      reps: fields[4] as int,
      durationSeconds: fields[5] as int,
      status: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, HiveExerciseRecordEntry obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.exerciseId)
      ..writeByte(2)
      ..write(obj.exerciseName)
      ..writeByte(3)
      ..write(obj.sets)
      ..writeByte(4)
      ..write(obj.reps)
      ..writeByte(5)
      ..write(obj.durationSeconds)
      ..writeByte(6)
      ..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveExerciseRecordEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HiveUserProgressAdapter extends TypeAdapter<HiveUserProgress> {
  @override
  final int typeId = 3;

  @override
  HiveUserProgress read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveUserProgress(
      title: fields[0] as String,
      titleColor: fields[1] as String,
      streak: fields[2] as int,
      totalDays: fields[3] as int,
      totalExercises: fields[4] as int,
      totalSeconds: fields[5] as int,
      notes: fields[6] as String?,
      lastExerciseDate: fields[7] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, HiveUserProgress obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.titleColor)
      ..writeByte(2)
      ..write(obj.streak)
      ..writeByte(3)
      ..write(obj.totalDays)
      ..writeByte(4)
      ..write(obj.totalExercises)
      ..writeByte(5)
      ..write(obj.totalSeconds)
      ..writeByte(6)
      ..write(obj.notes)
      ..writeByte(7)
      ..write(obj.lastExerciseDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveUserProgressAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HiveUserAssessAdapter extends TypeAdapter<HiveUserAssess> {
  @override
  final int typeId = 4;

  @override
  HiveUserAssess read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveUserAssess(
      rehabGoal: fields[0] as String,
      generalMuscle: fields[1] as String,
      specificMuscle: fields[2] as String,
      painScale: fields[3] as int,
      painLevel: fields[4] as String,
      painType: fields[5] as String,
      painDuration: fields[6] as String,
      isInjured: fields[7] as bool,
      isAssessed: fields[8] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, HiveUserAssess obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.rehabGoal)
      ..writeByte(1)
      ..write(obj.generalMuscle)
      ..writeByte(2)
      ..write(obj.specificMuscle)
      ..writeByte(3)
      ..write(obj.painScale)
      ..writeByte(4)
      ..write(obj.painLevel)
      ..writeByte(5)
      ..write(obj.painType)
      ..writeByte(6)
      ..write(obj.painDuration)
      ..writeByte(7)
      ..write(obj.isInjured)
      ..writeByte(8)
      ..write(obj.isAssessed);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveUserAssessAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HiveUserSettingsAdapter extends TypeAdapter<HiveUserSettings> {
  @override
  final int typeId = 5;

  @override
  HiveUserSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveUserSettings(
      isDailyReminder: fields[0] as bool,
      isStreakAlert: fields[1] as bool,
      isExerciseReminder: fields[2] as bool,
      exerciseReminderHour: fields[3] as int,
      exerciseReminderMinute: fields[4] as int,
    );
  }

  @override
  void write(BinaryWriter writer, HiveUserSettings obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.isDailyReminder)
      ..writeByte(1)
      ..write(obj.isStreakAlert)
      ..writeByte(2)
      ..write(obj.isExerciseReminder)
      ..writeByte(3)
      ..write(obj.exerciseReminderHour)
      ..writeByte(4)
      ..write(obj.exerciseReminderMinute);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveUserSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HiveUserDetailsAdapter extends TypeAdapter<HiveUserDetails> {
  @override
  final int typeId = 6;

  @override
  HiveUserDetails read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveUserDetails(
      firstName: fields[0] as String,
      lastName: fields[1] as String,
      email: fields[2] as String,
      password: fields[3] as String,
      notifications: (fields[4] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, HiveUserDetails obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.firstName)
      ..writeByte(1)
      ..write(obj.lastName)
      ..writeByte(2)
      ..write(obj.email)
      ..writeByte(3)
      ..write(obj.password)
      ..writeByte(4)
      ..write(obj.notifications);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveUserDetailsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HiveActiveProgramAdapter extends TypeAdapter<HiveActiveProgram> {
  @override
  final int typeId = 7;

  @override
  HiveActiveProgram read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveActiveProgram(
      startDate: fields[0] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, HiveActiveProgram obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.startDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveActiveProgramAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HiveExerciseReferenceAdapter extends TypeAdapter<HiveExerciseReference> {
  @override
  final int typeId = 9;

  @override
  HiveExerciseReference read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveExerciseReference(
      exerciseId: fields[0] as String,
      repetitions: fields[1] as int,
      sets: fields[2] as int,
    );
  }

  @override
  void write(BinaryWriter writer, HiveExerciseReference obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.exerciseId)
      ..writeByte(1)
      ..write(obj.repetitions)
      ..writeByte(2)
      ..write(obj.sets);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveExerciseReferenceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HiveTreatmentReferenceAdapter
    extends TypeAdapter<HiveTreatmentReference> {
  @override
  final int typeId = 10;

  @override
  HiveTreatmentReference read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveTreatmentReference(
      treatmentId: fields[0] as String,
    );
  }

  @override
  void write(BinaryWriter writer, HiveTreatmentReference obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.treatmentId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveTreatmentReferenceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HiveExerciseIdsAdapter extends TypeAdapter<HiveExerciseIds> {
  @override
  final int typeId = 11;

  @override
  HiveExerciseIds read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveExerciseIds(
      exerciseIds: (fields[0] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, HiveExerciseIds obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.exerciseIds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveExerciseIdsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HiveTreatmentIdsAdapter extends TypeAdapter<HiveTreatmentIds> {
  @override
  final int typeId = 12;

  @override
  HiveTreatmentIds read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveTreatmentIds(
      treatmentIds: (fields[0] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, HiveTreatmentIds obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.treatmentIds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveTreatmentIdsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
