import 'package:flutter/foundation.dart';
import '../data/treatment.dart';
import '../data/rehabilitation_plan.dart';

/// Load treatments from CSV with comprehensive error handling and logging
Future<List<Treatment>> loadTreatmentsFromCSV() async {
  try {
    debugPrint('GenerateTreatment: Loading treatments from CSV...');
    final csvData = await loadCSVFromAsset('assets/data/treatment.csv');
    
    if (csvData.isEmpty) {
      debugPrint('GenerateTreatment: CSV file is empty');
      return [];
    }
    
    // Expected column count for treatment CSV (now 7 with Treatment_Instruction column)
    const expectedColumnCount = 7;
    
    // Fix malformed header: if first row has too many columns, truncate to expected count
    List<dynamic> header = csvData.first;
    if (header.length > expectedColumnCount) {
      debugPrint('GenerateTreatment: [TREATMENT FIX] Header row has ${header.length} columns (expected $expectedColumnCount), truncating...');
      header = header.sublist(0, expectedColumnCount);
    }
    
    // Check if Treatment_Instruction column exists (backward compatibility)
    bool hasInstructionColumn = false;
    if (header.length >= 7) {
      // Check if 7th column (index 6) exists and is named appropriately
      final columnName = header[6].toString().trim().toLowerCase().replaceAll(' ', '_');
      hasInstructionColumn = columnName.contains('treatment') && columnName.contains('instruction');
    }
    
    if (!hasInstructionColumn && header.length >= expectedColumnCount) {
      debugPrint('GenerateTreatment: [WARNING] Treatment_Instruction column not found in CSV. Defaulting to empty string.');
    }
    
    final data = csvData.sublist(1);
    
    // Build normalized header map for debug
    String normalizeColumnKey(final String columnLabel) {
      if (columnLabel.isEmpty) return columnLabel;
      var t = columnLabel.replaceAll('\r', '').trim();
      if (t.isNotEmpty && t.codeUnitAt(0) == 0xFEFF) t = t.substring(1);
      if (t.startsWith('"') && t.endsWith('"') && t.length >= 2) {
        t = t.substring(1, t.length - 1);
      }
      t = t.toLowerCase().replaceAll(' ', '_');
      return t;
    }
    final Map<String, int> headerMap = <String, int>{};
    // Process up to 7 columns (including Treatment_Instruction)
    for (int i = 0; i < header.length && i < expectedColumnCount; i++) {
      final normalizedKey = normalizeColumnKey(header[i].toString());
      headerMap[normalizedKey] = i;
    }
    
    // Debug: print treatment CSV header info
    debugPrint('GenerateTreatment: [TREATMENT HEADER] Raw header row has ${header.length} columns (using first $expectedColumnCount)');
    debugPrint('GenerateTreatment: [TREATMENT HEADER] Raw header (first $expectedColumnCount): ${header.take(expectedColumnCount).toList()}');
    final normalizedColumns = headerMap.keys.toList()..sort();
    debugPrint('GenerateTreatment: [TREATMENT HEADER] Normalized column names (${normalizedColumns.length}): ${normalizedColumns.join(', ')}');
    debugPrint('GenerateTreatment: [TREATMENT HEADER] Header map entries: ${headerMap.entries.map((e) => '${e.key}->${e.value}').join(', ')}');
    debugPrint('GenerateTreatment: [TREATMENT DATA] ${data.length} treatment rows');

    // Skip header row and map to Treatment objects
    final treatments = data.map((row) {
      if (row.length < 6) {
        debugPrint('GenerateTreatment: Warning - row has insufficient columns: ${row.length}');
        return null;
      }
      
      // Parse Treatment_Instruction column (7th column, index 6) with backward compatibility
      String treatmentInstruction = '';
      if (row.length >= 7) {
        treatmentInstruction = row[6].toString().trim();
      } else {
        debugPrint('GenerateTreatment: Row has ${row.length} columns (expected 7). Treatment_Instruction will be empty.');
      }
      
      return Treatment(
        treatmentId: row[0].toString(),
        treatmentName: row[1].toString(),
        description: row[2].toString(),
        musclesInvolved: row[3].toString(),
        painLevel: row[4].toString(),
        painDuration: row[5].toString(),
        treatmentInstruction: treatmentInstruction,
      );
    }).where((treatment) => treatment != null).cast<Treatment>().toList();

    debugPrint('GenerateTreatment: Successfully loaded ${treatments.length} treatments from CSV');
    return treatments;
  } catch (e, stackTrace) {
    debugPrint('GenerateTreatment: ERROR loading treatments from CSV - $e');
    debugPrint('GenerateTreatment: Stack trace: $stackTrace');
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
    debugPrint('GenerateTreatment: Filtering treatments...');
    debugPrint('GenerateTreatment: Target muscle: "$targetMuscles"');
    debugPrint('GenerateTreatment: Target pain level: "$targetPainLevel"');
    debugPrint('GenerateTreatment: Target pain duration: "$targetPainDuration"');
    debugPrint('GenerateTreatment: Total treatments to filter: ${allTreatments.length}');

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
        debugPrint('GenerateTreatment: Match found - ${treatment.treatmentName} (${treatment.treatmentId})');
      }

      return matches;
    }).toList();

    debugPrint('GenerateTreatment: Filtering completed - ${filteredTreatments.length} treatments match criteria');
    return filteredTreatments;
  } catch (e, stackTrace) {
    debugPrint('GenerateTreatment: ERROR filtering treatments - $e');
    debugPrint('GenerateTreatment: Stack trace: $stackTrace');
    return [];
  }
}

/// Generate treatment plan with comprehensive error handling and logging
Future<List<TreatmentReference>?> generateTreatmentPlan({
  required String specificMuscle,
  required String painLevel,
  required String painDuration,
}) async {
  debugPrint('=== GenerateTreatment: generateTreatmentPlan() START ===');
  debugPrint('GenerateTreatment: specificMuscle = "$specificMuscle"');
  debugPrint('GenerateTreatment: painLevel = "$painLevel"');
  debugPrint('GenerateTreatment: painDuration = "$painDuration"');
  
  try {
    // Load all treatments from CSV
    debugPrint('GenerateTreatment: Loading treatments from CSV...');
    final allTreatments = await loadTreatmentsFromCSV();
    
    if (allTreatments.isEmpty) {
      debugPrint('GenerateTreatment: No treatments loaded from CSV');
      return null;
    }
    
    debugPrint('GenerateTreatment: Loaded ${allTreatments.length} treatments from CSV');
    
    // Core treatment IDs that are the only treatments included (T001, T002, T003)
    const coreTreatmentIds = ['T001', 'T002', 'T003'];
    
    // Build treatment list: ONLY include core treatments (T001, T002, T003)
    final List<TreatmentReference> treatmentReferences = [];
    
    // Only add core treatments (T001, T002, T003) - no optional treatments from filtering
    debugPrint('GenerateTreatment: Including only core treatments (T001, T002, T003)...');
    for (final coreId in coreTreatmentIds) {
      // Verify core treatment exists in CSV (log warning if not found)
      final exists = allTreatments.any((t) => t.treatmentId == coreId);
      if (!exists) {
        debugPrint('GenerateTreatment: [WARNING] Core treatment $coreId not found in CSV');
      }
      treatmentReferences.add(TreatmentReference(treatmentId: coreId));
      debugPrint('GenerateTreatment: Added core treatment: $coreId');
    }
    
    debugPrint('GenerateTreatment: Generated ${treatmentReferences.length} treatment references (only core treatments)');
    debugPrint('GenerateTreatment: Treatment IDs: ${treatmentReferences.map((ref) => ref.treatmentId).join(", ")}');
    debugPrint('=== GenerateTreatment: generateTreatmentPlan() COMPLETED successfully ===');
    
    return treatmentReferences;
  } catch (e, stackTrace) {
    debugPrint('GenerateTreatment: ERROR in generateTreatmentPlan() - $e');
    debugPrint('GenerateTreatment: Stack trace: $stackTrace');
    debugPrint('=== GenerateTreatment: generateTreatmentPlan() FAILED ===');
    return null;
  }
}

/// Generate treatment plan using ExerciseDataService for consistency with generate_plan.dart
Future<List<TreatmentReference>?> generateTreatmentPlanFromService({
  required String specificMuscle,
  required String painLevel,
  required String painDuration,
}) async {
  debugPrint('=== GenerateTreatment: generateTreatmentPlanFromService() START ===');
  debugPrint('GenerateTreatment: specificMuscle = "$specificMuscle"');
  debugPrint('GenerateTreatment: painLevel = "$painLevel"');
  debugPrint('GenerateTreatment: painDuration = "$painDuration"');
  
  try {
    // Use ExerciseDataService for consistency with generate_plan.dart
    debugPrint('GenerateTreatment: Loading treatments using ExerciseDataService...');
    final allTreatments = await ExerciseDataService.loadAllTreatments();
    
    if (allTreatments.isEmpty) {
      debugPrint('GenerateTreatment: No treatments loaded from ExerciseDataService');
      return null;
    }
    
    debugPrint('GenerateTreatment: Loaded ${allTreatments.length} treatments from ExerciseDataService');
    
    // Core treatment IDs that are the only treatments included (T001, T002, T003)
    const coreTreatmentIds = ['T001', 'T002', 'T003'];
    
    // Build treatment list: ONLY include core treatments (T001, T002, T003)
    final List<TreatmentReference> treatmentReferences = [];
    
    // Only add core treatments (T001, T002, T003) - no optional treatments from filtering
    debugPrint('GenerateTreatment: Including only core treatments (T001, T002, T003)...');
    for (final coreId in coreTreatmentIds) {
      // Verify core treatment exists in CSV (log warning if not found)
      final exists = allTreatments.any((t) => t.treatmentId == coreId);
      if (!exists) {
        debugPrint('GenerateTreatment: [WARNING] Core treatment $coreId not found in CSV');
      }
      treatmentReferences.add(TreatmentReference(treatmentId: coreId));
      debugPrint('GenerateTreatment: Added core treatment: $coreId');
    }
    
    debugPrint('GenerateTreatment: Generated ${treatmentReferences.length} treatment references (only core treatments)');
    debugPrint('GenerateTreatment: Treatment IDs: ${treatmentReferences.map((ref) => ref.treatmentId).join(", ")}');
    debugPrint('=== GenerateTreatment: generateTreatmentPlanFromService() COMPLETED successfully ===');
    
    return treatmentReferences;
  } catch (e, stackTrace) {
    debugPrint('GenerateTreatment: ERROR in generateTreatmentPlanFromService() - $e');
    debugPrint('GenerateTreatment: Stack trace: $stackTrace');
    debugPrint('=== GenerateTreatment: generateTreatmentPlanFromService() FAILED ===');
    return null;
  }
}