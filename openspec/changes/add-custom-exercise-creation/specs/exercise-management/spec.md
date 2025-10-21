## ADDED Requirements

### Requirement: Custom Exercise Creation Form
The system SHALL provide a comprehensive form for users to create custom exercises with all necessary metadata fields.

#### Scenario: User creates custom exercise
- **WHEN** user selects "Create Custom Exercise" from the add exercise options
- **THEN** a form dialog appears with fields for exercise name, description, muscle group, pain level, functional goal, repetitions, sets, image filename, video URL, and other muscles
- **AND** all required fields are marked with validation indicators
- **AND** the form provides dropdown selections for standardized values (muscle groups, pain levels, goals)

#### Scenario: Form validation prevents invalid submissions
- **WHEN** user attempts to submit the form with missing required fields
- **THEN** validation errors are displayed for each invalid field
- **AND** the submit button remains disabled until all validation passes
- **AND** specific error messages guide the user to correct the issues

### Requirement: Custom Exercise Persistence
The system SHALL save custom exercises locally using CSV format and make them available in the exercise selection interface.

#### Scenario: Custom exercise is saved successfully
- **WHEN** user submits a valid custom exercise form
- **THEN** the exercise is saved to a local CSV file (exercises_custom.csv)
- **AND** a success message is displayed to the user
- **AND** the form dialog closes automatically
- **AND** the custom exercise becomes immediately available in the exercise list

#### Scenario: Custom exercises persist across app sessions
- **WHEN** the app is restarted after creating custom exercises
- **THEN** custom exercises remain available in the exercise selection
- **AND** they are merged with default exercises in the exercise list
- **AND** no data loss occurs during app restarts

### Requirement: Exercise Selection Integration
The system SHALL integrate custom exercises seamlessly with the existing exercise selection workflow.

#### Scenario: Custom exercises appear in exercise list
- **WHEN** user navigates to the exercise selection page
- **THEN** custom exercises are displayed alongside default exercises
- **AND** custom exercises are clearly identifiable (e.g., with a custom badge or icon)
- **AND** all exercise properties are properly displayed

#### Scenario: Custom exercises can be added to rehabilitation plans
- **WHEN** user selects a custom exercise from the exercise list
- **THEN** the exercise can be added to their rehabilitation plan
- **AND** it behaves identically to default exercises in the plan
- **AND** all exercise metadata is preserved in the plan

### Requirement: Add Exercise Options Modal
The system SHALL provide a modal interface that allows users to choose between selecting existing exercises or creating custom ones.

#### Scenario: User sees exercise creation options
- **WHEN** user taps the "Add Exercise" button in the plan manager
- **THEN** a modal bottom sheet appears with two options
- **AND** option 1: "Select from Existing Exercises" (navigates to exercise list)
- **AND** option 2: "Create Custom Exercise" (opens custom exercise form)
- **AND** the modal has a clean, accessible design with clear icons and labels

#### Scenario: Modal navigation works correctly
- **WHEN** user selects "Select from Existing Exercises"
- **THEN** the modal closes and navigates to the exercise list page
- **AND** the existing exercise selection workflow continues normally
- **WHEN** user selects "Create Custom Exercise"
- **THEN** the modal closes and opens the custom exercise creation form
- **AND** the form is properly initialized and ready for input