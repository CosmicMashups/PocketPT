import 'dart:io';

/// Local assessment data storage - No Firebase/Hive dependencies
/// This class manages assessment data locally within the app session
class AssessmentData {
  // Assessment data fields
  static String rehabGoal = '';
  static String generalMuscle = '';
  static String specificMuscle = '';
  static File? painVideo;
  static int painScale = 0;
  static String painLevel = '';
  static String painType = '';
  static String painDuration = '';
  static bool isInjured = false;
  static bool isAssessed = false;
  
  // Muscle injury assessment fields
  static List<String> injuredMuscles = [];
  static Map<String, int> musclePainLevels = {}; // muscle name -> pain level (0-10)
  static Map<String, String> musclePainCategories = {}; // muscle name -> category (Low/Moderate/Severe)
  static Map<String, bool> muscleStillPainful = {}; // muscle name -> still experiencing pain (true/false)
  
  // AI Analysis fields
  static Map<String, dynamic>? aiAnalysisResults;
  static bool hasAIAnalysis = false;
  static DateTime? aiAnalysisTimestamp;

  /// Reset all assessment data to default values
  static void reset() {
    rehabGoal = '';
    generalMuscle = '';
    specificMuscle = '';
    painVideo = null;
    painScale = 0;
    painLevel = '';
    painType = '';
    painDuration = '';
    isInjured = false;
    isAssessed = false;
    
    // Reset muscle injury fields
    injuredMuscles = [];
    musclePainLevels = {};
    musclePainCategories = {};
    muscleStillPainful = {};
    
    // Reset AI analysis fields
    aiAnalysisResults = null;
    hasAIAnalysis = false;
    aiAnalysisTimestamp = null;
  }

  /// Check if assessment is complete
  static bool get isComplete {
    return rehabGoal.isNotEmpty &&
           generalMuscle.isNotEmpty &&
           specificMuscle.isNotEmpty &&
           painLevel.isNotEmpty &&
           painType.isNotEmpty &&
           painDuration.isNotEmpty;
  }

  /// Get assessment progress as a percentage
  static double get progressPercentage {
    int completedFields = 0;
    int totalFields = 6; // rehabGoal, generalMuscle, specificMuscle, painLevel, painType, painDuration
    
    if (rehabGoal.isNotEmpty) completedFields++;
    if (generalMuscle.isNotEmpty) completedFields++;
    if (specificMuscle.isNotEmpty) completedFields++;
    if (painLevel.isNotEmpty) completedFields++;
    if (painType.isNotEmpty) completedFields++;
    if (painDuration.isNotEmpty) completedFields++;
    
    return completedFields / totalFields;
  }

  /// Get assessment data as a map for debugging
  static Map<String, dynamic> toMap() {
    return {
      'rehabGoal': rehabGoal,
      'generalMuscle': generalMuscle,
      'specificMuscle': specificMuscle,
      'painScale': painScale,
      'painLevel': painLevel,
      'painType': painType,
      'painDuration': painDuration,
      'isInjured': isInjured,
      'isAssessed': isAssessed,
      'injuredMuscles': injuredMuscles,
      'musclePainLevels': musclePainLevels,
      'musclePainCategories': musclePainCategories,
      'muscleStillPainful': muscleStillPainful,
      'isComplete': isComplete,
      'progressPercentage': progressPercentage,
    };
  }

  /// Print assessment data for debugging
  static void printData() {
    print('Assessment Data:');
    print('  Rehab Goal: $rehabGoal');
    print('  General Muscle: $generalMuscle');
    print('  Specific Muscle: $specificMuscle');
    print('  Pain Scale: $painScale');
    print('  Pain Level: $painLevel');
    print('  Pain Type: $painType');
    print('  Pain Duration: $painDuration');
    print('  Is Injured: $isInjured');
    print('  Is Assessed: $isAssessed');
    print('  Injured Muscles: $injuredMuscles');
    print('  Muscle Pain Levels: $musclePainLevels');
    print('  Muscle Pain Categories: $musclePainCategories');
    print('  Muscle Still Painful: $muscleStillPainful');
    print('  Is Complete: $isComplete');
    print('  Progress: ${(progressPercentage * 100).toStringAsFixed(1)}%');
  }
}
