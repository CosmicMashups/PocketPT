## ADDED Requirements

### Requirement: Consistent Data Access Pattern
All pages that display exercise and treatment data SHALL use the same individual FutureBuilder pattern for loading data from ExerciseDataService.

#### Scenario: EditPlanPage displays actual exercise data
- **WHEN** user navigates to EditPlanPage
- **THEN** the page displays actual exercise names, descriptions, and details instead of placeholder data

#### Scenario: ReportsPage displays actual exercise data
- **WHEN** user navigates to ReportsPage
- **THEN** the page displays actual exercise names and treatment details instead of placeholder data

#### Scenario: Consistent loading states across pages
- **WHEN** any page loads exercise or treatment data
- **THEN** the page shows appropriate loading indicators and error handling

### Requirement: Individual Exercise Loading
Pages SHALL load individual exercises using FutureBuilder with ExerciseDataService.getExerciseById() instead of bulk loading methods.

#### Scenario: Individual exercise loading success
- **WHEN** a page needs to display an exercise
- **THEN** it uses FutureBuilder with getExerciseById() to load the exercise data
- **AND** displays the actual exercise name and description

#### Scenario: Individual exercise loading error handling
- **WHEN** an exercise cannot be loaded by ID
- **THEN** the page shows an appropriate error state or placeholder
- **AND** logs the error for debugging

### Requirement: Individual Treatment Loading
Pages SHALL load individual treatments using FutureBuilder with ExerciseDataService.getTreatmentById() instead of bulk loading methods.

#### Scenario: Individual treatment loading success
- **WHEN** a page needs to display a treatment
- **THEN** it uses FutureBuilder with getTreatmentById() to load the treatment data
- **AND** displays the actual treatment name and description

#### Scenario: Individual treatment loading error handling
- **WHEN** a treatment cannot be loaded by ID
- **THEN** the page shows an appropriate error state or placeholder
- **AND** logs the error for debugging

## MODIFIED Requirements

### Requirement: ExerciseDataService Error Handling
The ExerciseDataService SHALL provide better error handling and validation for bulk operations, including logging of missing IDs and graceful handling of partial failures.

#### Scenario: Bulk exercise loading with missing IDs
- **WHEN** getExercisesByIds() is called with some invalid IDs
- **THEN** it returns the exercises that were found
- **AND** logs warnings for missing IDs
- **AND** does not throw exceptions for missing data

#### Scenario: Bulk treatment loading with missing IDs
- **WHEN** getTreatmentsByIds() is called with some invalid IDs
- **THEN** it returns the treatments that were found
- **AND** logs warnings for missing IDs
- **AND** does not throw exceptions for missing data

## REMOVED Requirements

### Requirement: Provider-based Data Access in Reports
**Reason**: Riverpod providers are synchronous and cannot perform async operations, leading to placeholder data being displayed instead of actual exercise and treatment information.

**Migration**: Replace all provider-based data access in ReportsPage with direct FutureBuilder usage for async data loading.
