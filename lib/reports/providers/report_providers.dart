import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/globals.dart';
import '../../data/rehabilitation_plan.dart';
import '../services/reports_data_service.dart';

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
  final String icdCode;
  final String exerciseId;
  final String exerciseName;
  final int sets;
  final int reps;
  final String status;

  ExerciseRecord({
    required this.date,
    required this.icdCode,
    required this.exerciseId,
    required this.exerciseName,
    required this.sets,
    required this.reps,
    required this.status,
  });
}

// Enhanced Providers using the new data service
final enhancedRehabPlansProvider = FutureProvider<List<RehabPlan>>((ref) async {
  final service = ref.read(reportsDataServiceProvider);
  final plans = await service.loadRehabPlans();
  
  // Convert RehabilitationPlan data to RehabPlan format
  final userRehab = UserRehabilitation.instance;
  final List<RehabPlan> convertedPlans = [];
  
  // Add rehabilitation plans
  for (int i = 0; i < plans.length; i++) {
    final plan = plans[i];
    
    convertedPlans.add(RehabPlan(
      title: 'Week ${plan.weekNumber} - ${userRehab.selectedMuscle} Rehabilitation',
      icdCode: 'REHAB-${plan.weekNumber}',
      status: 'ongoing',
      startDate: DateTime.now().subtract(Duration(days: i * 7)), // Approximate start date
      focusArea: _getFocusArea(userRehab.selectedMuscle),
      targetMuscle: userRehab.selectedMuscle,
    ));
  }
  
  // Add treatments as separate plans if they exist
  if (userRehab.treatmentReferences != null && userRehab.treatmentReferences!.isNotEmpty) {
    for (int i = 0; i < userRehab.treatmentReferences!.length; i++) {
      final treatmentRef = userRehab.treatmentReferences![i];
      convertedPlans.add(RehabPlan(
        title: 'Treatment - ${treatmentRef.treatmentId}',
        icdCode: 'TREAT-${treatmentRef.treatmentId}',
        status: 'ongoing',
        startDate: DateTime.now(),
        focusArea: 'General', // Default since we don't have full treatment data
        targetMuscle: 'Unknown', // Default since we don't have full treatment data
      ));
    }
  }
  
  return convertedPlans;
});

// Legacy provider for backward compatibility
final rehabPlansProvider = StateProvider<List<RehabPlan>>((ref) {
  // Convert UserRehabilitation data to RehabPlan format
  final userRehab = UserRehabilitation.instance;
  final List<RehabPlan> plans = [];
  
  // Add rehabilitation plans
  for (int i = 0; i < userRehab.rehabPlans.length; i++) {
    final plan = userRehab.rehabPlans[i];
    
    plans.add(RehabPlan(
      title: 'Week ${plan.weekNumber} - ${userRehab.selectedMuscle} Rehabilitation',
      icdCode: 'REHAB-${plan.weekNumber}',
      status: 'ongoing',
      startDate: DateTime.now().subtract(Duration(days: i * 7)), // Approximate start date
      focusArea: _getFocusArea(userRehab.selectedMuscle),
      targetMuscle: userRehab.selectedMuscle,
    ));
  }
  
  // Add treatments as separate plans if they exist
  if (userRehab.treatmentReferences != null && userRehab.treatmentReferences!.isNotEmpty) {
    // Note: We can't access full treatment data here without async call
    // This is a limitation of the provider pattern
    for (int i = 0; i < userRehab.treatmentReferences!.length; i++) {
      final treatmentRef = userRehab.treatmentReferences![i];
      plans.add(RehabPlan(
        title: 'Treatment - ${treatmentRef.treatmentId}',
        icdCode: 'TREAT-${treatmentRef.treatmentId}',
        status: 'ongoing',
        startDate: DateTime.now(),
        focusArea: 'General', // Default since we don't have full treatment data
        targetMuscle: 'Unknown', // Default since we don't have full treatment data
      ));
    }
  }
  
  return plans;
});

// Helper function to determine focus area based on muscle
String _getFocusArea(String muscle) {
  final lowerBodyMuscles = ['quadriceps', 'hamstrings', 'calves', 'glutes', 'ankle', 'knee', 'hip'];
  final upperBodyMuscles = ['shoulder', 'rotator cuff', 'deltoids', 'biceps', 'triceps', 'elbow', 'wrist'];
  final coreMuscles = ['core', 'abs', 'back', 'spine', 'neck'];
  
  final muscleLower = muscle.toLowerCase();
  
  if (lowerBodyMuscles.any((m) => muscleLower.contains(m))) {
    return 'Lower Body';
  } else if (upperBodyMuscles.any((m) => muscleLower.contains(m))) {
    return 'Upper Body';
  } else if (coreMuscles.any((m) => muscleLower.contains(m))) {
    return 'Core';
  } else {
    return 'General';
  }
}

final selectedDateProvider = StateProvider<DateTime>((ref) {
  return DateTime.now();
});

// Enhanced exercise records provider using the new data service
final enhancedExerciseRecordsProvider = FutureProvider<List<ExerciseRecord>>((ref) async {
  final service = ref.read(reportsDataServiceProvider);
  // Force refresh to ensure we get all historical data from Firebase
  final history = await service.loadExerciseHistory(forceRefresh: true);
  
  // Convert ExerciseHistory entries to ExerciseRecord format for the calendar
  return history.map((entry) => ExerciseRecord(
    date: entry.date,
    icdCode: 'REHAB', // Using a generic code since we don't have ICD codes in our system
    exerciseId: entry.exerciseId, // Include exercise ID for loading actual exercise data
    exerciseName: entry.exerciseName, // This will be placeholder name like "Exercise 1"
    sets: entry.sets,
    reps: entry.reps,
    status: entry.status,
  )).toList();
});

// Legacy provider for backward compatibility
final exerciseRecordsProvider = StateProvider<List<ExerciseRecord>>((ref) {
  // Convert ExerciseHistory entries to ExerciseRecord format for the calendar
  // Note: This provider returns placeholder names. The actual exercise names
  // will be loaded in the UI using FutureBuilder with ExerciseDataService
  return ExerciseHistory.entries.map((entry) => ExerciseRecord(
    date: entry.date,
    icdCode: 'REHAB', // Using a generic code since we don't have ICD codes in our system
    exerciseId: entry.exerciseId, // Include exercise ID for loading actual exercise data
    exerciseName: entry.exerciseName, // This will be placeholder name like "Exercise 1"
    sets: entry.sets,
    reps: entry.reps,
    status: entry.status,
  )).toList();
}); 