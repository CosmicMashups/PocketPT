import 'package:flutter_riverpod/flutter_riverpod.dart';

// Models
class RehabPlan {
  final String title;
  final String icdCode;
  final String status;
  final DateTime startDate;
  final String focusArea;
  final String targetMuscle;

  RehabPlan({
    required this.title,
    required this.icdCode,
    required this.status,
    required this.startDate,
    required this.focusArea,
    required this.targetMuscle,
  });
}

class ExerciseRecord {
  final DateTime date;
  final String exerciseName;
  final int sets;
  final int reps;
  final String status;

  ExerciseRecord({
    required this.date,
    required this.exerciseName,
    required this.sets,
    required this.reps,
    required this.status,
  });
}

// Providers
final rehabPlansProvider = StateProvider<List<RehabPlan>>((ref) {
  // TODO: Replace with actual data from backend
  return [
    RehabPlan(
      title: 'Alleviate Pain - Rotator Cuff',
      icdCode: 'M25.561',
      status: 'ongoing',
      startDate: DateTime(2024, 4, 1),
      focusArea: 'Upper Body',
      targetMuscle: 'Rotator Cuff',
    ),
    RehabPlan(
      title: 'Strengthen - Deltoids',
      icdCode: 'M75.100',
      status: 'ongoing',
      startDate: DateTime(2024, 4, 1),
      focusArea: 'Upper Body',
      targetMuscle: 'Deltoids',
    ),
    RehabPlan(
      title: 'Improve Mobility - Quadriceps',
      icdCode: 'M62.81',
      status: 'ongoing',
      startDate: DateTime(2024, 4, 1),
      focusArea: 'Lower Body',
      targetMuscle: 'Quadriceps',
    ),
  ];
});

final selectedDateProvider = StateProvider<DateTime>((ref) {
  return DateTime.now();
});

final exerciseRecordsProvider = StateProvider<List<ExerciseRecord>>((ref) {
  // TODO: Replace with actual data from backend
  return [
    ExerciseRecord(
      date: DateTime(2024, 4, 1),
      exerciseName: 'External Rotation',
      sets: 3,
      reps: 12,
      status: 'completed',
    ),
    ExerciseRecord(
      date: DateTime(2024, 4, 1),
      exerciseName: 'Internal Rotation',
      sets: 3,
      reps: 12,
      status: 'completed',
    ),
  ];
}); 