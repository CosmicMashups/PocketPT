/// Muscle Video Mapping System
/// 
/// This class provides a mapping between muscle names and their corresponding
/// YouTube video URLs for ROM assessment instructions.
class MuscleVideoMapping {
  /// Comprehensive mapping of muscle names to YouTube video URLs
  static const Map<String, String> muscleVideos = {
    // Upper Body Muscles
    'Deltoids': 'https://www.youtube.com/shorts/7XZupcbo2EE',
    'Chest': 'https://www.youtube.com/shorts/7XZupcbo2EE',
    'Triceps': 'https://www.youtube.com/shorts/_IOHtPSYGbk',
    'Biceps': 'https://www.youtube.com/shorts/Hs6FQNoI2TM',
    'Cervical Muscle': 'https://youtu.be/am0-6R-ceEs', // Default to Deltoids video
    
    // Lower Body Muscles
    'Quadriceps': 'https://youtube.com/shorts/THG-qpHlP90',
    'Hamstrings': 'https://www.youtube.com/shorts/dkG8439CpVY',
    'Gluteals': 'https://www.youtube.com/shorts/dkG8439CpVY',
    'Calf': 'https://www.youtube.com/shorts/dkG8439CpVY',
    'Ankle': 'https://youtube.com/shorts/THG-qpHlP90', // Default to Quadriceps
    
    // Core Muscles
    'Abdominals': 'https://youtube.com/shorts/os2gPnQGIQs',
    'Obliques': 'https://youtube.com/shorts/os2gPnQGIQs',
    'Lower Back': 'https://youtube.com/shorts/os2gPnQGIQs',
    'Multifidus': 'https://youtube.com/shorts/os2gPnQGIQs',
  };
  
  /// Default fallback video URL - using Deltoids video as it's a standard YouTube URL
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

  /// Convert YouTube Shorts URL to regular YouTube watch URL for better embedding compatibility
  /// 
  /// [url] The YouTube Shorts URL to convert
  /// Returns the converted URL or original URL if not a Shorts URL
  static String convertShortsToWatchUrl(String url) {
    try {
      final uri = Uri.parse(url.trim());
      
      if (uri.host.contains('youtube.com') && uri.path.contains('/shorts/')) {
        final videoId = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : null;
        if (videoId != null && videoId.length == 11) {
          final watchUrl = 'https://www.youtube.com/watch?v=$videoId';
          print('MuscleVideoMapping: Converted Shorts URL to watch URL: $watchUrl');
          return watchUrl;
        }
      }
      
      return url; // Return original URL if not a Shorts URL or conversion failed
    } catch (e) {
      print('MuscleVideoMapping: Error converting Shorts URL: $e');
      return url; // Return original URL on error
    }
  }
  
  /// Extract YouTube video ID from URL
  static String? extractVideoId(String url) {
    try {
      // Clean up the URL first
      String cleanUrl = url.trim();
      
      // Handle various YouTube URL formats
      final uri = Uri.parse(cleanUrl);
      
      String? videoId;
      
      if (uri.host.contains('youtube.com')) {
        // Check if it's a shorts URL first
        if (uri.path.contains('/shorts/')) {
          videoId = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : null;
        } else if (uri.path.contains('/watch')) {
          // Regular YouTube watch URL
          videoId = uri.queryParameters['v'];
        } else if (uri.path.contains('/embed/')) {
          // Embedded YouTube URL
          videoId = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : null;
        } else {
          // Fallback to query parameter
          videoId = uri.queryParameters['v'];
        }
      } else if (uri.host.contains('youtu.be')) {
        // Short YouTube URL format (works for both regular videos and shorts)
        videoId = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : null;
      } else if (uri.host.contains('m.youtube.com')) {
        // Mobile YouTube URL
        if (uri.path.contains('/shorts/')) {
          videoId = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : null;
        } else {
          videoId = uri.queryParameters['v'];
        }
      }
      
      // Validate video ID format (should be 11 characters for standard YouTube videos)
      if (videoId != null && videoId.length == 11) {
        print('MuscleVideoMapping: Successfully extracted video ID: $videoId');
        return videoId;
      }
      
      print('MuscleVideoMapping: Invalid video ID format: $videoId (length: ${videoId?.length ?? 0})');
      return null;
    } catch (e) {
      print('MuscleVideoMapping: Error parsing YouTube URL: $url - $e');
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

  /// Test video ID extraction for all muscle videos (for debugging)
  static void testVideoIdExtraction() {
    print('MuscleVideoMapping: Testing video ID extraction...');
    for (final entry in muscleVideos.entries) {
      final muscleName = entry.key;
      final videoUrl = entry.value;
      final videoId = extractVideoId(videoUrl);
      final isShort = _detectYouTubeShort(videoUrl);
      
      print('MuscleVideoMapping: $muscleName:');
      print('  URL: $videoUrl');
      print('  Video ID: $videoId');
      print('  Is Short: $isShort');
      print('  Valid: ${videoId != null && videoId.length == 11}');
      print('');
    }
  }

  /// Detect if URL is a YouTube Short (helper method)
  static bool _detectYouTubeShort(String url) {
    try {
      final uri = Uri.parse(url.trim());
      return uri.host.contains('youtube.com') && uri.path.contains('/shorts/');
    } catch (e) {
      return false;
    }
  }
}
