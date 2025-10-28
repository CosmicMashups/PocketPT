import 'package:flutter/material.dart';

/// Standardized assessment result structure
class AssessmentResult {
  final String romLevel;
  final int painScore;
  final String categoricalPainLevel;
  final String displayLabel;
  final Color displayColor;
  final String clinicalContext;
  final Map<String, dynamic> additionalData;
  final String? alignment;
  final String? compensation;

  const AssessmentResult({
    required this.romLevel,
    required this.painScore,
    required this.categoricalPainLevel,
    required this.displayLabel,
    required this.displayColor,
    required this.clinicalContext,
    this.additionalData = const {},
    this.alignment,
    this.compensation,
  });

  /// Create a result for when assessment cannot be performed
  static AssessmentResult notVisible(String muscleGroup) {
    return AssessmentResult(
      romLevel: 'unknown',
      painScore: 5, // Default moderate
      categoricalPainLevel: 'Moderate', // Default moderate
      displayLabel: '$muscleGroup: Not visible',
      displayColor: Colors.white,
      clinicalContext: 'Assessment incomplete - Retry assessment',
    );
  }

  /// Create a result for when assessment encounters an error
  static AssessmentResult error(String muscleGroup) {
    return AssessmentResult(
      romLevel: 'error',
      painScore: 5, // Default moderate
      categoricalPainLevel: 'Moderate', // Default moderate
      displayLabel: '$muscleGroup: Error',
      displayColor: Colors.red,
      clinicalContext: 'Assessment error - Retry assessment',
    );
  }

  /// Create a result for when position needs adjustment
  static AssessmentResult adjustPosition(String muscleGroup) {
    return AssessmentResult(
      romLevel: 'adjust',
      painScore: 5, // Default moderate
      categoricalPainLevel: 'Moderate', // Default moderate
      displayLabel: '$muscleGroup: Adjust position',
      displayColor: Colors.yellow,
      clinicalContext: 'Adjust positioning for accurate assessment',
    );
  }
}
