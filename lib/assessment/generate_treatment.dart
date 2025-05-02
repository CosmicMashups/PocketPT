import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import '../data/treatment.dart';

Future<List<Treatment>> loadTreatmentsFromCSV() async {
  final csvData = await rootBundle.loadString('assets/data/treatment.csv');
  final List<List<dynamic>> csvTable = const CsvToListConverter().convert(csvData);

  // Skip header row and map to Treatment objects
  return csvTable.skip(1).map((row) {
    return Treatment(
      treatmentId: row[0].toString(),
      treatmentName: row[1].toString(),
      description: row[2].toString(),
      musclesInvolved: row[3].toString(),
      painLevel: row[4].toString(),
      painDuration: row[5].toString(),
    );
  }).toList();
}

List<Treatment> filterTreatments({
  required List<Treatment> allTreatments,
  required String targetMuscles,  // Now expects a single muscle
  required String targetPainLevel,
  required String targetPainDuration,
}) {
  return allTreatments.where((treatment) {
    // Check if treatment includes the target muscle
    final treatmentMuscles = treatment.musclesInvolved.split(', ');
    final muscleMatch = treatmentMuscles.contains(targetMuscles);

    // Check pain level (treatment can have multiple levels separated by comma)
    final treatmentPainLevels = treatment.painLevel.split(', ');
    final painLevelMatch = treatmentPainLevels.contains(targetPainLevel) || 
                         treatmentPainLevels.contains('$targetPainLevel,') ||
                         treatment.painLevel.contains(targetPainLevel);

    // Check pain duration (treatment can have multiple durations separated by comma)
    final treatmentPainDurations = treatment.painDuration.split(', ');
    final painDurationMatch = treatmentPainDurations.contains(targetPainDuration) || 
                            treatmentPainDurations.contains('$targetPainDuration,') ||
                            treatment.painDuration.contains(targetPainDuration);

    return muscleMatch && painLevelMatch && painDurationMatch;
  }).toList();
}

Future<List<Treatment>?> generateTreatmentPlan({
  required String specificMuscle,
  required String painLevel,
  required String painDuration,
}) async {
  try {
    final allTreatments = await loadTreatmentsFromCSV();
    final matchedTreatments = filterTreatments(
      allTreatments: allTreatments,
      targetMuscles: specificMuscle,
      targetPainLevel: painLevel,
      targetPainDuration: painDuration,
    );

    if (matchedTreatments.isEmpty) {
      return null;
    }

    return matchedTreatments.take(3).toList();
  } catch (e) {
    print('Error generating treatment plan: $e');
    return null;
  }
}