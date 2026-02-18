import 'package:flutter/foundation.dart';
import 'dart:math' as math;
import 'globals.dart';
import 'rehabilitation_plan.dart';

/// Ranked exercise with suitability score
class RankedExercise {
  final Exercise exercise;
  final double suitabilityScore;
  final String? explanation;

  RankedExercise({
    required this.exercise,
    required this.suitabilityScore,
    this.explanation,
  });
}

/// Service for ranking exercises using AI/ML-based scoring
/// 
/// This service uses a lightweight Decision Tree-inspired algorithm to rank
/// exercises based on user history, pain patterns, and exercise effectiveness.
/// 
/// Features:
/// - User pain history trends
/// - Exercise completion rates
/// - Pain outcomes after exercises
/// - Exercise metadata matching
class ExerciseRankingService {
  static final ExerciseRankingService _instance = ExerciseRankingService._internal();
  factory ExerciseRankingService() => _instance;
  ExerciseRankingService._internal();

  // Minimum data requirements
  static const int minExerciseHistoryRecords = 5; // Lowered for prototype
  static const int minPainHistoryDays = 3; // Lowered for prototype

  /// Rank exercises based on user history and current condition
  /// 
  /// Returns ranked list of exercises with suitability scores (0.0-1.0).
  /// Higher scores indicate better suitability for the user.
  /// 
  /// Falls back to rule-based ranking if insufficient data.
  static Future<List<RankedExercise>> rankExercises({
    required List<Exercise> exercises,
    required String specificMuscle,
    required String painLevel,
    required String rehabGoal,
  }) async {
    try {
      // Check if we have sufficient data for AI ranking
      final hasEnoughData = _hasEnoughData();
      
      if (!hasEnoughData) {
        debugPrint('ExerciseRankingService: Insufficient data, using rule-based ranking');
        return _ruleBasedRanking(exercises, specificMuscle, painLevel, rehabGoal);
      }

      // Extract features for each exercise
      final rankedExercises = <RankedExercise>[];
      
      for (final exercise in exercises) {
        final score = await _calculateSuitabilityScore(
          exercise: exercise,
          specificMuscle: specificMuscle,
          painLevel: painLevel,
          rehabGoal: rehabGoal,
        );
        
        rankedExercises.add(RankedExercise(
          exercise: exercise,
          suitabilityScore: score,
          explanation: _generateExplanation(exercise, score),
        ));
      }

      // Sort by suitability score (descending)
      rankedExercises.sort((a, b) => b.suitabilityScore.compareTo(a.suitabilityScore));

      debugPrint('ExerciseRankingService: Ranked ${rankedExercises.length} exercises');
      if (rankedExercises.isNotEmpty) {
        debugPrint('ExerciseRankingService: Top exercise: ${rankedExercises.first.exercise.exerciseName} (score: ${rankedExercises.first.suitabilityScore.toStringAsFixed(3)})');
      }

      return rankedExercises;
    } catch (e, stackTrace) {
      debugPrint('ExerciseRankingService: Error ranking exercises: $e');
      debugPrint('ExerciseRankingService: Stack trace: $stackTrace');
      // Fallback to rule-based ranking on error
      return _ruleBasedRanking(exercises, specificMuscle, painLevel, rehabGoal);
    }
  }

  /// Check if we have sufficient data for AI ranking
  static bool _hasEnoughData() {
    final exerciseHistoryCount = ExerciseHistory.entries.length;
    final painHistoryDays = PainHistory.entries.length;
    
    final hasEnough = exerciseHistoryCount >= minExerciseHistoryRecords &&
                      painHistoryDays >= minPainHistoryDays;
    
    debugPrint('ExerciseRankingService: Data check - Exercise history: $exerciseHistoryCount, Pain history days: $painHistoryDays, Sufficient: $hasEnough');
    
    return hasEnough;
  }

  /// Calculate suitability score for an exercise using Decision Tree-inspired logic
  /// 
  /// Score components:
  /// - Exercise metadata matching (40%): muscle, pain level, goal
  /// - Exercise effectiveness (30%): completion rate, pain outcomes
  /// - User pain trends (20%): improving/worsening pain
  /// - Safety factors (10%): injured muscle avoidance
  static Future<double> _calculateSuitabilityScore({
    required Exercise exercise,
    required String specificMuscle,
    required String painLevel,
    required String rehabGoal,
  }) async {
    double score = 0.0;

    // 1. Exercise Metadata Matching (40% weight)
    final metadataScore = _calculateMetadataScore(
      exercise: exercise,
      specificMuscle: specificMuscle,
      painLevel: painLevel,
      rehabGoal: rehabGoal,
    );
    score += metadataScore * 0.4;

    // 2. Exercise Effectiveness (30% weight)
    final effectivenessScore = _calculateEffectivenessScore(exercise);
    score += effectivenessScore * 0.3;

    // 3. User Pain Trends (20% weight)
    final painTrendScore = _calculatePainTrendScore(exercise, painLevel);
    score += painTrendScore * 0.2;

    // 4. Safety Factors (10% weight)
    final safetyScore = _calculateSafetyScore(exercise);
    score += safetyScore * 0.1;

    // Ensure score is in [0.0, 1.0] range
    return math.max(0.0, math.min(1.0, score));
  }

  /// Calculate metadata matching score (0.0-1.0)
  static double _calculateMetadataScore({
    required Exercise exercise,
    required String specificMuscle,
    required String painLevel,
    required String rehabGoal,
  }) {
    double score = 0.0;
    int matches = 0;
    int totalChecks = 3;

    // Muscle match
    if (exercise.muscle.toLowerCase().trim() == specificMuscle.toLowerCase().trim()) {
      score += 0.4;
      matches++;
    }

    // Pain level match
    if (exercise.painLevel.toLowerCase().trim() == painLevel.toLowerCase().trim()) {
      score += 0.4;
      matches++;
    }

    // Goal match
    if (exercise.goal.toLowerCase().trim() == rehabGoal.toLowerCase().trim()) {
      score += 0.2;
      matches++;
    }

    // Bonus for multiple matches
    if (matches == totalChecks) {
      score = 1.0; // Perfect match
    } else if (matches == 2) {
      score = math.min(1.0, score * 1.2); // Boost for 2 matches
    }

    return math.min(1.0, score);
  }

  /// Calculate exercise effectiveness score based on history (0.0-1.0)
  static double _calculateEffectivenessScore(Exercise exercise) {
    // Get exercise history for this specific exercise
    final exerciseHistory = ExerciseHistory.entries
        .where((e) => e.exerciseId == exercise.exerciseId)
        .toList();

    if (exerciseHistory.isEmpty) {
      // No history: default to neutral score
      return 0.5;
    }

    // Calculate completion rate
    final completedCount = exerciseHistory.where((e) => e.status == 'completed').length;
    final completionRate = completedCount / exerciseHistory.length;

    // Calculate pain outcomes (if available)
    double painOutcomeScore = 0.5; // Default neutral
    final exercisesWithPain = exerciseHistory.where((e) => e.painScale != null).toList();
    
    if (exercisesWithPain.isNotEmpty) {
      // Get pain before and after exercise (simplified: use pain history around exercise date)
      final painChanges = <double>[];
      
      for (final ex in exercisesWithPain) {
        // Find pain entry on exercise date
        final exerciseDate = ex.date;
        final painOnDate = PainHistory.entries
            .where((p) => _isSameDate(p.date, exerciseDate))
            .firstOrNull;
        
        if (painOnDate != null) {
          // Find pain entry 1-2 days after exercise
          final painAfter = PainHistory.entries
              .where((p) => p.date.isAfter(exerciseDate) && 
                           p.date.difference(exerciseDate).inDays <= 2)
              .firstOrNull;
          
          if (painAfter != null) {
            final painChange = (painOnDate.painScale - painAfter.painScale).toDouble();
            painChanges.add(painChange);
          }
        }
      }

      if (painChanges.isNotEmpty) {
        final avgPainChange = painChanges.reduce((a, b) => a + b) / painChanges.length;
        // Normalize: pain reduction is good (positive change), pain increase is bad
        // Map to [0, 1]: -5 (worse) -> 0.0, 0 (neutral) -> 0.5, +5 (better) -> 1.0
        painOutcomeScore = math.max(0.0, math.min(1.0, 0.5 + (avgPainChange / 10.0)));
      }
    }

    // Combine completion rate and pain outcomes
    // Weight: 60% completion rate, 40% pain outcomes
    final effectiveness = (completionRate * 0.6) + (painOutcomeScore * 0.4);
    
    return math.max(0.0, math.min(1.0, effectiveness));
  }

  /// Calculate pain trend score (0.0-1.0)
  /// Higher score if exercise is suitable for current pain trend
  static double _calculatePainTrendScore(Exercise exercise, String currentPainLevel) {
    // Get last 7 days of pain history
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final recentPain = PainHistory.entries
        .where((p) => p.date.isAfter(sevenDaysAgo))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (recentPain.length < 2) {
      // Not enough data: default to neutral
      return 0.5;
    }

    // Calculate pain trend
    final firstPain = recentPain.first.painScale;
    final lastPain = recentPain.last.painScale;
    final painTrend = lastPain - firstPain; // Negative = improving, positive = worsening

    // Determine if exercise is suitable for trend
    // If pain is improving: prefer exercises for lower pain levels
    // If pain is worsening: prefer exercises for current/higher pain levels
    final exercisePainLevel = exercise.painLevel.toLowerCase();
    final currentPainLevelLower = currentPainLevel.toLowerCase();

    double score = 0.5; // Default neutral

    if (painTrend < -1) {
      // Pain improving: prefer exercises for lower pain levels
      if (exercisePainLevel == 'low' || 
          (exercisePainLevel == 'moderate' && currentPainLevelLower == 'severe')) {
        score = 0.8;
      } else if (exercisePainLevel == currentPainLevelLower) {
        score = 0.6;
      } else {
        score = 0.4;
      }
    } else if (painTrend > 1) {
      // Pain worsening: prefer exercises for current pain level (don't push too hard)
      if (exercisePainLevel == currentPainLevelLower) {
        score = 0.7;
      } else if (exercisePainLevel == 'low' && currentPainLevelLower != 'low') {
        score = 0.5; // May be too easy
      } else {
        score = 0.3; // Too aggressive
      }
    } else {
      // Pain stable: prefer exercises matching current level
      if (exercisePainLevel == currentPainLevelLower) {
        score = 0.7;
      } else {
        score = 0.5;
      }
    }

    return score;
  }

  /// Calculate safety score (0.0-1.0)
  /// Lower score if exercise involves severely injured muscles
  static double _calculateSafetyScore(Exercise exercise) {
    // Check if exercise involves injured muscles (from UserAssess)
    if (UserAssess.injuredMuscles.isEmpty) {
      return 1.0; // No injured muscles: safe
    }

    // Check if Other_Muscles contains severely injured muscles
    final otherMuscles = exercise.otherMuscles.toLowerCase();
    bool hasSeverelyInjuredMuscle = false;

    for (final injuredMuscle in UserAssess.injuredMuscles) {
      final painLevel = UserAssess.musclePainLevels[injuredMuscle] ?? 0;
      if (painLevel >= 8) {
        // Severely injured muscle
        if (otherMuscles.contains(injuredMuscle.toLowerCase())) {
          hasSeverelyInjuredMuscle = true;
          break;
        }
      }
    }

    // Penalize exercises involving severely injured muscles
    if (hasSeverelyInjuredMuscle) {
      return 0.2; // Low safety score
    }

    return 1.0; // Safe
  }

  /// Generate explanation for ranking (optional)
  static String? _generateExplanation(Exercise exercise, double score) {
    if (score >= 0.7) {
      return 'Highly suitable based on your history and current condition';
    } else if (score >= 0.5) {
      return 'Moderately suitable';
    } else {
      return 'Less suitable - consider alternatives';
    }
  }

  /// Rule-based ranking fallback (when insufficient data)
  static List<RankedExercise> _ruleBasedRanking(
    List<Exercise> exercises,
    String specificMuscle,
    String painLevel,
    String rehabGoal,
  ) {
    final ranked = <RankedExercise>[];

    for (final exercise in exercises) {
      double score = 0.0;

      // Simple rule-based scoring
      if (exercise.muscle.toLowerCase().trim() == specificMuscle.toLowerCase().trim()) {
        score += 0.4;
      }
      if (exercise.painLevel.toLowerCase().trim() == painLevel.toLowerCase().trim()) {
        score += 0.4;
      }
      if (exercise.goal.toLowerCase().trim() == rehabGoal.toLowerCase().trim()) {
        score += 0.2;
      }

      ranked.add(RankedExercise(
        exercise: exercise,
        suitabilityScore: score,
        explanation: 'Rule-based ranking (insufficient data for AI ranking)',
      ));
    }

    // Sort by score
    ranked.sort((a, b) => b.suitabilityScore.compareTo(a.suitabilityScore));

    return ranked;
  }

  /// Helper: Check if two dates are the same (date only)
  static bool _isSameDate(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  /// Compute ground truth relevance scores for exercises
  /// 
  /// Returns a map of exerciseId -> relevance score (0.0-1.0)
  /// Relevance: 1.0 = exercise led to pain reduction, 0.5 = neutral, 0.0 = pain increase
  static Map<String, double> _computeGroundTruth() {
    final groundTruth = <String, double>{};
    
    // Group exercises by ID and compute average pain change
    final exerciseGroups = <String, List<double>>{};
    
    for (final ex in ExerciseHistory.entries) {
      if (ex.status != 'completed' || ex.painScale == null) continue;
      
      final exerciseDate = ex.date;
      final painOnDate = PainHistory.entries
          .where((p) => _isSameDate(p.date, exerciseDate))
          .firstOrNull;
      
      if (painOnDate == null) continue;
      
      // Find pain entry 1-2 days after exercise
      final painAfter = PainHistory.entries
          .where((p) => p.date.isAfter(exerciseDate) && 
                       p.date.difference(exerciseDate).inDays <= 2)
          .firstOrNull;
      
      if (painAfter != null) {
        final painChange = (painOnDate.painScale - painAfter.painScale).toDouble();
        exerciseGroups.putIfAbsent(ex.exerciseId, () => []).add(painChange);
      }
    }
    
    // Compute relevance scores: normalize pain changes to [0, 1]
    for (final entry in exerciseGroups.entries) {
      final avgPainChange = entry.value.reduce((a, b) => a + b) / entry.value.length;
      // Map: -5 (worse) -> 0.0, 0 (neutral) -> 0.5, +5 (better) -> 1.0
      final relevance = math.max(0.0, math.min(1.0, 0.5 + (avgPainChange / 10.0)));
      groundTruth[entry.key] = relevance;
    }
    
    return groundTruth;
  }

  /// Compute NDCG@k (Normalized Discounted Cumulative Gain at k)
  /// 
  /// Measures ranking quality at top k positions
  static double _computeNDCG({
    required List<RankedExercise> rankedExercises,
    required Map<String, double> groundTruth,
    int k = 3,
  }) {
    if (rankedExercises.isEmpty || groundTruth.isEmpty) return 0.0;
    
    // Compute DCG@k
    double dcg = 0.0;
    final topK = rankedExercises.take(k).toList();
    
    for (int i = 0; i < topK.length; i++) {
      final exerciseId = topK[i].exercise.exerciseId;
      final relevance = groundTruth[exerciseId] ?? 0.5; // Default neutral if no ground truth
      final position = i + 1;
      // DCG formula: relevance / log2(position + 1)
      dcg += relevance / math.log(position + 1) / math.ln2;
    }
    
    // Compute ideal DCG (IDCG) - perfect ranking *over the same candidate set*
    //
    // Important: DCG uses a default relevance (0.5) for exercises with no ground truth.
    // If we compute IDCG from only groundTruth.values, DCG can exceed IDCG and NDCG>1.
    // To keep NDCG in [0, 1], build the ideal list from the same candidate exercises.
    final candidateRelevance = rankedExercises
        .map((r) => groundTruth[r.exercise.exerciseId] ?? 0.5)
        .toList()
      ..sort((a, b) => b.compareTo(a));
    double idcg = 0.0;
    
    for (int i = 0; i < math.min(k, candidateRelevance.length); i++) {
      final position = i + 1;
      idcg += candidateRelevance[i] / math.log(position + 1) / math.ln2;
    }
    
    // NDCG = DCG / IDCG
    return idcg > 0 ? dcg / idcg : 0.0;
  }

  /// Compute Precision@k
  /// 
  /// Fraction of top k exercises that are relevant (relevance > 0.5)
  static double _computePrecision({
    required List<RankedExercise> rankedExercises,
    required Map<String, double> groundTruth,
    int k = 3,
  }) {
    if (rankedExercises.isEmpty) return 0.0;
    
    final topK = rankedExercises.take(k).toList();
    int relevantCount = 0;
    
    for (final ranked in topK) {
      final relevance = groundTruth[ranked.exercise.exerciseId] ?? 0.5;
      if (relevance > 0.5) relevantCount++;
    }
    
    return topK.isNotEmpty ? relevantCount / topK.length : 0.0;
  }

  /// Compute Recall@k
  /// 
  /// Fraction of relevant exercises found in top k
  static double _computeRecall({
    required List<RankedExercise> rankedExercises,
    required Map<String, double> groundTruth,
    int k = 3,
  }) {
    if (groundTruth.isEmpty) return 0.0;
    
    final totalRelevant = groundTruth.values.where((r) => r > 0.5).length;
    if (totalRelevant == 0) return 0.0;
    
    final topK = rankedExercises.take(k).toList();
    int foundRelevant = 0;
    
    for (final ranked in topK) {
      final relevance = groundTruth[ranked.exercise.exerciseId] ?? 0.0;
      if (relevance > 0.5) foundRelevant++;
    }
    
    return foundRelevant / totalRelevant;
  }

  /// Generate random ranking baseline
  static List<RankedExercise> _generateRandomRanking(List<Exercise> exercises) {
    final random = math.Random();
    final shuffled = List<Exercise>.from(exercises)..shuffle(random);
    
    return shuffled.map((e) => RankedExercise(
      exercise: e,
      suitabilityScore: random.nextDouble(),
      explanation: 'Random baseline',
    )).toList();
  }

  /// Generate rule-based ranking baseline
  static List<RankedExercise> _generateRuleBasedRanking({
    required List<Exercise> exercises,
    required String specificMuscle,
    required String painLevel,
    required String rehabGoal,
  }) {
    final ranked = <RankedExercise>[];

    for (final exercise in exercises) {
      double score = 0.0;

      if (exercise.muscle.toLowerCase().trim() == specificMuscle.toLowerCase().trim()) {
        score += 0.4;
      }
      if (exercise.painLevel.toLowerCase().trim() == painLevel.toLowerCase().trim()) {
        score += 0.4;
      }
      if (exercise.goal.toLowerCase().trim() == rehabGoal.toLowerCase().trim()) {
        score += 0.2;
      }

      ranked.add(RankedExercise(
        exercise: exercise,
        suitabilityScore: score,
        explanation: 'Rule-based baseline',
      ));
    }

    ranked.sort((a, b) => b.suitabilityScore.compareTo(a.suitabilityScore));
    return ranked;
  }

  /// Compute component score statistics
  static Map<String, dynamic> _computeComponentStats(List<RankedExercise> rankedExercises) {
    if (rankedExercises.isEmpty) {
      return {
        'avgScore': 0.0,
        'minScore': 0.0,
        'maxScore': 0.0,
        'stdDev': 0.0,
      };
    }

    final scores = rankedExercises.map((r) => r.suitabilityScore).toList();
    final avgScore = scores.reduce((a, b) => a + b) / scores.length;
    final minScore = scores.reduce(math.min);
    final maxScore = scores.reduce(math.max);
    
    // Compute standard deviation
    final variance = scores.map((s) => math.pow(s - avgScore, 2)).reduce((a, b) => a + b) / scores.length;
    final stdDev = math.sqrt(variance);

    return {
      'avgScore': avgScore,
      'minScore': minScore,
      'maxScore': maxScore,
      'stdDev': stdDev,
      'scoreRange': maxScore - minScore,
    };
  }

  /// Get comprehensive evaluation metrics for the ranking service
  /// 
  /// Returns metrics comparing AI ranking with baseline (random/rule-based)
  /// Includes NDCG@3, Precision@3, Recall@3, and component statistics
  static Future<Map<String, dynamic>> getEvaluationMetrics({
    List<Exercise>? testExercises,
    String? specificMuscle,
    String? painLevel,
    String? rehabGoal,
  }) async {
    final exerciseHistoryCount = ExerciseHistory.entries.length;
    final painHistoryDays = PainHistory.entries.length;
    final hasEnoughData = _hasEnoughData();

    final baseMetrics = {
      'exerciseHistoryRecords': exerciseHistoryCount,
      'painHistoryDays': painHistoryDays,
      'hasEnoughData': hasEnoughData,
      'minRequiredRecords': minExerciseHistoryRecords,
      'minRequiredDays': minPainHistoryDays,
      'serviceStatus': hasEnoughData ? 'AI Ranking Active' : 'Rule-Based Fallback',
    };

    // If insufficient data or no test exercises provided, return basic metrics
    if (!hasEnoughData || testExercises == null || testExercises.isEmpty) {
      return {
        ...baseMetrics,
        'evaluationStatus': testExercises == null || testExercises.isEmpty
            ? 'No test exercises provided'
            : 'Insufficient data for evaluation',
        'note': testExercises == null || testExercises.isEmpty
            ? 'Provide testExercises parameter to compute ranking metrics'
            : 'Need ${minExerciseHistoryRecords}+ exercise records and ${minPainHistoryDays}+ pain history days',
      };
    }

    try {
      // Use provided parameters or fall back to UserAssess
      final muscle = specificMuscle ?? UserAssess.specificMuscle;
      final pain = painLevel ?? UserAssess.painLevel;
      final goal = rehabGoal ?? UserAssess.rehabGoal;

      // Compute ground truth from exercise history
      final groundTruth = _computeGroundTruth();
      
      if (groundTruth.isEmpty) {
        // No ground truth available (no exercise history with pain outcomes)
        return {
          ...baseMetrics,
          'evaluationStatus': 'No ground truth data available',
          'note': 'Need exercise history with pain outcomes to compute ranking metrics',
        };
      }

      // Generate AI ranking
      final aiRanked = await rankExercises(
        exercises: testExercises,
        specificMuscle: muscle,
        painLevel: pain,
        rehabGoal: goal,
      );

      // Generate baseline rankings
      final randomRanked = _generateRandomRanking(testExercises);
      final ruleBasedRanked = _generateRuleBasedRanking(
        exercises: testExercises,
        specificMuscle: muscle,
        painLevel: pain,
        rehabGoal: goal,
      );

      // Compute metrics for AI ranking
      final aiNDCG = _computeNDCG(rankedExercises: aiRanked, groundTruth: groundTruth, k: 3);
      final aiPrecision = _computePrecision(rankedExercises: aiRanked, groundTruth: groundTruth, k: 3);
      final aiRecall = _computeRecall(rankedExercises: aiRanked, groundTruth: groundTruth, k: 3);

      // Compute metrics for baselines
      final randomNDCG = _computeNDCG(rankedExercises: randomRanked, groundTruth: groundTruth, k: 3);
      final randomPrecision = _computePrecision(rankedExercises: randomRanked, groundTruth: groundTruth, k: 3);
      final randomRecall = _computeRecall(rankedExercises: randomRanked, groundTruth: groundTruth, k: 3);

      final ruleBasedNDCG = _computeNDCG(rankedExercises: ruleBasedRanked, groundTruth: groundTruth, k: 3);
      final ruleBasedPrecision = _computePrecision(rankedExercises: ruleBasedRanked, groundTruth: groundTruth, k: 3);
      final ruleBasedRecall = _computeRecall(rankedExercises: ruleBasedRanked, groundTruth: groundTruth, k: 3);

      // Compute component statistics
      final componentStats = _computeComponentStats(aiRanked);

      // Compute improvements
      final improvementOverRandom = aiNDCG > 0 && randomNDCG > 0
          ? ((aiNDCG - randomNDCG) / randomNDCG * 100)
          : 0.0;
      final improvementOverRuleBased = aiNDCG > 0 && ruleBasedNDCG > 0
          ? ((aiNDCG - ruleBasedNDCG) / ruleBasedNDCG * 100)
          : 0.0;

      return {
        ...baseMetrics,
        'evaluationStatus': 'Complete',
        'groundTruthExercises': groundTruth.length,
        'testExercises': testExercises.length,
        'aiRanking': {
          'ndcg@3': aiNDCG,
          'precision@3': aiPrecision,
          'recall@3': aiRecall,
          'componentStats': componentStats,
        },
        'randomBaseline': {
          'ndcg@3': randomNDCG,
          'precision@3': randomPrecision,
          'recall@3': randomRecall,
        },
        'ruleBasedBaseline': {
          'ndcg@3': ruleBasedNDCG,
          'precision@3': ruleBasedPrecision,
          'recall@3': ruleBasedRecall,
        },
        'improvements': {
          'overRandom': improvementOverRandom,
          'overRuleBased': improvementOverRuleBased,
          'overRandomPercent': '${improvementOverRandom.toStringAsFixed(1)}%',
          'overRuleBasedPercent': '${improvementOverRuleBased.toStringAsFixed(1)}%',
        },
      };
    } catch (e, stackTrace) {
      debugPrint('ExerciseRankingService: Error computing evaluation metrics: $e');
      debugPrint('ExerciseRankingService: Stack trace: $stackTrace');
      return {
        ...baseMetrics,
        'evaluationStatus': 'Error',
        'error': e.toString(),
      };
    }
  }
}
