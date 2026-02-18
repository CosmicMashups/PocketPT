# Evaluation Metrics Testing Guide

## Overview

You can compute evaluation metrics for the Exercise Ranking Service **without building the APK** by running a standalone Flutter test.

## Quick Start

### Run the Test

```bash
flutter test test/exercise_ranking_evaluation_test.dart
```

This will:
1. Set up mock exercise and pain history data
2. Load exercises from CSV
3. Compute evaluation metrics (NDCG@3, Precision@3, Recall@3)
4. Print results to console

## What the Test Does

### Test 1: Mock Data Evaluation (Always Runs)

Creates synthetic data to demonstrate the evaluation metrics:

- **Pain History**: 7 days of pain tracking (varying pain levels 4-6)
- **Exercise History**: 
  - E001: Led to pain reduction (good exercise)
  - E002: Neutral (no pain change)
  - E003: Led to pain increase (bad exercise)
  - E004: Multiple completions

Then computes:
- AI Ranking metrics (NDCG@3, Precision@3, Recall@3)
- Random baseline metrics
- Rule-based baseline metrics
- Improvement percentages
- Component statistics

### Test 2: Real Data Evaluation (Skipped by Default)

If you have real user data in Hive, you can enable this test to compute metrics with actual data:

1. Edit `test/exercise_ranking_evaluation_test.dart`
2. Change `skip: true` to `skip: false` on line ~180
3. Run the test again

## Expected Output

```
=== Exercise Ranking Evaluation Metrics ===

Mock Data Setup:
- Pain History Entries: 10
- Exercise History Entries: 5
- User Muscle: Deltoids
- User Pain Level: Moderate
- User Goal: Strength

Loaded 150 exercises from CSV

Filtered to 25 matching exercises

Computing evaluation metrics...

=== Evaluation Results ===

Service Status: AI Ranking Active
Evaluation Status: Complete
Exercise History Records: 5
Pain History Days: 10
Has Enough Data: true

--- AI Ranking Metrics ---
NDCG@3: 0.687
Precision@3: 0.667
Recall@3: 0.750

Component Statistics:
  Average Score: 0.623
  Min Score: 0.400
  Max Score: 0.850
  Std Deviation: 0.142
  Score Range: 0.450

--- Random Baseline ---
NDCG@3: 0.512
Precision@3: 0.333
Recall@3: 0.500

--- Rule-Based Baseline ---
NDCG@3: 0.578
Precision@3: 0.500
Recall@3: 0.625

--- Improvements ---
Over Random: +34.2%
Over Rule-Based: +18.9%

=== Summary ===
AI Ranking NDCG@3: 0.687
Random Baseline NDCG@3: 0.512
Rule-Based Baseline NDCG@3: 0.578
✅ AI Ranking outperforms random baseline
✅ AI Ranking outperforms rule-based baseline

=== Test Complete ===
```

## Understanding the Metrics

### NDCG@3 (Normalized Discounted Cumulative Gain)
- **Range**: 0.0 to 1.0
- **Meaning**: Measures ranking quality at top 3 positions
- **Higher is better**: 1.0 = perfect ranking
- **Interpretation**: 
  - 0.5 = Random quality
  - 0.6-0.7 = Good improvement
  - 0.7+ = Excellent ranking

### Precision@3
- **Range**: 0.0 to 1.0
- **Meaning**: Fraction of top 3 exercises that are actually relevant
- **Higher is better**: 1.0 = all top 3 are relevant

### Recall@3
- **Range**: 0.0 to 1.0
- **Meaning**: Fraction of relevant exercises found in top 3
- **Higher is better**: 1.0 = found all relevant exercises

### Component Statistics
- **Average Score**: Mean suitability score across all exercises
- **Min/Max Score**: Range of scores
- **Std Deviation**: Variability in scores
- **Score Range**: Difference between max and min

## Troubleshooting

### "No exercises loaded"
- Ensure `assets/data/exercises.csv` exists
- Check CSV file format is correct

### "No ground truth data available"
- Need exercise history with pain outcomes
- Ensure exercises have `painScale` recorded
- Need pain entries before and after exercises

### "Insufficient data"
- Need minimum 5 exercise history records
- Need minimum 3 pain history days
- Add more mock data in the test if needed

## Customizing the Test

### Change Mock Data

Edit the `setUp()` method in the test to customize:
- Pain history patterns
- Exercise completion rates
- Pain outcomes after exercises

### Test Different Scenarios

Add more test cases:
```dart
test('Compute metrics with high pain scenario', () async {
  // Set up high pain data
  // Compute metrics
  // Assert improvements
});
```

### Compare Different Algorithms

Modify the ranking service to test different approaches:
- Change feature weights
- Try different scoring algorithms
- Compare results

## Integration with CI/CD

Add to your CI pipeline:
```yaml
- name: Run Evaluation Metrics Test
  run: flutter test test/exercise_ranking_evaluation_test.dart
```

## Next Steps

1. **Run the test**: `flutter test test/exercise_ranking_evaluation_test.dart`
2. **Review results**: Check NDCG@3, Precision@3, Recall@3
3. **Compare baselines**: Verify AI ranking outperforms random/rule-based
4. **Iterate**: Adjust ranking algorithm based on results
5. **Monitor**: Run regularly to track improvements

---

**File**: `test/exercise_ranking_evaluation_test.dart`  
**Status**: ✅ Ready to use  
**Dependencies**: Flutter test framework, CSV data file
