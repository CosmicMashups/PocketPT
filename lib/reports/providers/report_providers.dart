import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/globals.dart';
import '../../data/rehabilitation_plan.dart';

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
  final String exerciseName;
  final int sets;
  final int reps;
  final String status;

  ExerciseRecord({
    required this.date,
    required this.icdCode,
    required this.exerciseName,
    required this.sets,
    required this.reps,
    required this.status,
  });
}

// Providers
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

final exerciseRecordsProvider = StateProvider<List<ExerciseRecord>>((ref) {
  // Convert ExerciseHistory entries to ExerciseRecord format for the calendar
  return ExerciseHistory.entries.map((entry) => ExerciseRecord(
    date: entry.date,
    icdCode: 'REHAB', // Using a generic code since we don't have ICD codes in our system
    exerciseName: entry.exerciseName,
    sets: entry.sets,
    reps: entry.reps,
    status: entry.status,
  )).toList();
}); 