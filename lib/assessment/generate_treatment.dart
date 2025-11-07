import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import '../data/treatment.dart';
import '../data/rehabilitation_plan.dart';

/// Load treatments from CSV with comprehensive error handling and logging
Future<List<Treatment>> loadTreatmentsFromCSV() async {
  try {
    print('GenerateTreatment: Loading treatments from CSV...');
    final csvData = await loadCSVFromAsset('assets/data/treatment.csv');
    
    if (csvData.isEmpty) {
      print('GenerateTreatment: CSV file is empty');
      return [];
    }
    
    // Expected column count for treatment CSV
    const expectedColumnCount = 6;
    
    // Fix malformed header: if first row has too many columns, truncate to expected count
    List<dynamic> header = csvData.first;
    if (header.length > expectedColumnCount) {
      print('GenerateTreatment: [TREATMENT FIX] Header row has ${header.length} columns (expected $expectedColumnCount), truncating...');
      header = header.sublist(0, expectedColumnCount);
    }
    
    final data = csvData.sublist(1);
    
    // Build normalized header map for debug
    String _norm(String s) {
      if (s.isEmpty) return s;
      var t = s.replaceAll('\r', '').trim();
      if (t.isNotEmpty && t.codeUnitAt(0) == 0xFEFF) t = t.substring(1);
      if (t.startsWith('"') && t.endsWith('"') && t.length >= 2) {
        t = t.substring(1, t.length - 1);
      }
      t = t.toLowerCase().replaceAll(' ', '_');
      return t;
    }
    final Map<String, int> headerMap = <String, int>{};
    for (int i = 0; i < header.length && i < expectedColumnCount; i++) {
      final normalizedKey = _norm(header[i].toString());
      headerMap[normalizedKey] = i;
    }
    
    // Debug: print treatment CSV header info
    print('GenerateTreatment: [TREATMENT HEADER] Raw header row has ${header.length} columns (using first $expectedColumnCount)');
    print('GenerateTreatment: [TREATMENT HEADER] Raw header (first $expectedColumnCount): ${header.take(expectedColumnCount).toList()}');
    final normalizedColumns = headerMap.keys.toList()..sort();
    print('GenerateTreatment: [TREATMENT HEADER] Normalized column names (${normalizedColumns.length}): ${normalizedColumns.join(', ')}');
    print('GenerateTreatment: [TREATMENT HEADER] Header map entries: ${headerMap.entries.map((e) => '${e.key}->${e.value}').join(', ')}');
    print('GenerateTreatment: [TREATMENT DATA] ${data.length} treatment rows');

    // Skip header row and map to Treatment objects
    final treatments = data.map((row) {
      if (row.length < 6) {
        print('GenerateTreatment: Warning - row has insufficient columns: ${row.length}');
        return null;
      }
      
      return Treatment(
        treatmentId: row[0].toString(),
        treatmentName: row[1].toString(),
        description: row[2].toString(),
        musclesInvolved: row[3].toString(),
        painLevel: row[4].toString(),
        painDuration: row[5].toString(),
      );
    }).where((treatment) => treatment != null).cast<Treatment>().toList();

    print('GenerateTreatment: Successfully loaded ${treatments.length} treatments from CSV');
    return treatments;
  } catch (e, stackTrace) {
    print('GenerateTreatment: ERROR loading treatments from CSV - $e');
    print('GenerateTreatment: Stack trace: $stackTrace');
    return [];
  }
}

/// Filter treatments based on target criteria with comprehensive logging
List<Treatment> filterTreatments({
  required List<Treatment> allTreatments,
  required String targetMuscles,  // Now expects a single muscle
  required String targetPainLevel,
  required String targetPainDuration,
}) {
  try {
    print('GenerateTreatment: Filtering treatments...');
    print('GenerateTreatment: Target muscle: "$targetMuscles"');
    print('GenerateTreatment: Target pain level: "$targetPainLevel"');
    print('GenerateTreatment: Target pain duration: "$targetPainDuration"');
    print('GenerateTreatment: Total treatments to filter: ${allTreatments.length}');

    final filteredTreatments = allTreatments.where((treatment) {
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

      final matches = muscleMatch && painLevelMatch && painDurationMatch;
      
      if (matches) {
        print('GenerateTreatment: Match found - ${treatment.treatmentName} (${treatment.treatmentId})');
      }

      return matches;
    }).toList();

    print('GenerateTreatment: Filtering completed - ${filteredTreatments.length} treatments match criteria');
    return filteredTreatments;
  } catch (e, stackTrace) {
    print('GenerateTreatment: ERROR filtering treatments - $e');
    print('GenerateTreatment: Stack trace: $stackTrace');
    return [];
  }
}

/// Generate treatment plan with comprehensive error handling and logging
Future<List<TreatmentReference>?> generateTreatmentPlan({
  required String specificMuscle,
  required String painLevel,
  required String painDuration,
}) async {
  print('=== GenerateTreatment: generateTreatmentPlan() START ===');
  print('GenerateTreatment: specificMuscle = "$specificMuscle"');
  print('GenerateTreatment: painLevel = "$painLevel"');
  print('GenerateTreatment: painDuration = "$painDuration"');
  
  try {
    // Load all treatments from CSV
    print('GenerateTreatment: Loading treatments from CSV...');
    final allTreatments = await loadTreatmentsFromCSV();
    
    if (allTreatments.isEmpty) {
      print('GenerateTreatment: No treatments loaded from CSV');
      return null;
    }
    
    print('GenerateTreatment: Loaded ${allTreatments.length} treatments from CSV');
    
    // Filter treatments based on criteria
    print('GenerateTreatment: Filtering treatments based on criteria...');
    final matchedTreatments = filterTreatments(
      allTreatments: allTreatments,
      targetMuscles: specificMuscle,
      targetPainLevel: painLevel,
      targetPainDuration: painDuration,
    );

    if (matchedTreatments.isEmpty) {
      print('GenerateTreatment: No treatments match the specified criteria');
      return null;
    }
    
    print('GenerateTreatment: Found ${matchedTreatments.length} matching treatments');

    // Remove duplicate treatments based on treatmentId to ensure uniqueness
    print('GenerateTreatment: Removing duplicates...');
    final uniqueTreatments = <String, Treatment>{};
    for (final treatment in matchedTreatments) {
      if (!uniqueTreatments.containsKey(treatment.treatmentId)) {
        uniqueTreatments[treatment.treatmentId] = treatment;
      }
    }
    
    final deduplicatedTreatments = uniqueTreatments.values.toList();
    print('GenerateTreatment: Unique treatments after deduplication: ${deduplicatedTreatments.length} treatments found');

    if (deduplicatedTreatments.isEmpty) {
      print('GenerateTreatment: No unique treatments found after deduplication');
      return null;
    }

    // Create treatment references (limit to 3)
    final treatmentReferences = deduplicatedTreatments.take(3).map((treatment) => 
      TreatmentReference(treatmentId: treatment.treatmentId)
    ).toList();
    
    print('GenerateTreatment: Generated ${treatmentReferences.length} treatment references');
    print('GenerateTreatment: Treatment IDs: ${treatmentReferences.map((ref) => ref.treatmentId).join(", ")}');
    print('=== GenerateTreatment: generateTreatmentPlan() COMPLETED successfully ===');
    
    return treatmentReferences;
  } catch (e, stackTrace) {
    print('GenerateTreatment: ERROR in generateTreatmentPlan() - $e');
    print('GenerateTreatment: Stack trace: $stackTrace');
    print('=== GenerateTreatment: generateTreatmentPlan() FAILED ===');
    return null;
  }
}

/// Generate treatment plan using ExerciseDataService for consistency with generate_plan.dart
Future<List<TreatmentReference>?> generateTreatmentPlanFromService({
  required String specificMuscle,
  required String painLevel,
  required String painDuration,
}) async {
  print('=== GenerateTreatment: generateTreatmentPlanFromService() START ===');
  print('GenerateTreatment: specificMuscle = "$specificMuscle"');
  print('GenerateTreatment: painLevel = "$painLevel"');
  print('GenerateTreatment: painDuration = "$painDuration"');
  
  try {
    // Use ExerciseDataService for consistency with generate_plan.dart
    print('GenerateTreatment: Loading treatments using ExerciseDataService...');
    final allTreatments = await ExerciseDataService.loadAllTreatments();
    
    if (allTreatments.isEmpty) {
      print('GenerateTreatment: No treatments loaded from ExerciseDataService');
      return null;
    }
    
    print('GenerateTreatment: Loaded ${allTreatments.length} treatments from ExerciseDataService');
    
    // Filter treatments based on criteria
    print('GenerateTreatment: Filtering treatments based on criteria...');
    final matchedTreatments = filterTreatments(
      allTreatments: allTreatments,
      targetMuscles: specificMuscle,
      targetPainLevel: painLevel,
      targetPainDuration: painDuration,
    );

    if (matchedTreatments.isEmpty) {
      print('GenerateTreatment: No treatments match the specified criteria');
      return null;
    }
    
    print('GenerateTreatment: Found ${matchedTreatments.length} matching treatments');

    // Remove duplicate treatments based on treatmentId to ensure uniqueness
    print('GenerateTreatment: Removing duplicates...');
    final uniqueTreatments = <String, Treatment>{};
    for (final treatment in matchedTreatments) {
      if (!uniqueTreatments.containsKey(treatment.treatmentId)) {
        uniqueTreatments[treatment.treatmentId] = treatment;
      }
    }
    
    final deduplicatedTreatments = uniqueTreatments.values.toList();
    print('GenerateTreatment: Unique treatments after deduplication: ${deduplicatedTreatments.length} treatments found');

    if (deduplicatedTreatments.isEmpty) {
      print('GenerateTreatment: No unique treatments found after deduplication');
      return null;
    }

    // Create treatment references (limit to 3)
    final treatmentReferences = deduplicatedTreatments.take(3).map((treatment) => 
      TreatmentReference(treatmentId: treatment.treatmentId)
    ).toList();
    
    print('GenerateTreatment: Generated ${treatmentReferences.length} treatment references');
    print('GenerateTreatment: Treatment IDs: ${treatmentReferences.map((ref) => ref.treatmentId).join(", ")}');
    print('=== GenerateTreatment: generateTreatmentPlanFromService() COMPLETED successfully ===');
    
    return treatmentReferences;
  } catch (e, stackTrace) {
    print('GenerateTreatment: ERROR in generateTreatmentPlanFromService() - $e');
    print('GenerateTreatment: Stack trace: $stackTrace');
    print('=== GenerateTreatment: generateTreatmentPlanFromService() FAILED ===');
    return null;
  }
}