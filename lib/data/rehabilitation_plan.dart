import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import 'globals.dart';

class Exercise {
  final String exerciseId;
  final String exerciseName;
  final String description;
  final String muscle;
  final String painLevel;
  final String goal;
  final int repetitions;
  final int sets;
  final String imageUrl;
  final String videoUrl;

  Exercise({
    required this.exerciseId,
    required this.exerciseName,
    required this.description,
    required this.muscle,
    required this.painLevel,
    required this.goal,
    required this.repetitions,
    required this.sets,
    required this.imageUrl,
    required this.videoUrl,
  });

  @override
  String toString() {
    return '$exerciseName ($repetitions x $sets)';
  }
}

class RehabilitationPlan {
  final int weekNumber;
  final List<Exercise> exercises;
  final List<DailyProgress> daily;

  RehabilitationPlan({
    required this.weekNumber,
    required this.exercises,
    this.daily = const [],
  });
}

class UserRehabilitation {
  static final UserRehabilitation _instance = UserRehabilitation._internal();
  static UserRehabilitation get instance => _instance;
  UserRehabilitation._internal();

  String selectedMuscle = '';
  String selectedPainLevel = '';
  String selectedPainDuration = '';
  String selectedGoal = '';

  List<RehabilitationPlan> rehabPlans = [];
}

/// Class to track daily progress of exercises.
class DailyProgress {
  final DateTime date;
  final Map<String, bool> completedExercises;

  DailyProgress({
    required this.date,
    required this.completedExercises,
  });
}

/// Reads the CSV from assets and parses the data.
Future<List<List<dynamic>>> loadCSVFromAsset(String path) async {
  try {
    final rawCSV = await rootBundle.loadString(path);
    print('CSV data loaded from $path');
    final parsedCSV = const CsvToListConverter().convert(rawCSV);
    print('CSV parsed successfully');
    return parsedCSV;
  } catch (e) {
    print('Error loading CSV: $e');
    rethrow; // Re-throw the exception after logging
  }
}

/// Generates a rehabilitation plan from the CSV based on selected user inputs.
Future<RehabilitationPlan?> generateRehabilitationPlanFromCSV() async {
  try {
    final csvData = await loadCSVFromAsset('assets/data/exercises.csv');
    print('CSV data: $csvData');

    final header = csvData.first;
    final data = csvData.sublist(1); // remove header row
    print('CSV Header: $header');
    print('CSV Data: ${data.length} rows');

    // Validate headers
    final requiredHeaders = [
      'Exercise_ID',
      'Exercise',
      'Exercise_Description',
      'Muscle_Involved',
      'Pain_Level',
      'Functional_Goal',
      'Repetition',
      'Set',
      'Image_Link',
      'Video_Link',
    ];

    for (final field in requiredHeaders) {
      if (!header.contains(field)) {
        print('Missing column: $field');
        throw Exception('Missing column: $field in CSV header');
      }
    }

    int col(String name) => header.indexOf(name);

    // Filter exercises based on selected criteria
    final filteredExercises = data.where((row) {
      bool muscleMatch = row[col('Muscle_Involved')].toString().toLowerCase() == UserAssess.specificMuscle.toLowerCase().trim();
      bool painLevelMatch = row[col('Pain_Level')].toString().toLowerCase() == UserAssess.painLevel.toLowerCase().trim();
      bool goalMatch = row[col('Functional_Goal')].toString().toLowerCase() ==UserAssess.rehabGoal.toLowerCase().trim();

      print('Matching row: ${row[col('Exercise')]}, Muscle Match: $muscleMatch, Pain Level Match: $painLevelMatch, Goal Match: $goalMatch \n CSV: ${row[col('Muscle_Involved')].toString().toLowerCase()}, Input: ${UserAssess.painLevel.toLowerCase().trim()}');

      return muscleMatch && painLevelMatch && goalMatch;
    }).toList();

    print('Filtered exercises: ${filteredExercises.length} exercises found');

    if (filteredExercises.length < 2) {
      print('Not enough exercises found, returning null');
      return null;
    }

    final random = Random();
    filteredExercises.shuffle(random);

    final selected = filteredExercises.take(3).map((row) {
      print('Selected exercise: ${row[col('Exercise')]}');
      return Exercise(
        exerciseId: row[col('Exercise_ID')].toString(),
        exerciseName: row[col('Exercise')].toString(),
        description: row[col('Exercise_Description')].toString(),
        muscle: row[col('Muscle_Involved')].toString(),
        painLevel: row[col('Pain_Level')].toString(),
        goal: row[col('Functional_Goal')].toString(),
        repetitions: int.tryParse(row[col('Repetition')].toString()) ?? 0,
        sets: int.tryParse(row[col('Set')].toString()) ?? 0,
        imageUrl: row[col('Image_Link')].toString(),
        videoUrl: row[col('Video_Link')].toString(),
      );
    }).toList();

    return RehabilitationPlan(weekNumber: 1, exercises: selected);
  } catch (e) {
    print('Error generating rehabilitation plan: $e');
    return null; // Return null if an error occurs
  }
}