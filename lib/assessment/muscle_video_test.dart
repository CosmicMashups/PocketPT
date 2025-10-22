import 'muscle_video_mapping.dart';

/// Test class to verify muscle video mappings
/// 
/// This class provides methods to test and validate the muscle-to-video
/// mapping system to ensure all muscles have proper video assignments.
class MuscleVideoTest {
  /// Test all muscle mappings and return results
  static Map<String, dynamic> testAllMappings() {
    final results = <String, dynamic>{
      'totalMuscles': 0,
      'mappedMuscles': 0,
      'unmappedMuscles': <String>[],
      'invalidUrls': <String>[],
      'validMappings': <String, String>{},
    };

    // Get all muscle names from the mapping
    final allMuscles = MuscleVideoMapping.getAllMuscleNames();
    results['totalMuscles'] = allMuscles.length;

    for (final muscle in allMuscles) {
      final videoUrl = MuscleVideoMapping.getVideoUrl(muscle);
      
      // Check if muscle has a specific video (not default)
      if (MuscleVideoMapping.hasSpecificVideo(muscle)) {
        results['mappedMuscles']++;
        results['validMappings'][muscle] = videoUrl;
        
        // Validate URL format
        if (!MuscleVideoMapping.isValidYouTubeUrl(videoUrl)) {
          results['invalidUrls'].add('$muscle: $videoUrl');
        }
      } else {
        results['unmappedMuscles'].add(muscle);
      }
    }

    return results;
  }

  /// Test specific muscle mappings
  static Map<String, String> testSpecificMuscles(List<String> muscleNames) {
    final results = <String, String>{};
    
    for (final muscle in muscleNames) {
      final videoUrl = MuscleVideoMapping.getVideoUrl(muscle);
      results[muscle] = videoUrl;
    }
    
    return results;
  }

  /// Test fallback mechanisms
  static Map<String, dynamic> testFallbacks() {
    final results = <String, dynamic>{
      'emptyMuscle': MuscleVideoMapping.getVideoUrl(''),
      'nullMuscle': MuscleVideoMapping.getVideoUrl(''),
      'unknownMuscle': MuscleVideoMapping.getVideoUrl('Unknown Muscle'),
      'caseInsensitive': MuscleVideoMapping.getVideoUrl('deltoids'),
      'withFallback': MuscleVideoMapping.getVideoUrlWithFallback(
        'Unknown Muscle',
        fallbackMuscle: 'Deltoids',
        defaultUrl: 'https://youtu.be/fallback',
      ),
    };
    
    return results;
  }

  /// Test URL extraction
  static Map<String, String?> testUrlExtraction() {
    final testUrls = [
      'https://youtu.be/am0-6R-ceEs',
      'https://www.youtube.com/watch?v=am0-6R-ceEs',
      'https://www.youtube.com/shorts/Hs6FQNoI2TM',
      'https://youtube.com/watch?v=invalid',
      'not-a-youtube-url',
    ];
    
    final results = <String, String?>{};
    
    for (final url in testUrls) {
      results[url] = MuscleVideoMapping.extractVideoId(url);
    }
    
    return results;
  }

  /// Run comprehensive tests
  static Map<String, dynamic> runAllTests() {
    return {
      'mappingTest': testAllMappings(),
      'fallbackTest': testFallbacks(),
      'urlExtractionTest': testUrlExtraction(),
      'specificMuscleTest': testSpecificMuscles([
        'Deltoids',
        'Biceps',
        'Triceps',
        'Quadriceps',
        'Hamstrings',
        'Abdominals',
        'Cervical Muscle',
        'Calf',
        'Ankle',
      ]),
    };
  }

  /// Print test results in a readable format
  static void printTestResults() {
    final results = runAllTests();
    
    print('=== Muscle Video Mapping Test Results ===');
    print('');
    
    // Mapping test results
    final mappingResults = results['mappingTest'] as Map<String, dynamic>;
    print('📊 Mapping Statistics:');
    print('  Total muscles: ${mappingResults['totalMuscles']}');
    print('  Mapped muscles: ${mappingResults['mappedMuscles']}');
    print('  Unmapped muscles: ${mappingResults['unmappedMuscles']}');
    print('  Invalid URLs: ${mappingResults['invalidUrls']}');
    print('');
    
    // Fallback test results
    final fallbackResults = results['fallbackTest'] as Map<String, dynamic>;
    print('🔄 Fallback Tests:');
    fallbackResults.forEach((key, value) {
      print('  $key: $value');
    });
    print('');
    
    // URL extraction test results
    final urlResults = results['urlExtractionTest'] as Map<String, String?>;
    print('🔗 URL Extraction Tests:');
    urlResults.forEach((url, extractedId) {
      print('  $url -> $extractedId');
    });
    print('');
    
    // Specific muscle test results
    final muscleResults = results['specificMuscleTest'] as Map<String, String>;
    print('💪 Specific Muscle Tests:');
    muscleResults.forEach((muscle, videoUrl) {
      print('  $muscle: $videoUrl');
    });
    print('');
    
    print('=== Test Complete ===');
  }
}
