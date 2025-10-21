## ADDED Requirements
### Requirement: Muscle-Specific Pain Assessment
The system SHALL provide a comprehensive muscle assessment interface that captures specific muscle injuries and their current pain levels for users who indicate previous injuries in their medical history.

#### Scenario: Muscle assessment page navigation
- **WHEN** user selects "Yes" for previous injuries in medical history assessment
- **THEN** the system navigates to the muscle assessment page (`d_muscle.dart`)
- **AND** the page displays "Step 5 of 6 - Muscle Assessment" in the progress indicator

#### Scenario: Muscle selection interface
- **WHEN** user reaches the muscle assessment page
- **THEN** the system displays a scrollable list of 15 predefined muscles with checkboxes
- **AND** each muscle has an appropriate icon and visual feedback on selection
- **AND** the muscles include: Abdominals, Ankle, Biceps, Calf, Cervical Muscle, Chest, Deltoids, Diaphragm, Gluteals, Hamstrings, Lower Back, Multifidus, Obliques, Quadriceps, Triceps

#### Scenario: Pain level assessment for selected muscles
- **WHEN** user selects one or more muscles
- **THEN** the system displays a pain scale (0-10) for each selected muscle
- **AND** the pain scale provides real-time categorical classification (Low: 0-3, Moderate: 4-6, Severe: 7-10)
- **AND** both numerical and categorical values are stored dynamically

#### Scenario: Data persistence and navigation
- **WHEN** user completes muscle assessment
- **THEN** all muscle selection and pain level data is saved to both `UserAssess` and `AssessmentData`
- **AND** the system navigates to the assessment summary page (`e_summary.dart`)
- **AND** the data persists across navigation and app restarts

### Requirement: Exercise Filtering Based on Muscle Injuries
The system SHALL filter rehabilitation exercises based on muscle injury data to ensure safe and appropriate exercise recommendations.

#### Scenario: Exercise exclusion for severe muscle injuries
- **WHEN** generating a rehabilitation plan
- **THEN** exercises targeting muscles with "Severe" pain levels (7-10) are excluded from the plan
- **AND** the filtering uses the "Other_Muscles" column from the exercises.csv file

#### Scenario: Exercise inclusion with intensity modification
- **WHEN** generating a rehabilitation plan
- **THEN** exercises targeting muscles with "Moderate" pain levels (4-6) are included with reduced intensity markers
- **AND** exercises targeting muscles with "Low" pain levels (0-3) are included normally

#### Scenario: No muscle injury impact
- **WHEN** user has no muscle injuries or selects "No" in medical history
- **THEN** all exercises are included in the plan without filtering
- **AND** the system proceeds directly from medical history to assessment summary

## MODIFIED Requirements
### Requirement: Assessment Navigation Flow
The assessment module SHALL follow a logical sequence where medical history assessment can lead to detailed muscle assessment before proceeding to the summary.

#### Scenario: Medical history to muscle assessment navigation
- **WHEN** user completes medical history assessment and selects "Yes" for previous injuries
- **THEN** the system navigates to the muscle assessment page (`d_muscle.dart`)
- **AND** all previous assessment data is preserved

#### Scenario: Medical history to summary navigation
- **WHEN** user completes medical history assessment and selects "No" for previous injuries
- **THEN** the system navigates directly to the assessment summary page (`e_summary.dart`)
- **AND** no muscle assessment data is collected

#### Scenario: Complete assessment flow sequence
- **WHEN** user progresses through the full assessment with muscle injuries
- **THEN** the sequence follows: pain assessment → medical history → muscle assessment → summary → plan generation
- **AND** when no muscle injuries exist, the sequence follows: pain assessment → medical history → summary → plan generation

### Requirement: Assessment Data Model
The assessment data model SHALL include comprehensive muscle injury tracking capabilities alongside existing assessment data.

#### Scenario: Muscle injury data storage
- **WHEN** user completes muscle assessment
- **THEN** the system stores injured muscle names in `UserAssess.injuredMuscles` and `AssessmentData.injuredMuscles`
- **AND** pain levels are stored in `UserAssess.musclePainLevels` and `AssessmentData.musclePainLevels`
- **AND** pain categories are stored in `UserAssess.musclePainCategories` and `AssessmentData.musclePainCategories`

#### Scenario: Data model initialization and reset
- **WHEN** assessment data is initialized or reset
- **THEN** all muscle injury fields are properly initialized to empty states
- **AND** existing assessment data fields remain unchanged
