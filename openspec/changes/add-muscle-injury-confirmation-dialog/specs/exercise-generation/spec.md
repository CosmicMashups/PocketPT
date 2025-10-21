## ADDED Requirements

### Requirement: Muscle Injury Confirmation Dialog System
The system SHALL provide a user confirmation dialog when exercise filtering results in insufficient exercise options due to muscle injury safety filtering.

#### Scenario: Insufficient exercises after muscle injury filtering
- **WHEN** the exercise generation system filters exercises based on muscle injury data
- **AND** the resulting filtered exercise count is less than 3
- **AND** the user has muscle injuries with "Severe" pain levels
- **THEN** the system SHALL display a confirmation dialog asking the user whether to include exercises targeting previously injured muscles
- **AND** the dialog SHALL clearly explain the safety implications and potential discomfort

#### Scenario: User chooses to include all exercises
- **WHEN** the user selects "Yes, Include All Exercises" in the confirmation dialog
- **THEN** the system SHALL re-filter exercises without muscle injury filtering
- **AND** the system SHALL generate a rehabilitation plan with all available exercises
- **AND** the system SHALL log the user's choice for safety monitoring

#### Scenario: User chooses to keep safe exercises only
- **WHEN** the user selects "No, Keep Safe Exercises Only" in the confirmation dialog
- **THEN** the system SHALL continue with the current filtered exercise set
- **AND** the system SHALL generate a rehabilitation plan with the limited safe exercises
- **AND** the system SHALL inform the user about the limited exercise options

#### Scenario: User cancels the dialog
- **WHEN** the user selects "Cancel" in the confirmation dialog
- **THEN** the system SHALL return null from exercise generation
- **AND** the system SHALL display an appropriate error message in the plan generation UI
- **AND** the system SHALL allow the user to return to the assessment to modify muscle injury data

### Requirement: Safety Communication and Warnings
The confirmation dialog SHALL provide clear safety information and healthcare recommendations to ensure informed user consent.

#### Scenario: Safety warning display
- **WHEN** the confirmation dialog is displayed
- **THEN** the dialog SHALL include prominent warnings about potential discomfort
- **AND** the dialog SHALL recommend consulting with a healthcare provider
- **AND** the dialog SHALL list the specific injured muscles that would be targeted
- **AND** the dialog SHALL show the pain levels of muscles that would be included

#### Scenario: Healthcare consultation recommendation
- **WHEN** the user chooses to include exercises targeting injured muscles
- **THEN** the system SHALL display a recommendation to consult with a healthcare provider
- **AND** the system SHALL suggest monitoring pain levels during exercises
- **AND** the system SHALL provide clear guidance on when to stop exercises

## MODIFIED Requirements

### Requirement: Exercise Generation Filtering Logic
The existing exercise generation filtering logic SHALL be modified to support user choice in muscle injury filtering scenarios.

#### Scenario: Modified filtering with user choice
- **WHEN** the exercise generation system applies muscle injury filtering
- **AND** the filtered exercise count is less than 3
- **AND** the user has severe muscle injuries
- **THEN** the system SHALL trigger the confirmation dialog
- **AND** the system SHALL apply the user's choice to the filtering logic
- **AND** the system SHALL maintain the existing filtering behavior for all other scenarios

#### Scenario: Exercise generation with dialog integration
- **WHEN** the `generateRehabilitationPlanFromCSV()` function is called
- **AND** muscle injury filtering results in insufficient exercises
- **THEN** the function SHALL display the confirmation dialog
- **AND** the function SHALL wait for user input before proceeding
- **AND** the function SHALL return the appropriate exercise set based on user choice
- **AND** the function SHALL maintain backward compatibility for users without muscle injuries

### Requirement: Plan Generation Error Handling
The existing plan generation error handling SHALL be updated to handle user cancellation scenarios from the muscle injury confirmation dialog.

#### Scenario: User cancellation error handling
- **WHEN** the user cancels the muscle injury confirmation dialog
- **THEN** the plan generation system SHALL display an appropriate error message
- **AND** the system SHALL provide clear guidance on how to proceed
- **AND** the system SHALL maintain the existing error handling patterns for other scenarios
- **AND** the system SHALL allow the user to return to the assessment flow

#### Scenario: Insufficient exercises error handling
- **WHEN** the user chooses to keep safe exercises only
- **AND** the resulting exercise count is still less than 3
- **THEN** the system SHALL display an informative message about limited exercise options
- **AND** the system SHALL provide alternative recommendations
- **AND** the system SHALL maintain the existing error handling for other insufficient exercise scenarios
