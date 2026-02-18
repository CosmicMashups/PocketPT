# PocketPT AI Opportunity Analysis - Structure

This document outlines the comprehensive technical analysis structure for identifying AI enhancement opportunities in the PocketPT codebase.

## PART 1 — AI Opportunity Identification

### 1.1 Thesis Components Documentation

#### Human Pose Estimation
**Implementation Analysis:**
- **Files**: `lib/data/pose_detection_service.dart`, `lib/data/custom_pose_detection_service.dart`, `lib/data/pose_model_manager.dart`
- **Technology**: Google ML Kit (primary) + Custom YOLO11s-pose model (PyTorch Lite)
- **Keypoints**: 33 landmarks (ML Kit) or 17 COCO format keypoints (custom model)
- **Functionality**: Real-time pose detection, ROM assessment, angle calculations, compensation detection
- **Integration Points**: Camera assessment pages, exercise recording, daily assessment flows
- **Data Flow**: Camera → PoseDetectionService → Landmark Processing → ROM Assessment → UI Display

#### Pain Recognition
**Implementation Analysis:**
- **Files**: `lib/data/facial_pain_recognition_service.dart`
- **Technology**: PyTorch Mobile (ResNet18-based model)
- **Classes**: 3-class system (Low, Moderate, Severe)
- **Input**: 224x224 RGB face images
- **Output**: Pain level prediction + confidence score
- **Integration Points**: Exercise recording, assessment workflows, real-time camera processing
- **Data Flow**: Camera → Face Detection → Image Preprocessing → PyTorch Inference → Pain Classification → UI Display

#### Exercise Generation Logic
**Implementation Analysis:**
- **Files**: `lib/data/rehabilitation_plan.dart` (generateRehabilitationPlanFromCSV), `lib/assessment/generate_plan.dart`
- **Filtering Logic**:
  - Exact string matching on `Muscle_Involved` == `UserAssess.specificMuscle`
  - Exact string matching on `Pain_Level` == `UserAssess.painLevel`
  - Exact string matching on `Functional_Goal` == `UserAssess.rehabGoal`
  - `Other_Muscles` filtering: Excludes exercises if severely injured muscle (pain >= 8) appears in Other_Muscles column
- **Selection Logic**: Random shuffle + take first 3 exercises (no ranking, no personalization)
- **Data Source**: `assets/data/exercises.csv` (11 columns: Exercise_ID, Exercise, Exercise_Description, Muscle_Involved, Pain_Level, Functional_Goal, Repetition, Set, Image_Link, Video_Link, Other_Muscles)
- **Output**: `RehabilitationPlan` with 3 `ExerciseReference` objects (exerciseId, repetitions, sets)
- **Hardcoded Thresholds**: Pain level >= 8 for muscle injury filtering, pain scale >= 7 for severe pain exclusion

#### Treatment Generation Logic
**Implementation Analysis:**
- **Files**: `lib/assessment/generate_treatment.dart`
- **Selection Logic**: Always includes core treatments T001, T002, T003 (hardcoded)
- **Data Source**: `assets/data/treatment.csv` (loaded via ExerciseDataService)
- **Output**: List of `TreatmentReference` objects (treatmentId only)
- **No Filtering**: Treatments are not filtered by muscle, pain level, or duration (despite CSV having these columns)
- **Integration**: Treatments shown alongside exercises in plan generation UI

#### Pain History Tracking
**Implementation Analysis:**
- **Files**: `lib/data/globals.dart` (PainHistory class), `lib/data/hive_models.dart` (HivePainRecordEntry), `lib/data/unified_firebase_service.dart`
- **Data Structure**: `PainRecordEntry` (date, painScale: int 0-10, painLevel: String)
- **Storage**: Hive (local) + Firebase (cloud sync)
- **Operations**: `recordToday()`, `addEntry()`, `saveToHive()`, `saveToFirebase()`, `loadFromHive()`, `loadFromFirebase()`
- **Usage**: Daily pain tracking, pain change detection, assessment workflows
- **No Analysis**: Pain history is stored but not analyzed for trends, patterns, or predictions

#### Plan Editing Logic
**Implementation Analysis:**
- **Files**: `lib/exercise/edit_plan.dart`
- **Functionality**: Users can replace exercises in existing plans
- **Replacement Logic**: `generateRandomExercise()` filters by muscle group and pain level (string contains matching), then random selection
- **No Learning**: Exercise replacements don't consider user history, exercise effectiveness, or pain outcomes

#### Filtering Mechanisms
**Implementation Analysis:**
- **Muscle_Involved Filtering**: Exact lowercase string match with `UserAssess.specificMuscle`
- **Other_Muscles Filtering**: String contains check for severely injured muscles (pain >= 8)
- **Pain_Level Filtering**: Exact lowercase string match with `UserAssess.painLevel`
- **Functional_Goal Filtering**: Exact lowercase string match with `UserAssess.rehabGoal`
- **No Ranking**: All matching exercises treated equally, random selection
- **No Personalization**: No user-specific factors considered

#### CSV Parsing Logic
**Implementation Analysis:**
- **Files**: `lib/data/rehabilitation_plan.dart` (loadCSVFromAsset), `lib/data/exercise_data_service.dart`
- **Parsing**: CsvToListConverter with comma delimiter, quote handling, BOM removal
- **Normalization**: Header normalization (lowercase, underscore replacement, whitespace trimming)
- **Error Handling**: Malformed header truncation, column count validation
- **Data Transformation**: CSV rows → Exercise objects (with all metadata)

#### Hive/Firebase Database Structures
**Implementation Analysis:**
- **Hive Models**: 13 registered adapters (UserDetails, UserProgress, UserAssess, UserSettings, ActiveProgram, RehabilitationPlan, TreatmentReference, PainHistory, ExerciseHistory, CustomExercises, ExerciseReference, TreatmentReference)
- **Firebase Collections**: `users/{userId}`, `users/{userId}/rehabilitationPlans/plans`, `users/{userId}/treatments/treatments`, `users/{userId}/userData/painHistory`, `users/{userId}/userData/exerciseHistory`
- **Sync Strategy**: Timestamp-based conflict resolution, background sync, offline-first architecture
- **Data Access**: Hive is system of record on mobile/desktop, Firebase for cloud sync

### 1.2 AI Enhancement Opportunities

#### Opportunity 1: Intelligent Exercise Ranking
**Problem**: Current system uses random selection from filtered exercises. No consideration of:
- User's pain history trends
- Exercise completion rates
- Pain outcomes after exercises
- User preferences or goals

**Affected Files**: `lib/data/rehabilitation_plan.dart` (generateRehabilitationPlanFromCSV), `lib/assessment/generate_plan.dart`

**Input Features**:
- Exercise metadata (Muscle_Involved, Pain_Level, Functional_Goal, Other_Muscles)
- User pain history (last 7 days pain scale, pain level trends)
- Exercise history (completion rates, pain reported during/after exercises)
- User assessment data (specificMuscle, painLevel, painDuration, rehabGoal)

**Expected Output**: Ranked list of exercises with scores (0.0-1.0), top 3 selected based on ranking

**Integration Points**:
- Enhance `generateRehabilitationPlanFromCSV()` to use ranking service
- Add `ExerciseRankingService` that uses ML model
- Store ranking scores in ExerciseReference for future learning

**Justification**: Improves exercise selection quality by learning from user outcomes and personalizing recommendations.

#### Opportunity 2: Pain Trend Prediction
**Problem**: Pain history is stored but not analyzed. No prediction of:
- Recovery trajectory
- Pain level trends
- Optimal exercise timing based on pain patterns

**Affected Files**: `lib/data/globals.dart` (PainHistory), `lib/reports/services/reports_data_service.dart`

**Input Features**:
- Historical pain scale values (time series: last 14-30 days)
- Exercise completion dates
- Pain level changes (deltas)
- Day of week, time patterns

**Expected Output**: Predicted pain scale for next 3-7 days, trend direction (improving/stable/worsening), confidence interval

**Integration Points**:
- Add `PainTrendPredictor` service
- Integrate predictions into reports/dashboard
- Use predictions to adjust exercise recommendations

**Justification**: Enables proactive rehabilitation adjustments and helps users understand recovery patterns.

#### Opportunity 3: Exercise Effectiveness Learning
**Problem**: System doesn't learn which exercises are most effective for specific conditions. No feedback loop from:
- Exercise completion → pain outcomes
- Exercise adherence → recovery progress
- Exercise type → user satisfaction

**Affected Files**: `lib/data/globals.dart` (ExerciseHistory), `lib/exercise/edit_plan.dart`

**Input Features**:
- Exercise ID, muscle group, pain level
- User pain scale before/after exercise
- Exercise completion status, adherence rate
- Time to recovery (if available)

**Expected Output**: Exercise effectiveness score (0.0-1.0) per exercise-muscle-painLevel combination, recommendation confidence

**Integration Points**:
- Enhance exercise ranking with effectiveness scores
- Update effectiveness scores after each exercise completion
- Use effectiveness in plan generation

**Justification**: Creates adaptive system that improves recommendations over time based on actual outcomes.

#### Opportunity 4: Anomaly Detection in Pain Reports
**Problem**: No detection of unusual pain patterns that might indicate:
- Injury worsening
- Need for medical attention
- Data entry errors
- Recovery setbacks

**Affected Files**: `lib/data/globals.dart` (PainHistory), `lib/assessment/assessment_data.dart`

**Input Features**:
- Recent pain scale values (last 7 days)
- Pain level changes (sudden spikes)
- Exercise history (correlation with pain changes)
- Baseline pain level

**Expected Output**: Anomaly score (0.0-1.0), anomaly type (spike, plateau, inconsistent), recommendation (continue/rest/consult)

**Integration Points**:
- Add anomaly detection to daily pain tracking
- Alert users to unusual patterns
- Adjust exercise recommendations based on anomalies

**Justification**: Improves safety and helps identify when users should consult healthcare providers.

#### Opportunity 5: Adaptive Treatment Selection
**Problem**: Treatment selection is hardcoded (always T001, T002, T003). No consideration of:
- User's specific condition
- Treatment effectiveness history
- Pain duration and severity
- Treatment combinations

**Affected Files**: `lib/assessment/generate_treatment.dart`

**Input Features**:
- Treatment metadata (Pain_Level, Pain_Duration from CSV)
- User assessment (painLevel, painDuration, specificMuscle)
- Treatment history (if available)
- Pain outcomes after treatments

**Expected Output**: Ranked treatment list with scores, top 3-5 treatments selected

**Integration Points**:
- Enhance `generateTreatmentPlan()` to use ranking
- Add `TreatmentRankingService`
- Consider treatment combinations

**Justification**: Personalizes treatment recommendations beyond hardcoded core treatments.

#### Opportunity 6: Muscle Group Relationship Learning
**Problem**: `Other_Muscles` filtering is rule-based (exact string match). No learning of:
- Which muscle groups work well together
- Which combinations should be avoided
- Muscle group relationships for different pain levels

**Affected Files**: `lib/data/rehabilitation_plan.dart` (_checkMuscleInjuryFilter)

**Input Features**:
- Exercise muscle groups (Muscle_Involved, Other_Muscles)
- User injured muscles and pain levels
- Exercise outcomes (pain changes, completion rates)
- Muscle group co-occurrence patterns

**Expected Output**: Muscle group compatibility score, recommendations for safe combinations

**Integration Points**:
- Enhance muscle injury filtering with learned compatibility
- Use compatibility scores in exercise ranking

**Justification**: Improves safety and effectiveness of exercise selection for multi-muscle conditions.

## PART 2 — Mini AI Prototype (Selected: Exercise Ranking with Pain History)

### 2.1 AI Method Selected
**Decision Tree Classifier** for exercise ranking

**Why Decision Tree**:
- Interpretable (can explain why exercises are ranked)
- Fast training and inference (<5 minutes)
- Handles mixed data types (categorical + numerical)
- No feature scaling required
- Works well with small datasets

### 2.2 Why It Fits PocketPT
- **Interpretability**: Users can understand why exercises are recommended
- **Speed**: Real-time ranking during plan generation
- **Data Efficiency**: Works with limited historical data
- **Integration**: Can be added alongside existing rule-based filtering
- **Demonstrability**: Clear ranking scores show improvement over random selection

### 2.3 Dataset Source
**Primary**: `PainHistory.entries` (from Hive/Firebase)
**Secondary**: `ExerciseHistory.entries` (from Hive/Firebase)
**Metadata**: `assets/data/exercises.csv` (exercise features)

**Data Extraction**:
- Pain history: Last 7 days pain scale, pain level, pain trends
- Exercise history: Exercise IDs completed, completion dates, pain reported
- Exercise metadata: Muscle_Involved, Pain_Level, Functional_Goal, Other_Muscles

### 2.4 Feature Set
**User Features**:
- `avg_pain_last_7_days`: Average pain scale over last 7 days (0-10)
- `pain_trend`: Trend direction (-1: improving, 0: stable, 1: worsening)
- `current_pain_level`: Current pain level (Low/Moderate/Severe)
- `days_since_assessment`: Days since initial assessment

**Exercise Features**:
- `muscle_match`: Binary (1 if Muscle_Involved matches user's specificMuscle)
- `pain_level_match`: Binary (1 if Pain_Level matches user's painLevel)
- `goal_match`: Binary (1 if Functional_Goal matches user's rehabGoal)
- `has_injured_muscle_in_other`: Binary (1 if severely injured muscle in Other_Muscles)

**Historical Features**:
- `exercise_completion_rate`: Completion rate for this exercise (if in history)
- `pain_after_exercise`: Average pain scale after completing this exercise (if available)
- `exercise_frequency`: How often this exercise was done (if in history)

**Target Variable** (for training):
- `exercise_suitability_score`: Computed from historical outcomes (1.0 if exercise led to pain reduction, 0.5 if neutral, 0.0 if pain increase)

### 2.5 Preprocessing Steps
1. **Data Extraction**: Load PainHistory and ExerciseHistory from Hive
2. **Feature Engineering**: Compute pain trends, completion rates, exercise outcomes
3. **Missing Value Handling**: Default values for exercises not in history (completion_rate=0.5, pain_after_exercise=current_pain)
4. **Categorical Encoding**: One-hot encode pain levels, muscle groups
5. **Normalization**: Not required for Decision Tree

### 2.6 Train/Test Split Method
- **Time-based split**: Use older data (first 70%) for training, recent data (last 30%) for testing
- **If insufficient data**: Use 80/20 random split with stratification by pain level
- **Minimum data requirement**: At least 20 historical exercise records

### 2.7 Evaluation Metric
**Primary**: Ranking Quality (NDCG@3 - Normalized Discounted Cumulative Gain at top 3)
- Measures how well the model ranks exercises compared to ground truth
- Ground truth: Exercises that led to pain reduction ranked higher

**Secondary**: Accuracy (if treating as classification: suitable/unsuitable)

**Baseline Comparison**: Random ranking (expected NDCG@3 ≈ 0.5)

### 2.8 Expected Accuracy or Performance Range
- **NDCG@3**: 0.65-0.75 (moderate improvement over random 0.5)
- **Training Time**: <2 minutes
- **Inference Time**: <10ms per exercise ranking
- **Data Requirement**: Minimum 20 exercise history records

### 2.9 Integration Plan into Flutter
1. **Create Service**: `lib/data/exercise_ranking_service.dart`
   - Load Decision Tree model (trained offline or on-device)
   - Extract features from PainHistory, ExerciseHistory, Exercise metadata
   - Rank exercises and return top N

2. **Enhance Plan Generation**: Modify `generateRehabilitationPlanFromCSV()` in `rehabilitation_plan.dart`
   - After filtering, call `ExerciseRankingService.rankExercises()`
   - Select top 3 ranked exercises instead of random 3

3. **Fallback Strategy**: If ranking service unavailable or insufficient data, fall back to random selection

4. **Feature Flag**: Add flag to enable/disable ranking (for A/B testing)

### 2.10 Limitations
- **Data Dependency**: Requires sufficient exercise history (minimum 20 records)
- **Cold Start Problem**: New users without history get random selection
- **Simplified Model**: Decision Tree may not capture complex interactions
- **No Online Learning**: Model doesn't update in real-time (requires retraining)
- **Feature Engineering**: Manual feature selection may miss important patterns

### 2.11 Time Estimation Breakdown
- **Data Extraction & Preprocessing**: 20 minutes
- **Feature Engineering**: 15 minutes
- **Model Training**: 10 minutes
- **Evaluation & Metrics**: 15 minutes
- **Flutter Integration**: 30 minutes
- **Testing & Validation**: 20 minutes
- **Documentation**: 10 minutes
- **Total**: ~2 hours

## PART 3 — Reflection and Analysis Report Template

### 3.1 AI Method Used
[Document the selected AI method, algorithm details, hyperparameters, and implementation approach]

### 3.2 Why It Fits the Thesis
[Explain how the AI method addresses the research questions, enhances the rehabilitation system, and provides practical value]

### 3.3 Dataset Used
[Document data sources, data size, feature engineering, data quality, and preprocessing steps]

### 3.4 Accuracy or Results
[Present evaluation metrics, comparison with baseline, statistical significance, and performance analysis]

### 3.5 Challenges Faced
[Document technical challenges, data limitations, integration issues, and how they were addressed]

### 3.6 How AI Improves Research Quality
[Explain how the AI enhancement provides evidence-based improvements, supports research claims, and demonstrates practical value]

---

## Next Steps

1. Execute Part 1: Complete technical analysis of all thesis components
2. Execute Part 2: Implement selected mini AI prototype
3. Execute Part 3: Document results and reflection
4. Validate: Ensure all recommendations are grounded in actual codebase
5. Review: Validate proposal meets research requirements
