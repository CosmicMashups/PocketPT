/// Enum representing user choices in the muscle injury confirmation dialog
enum MuscleInjuryChoice {
  /// User chooses to include all exercises, bypassing muscle injury filtering
  includeAll,
  
  /// User chooses to keep only safe exercises that avoid injured muscles
  keepSafe,
  
  /// User chooses to focus on treatments only (no exercises)
  treatmentsOnly,
  
  /// User cancels the dialog and wants to return to assessment
  cancel,
}

/// Extension methods for MuscleInjuryChoice enum
extension MuscleInjuryChoiceExtension on MuscleInjuryChoice {
  /// Returns a user-friendly description of the choice
  String get description {
    switch (this) {
      case MuscleInjuryChoice.includeAll:
        return 'Include all exercises (may target injured muscles)';
      case MuscleInjuryChoice.keepSafe:
        return 'Keep safe exercises only (avoid injured muscles)';
      case MuscleInjuryChoice.treatmentsOnly:
        return 'Focus on treatments only (no exercises)';
      case MuscleInjuryChoice.cancel:
        return 'Cancel and return to assessment';
    }
  }
  
  /// Returns whether this choice involves including exercises targeting injured muscles
  bool get includesInjuredMuscles {
    switch (this) {
      case MuscleInjuryChoice.includeAll:
        return true;
      case MuscleInjuryChoice.keepSafe:
      case MuscleInjuryChoice.treatmentsOnly:
      case MuscleInjuryChoice.cancel:
        return false;
    }
  }
}
