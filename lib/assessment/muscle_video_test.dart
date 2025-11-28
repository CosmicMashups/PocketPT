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
      'invalidPaths': <String>[],
      'validMappings': <String, String>{},
    };

    // Get all muscle names from the mapping
    final allMuscles = MuscleVideoMapping.getAllMuscleNames();
    results['totalMuscles'] = allMuscles.length;

    for (final muscle in allMuscles) {
      final videoPath = MuscleVideoMapping.getVideoPath(muscle);
      
      // Check if muscle has a specific video (not default)
      if (MuscleVideoMapping.hasSpecificVideo(muscle)) {
        results['mappedMuscles']++;
        results['validMappings'][muscle] = videoPath;
        
        // Validate path format
        if (!MuscleVideoMapping.isValidVideoPath(videoPath)) {
          results['invalidPaths'].add('$muscle: $videoPath');
        }
      } else {
        results['unmappedMuscles'].add(muscle);
      }
    }

    return results;
  }

  /// Test specific muscle mappings
  static Map<String, String> testSpecificMuscles(final List<String> muscleNames) {
    final results = <String, String>{};
    
    for (final muscle in muscleNames) {
      final videoPath = MuscleVideoMapping.getVideoPath(muscle);
      results[muscle] = videoPath;
    }
    
    return results;
  }

  /// Test fallback mechanisms
  static Map<String, dynamic> testFallbacks() {
    final results = <String, dynamic>{
      'emptyMuscle': MuscleVideoMapping.getVideoPath(''),
      'unknownMuscle': MuscleVideoMapping.getVideoPath('Unknown Muscle'),
      'caseInsensitive': MuscleVideoMapping.getVideoPath('deltoids'),
      'withFallback': MuscleVideoMapping.getVideoPathWithFallback(
        'Unknown Muscle',
        fallbackMuscle: 'Deltoids',
        defaultPath: 'assets/videos/fallback.mp4',
      ),
    };
    
    return results;
  }

  /// Test path validation
  static Map<String, bool> testPathValidation() {
    final testPaths = [
      'assets/videos/deltoids_chest.mp4',
      'assets/videos/triceps.mp4',
      'assets/videos/invalid.txt',
      'invalid/path/video.mp4',
      'assets/videos/missing.mp4',
    ];
    
    final results = <String, bool>{};
    
    for (final path in testPaths) {
      results[path] = MuscleVideoMapping.isValidVideoPath(path);
    }
    
    return results;
  }

  /// Run comprehensive tests
  static Map<String, dynamic> runAllTests() {
    return {
      'mappingTest': testAllMappings(),
      'fallbackTest': testFallbacks(),
      'pathValidationTest': testPathValidation(),
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
    print('  Invalid paths: ${mappingResults['invalidPaths']}');
    print('');
    
    // Fallback test results
    final fallbackResults = results['fallbackTest'] as Map<String, dynamic>;
    print('🔄 Fallback Tests:');
    fallbackResults.forEach((final key, final value) {
      print('  $key: $value');
    });
    print('');
    
    // Path validation test results
    final pathResults = results['pathValidationTest'] as Map<String, bool>;
    print('✅ Path Validation Tests:');
    pathResults.forEach((final path, final isValid) {
      print('  $path -> ${isValid ? "Valid" : "Invalid"}');
    });
    print('');
    
    // Specific muscle test results
    final muscleResults = results['specificMuscleTest'] as Map<String, String>;
    print('💪 Specific Muscle Tests:');
    muscleResults.forEach((final muscle, final videoPath) {
      print('  $muscle: $videoPath');
    });
    print('');
    
    print('=== Test Complete ===');
  }
}
