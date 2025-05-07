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
  required String targetMuscles,
  required String targetPainLevel,
  required String targetPainDuration,
}) {
  return allTreatments.where((treatment) {
    // Normalize all strings for comparison
    final treatmentMuscles = treatment.musclesInvolved.toLowerCase().split(',').map((m) => m.trim()).toList();
    final targetMuscle = targetMuscles.toLowerCase().trim();
    
    // Check if any of the treatment's muscles contains the target muscle
    final muscleMatch = treatmentMuscles.any((m) => m.contains(targetMuscle));

    // Check pain level (case insensitive)
    final treatmentPainLevel = treatment.painLevel.toLowerCase();
    final painLevelMatch = treatmentPainLevel.contains(targetPainLevel.toLowerCase());

    // Check pain duration (case insensitive)
    final treatmentPainDuration = treatment.painDuration.toLowerCase();
    final painDurationMatch = treatmentPainDuration.contains(targetPainDuration.toLowerCase());

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