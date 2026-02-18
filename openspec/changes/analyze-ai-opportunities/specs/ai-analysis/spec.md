## ADDED Requirements

### Requirement: Comprehensive Technical Analysis
The system SHALL provide comprehensive technical documentation of all thesis components currently implemented in the PocketPT codebase, including implementation details, data flows, and architectural patterns.

#### Scenario: Documenting Human Pose Estimation
- **WHEN** analyzing the pose estimation implementation
- **THEN** the documentation describes ML Kit integration, keypoint detection, ROM assessment algorithms, and pose model manager architecture
- **AND** identifies affected files (pose_detection_service.dart, custom_pose_detection_service.dart, pose_model_manager.dart)
- **AND** explains how pose data flows from camera to assessment results

#### Scenario: Documenting Pain Recognition
- **WHEN** analyzing the pain recognition implementation
- **THEN** the documentation describes PyTorch model integration, 3-class pain classification (Low/Moderate/Severe), facial detection pipeline, and confidence scoring
- **AND** identifies affected files (facial_pain_recognition_service.dart, pain model assets)
- **AND** explains how pain predictions are generated and stored

#### Scenario: Documenting Exercise Generation Logic
- **WHEN** analyzing exercise plan generation
- **THEN** the documentation describes CSV filtering logic (Muscle_Involved, Pain_Level, Functional_Goal), Other_Muscles filtering for injured muscles, random selection mechanism, and exercise reference structure
- **AND** identifies affected files (rehabilitation_plan.dart, generate_plan.dart, ExerciseDataService)
- **AND** explains the complete flow from assessment data to exercise plan creation

#### Scenario: Documenting Treatment Generation Logic
- **WHEN** analyzing treatment plan generation
- **THEN** the documentation describes core treatment selection (T001, T002, T003), CSV-based treatment loading, and treatment reference structure
- **AND** identifies affected files (generate_treatment.dart, treatment.dart, ExerciseDataService)
- **AND** explains how treatments are selected and associated with rehabilitation plans

#### Scenario: Documenting Pain History Tracking
- **WHEN** analyzing pain tracking implementation
- **THEN** the documentation describes PainHistory class structure, PainRecordEntry model, Hive/Firebase persistence, daily tracking workflow, and pain history retrieval methods
- **AND** identifies affected files (globals.dart PainHistory class, hive_models.dart, unified_firebase_service.dart)
- **AND** explains how pain data is recorded, stored, and retrieved

#### Scenario: Documenting CSV Parsing Logic
- **WHEN** analyzing CSV data loading
- **THEN** the documentation describes CSV parsing implementation, column normalization, header mapping, exercise/treatment data structures, and error handling
- **AND** identifies affected files (rehabilitation_plan.dart loadCSVFromAsset, ExerciseDataService)
- **AND** explains how CSV data is transformed into Exercise and Treatment objects

#### Scenario: Documenting Database Structures
- **WHEN** analyzing data persistence
- **THEN** the documentation describes all 13 Hive models, Firebase collection structure, sync strategy, offline-first architecture, and data model relationships
- **AND** identifies affected files (hive_models.dart, unified_firebase_service.dart, data_persistence_service.dart)
- **AND** explains how data flows between Hive (local) and Firebase (cloud)

### Requirement: AI Opportunity Identification
The system SHALL identify and document specific AI enhancement opportunities that can improve, automate, or enhance PocketPT beyond its current rule-based logic, with each opportunity grounded in actual codebase implementation.

#### Scenario: Identifying Hardcoded Threshold Replacement
- **WHEN** analyzing filtering logic for opportunities to replace hardcoded thresholds
- **THEN** the documentation identifies specific thresholds (e.g., pain level >= 8 for muscle injury filtering, pain scale >= 7 for severe pain)
- **AND** proposes ML-based threshold learning or adaptive thresholds
- **AND** documents affected files and integration points

#### Scenario: Identifying Personalization Opportunities
- **WHEN** analyzing exercise selection for personalization opportunities
- **THEN** the documentation identifies how user-specific factors (pain history, exercise completion rates, recovery patterns) could improve exercise ranking
- **AND** proposes learning-based personalization algorithms
- **AND** documents required input features from existing data sources

#### Scenario: Identifying Learning-Based Recommendations
- **WHEN** analyzing recommendation mechanisms for learning opportunities
- **THEN** the documentation identifies how exercise effectiveness could be learned from user outcomes
- **AND** proposes recommendation algorithms that adapt based on historical data
- **AND** documents expected output format and integration with existing recommendation system

#### Scenario: Identifying Pattern Detection Opportunities
- **WHEN** analyzing pain history for pattern detection opportunities
- **THEN** the documentation identifies how pain trends, recovery progression, and anomalies could be detected
- **AND** proposes time-series analysis or clustering approaches
- **AND** documents how detected patterns could inform rehabilitation decisions

#### Scenario: Documenting Opportunity Details
- **WHEN** documenting each AI opportunity
- **THEN** the documentation includes: specific problem in current implementation, affected files with line references, required input features, expected output format, integration points with Hive/Firebase, and justification for why this improves the system

### Requirement: Mini AI Prototype Implementation
The system SHALL implement one lightweight AI enhancement prototype that is realistically implementable in under 2 hours, uses existing data sources, and demonstrates practical value through measurable evaluation metrics.

#### Scenario: Selecting Feasible Prototype
- **WHEN** evaluating AI opportunities for prototype implementation
- **THEN** the system selects an opportunity that: requires <2 hours implementation, uses no external APIs, leverages existing CSV/Hive/Firebase data, can be demonstrated locally, and has a simple evaluation metric
- **AND** avoids: deep learning training, complex CNN retraining, transformer models, heavy preprocessing pipelines, large dataset dependencies

#### Scenario: Implementing Lightweight ML Model
- **WHEN** implementing the selected prototype
- **THEN** the system implements a simple ML model (Decision Tree, Logistic Regression, K-means, Linear Regression, Naive Bayes, or weighted scoring algorithm)
- **AND** uses existing data sources (exercises.csv, treatment.csv, PainHistory entries, ExerciseHistory entries)
- **AND** includes data preprocessing, feature extraction, train/test split, and evaluation metrics

#### Scenario: Integrating Prototype into Flutter
- **WHEN** integrating the ML model into the Flutter application
- **THEN** the system creates a new service or enhances an existing service (e.g., ExerciseRankingService, PainTrendPredictor)
- **AND** maintains compatibility with existing rule-based logic (additive enhancement, not replacement)
- **AND** provides clear API for using the ML model predictions

#### Scenario: Evaluating Prototype Performance
- **WHEN** evaluating the prototype
- **THEN** the system provides measurable metrics (accuracy, precision, recall, ranking quality, prediction error)
- **AND** compares ML-based results with rule-based baseline
- **AND** documents expected accuracy or performance range

#### Scenario: Documenting Prototype Details
- **WHEN** documenting the prototype
- **THEN** the documentation includes: AI method selected, why it fits PocketPT, dataset source, feature set, preprocessing steps, train/test split method, evaluation metric, expected accuracy range, integration plan, limitations, and time estimation breakdown

### Requirement: Structured Analysis Documentation
The system SHALL provide structured documentation following the three-part template: AI Opportunity Identification, Mini AI Prototype, and Reflection and Analysis Report.

#### Scenario: Part 1 Documentation
- **WHEN** documenting AI opportunity identification
- **THEN** the documentation includes: thesis components explanation, AI enhancement opportunities with full details, problem statements, affected files, input/output specifications, integration points, and justifications

#### Scenario: Part 2 Documentation
- **WHEN** documenting the mini AI prototype
- **THEN** the documentation includes: AI method selection rationale, dataset source and feature engineering, preprocessing pipeline, model implementation, evaluation results, integration approach, and limitations

#### Scenario: Part 3 Documentation
- **WHEN** creating the reflection template
- **THEN** the documentation includes: AI method used, why it fits the thesis, dataset used, accuracy/results, challenges faced, and how AI improves research quality

#### Scenario: Codebase Grounding
- **WHEN** writing all documentation
- **THEN** all recommendations reference actual code files, line numbers, and implementation details
- **AND** no theoretical-only AI ideas are included
- **AND** all opportunities are justified based on existing architecture
