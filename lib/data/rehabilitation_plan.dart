import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import '../assessment/globals.dart';

// Class: For rehabilitation plan
class ExercisePlan {
  final String exerciseId;
  final int repetitions;
  final String exerciseName;
  final int sets;

  ExercisePlan({
    required this.exerciseId,
    required this.exerciseName,
    required this.repetitions,
    required this.sets,
  });

  @override
  String toString() {
    return 'ExercisePlan(exerciseId: $exerciseId, exerciseName: $exerciseName, reps: $repetitions, sets: $sets)';
  }
}

class DailyProgress {
  final String exerciseId;
  bool isCompleted;
  int repsCompleted;
  int setsCompleted;

  DailyProgress({
    required this.exerciseId,
    this.isCompleted = false,
    this.repsCompleted = 0,
    this.setsCompleted = 0,
  });

  @override
  String toString() {
    return 'Progress($exerciseId: $setsCompleted sets of $repsCompleted reps - Completed: $isCompleted)';
  }
}

class RehabilitationPlan {
  final int weekNumber;
  final List<ExercisePlan> exercises;
  final List<DailyProgress> daily;

  RehabilitationPlan({
    required this.weekNumber,
    required this.exercises,
    List<DailyProgress>? daily,
  }) : daily = daily ??
            exercises
                .map((e) => DailyProgress(exerciseId: e.exerciseId))
                .toList();

  @override
  String toString() {
    return 'Week $weekNumber:\nExercises: $exercises\nDaily Progress: $daily';
  }
}

// ======================

Future<RehabilitationPlan?> generateRehabilitationPlanFromCSV() async {
  // Load the CSV file from assets
  final rawData = await rootBundle.loadString('../../assets/data/exercises.csv');
  final List<List<dynamic>> csvData = const CsvToListConverter(eol: '\n').convert(rawData, shouldParseNumbers: false);

  // Extract header and rows
  final header = csvData.first;
  final rows = csvData.sublist(1);

  // Helper to get column index
  int col(String name) => header.indexOf(name);

  // Print: For debugging purposes
  print('Matching with:');
  print('Goal: ${UserAssess.rehabGoal}');
  print('Muscle: ${UserAssess.specificMuscle}');
  print('Pain Level: ${UserAssess.painLevel}');

  for (var row in rows) {
    print('Row: Functional_Goal=${row[col('Functional_Goal')]} | '
        'Muscle_Involved=${row[col('Muscle_Involved')]} | '
        'Pain_Level=${row[col('Pain_Level')]}');
  }

  // Filter rows
  final filtered = rows.where((row) =>
    row[col('Functional_Goal')].toString().toLowerCase().trim() ==
        UserAssess.rehabGoal.toLowerCase().trim() &&
    row[col('Muscle_Involved')].toString().toLowerCase().trim() ==
        UserAssess.specificMuscle.toLowerCase().trim() &&
    row[col('Pain_Level')].toString().toLowerCase().trim() ==
        UserAssess.painLevel.toLowerCase().trim()
  ).toList();


  if (filtered.length < 2) {
    print("Not enough exercises found based on user's assessment.");
    return null;
  }

  // Shuffle and pick 3 random rows
  filtered.shuffle(Random());
  final selectedRows = filtered.take(3).toList();

  // Convert to ExercisePlan
  final exercisePlans = selectedRows.map((row) {
    return ExercisePlan(
      exerciseId: row[col('Exercise_ID')],
      exerciseName: row[col('Exercise')],
      repetitions: int.tryParse(row[col('Repetition')]) ?? 10,
      sets: int.tryParse(row[col('Set')]) ?? 3,
    );
  }).toList();

  // Return the rehabilitation plan
  return RehabilitationPlan(
    weekNumber: 1,
    exercises: exercisePlans,
  );
}

// ============== INSTANCE ======================

class UserRehabilitation {
  static final UserRehabilitation instance = UserRehabilitation._internal();

  factory UserRehabilitation() => instance;

  UserRehabilitation._internal();

  List<RehabilitationPlan> rehabPlans = [];
}

// ============== SAMPLE USAGE ==================

// final plan = RehabilitationPlan(
//   weekNumber: 1,
//   exercises: [
//     ExercisePlan(exerciseId: 'E001', exerciseName: '', repetitions: 10, sets: 3),
//     ExercisePlan(exerciseId: 'E002', exerciseName: '', repetitions: 8, sets: 2),
//   ],
//   daily: [
//     DailyProgress(
//       exerciseId: 'E001',
//       repsCompleted: 10,
//       setsCompleted: 3,
//       isCompleted: true,
//     ),
//     DailyProgress(
//       exerciseId: 'E002',
//       repsCompleted: 6,
//       setsCompleted: 2,
//       isCompleted: false,
//     ),
//   ],
// );