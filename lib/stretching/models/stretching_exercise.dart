/// Stretching exercise model for warm-up and cooldown routines
class StretchingExercise {
  final String exerciseId;
  final String exerciseName;
  final String muscleGroup;
  final String exerciseType; // 'warmup' or 'cooldown'
  final String description;
  final List<String> stepByStepInstructions;
  final int recommendedDuration; // in seconds
  final String difficultyLevel; // 'beginner', 'intermediate', 'advanced'
  final List<String> benefits;
  final List<String> precautions;
  final String imagePath;
  final String videoPath; // optional
  final bool requiresEquipment;
  final String equipmentNeeded;
  final int? minPainLevel; // minimum pain level (0-10 scale) where exercise is safe
  final int? maxPainLevel; // maximum pain level (0-10 scale) where exercise is safe
  final bool severePainContraindicated; // whether exercise should be avoided with severe pain (0-3)

  StretchingExercise({
    required this.exerciseId,
    required this.exerciseName,
    required this.muscleGroup,
    required this.exerciseType,
    required this.description,
    required this.stepByStepInstructions,
    required this.recommendedDuration,
    required this.difficultyLevel,
    required this.benefits,
    required this.precautions,
    required this.imagePath,
    required this.videoPath,
    required this.requiresEquipment,
    required this.equipmentNeeded,
    required this.minPainLevel,
    required this.maxPainLevel,
    required this.severePainContraindicated,
  });

  /// Create StretchingExercise from CSV row data
  factory StretchingExercise.fromCSV(List<dynamic> row) {
    return StretchingExercise(
      exerciseId: row[0].toString(),
      exerciseName: row[1].toString(),
      muscleGroup: row[2].toString(),
      exerciseType: row[3].toString(),
      description: row[4].toString(),
      stepByStepInstructions: [
        row[5].toString(),
        row[6].toString(),
        row[7].toString(),
        row[8].toString(),
        row[9].toString(),
        row[10].toString(),
        row[11].toString(),
        row[12].toString(),
      ].where((step) => step.isNotEmpty).toList(),
      recommendedDuration: int.tryParse(row[13].toString()) ?? 30,
      difficultyLevel: row[14].toString(),
      benefits: [
        row[15].toString(),
        row[16].toString(),
        row[17].toString(),
      ].where((benefit) => benefit.isNotEmpty).toList(),
      precautions: [
        row[18].toString(),
        row[19].toString(),
        row[20].toString(),
      ].where((precaution) => precaution.isNotEmpty).toList(),
      imagePath: row[21].toString().isNotEmpty ? row[21].toString() : '',
      videoPath: row[22].toString().isNotEmpty ? row[22].toString() : '',
      requiresEquipment: row[23].toString().toLowerCase() == 'true',
      equipmentNeeded: row[24].toString(),
      minPainLevel: row.length > 25 && row[25].toString().isNotEmpty 
          ? int.tryParse(row[25].toString()) 
          : null,
      maxPainLevel: row.length > 26 && row[26].toString().isNotEmpty 
          ? int.tryParse(row[26].toString()) 
          : null,
      severePainContraindicated: row.length > 27 && row[27].toString().toLowerCase() == 'true',
    );
  }

  /// Convert to map for debugging
  Map<String, dynamic> toMap() {
    return {
      'exerciseId': exerciseId,
      'exerciseName': exerciseName,
      'muscleGroup': muscleGroup,
      'exerciseType': exerciseType,
      'description': description,
      'stepByStepInstructions': stepByStepInstructions,
      'recommendedDuration': recommendedDuration,
      'difficultyLevel': difficultyLevel,
      'benefits': benefits,
      'precautions': precautions,
      'imagePath': imagePath,
      'videoPath': videoPath,
      'requiresEquipment': requiresEquipment,
      'equipmentNeeded': equipmentNeeded,
      'minPainLevel': minPainLevel,
      'maxPainLevel': maxPainLevel,
      'severePainContraindicated': severePainContraindicated,
    };
  }
}
