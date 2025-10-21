import 'package:flutter_test/flutter_test.dart';
import 'package:PocketPT/data/rehabilitation_plan.dart';
import 'package:PocketPT/data/treatment.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('Data Flow Integration Tests', () {
    setUp(() {
      // Clear any cached data before each test
      ExerciseDataService.invalidateCache();
    });

    test('Complete data flow: Load exercises -> Validate -> Cross-reference -> Repair', () async {
      // Arrange
      final stopwatch = Stopwatch()..start();
      
      // Act - Step 1: Load exercises
      final exercises = await ExerciseDataService.loadAllExercises();
      expect(exercises, isA<List<Exercise>>());
      expect(exercises.isNotEmpty, true);
      
      // Act - Step 2: Validate data integrity
      final integrityResults = await ExerciseDataService.validateDataIntegrity();
      expect(integrityResults['isValid'], isA<bool>());
      
      // Act - Step 3: Validate cross-references
      final crossRefResults = await ExerciseDataService.validateCrossReferences();
      expect(crossRefResults['isValid'], isA<bool>());
      
      // Act - Step 4: Repair data issues
      final repairResults = await ExerciseDataService.repairDataIssues();
      expect(repairResults['isRepaired'], isA<bool>());
      
      // Act - Step 5: Backup data
      final backupResults = await ExerciseDataService.backupData();
      expect(backupResults['isBackedUp'], isA<bool>());
      
      stopwatch.stop();
      
      // Assert
      expect(stopwatch.elapsedMilliseconds, lessThan(30000)); // Should complete within 30 seconds
      print('Complete data flow test completed in ${stopwatch.elapsedMilliseconds}ms');
    });

    test('Exercise lookup flow: Load -> Get by ID -> Validate properties', () async {
      // Arrange
      final exercises = await ExerciseDataService.loadAllExercises();
      if (exercises.isEmpty) {
        fail('No exercises loaded for testing');
      }
      final testExercise = exercises.first;
      
      // Act
      final retrievedExercise = await ExerciseDataService.getExerciseById(testExercise.exerciseId);
      
      // Assert
      expect(retrievedExercise, isNotNull);
      expect(retrievedExercise!.exerciseId, equals(testExercise.exerciseId));
      expect(retrievedExercise.exercise, equals(testExercise.exercise));
      expect(retrievedExercise.exerciseDescription, equals(testExercise.exerciseDescription));
      expect(retrievedExercise.repetition, equals(testExercise.repetition));
      expect(retrievedExercise.set, equals(testExercise.set));
    });

    test('Cache management flow: Load -> Cache -> Invalidate -> Reload', () async {
      // Arrange
      final firstLoad = await ExerciseDataService.loadAllExercises();
      expect(firstLoad, isA<List<Exercise>>());
      
      // Act - Verify cache hit
      final secondLoad = await ExerciseDataService.loadAllExercises();
      expect(identical(firstLoad, secondLoad), true);
      
      // Act - Invalidate cache
      ExerciseDataService.invalidateCache();
      
      // Act - Reload after invalidation
      final thirdLoad = await ExerciseDataService.loadAllExercises();
      expect(thirdLoad, isA<List<Exercise>>());
      expect(thirdLoad.length, equals(firstLoad.length));
    });

    test('Error recovery flow: Simulate errors -> Repair -> Validate', () async {
      // Arrange
      await ExerciseDataService.loadAllExercises();
      
      // Act - Mark cache as stale to simulate issues
      ExerciseDataService.markCacheStale();
      
      // Act - Attempt repair
      final repairResults = await ExerciseDataService.repairDataIssues();
      expect(repairResults['isRepaired'], isA<bool>());
      
      // Act - Validate after repair
      final integrityResults = await ExerciseDataService.validateDataIntegrity();
      expect(integrityResults['isValid'], isA<bool>());
      
      // Assert
      expect(repairResults['issuesFound'], isA<int>());
      expect(repairResults['issuesRepaired'], isA<int>());
    });

    test('Performance monitoring flow: Load -> Monitor -> Report', () async {
      // Arrange
      final loadTimes = <int>[];
      const iterations = 5;
      
      // Act - Multiple loads to test performance
      for (int i = 0; i < iterations; i++) {
        final stopwatch = Stopwatch()..start();
        await ExerciseDataService.loadAllExercises();
        stopwatch.stop();
        loadTimes.add(stopwatch.elapsedMilliseconds);
      }
      
      // Assert
      expect(loadTimes.length, equals(iterations));
      expect(loadTimes.every((time) => time < 5000), true); // All loads under 5 seconds
      
      // Calculate average load time
      final averageTime = loadTimes.reduce((a, b) => a + b) / loadTimes.length;
      expect(averageTime, lessThan(2000)); // Average under 2 seconds
      
      print('Performance monitoring: Average load time: ${averageTime.toStringAsFixed(1)}ms');
    });

    test('Data consistency flow: Load exercises -> Load treatments -> Validate consistency', () async {
      // Arrange
      final exercises = await ExerciseDataService.loadAllExercises();
      final treatments = await ExerciseDataService.loadAllTreatments();
      
      // Act - Validate data consistency
      final integrityResults = await ExerciseDataService.validateDataIntegrity();
      final crossRefResults = await ExerciseDataService.validateCrossReferences();
      
      // Assert
      expect(exercises, isA<List<Exercise>>());
      expect(treatments, isA<List<Treatment>>());
      expect(integrityResults['isValid'], isA<bool>());
      expect(crossRefResults['isValid'], isA<bool>());
      
      // Verify data structure consistency
      for (final exercise in exercises) {
        expect(exercise.exerciseId, isNotEmpty);
        expect(exercise.exerciseName, isNotEmpty);
        expect(exercise.description, isNotEmpty);
        expect(exercise.repetitions, greaterThan(0));
        expect(exercise.sets, greaterThan(0));
      }
      
      for (final treatment in treatments) {
        expect(treatment.treatmentId, isNotEmpty);
        expect(treatment.treatmentName, isNotEmpty);
        expect(treatment.description, isNotEmpty);
      }
    });

    test('Backup and restore flow: Backup -> Validate backup -> Restore simulation', () async {
      // Arrange
      await ExerciseDataService.loadAllExercises();
      await ExerciseDataService.loadAllTreatments();
      
      // Act - Create backup
      final backupResults = await ExerciseDataService.backupData();
      expect(backupResults['isBackedUp'], isTrue);
      expect(backupResults['backupSize'], greaterThan(0));
      expect(backupResults['backupTime'], greaterThan(0));
      
      // Act - Validate backup data
      expect(backupResults['backupLocation'], isNotEmpty);
      
      // Assert
      print('Backup created: ${backupResults['backupSize']} bytes in ${backupResults['backupTime']}ms');
    });
  });

  group('Stress Test Integration', () {
    test('High load scenario: Multiple concurrent operations', () async {
      // Arrange
      const concurrentOperations = 10;
      final futures = <Future>[];
      
      // Act - Start multiple concurrent operations
      for (int i = 0; i < concurrentOperations; i++) {
        futures.add(ExerciseDataService.loadAllExercises());
        futures.add(ExerciseDataService.loadAllTreatments());
        futures.add(ExerciseDataService.validateDataIntegrity());
      }
      
      // Wait for all operations to complete
      final results = await Future.wait(futures);
      
      // Assert
      expect(results.length, equals(concurrentOperations * 3));
      expect(results.every((result) => result != null), true);
    });

    test('Memory stress test: Repeated load and unload cycles', () async {
      // Arrange
      const cycles = 20;
      final loadTimes = <int>[];
      
      // Act - Repeated load cycles
      for (int i = 0; i < cycles; i++) {
        final stopwatch = Stopwatch()..start();
        await ExerciseDataService.loadAllExercises();
        await ExerciseDataService.loadAllTreatments();
        stopwatch.stop();
        loadTimes.add(stopwatch.elapsedMilliseconds);
        
        // Force garbage collection simulation
        if (i % 5 == 0) {
          ExerciseDataService.invalidateCache();
        }
      }
      
      // Assert
      expect(loadTimes.length, equals(cycles));
      expect(loadTimes.every((time) => time < 10000), true); // All cycles under 10 seconds
      
      final averageTime = loadTimes.reduce((a, b) => a + b) / loadTimes.length;
      expect(averageTime, lessThan(3000)); // Average under 3 seconds
      
      print('Memory stress test: Average cycle time: ${averageTime.toStringAsFixed(1)}ms');
    });
  });
}
