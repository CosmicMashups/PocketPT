import 'package:flutter_test/flutter_test.dart';
import 'package:PocketPT/data/rehabilitation_plan.dart';
import 'package:PocketPT/data/treatment.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('ExerciseDataService Tests', () {
    setUp(() {
      // Clear any cached data before each test
      ExerciseDataService.invalidateCache();
    });

    test('loadAllExercises should return a list of exercises', () async {
      // Act
      final exercises = await ExerciseDataService.loadAllExercises();
      
      // Assert
      expect(exercises, isA<List<Exercise>>());
      expect(exercises.isNotEmpty, true);
    });

    test('loadAllExercises should cache results on subsequent calls', () async {
      // Act
      final firstCall = await ExerciseDataService.loadAllExercises();
      final secondCall = await ExerciseDataService.loadAllExercises();
      
      // Assert
      expect(firstCall, equals(secondCall));
      expect(identical(firstCall, secondCall), true);
    });

    test('getExerciseById should return correct exercise', () async {
      // Arrange
      final exercises = await ExerciseDataService.loadAllExercises();
      if (exercises.isEmpty) {
        fail('No exercises loaded for testing');
      }
      final expectedExercise = exercises.first;
      
      // Act
      final result = await ExerciseDataService.getExerciseById(expectedExercise.exerciseId);
      
      // Assert
      expect(result, isNotNull);
      expect(result!.exerciseId, equals(expectedExercise.exerciseId));
      expect(result.exerciseName, equals(expectedExercise.exerciseName));
    });

    test('getExerciseById should return null for non-existent ID', () async {
      // Act
      final result = await ExerciseDataService.getExerciseById('non-existent-id');
      
      // Assert
      expect(result, isNull);
    });

    test('loadAllTreatments should return a list of treatments', () async {
      // Act
      final treatments = await ExerciseDataService.loadAllTreatments();
      
      // Assert
      expect(treatments, isA<List<Treatment>>());
    });

    test('validateDataIntegrity should return validation results', () async {
      // Act
      final results = await ExerciseDataService.validateDataIntegrity();
      
      // Assert
      expect(results, isA<Map<String, dynamic>>());
      expect(results.containsKey('isValid'), true);
      expect(results.containsKey('totalExercises'), true);
      expect(results.containsKey('validExercises'), true);
      expect(results.containsKey('invalidExercises'), true);
    });

    test('validateCrossReferences should return cross-reference results', () async {
      // Act
      final results = await ExerciseDataService.validateCrossReferences();
      
      // Assert
      expect(results, isA<Map<String, dynamic>>());
      expect(results.containsKey('isValid'), true);
      expect(results.containsKey('totalReferences'), true);
      expect(results.containsKey('validReferences'), true);
      expect(results.containsKey('invalidReferences'), true);
    });

    test('repairDataIssues should return repair results', () async {
      // Act
      final results = await ExerciseDataService.repairDataIssues();
      
      // Assert
      expect(results, isA<Map<String, dynamic>>());
      expect(results.containsKey('isRepaired'), true);
      expect(results.containsKey('issuesFound'), true);
      expect(results.containsKey('issuesRepaired'), true);
    });

    test('backupData should return backup results', () async {
      // Act
      final results = await ExerciseDataService.backupData();
      
      // Assert
      expect(results, isA<Map<String, dynamic>>());
      expect(results.containsKey('isBackedUp'), true);
      expect(results.containsKey('backupTime'), true);
      expect(results.containsKey('backupSize'), true);
    });

    test('refreshCache should clear and reload cache', () async {
      // Arrange
      await ExerciseDataService.loadAllExercises();
      
      // Act
      await ExerciseDataService.refreshCache();
      final exercises = await ExerciseDataService.loadAllExercises();
      
      // Assert
      expect(exercises, isA<List<Exercise>>());
      expect(exercises.isNotEmpty, true);
    });

    test('invalidateCache should clear cached data', () async {
      // Arrange
      await ExerciseDataService.loadAllExercises();
      
      // Act
      ExerciseDataService.invalidateCache();
      final exercises = await ExerciseDataService.loadAllExercises();
      
      // Assert
      expect(exercises, isA<List<Exercise>>());
      expect(exercises.isNotEmpty, true);
    });

    test('Exercise class should have required properties', () {
      // Arrange
      const exerciseId = 'test-id';
      const exerciseName = 'Test Exercise';
      const description = 'Test Description';
      const muscle = 'Test Muscle';
      const painLevel = 'Low';
      const goal = 'Test Goal';
      const repetitions = 10;
      const sets = 3;
      const imageUrl = 'test-image.jpg';
      const videoUrl = 'test-video.mp4';
      const otherMuscles = 'Other Muscles';
      
      // Act
      final exerciseObj = Exercise(
        exerciseId: exerciseId,
        exerciseName: exerciseName,
        description: description,
        muscle: muscle,
        painLevel: painLevel,
        goal: goal,
        repetitions: repetitions,
        sets: sets,
        imageUrl: imageUrl,
        videoUrl: videoUrl,
        otherMuscles: otherMuscles,
      );
      
      // Assert
      expect(exerciseObj.exerciseId, equals(exerciseId));
      expect(exerciseObj.exerciseName, equals(exerciseName));
      expect(exerciseObj.description, equals(description));
      expect(exerciseObj.muscle, equals(muscle));
      expect(exerciseObj.painLevel, equals(painLevel));
      expect(exerciseObj.goal, equals(goal));
      expect(exerciseObj.repetitions, equals(repetitions));
      expect(exerciseObj.sets, equals(sets));
      expect(exerciseObj.imageUrl, equals(imageUrl));
      expect(exerciseObj.videoUrl, equals(videoUrl));
      expect(exerciseObj.otherMuscles, equals(otherMuscles));
    });

    test('Treatment class should have required properties', () {
      // Arrange
      const treatmentId = 'test-treatment-id';
      const treatmentName = 'Test Treatment';
      const description = 'Test Treatment Description';
      const musclesInvolved = 'Test Muscles';
      const painLevel = 'Low';
      const painDuration = 'Short';
      
      // Act
      final treatmentObj = Treatment(
        treatmentId: treatmentId,
        treatmentName: treatmentName,
        description: description,
        musclesInvolved: musclesInvolved,
        painLevel: painLevel,
        painDuration: painDuration,
      );
      
      // Assert
      expect(treatmentObj.treatmentId, equals(treatmentId));
      expect(treatmentObj.treatmentName, equals(treatmentName));
      expect(treatmentObj.description, equals(description));
      expect(treatmentObj.musclesInvolved, equals(musclesInvolved));
      expect(treatmentObj.painLevel, equals(painLevel));
      expect(treatmentObj.painDuration, equals(painDuration));
    });
  });

  group('ExerciseDataService Performance Tests', () {
    test('loadAllExercises should complete within reasonable time', () async {
      // Arrange
      final stopwatch = Stopwatch()..start();
      
      // Act
      await ExerciseDataService.loadAllExercises();
      stopwatch.stop();
      
      // Assert
      expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // Should complete within 5 seconds
    });

    test('getExerciseById should complete within reasonable time', () async {
      // Arrange
      final exercises = await ExerciseDataService.loadAllExercises();
      if (exercises.isEmpty) {
        fail('No exercises loaded for testing');
      }
      final exerciseId = exercises.first.exerciseId;
      final stopwatch = Stopwatch()..start();
      
      // Act
      await ExerciseDataService.getExerciseById(exerciseId);
      stopwatch.stop();
      
      // Assert
      expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // Should complete within 1 second
    });

    test('validateDataIntegrity should complete within reasonable time', () async {
      // Arrange
      final stopwatch = Stopwatch()..start();
      
      // Act
      await ExerciseDataService.validateDataIntegrity();
      stopwatch.stop();
      
      // Assert
      expect(stopwatch.elapsedMilliseconds, lessThan(10000)); // Should complete within 10 seconds
    });
  });

  group('ExerciseDataService Error Handling Tests', () {
    test('should handle invalid exercise IDs gracefully', () async {
      // Act & Assert
      expect(
        () async => await ExerciseDataService.getExerciseById(''),
        returnsNormally,
      );
      
      expect(
        () async => await ExerciseDataService.getExerciseById('invalid-id'),
        returnsNormally,
      );
    });

    test('should handle cache operations gracefully', () async {
      // Act & Assert
      expect(
        () => ExerciseDataService.invalidateCache(),
        returnsNormally,
      );
      
      expect(
        () async => await ExerciseDataService.refreshCache(),
        returnsNormally,
      );
    });
  });
}
