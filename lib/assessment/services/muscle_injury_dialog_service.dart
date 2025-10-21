import 'package:flutter/material.dart';
import '../models/muscle_injury_choice.dart';
import '../widgets/muscle_injury_confirmation_dialog.dart';

/// Service for managing muscle injury confirmation dialogs
class MuscleInjuryDialogService {
  /// Shows the muscle injury confirmation dialog
  /// 
  /// Returns the user's choice or null if the dialog was dismissed
  static Future<MuscleInjuryChoice?> showConfirmationDialog({
    required BuildContext context,
    required List<String> injuredMuscles,
    required Map<String, String> musclePainCategories,
    required int availableExerciseCount,
  }) async {
    try {
      // Validate context
      if (!context.mounted) {
        debugPrint('MuscleInjuryDialogService: Context not mounted, cannot show dialog');
        return null;
      }
      
      // Validate parameters
      if (injuredMuscles.isEmpty) {
        debugPrint('MuscleInjuryDialogService: No injured muscles provided');
        return null;
      }
      
      debugPrint('MuscleInjuryDialogService: Showing confirmation dialog');
      debugPrint('MuscleInjuryDialogService: Injured muscles: $injuredMuscles');
      debugPrint('MuscleInjuryDialogService: Pain categories: $musclePainCategories');
      debugPrint('MuscleInjuryDialogService: Available exercises: $availableExerciseCount');
      
      // Show the dialog and wait for result
      final result = await showDialog<MuscleInjuryChoice>(
        context: context,
        barrierDismissible: false, // Prevent accidental dismissal
        builder: (BuildContext dialogContext) {
          return MuscleInjuryConfirmationDialog(
            injuredMuscles: injuredMuscles,
            musclePainCategories: musclePainCategories,
            availableExerciseCount: availableExerciseCount,
          );
        },
      );
      
      debugPrint('MuscleInjuryDialogService: Dialog result: $result');
      return result;
      
    } catch (e, stackTrace) {
      debugPrint('MuscleInjuryDialogService: Error showing dialog - $e');
      debugPrint('MuscleInjuryDialogService: Stack trace: $stackTrace');
      
      // Return null on error to maintain safe behavior
      return null;
    }
  }
  
  /// Validates if the dialog should be shown based on current conditions
  static bool shouldShowDialog({
    required int filteredExerciseCount,
    required List<String> injuredMuscles,
    required Map<String, String> musclePainCategories,
  }) {
    // Only show dialog if:
    // 1. Filtered exercises < 3
    // 2. User has muscle injuries that are still painful
    if (filteredExerciseCount >= 3) {
      debugPrint('MuscleInjuryDialogService: Sufficient exercises ($filteredExerciseCount), no dialog needed');
      return false;
    }
    
    if (injuredMuscles.isEmpty) {
      debugPrint('MuscleInjuryDialogService: No muscle injuries, no dialog needed');
      return false;
    }
    
    // With the simplified yes/no system, any muscle in injuredMuscles is considered "still painful"
    // since only muscles answered "Yes" are included in the injuredMuscles list
    debugPrint('MuscleInjuryDialogService: Dialog conditions met - showing dialog');
    return true;
  }
  
  /// Logs user choice for safety monitoring and analytics
  static void logUserChoice({
    required MuscleInjuryChoice choice,
    required List<String> injuredMuscles,
    required Map<String, String> musclePainCategories,
    required int availableExerciseCount,
  }) {
    debugPrint('MuscleInjuryDialogService: User choice logged');
    debugPrint('MuscleInjuryDialogService: Choice: ${choice.description}');
    debugPrint('MuscleInjuryDialogService: Injured muscles: $injuredMuscles');
    debugPrint('MuscleInjuryDialogService: Pain categories: $musclePainCategories');
    debugPrint('MuscleInjuryDialogService: Available exercises: $availableExerciseCount');
    debugPrint('MuscleInjuryDialogService: Includes injured muscles: ${choice.includesInjuredMuscles}');
    
    // TODO: Add analytics tracking here if needed
    // AnalyticsService.track('muscle_injury_dialog_choice', {
    //   'choice': choice.name,
    //   'injured_muscles_count': injuredMuscles.length,
    //   'severe_injuries_count': musclePainCategories.values.where((c) => c == 'Severe').length,
    //   'available_exercises': availableExerciseCount,
    // });
  }
}
