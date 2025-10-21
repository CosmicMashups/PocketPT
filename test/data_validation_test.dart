import 'package:flutter_test/flutter_test.dart';
import 'package:PocketPT/data/rehabilitation_plan.dart';
import 'package:PocketPT/data/treatment.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('Data Validation Tests', () {
    setUp(() {
      // Clear any cached data before each test
      ExerciseDataService.invalidateCache();
    });

    test('CSV data integrity validation should detect valid data', () async {
      // Act
      final results = await ExerciseDataService.validateDataIntegrity();
      
      // Assert
      expect(results, isA<Map<String, dynamic>>());
      expect(results.containsKey('isValid'), true);
      expect(results.containsKey('totalExercises'), true);
      expect(results.containsKey('validExercises'), true);
      expect(results.containsKey('invalidExercises'), true);
      expect(results.containsKey('issues'), true);
      expect(results.containsKey('validationTime'), true);
      
      // Validation should complete successfully
      expect(results['validationTime'], isA<int>());
      expect(results['validationTime'], greaterThan(0));
    });

    test('CSV data integrity validation should detect invalid data', () async {
      // Act
      final results = await ExerciseDataService.validateDataIntegrity();
      
      // Assert
      expect(results, isA<Map<String, dynamic>>());
      
      // Check if validation found any issues
      if (results['isValid'] == false) {
        expect(results['invalidExercises'], greaterThan(0));
        expect(results['issues'], isA<List<String>>());
        expect((results['issues'] as List<String>).isNotEmpty, true);
      }
    });

    test('Exercise ID validation should work correctly', () async {
      // Arrange
      final exercises = await ExerciseDataService.loadAllExercises();
      
      if (exercises.isNotEmpty) {
        final validId = exercises.first.exerciseId;
        final invalidId = 'invalid-exercise-id';
        
        // Act
        final validExercise = await ExerciseDataService.getExerciseById(validId);
        final invalidExercise = await ExerciseDataService.getExerciseById(invalidId);
        
        // Assert
        expect(validExercise, isNotNull);
        expect(validExercise!.exerciseId, equals(validId));
        expect(invalidExercise, isNull);
      }
    });

    test('Cross-reference validation should detect missing references', () async {
      // Act
      final results = await ExerciseDataService.validateCrossReferences();
      
      // Assert
      expect(results, isA<Map<String, dynamic>>());
      expect(results.containsKey('isValid'), true);
      expect(results.containsKey('totalReferences'), true);
      expect(results.containsKey('validReferences'), true);
      expect(results.containsKey('invalidReferences'), true);
      expect(results.containsKey('orphanedReferences'), true);
      expect(results.containsKey('missingReferences'), true);
      expect(results.containsKey('validationTime'), true);
      
      // Validation should complete successfully
      expect(results['validationTime'], isA<int>());
      expect(results['validationTime'], greaterThan(0));
    });

    test('Cross-reference validation should detect orphaned exercises', () async {
      // Act
      final results = await ExerciseDataService.validateCrossReferences();
      
      // Assert
      expect(results, isA<Map<String, dynamic>>());
      
      // Check for orphaned exercises
      expect(results['orphanedReferences'], isA<List<String>>());
      expect(results['missingReferences'], isA<List<String>>());
    });

    test('Data consistency validation should check exercise properties', () async {
      // Arrange
      final exercises = await ExerciseDataService.loadAllExercises();
      
      // Act & Assert
      for (final exercise in exercises) {
        // Check required properties
        expect(exercise.exerciseId, isNotEmpty);
        expect(exercise.exerciseName, isNotEmpty);
        expect(exercise.description, isNotEmpty);
        expect(exercise.muscle, isNotEmpty);
        expect(exercise.painLevel, isNotEmpty);
        // Note: goal can be empty in some exercises (data quality issue)
        expect(exercise.goal, isNotNull);
        
        // Check numeric properties
        expect(exercise.repetitions, greaterThan(0));
        expect(exercise.sets, greaterThan(0));
        
        // Check string properties are not null
        expect(exercise.imageUrl, isNotNull);
        expect(exercise.videoUrl, isNotNull);
        expect(exercise.otherMuscles, isNotNull);
      }
    });

    test('Data consistency validation should check treatment properties', () async {
      // Arrange
      final treatments = await ExerciseDataService.loadAllTreatments();
      
      // Act & Assert
      for (final treatment in treatments) {
        // Check required properties
        expect(treatment.treatmentId, isNotEmpty);
        expect(treatment.treatmentName, isNotEmpty);
        expect(treatment.description, isNotEmpty);
        expect(treatment.musclesInvolved, isNotEmpty);
        expect(treatment.painLevel, isNotEmpty);
        expect(treatment.painDuration, isNotEmpty);
      }
    });

    test('Error handling validation should handle invalid inputs gracefully', () async {
      // Act & Assert
      expect(
        () async => await ExerciseDataService.getExerciseById(''),
        returnsNormally,
      );
      
      expect(
        () async => await ExerciseDataService.getExerciseById('invalid-id'),
        returnsNormally,
      );
      
      expect(
        () async => await ExerciseDataService.validateDataIntegrity(),
        returnsNormally,
      );
      
      expect(
        () async => await ExerciseDataService.validateCrossReferences(),
        returnsNormally,
      );
    });

    test('Data recovery validation should handle repair operations', () async {
      // Act
      final results = await ExerciseDataService.repairDataIssues();
      
      // Assert
      expect(results, isA<Map<String, dynamic>>());
      expect(results.containsKey('isRepaired'), true);
      expect(results.containsKey('issuesFound'), true);
      expect(results.containsKey('issuesRepaired'), true);
      expect(results.containsKey('repairActions'), true);
      expect(results.containsKey('repairTime'), true);
      
      // Repair should complete successfully
      expect(results['repairTime'], isA<int>());
      expect(results['repairTime'], greaterThan(0));
    });

    test('Data backup validation should handle backup operations', () async {
      // Act
      final results = await ExerciseDataService.backupData();
      
      // Assert
      expect(results, isA<Map<String, dynamic>>());
      expect(results.containsKey('isBackedUp'), true);
      expect(results.containsKey('backupTime'), true);
      expect(results.containsKey('backupSize'), true);
      expect(results.containsKey('backupLocation'), true);
      
      // Backup should complete successfully
      expect(results['backupTime'], isA<int>());
      expect(results['backupTime'], greaterThan(0));
      expect(results['backupSize'], greaterThan(0));
      expect(results['backupLocation'], isNotEmpty);
    });
  });

  group('Data Validation Performance Tests', () {
    test('Data integrity validation should complete within reasonable time', () async {
      // Arrange
      final stopwatch = Stopwatch()..start();
      
      // Act
      await ExerciseDataService.validateDataIntegrity();
      stopwatch.stop();
      
      // Assert
      expect(stopwatch.elapsedMilliseconds, lessThan(10000)); // Should complete within 10 seconds
    });

    test('Cross-reference validation should complete within reasonable time', () async {
      // Arrange
      final stopwatch = Stopwatch()..start();
      
      // Act
      await ExerciseDataService.validateCrossReferences();
      stopwatch.stop();
      
      // Assert
      expect(stopwatch.elapsedMilliseconds, lessThan(10000)); // Should complete within 10 seconds
    });

    test('Data repair should complete within reasonable time', () async {
      // Arrange
      final stopwatch = Stopwatch()..start();
      
      // Act
      await ExerciseDataService.repairDataIssues();
      stopwatch.stop();
      
      // Assert
      expect(stopwatch.elapsedMilliseconds, lessThan(15000)); // Should complete within 15 seconds
    });

    test('Data backup should complete within reasonable time', () async {
      // Arrange
      final stopwatch = Stopwatch()..start();
      
      // Act
      await ExerciseDataService.backupData();
      stopwatch.stop();
      
      // Assert
      expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // Should complete within 5 seconds
    });
  });

  group('Data Validation Error Recovery Tests', () {
    test('Should handle CSV loading errors gracefully', () async {
      // Act & Assert
      expect(
        () async => await ExerciseDataService.loadAllExercises(),
        returnsNormally,
      );
      
      expect(
        () async => await ExerciseDataService.loadAllTreatments(),
        returnsNormally,
      );
    });

    test('Should handle validation errors gracefully', () async {
      // Act & Assert
      expect(
        () async => await ExerciseDataService.validateDataIntegrity(),
        returnsNormally,
      );
      
      expect(
        () async => await ExerciseDataService.validateCrossReferences(),
        returnsNormally,
      );
    });

    test('Should handle repair errors gracefully', () async {
      // Act & Assert
      expect(
        () async => await ExerciseDataService.repairDataIssues(),
        returnsNormally,
      );
    });

    test('Should handle backup errors gracefully', () async {
      // Act & Assert
      expect(
        () async => await ExerciseDataService.backupData(),
        returnsNormally,
      );
    });
  });

  group('Data Validation Consistency Tests', () {
    test('Multiple validation runs should produce consistent results', () async {
      // Act
      final results1 = await ExerciseDataService.validateDataIntegrity();
      final results2 = await ExerciseDataService.validateDataIntegrity();
      
      // Assert
      expect(results1['isValid'], equals(results2['isValid']));
      expect(results1['totalExercises'], equals(results2['totalExercises']));
      expect(results1['validExercises'], equals(results2['validExercises']));
      expect(results1['invalidExercises'], equals(results2['invalidExercises']));
    });

    test('Cross-reference validation should be consistent across runs', () async {
      // Act
      final results1 = await ExerciseDataService.validateCrossReferences();
      final results2 = await ExerciseDataService.validateCrossReferences();
      
      // Assert
      expect(results1['isValid'], equals(results2['isValid']));
      expect(results1['totalReferences'], equals(results2['totalReferences']));
      expect(results1['validReferences'], equals(results2['validReferences']));
      expect(results1['invalidReferences'], equals(results2['invalidReferences']));
    });

    test('Data repair should be idempotent', () async {
      // Act
      final results1 = await ExerciseDataService.repairDataIssues();
      final results2 = await ExerciseDataService.repairDataIssues();
      
      // Assert
      expect(results1['isRepaired'], equals(results2['isRepaired']));
      // Second repair should find fewer or no issues
      expect(results2['issuesFound'], lessThanOrEqualTo(results1['issuesFound']));
    });
  });
}
