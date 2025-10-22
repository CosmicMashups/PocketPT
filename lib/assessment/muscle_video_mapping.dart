/// Muscle Video Mapping System
/// 
/// This class provides a mapping between muscle names and their corresponding
/// YouTube video URLs for ROM assessment instructions.
class MuscleVideoMapping {
  /// Comprehensive mapping of muscle names to YouTube video URLs
  static const Map<String, String> muscleVideos = {
    // Upper Body Muscles
    'Deltoids': 'https://youtu.be/am0-6R-ceEs',
    'Chest': 'https://youtu.be/am0-6R-ceEs',
    'Triceps': 'https://youtu.be/oyRbGqmOeB4',
    'Biceps': 'https://www.youtube.com/shorts/Hs6FQNoI2TM',
    'Cervical Muscle': 'https://youtu.be/am0-6R-ceEs', // Default to Deltoids video
    
    // Lower Body Muscles
    'Quadriceps': 'https://www.youtube.com/shorts/THG-qpHlP90',
    'Hamstrings': 'https://www.youtube.com/shorts/dkG8439CpVY',
    'Gluteals': 'https://www.youtube.com/shorts/dkG8439CpVY',
    'Calf': 'https://www.youtube.com/shorts/THG-qpHlP90', // Default to Quadriceps
    'Ankle': 'https://www.youtube.com/shorts/THG-qpHlP90', // Default to Quadriceps
    
    // Core Muscles
    'Abdominals': 'https://www.youtube.com/shorts/os2gPnQGIQs',
    'Obliques': 'https://www.youtube.com/shorts/os2gPnQGIQs',
    'Lower Back': 'https://www.youtube.com/shorts/os2gPnQGIQs',
    'Multifidus': 'https://www.youtube.com/shorts/os2gPnQGIQs',
  };
  
  /// Default fallback video URL (Deltoids video)
  static const String defaultVideoUrl = 'https://youtu.be/am0-6R-ceEs';
  
  /// Get the YouTube video URL for a specific muscle
  /// 
  /// [muscleName] The name of the muscle to get the video for
  /// Returns the YouTube video URL, or the default video if muscle not found
  static String getVideoUrl(String muscleName) {
    if (muscleName.isEmpty) {
      return defaultVideoUrl;
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
    return defaultVideoUrl;
  }
  
  /// Get all available muscle names
  static List<String> getAllMuscleNames() {
    return muscleVideos.keys.toList();
  }
  
  /// Check if a muscle has a specific video assigned
  static bool hasSpecificVideo(String muscleName) {
    return muscleVideos.containsKey(muscleName);
  }
  
  /// Get video URL with fallback chain
  /// 
  /// [primaryMuscle] The primary muscle to get video for
  /// [fallbackMuscle] Fallback muscle if primary not found
  /// [defaultUrl] Final fallback URL
  static String getVideoUrlWithFallback(
    String primaryMuscle, {
    String? fallbackMuscle,
    String? defaultUrl,
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
    return defaultUrl ?? defaultVideoUrl;
  }
  
  /// Extract YouTube video ID from URL
  static String? extractVideoId(String url) {
    try {
      // Handle various YouTube URL formats
      final uri = Uri.parse(url);
      
      if (uri.host.contains('youtube.com')) {
        return uri.queryParameters['v'];
      } else if (uri.host.contains('youtu.be')) {
        return uri.pathSegments.isNotEmpty ? uri.pathSegments.last : null;
      } else if (uri.host.contains('youtube.com/shorts')) {
        return uri.pathSegments.isNotEmpty ? uri.pathSegments.last : null;
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }
  
  /// Validate if a URL is a valid YouTube URL
  static bool isValidYouTubeUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host.contains('youtube.com') || uri.host.contains('youtu.be');
    } catch (e) {
      return false;
    }
  }
}
