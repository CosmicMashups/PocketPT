import 'package:flutter_test/flutter_test.dart';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:PocketPT/data/globals.dart';
import 'package:PocketPT/data/rehabilitation_plan.dart';
import 'package:PocketPT/data/exercise_ranking_service.dart';

/// Standalone test to compute evaluation metrics for exercise ranking service
/// 
/// Run with: flutter test test/exercise_ranking_evaluation_test.dart
/// 
/// This test:
/// 1. Sets up mock exercise and pain history data
/// 2. Loads exercises from CSV
/// 3. Computes evaluation metrics (NDCG@3, Precision@3, Recall@3)
/// 4. Prints results to console
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Ensure Hive is initialized for ExerciseDataService -> CustomExerciseService -> openRehabBox()
  // This allows CSV-based tests to run without a full app startup / APK build.
  final hiveDir = Directory.systemTemp.createTempSync('pocketpt_hive_test_');
  Hive.init(hiveDir.path);
  
  group('Exercise Ranking Evaluation Metrics', () {
    setUp(() {
      // Clear existing data
      PainHistory.entries.clear();
      ExerciseHistory.entries.clear();
      
      // Set up UserAssess for testing
      UserAssess.specificMuscle = 'Deltoids';
      UserAssess.painLevel = 'Moderate';
      UserAssess.rehabGoal = 'Strength';
      UserAssess.painScale = 5;
    });

    test('Compute evaluation metrics with mock data', () async {
      // Create mock pain history (last 7 days)
      final now = DateTime.now();
      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        PainHistory.addEntry(
          painScale: 5 + (i % 3) - 1, // Varying pain: 4-6
          painLevel: 'Moderate',
          date: date,
        );
      }

      // Create mock exercise history with pain outcomes
      // Exercise E001: Led to pain reduction (good)
      ExerciseHistory.recordToday(
        exerciseId: 'E001',
        exerciseName: 'Shoulder Raise',
        sets: 3,
        reps: 10,
        durationSeconds: 300,
        status: 'completed',
        painScale: 5,
        painLevel: 'Moderate',
        now: now.subtract(const Duration(days: 3)),
      );
      // Add pain reduction after exercise
      PainHistory.addEntry(
        painScale: 4, // Reduced from 5
        painLevel: 'Moderate',
        date: now.subtract(const Duration(days: 2)),
      );

      // Exercise E002: Neutral (no change)
      ExerciseHistory.recordToday(
        exerciseId: 'E002',
        exerciseName: 'Arm Circles',
        sets: 2,
        reps: 15,
        durationSeconds: 240,
        status: 'completed',
        painScale: 5,
        painLevel: 'Moderate',
        now: now.subtract(const Duration(days: 5)),
      );
      PainHistory.addEntry(
        painScale: 5, // No change
        painLevel: 'Moderate',
        date: now.subtract(const Duration(days: 4)),
      );

      // Exercise E003: Led to pain increase (bad)
      ExerciseHistory.recordToday(
        exerciseId: 'E003',
        exerciseName: 'Heavy Lifting',
        sets: 5,
        reps: 8,
        durationSeconds: 600,
        status: 'completed',
        painScale: 5,
        painLevel: 'Moderate',
        now: now.subtract(const Duration(days: 1)),
      );
      PainHistory.addEntry(
        painScale: 6, // Increased from 5
        painLevel: 'Moderate',
        date: now,
      );

      // Exercise E004: Multiple completions, mostly good
      for (int i = 0; i < 3; i++) {
        ExerciseHistory.recordToday(
          exerciseId: 'E004',
          exerciseName: 'Stretching',
          sets: 3,
          reps: 12,
          durationSeconds: 180,
          status: 'completed',
          painScale: 5,
          painLevel: 'Moderate',
          now: now.subtract(Duration(days: 7 + i)),
        );
      }

      print('\n=== Exercise Ranking Evaluation Metrics ===\n');
      print('Mock Data Setup:');
      print('- Pain History Entries: ${PainHistory.entries.length}');
      print('- Exercise History Entries: ${ExerciseHistory.entries.length}');
      print('- User Muscle: ${UserAssess.specificMuscle}');
      print('- User Pain Level: ${UserAssess.painLevel}');
      print('- User Goal: ${UserAssess.rehabGoal}\n');

      // Load exercises from CSV
      try {
        final allExercises = await ExerciseDataService.loadAllExercises();
        print('Loaded ${allExercises.length} exercises from CSV\n');

        // Filter exercises matching user condition
        final filteredExercises = allExercises.where((e) {
          return e.muscle.toLowerCase() == UserAssess.specificMuscle.toLowerCase() ||
                 e.painLevel.toLowerCase() == UserAssess.painLevel.toLowerCase();
        }).toList();

        print('Filtered to ${filteredExercises.length} matching exercises\n');

        if (allExercises.isEmpty) {
          print('❌ No exercises loaded from CSV. Cannot compute evaluation metrics.');
          print('Please ensure assets/data/exercises.csv exists and is properly formatted.');
          return;
        }

        if (filteredExercises.isEmpty) {
          print('⚠️  No matching exercises found. Using all exercises for testing.');
        }

        // Use filtered exercises or all exercises for testing
        final testExercises = filteredExercises.isNotEmpty 
            ? filteredExercises.take(10).toList() // Use top 10 for testing
            : allExercises.take(10).toList();
        
        if (testExercises.isEmpty) {
          print('❌ No test exercises available. Cannot compute evaluation metrics.');
          return;
        }

        // Compute evaluation metrics
        print('Computing evaluation metrics...\n');
        final metrics = await ExerciseRankingService.getEvaluationMetrics(
          testExercises: testExercises,
          specificMuscle: UserAssess.specificMuscle,
          painLevel: UserAssess.painLevel,
          rehabGoal: UserAssess.rehabGoal,
        );

        // Print results
        print('=== Evaluation Results ===\n');
        print('Service Status: ${metrics['serviceStatus']}');
        print('Evaluation Status: ${metrics['evaluationStatus'] ?? 'Unknown'}');
        print('Exercise History Records: ${metrics['exerciseHistoryRecords']}');
        print('Pain History Days: ${metrics['painHistoryDays']}');
        print('Has Enough Data: ${metrics['hasEnoughData']}\n');

        final evaluationStatus = metrics['evaluationStatus'] as String?;
        if (evaluationStatus == 'Complete') {
          print('--- AI Ranking Metrics ---');
          final aiRanking = metrics['aiRanking'] as Map<String, dynamic>;
          print('NDCG@3: ${aiRanking['ndcg@3']?.toStringAsFixed(3)}');
          print('Precision@3: ${aiRanking['precision@3']?.toStringAsFixed(3)}');
          print('Recall@3: ${aiRanking['recall@3']?.toStringAsFixed(3)}');
          
          final componentStats = aiRanking['componentStats'] as Map<String, dynamic>;
          print('\nComponent Statistics:');
          print('  Average Score: ${componentStats['avgScore']?.toStringAsFixed(3)}');
          print('  Min Score: ${componentStats['minScore']?.toStringAsFixed(3)}');
          print('  Max Score: ${componentStats['maxScore']?.toStringAsFixed(3)}');
          print('  Std Deviation: ${componentStats['stdDev']?.toStringAsFixed(3)}');
          print('  Score Range: ${componentStats['scoreRange']?.toStringAsFixed(3)}');

          print('\n--- Random Baseline ---');
          final randomBaseline = metrics['randomBaseline'] as Map<String, dynamic>;
          print('NDCG@3: ${randomBaseline['ndcg@3']?.toStringAsFixed(3)}');
          print('Precision@3: ${randomBaseline['precision@3']?.toStringAsFixed(3)}');
          print('Recall@3: ${randomBaseline['recall@3']?.toStringAsFixed(3)}');

          print('\n--- Rule-Based Baseline ---');
          final ruleBasedBaseline = metrics['ruleBasedBaseline'] as Map<String, dynamic>;
          print('NDCG@3: ${ruleBasedBaseline['ndcg@3']?.toStringAsFixed(3)}');
          print('Precision@3: ${ruleBasedBaseline['precision@3']?.toStringAsFixed(3)}');
          print('Recall@3: ${ruleBasedBaseline['recall@3']?.toStringAsFixed(3)}');

          print('\n--- Improvements ---');
          final improvements = metrics['improvements'] as Map<String, dynamic>;
          print('Over Random: ${improvements['overRandomPercent']}');
          print('Over Rule-Based: ${improvements['overRuleBasedPercent']}');

          print('\n=== Summary ===');
          final aiNDCG = aiRanking['ndcg@3'] as double;
          final randomNDCG = randomBaseline['ndcg@3'] as double;
          final ruleBasedNDCG = ruleBasedBaseline['ndcg@3'] as double;
          
          print('AI Ranking NDCG@3: ${aiNDCG.toStringAsFixed(3)}');
          print('Random Baseline NDCG@3: ${randomNDCG.toStringAsFixed(3)}');
          print('Rule-Based Baseline NDCG@3: ${ruleBasedNDCG.toStringAsFixed(3)}');
          
          if (aiNDCG > randomNDCG) {
            print('✅ AI Ranking outperforms random baseline');
          }
          if (aiNDCG > ruleBasedNDCG) {
            print('✅ AI Ranking outperforms rule-based baseline');
          }
        } else {
          print('⚠️  ${evaluationStatus ?? 'Unknown status'}');
          if (metrics['note'] != null) {
            print('Note: ${metrics['note']}');
          }
          if (metrics['error'] != null) {
            print('Error: ${metrics['error']}');
          }
        }

        print('\n=== Test Complete ===\n');
      } catch (e, stackTrace) {
        print('❌ Error computing metrics: $e');
        print('Stack trace: $stackTrace');
        fail('Failed to compute evaluation metrics: $e');
      }
    }, timeout: const Timeout(Duration(minutes: 2)));

    test('Compute metrics with real user data (if available)', () async {
      // Load actual data from Hive if available
      try {
        await PainHistory.loadFromHive();
        print('\nLoaded ${PainHistory.entries.length} pain history entries from Hive');
      } catch (e) {
        print('No Hive data available: $e');
      }

      // Load exercises
      final allExercises = await ExerciseDataService.loadAllExercises();
      if (allExercises.isEmpty) {
        print('No exercises available');
        return;
      }

      // Use first 10 exercises for testing
      final testExercises = allExercises.take(10).toList();

      // Compute metrics
      final metrics = await ExerciseRankingService.getEvaluationMetrics(
        testExercises: testExercises,
      );

      print('\n=== Real Data Evaluation ===\n');
      print('Status: ${metrics['serviceStatus']}');
      print('Evaluation: ${metrics['evaluationStatus']}');
      
      if (metrics['evaluationStatus'] == 'Complete') {
        final aiRanking = metrics['aiRanking'] as Map<String, dynamic>;
        print('AI NDCG@3: ${aiRanking['ndcg@3']?.toStringAsFixed(3)}');
        
        final improvements = metrics['improvements'] as Map<String, dynamic>;
        print('Improvement over random: ${improvements['overRandomPercent']}');
      }
    }, skip: true); // Skip by default, enable to test with real data
  });
}
