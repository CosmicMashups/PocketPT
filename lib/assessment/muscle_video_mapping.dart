/// Muscle Video Mapping System
/// 
/// This class provides a mapping between muscle names and their corresponding
/// local video file paths for ROM assessment instructions.
class MuscleVideoMapping {
  /// Comprehensive mapping of muscle names to local video asset paths
  static const Map<String, String> muscleVideos = {
    // Upper Body Muscles
    'Deltoids': 'assets/videos/deltoids_chest.mp4',
    'Chest': 'assets/videos/deltoids_chest.mp4',
    'Triceps': 'assets/videos/triceps.mp4',
    'Biceps': 'assets/videos/biceps.mp4',
    'Cervical Muscle': 'assets/videos/deltoids_chest.mp4', // Default to Deltoids video
    
    // Lower Body Muscles
    'Quadriceps': 'assets/videos/quadriceps.mp4',
    'Hamstrings': 'assets/videos/hamstrings_gluteals.mp4',
    'Gluteals': 'assets/videos/hamstrings_gluteals.mp4',
    'Calf': 'assets/videos/calf.mp4',
    'Ankle': 'assets/videos/quadriceps.mp4', // Default to Quadriceps
    
    // Core Muscles
    'Abdominals': 'assets/videos/trunk.mp4',
    'Obliques': 'assets/videos/trunk.mp4',
    'Lower Back': 'assets/videos/trunk.mp4',
    'Multifidus': 'assets/videos/trunk.mp4',
  };
  
  /// Default fallback video path
  static const String defaultVideoPath = 'assets/videos/deltoids_chest.mp4';
  
  /// Get the local video asset path for a specific muscle
  /// 
  /// [muscleName] The name of the muscle to get the video for
  /// Returns the local video asset path, or the default video if muscle not found
  static String getVideoPath(final String muscleName) {
    if (muscleName.isEmpty) {
      return defaultVideoPath;
    }
    
    // Try exact match first
    if (muscleVideos.containsKey(muscleName)) {
      return muscleVideos[muscleName]!;
    }
    
    // Try case-insensitive match
    final lowerCaseMuscle = muscleName.toLowerCase();
    for (final entry in muscleVideos.entries) {
      if (entry.key.toLowerCase() == lowerCaseMuscle) {
        return entry.value;
      }
    }
    
    // Return default if no match found
    return defaultVideoPath;
  }
  
  /// Get all available muscle names
  static List<String> getAllMuscleNames() {
    return muscleVideos.keys.toList();
  }
  
  /// Check if a muscle has a specific video assigned
  static bool hasSpecificVideo(final String muscleName) {
    return muscleVideos.containsKey(muscleName);
  }
  
  /// Get video path with fallback chain
  /// 
  /// [primaryMuscle] The primary muscle to get video for
  /// [fallbackMuscle] Fallback muscle if primary not found
  /// [defaultPath] Final fallback path
  static String getVideoPathWithFallback(
    final String primaryMuscle, {
    final String? fallbackMuscle,
    final String? defaultPath,
  }) {
    // Try primary muscle
    if (primaryMuscle.isNotEmpty && muscleVideos.containsKey(primaryMuscle)) {
      return muscleVideos[primaryMuscle]!;
    }
    
    // Try fallback muscle
    if (fallbackMuscle != null && 
        fallbackMuscle.isNotEmpty && 
        muscleVideos.containsKey(fallbackMuscle)) {
      return muscleVideos[fallbackMuscle]!;
    }
    
    // Use provided default or system default
    return defaultPath ?? defaultVideoPath;
  }
  
  /// Validate if a path is a valid local video asset path
  static bool isValidVideoPath(final String path) {
    return path.startsWith('assets/videos/') && path.endsWith('.mp4');
  }
}
