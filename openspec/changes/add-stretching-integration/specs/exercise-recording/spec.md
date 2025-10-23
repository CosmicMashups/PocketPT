## MODIFIED Requirements

### Requirement: Pre-Recording Warm-up Integration
The exercise recording system SHALL provide an optional warm-up stretching routine before starting the first exercise, based on the user's selected muscle group from the assessment process.

#### Scenario: User starts recording with warm-up option
- **WHEN** user clicks "Start Recording" in the pre-record page
- **THEN** a dialog appears explaining the benefits of warm-up stretching
- **AND** user can choose "Skip Warm-up" or "Start Warm-up"
- **AND** if warm-up is selected, the system navigates to WarmupStretchingPage
- **AND** if skipped, the system proceeds directly to RecordExercisePage

#### Scenario: Warm-up routine completion
- **WHEN** user completes the warm-up stretching routine
- **THEN** the system navigates to the first exercise in RecordExercisePage
- **AND** the warm-up completion is tracked in the exercise history
- **AND** the user can skip the warm-up at any time during the routine

#### Scenario: Warm-up routine skipping
- **WHEN** user chooses to skip the warm-up routine
- **THEN** the system proceeds directly to RecordExercisePage
- **AND** no warm-up data is recorded
- **AND** the exercise recording workflow continues normally

### Requirement: Post-Recording Cooldown Integration
The exercise recording system SHALL provide an optional cooldown stretching routine after completing the last exercise in the rehabilitation plan.

#### Scenario: User completes last exercise with cooldown option
- **WHEN** user clicks "Finish" on the last exercise in the recording workflow
- **THEN** a dialog appears explaining the benefits of cooldown stretching
- **AND** user can choose "Skip Cooldown" or "Start Cooldown"
- **AND** if cooldown is selected, the system navigates to CooldownStretchingPage
- **AND** if skipped, the system proceeds to the home page

#### Scenario: Cooldown routine completion
- **WHEN** user completes the cooldown stretching routine
- **THEN** the system navigates to the home page
- **AND** the cooldown completion is tracked in the exercise history
- **AND** the user can skip the cooldown at any time during the routine

#### Scenario: Cooldown routine skipping
- **WHEN** user chooses to skip the cooldown routine
- **THEN** the system proceeds directly to the home page
- **AND** no cooldown data is recorded
- **AND** the exercise recording workflow completes normally

### Requirement: Muscle Group Integration
The exercise recording system SHALL use the user's selected muscle group from the assessment process to provide targeted stretching routines.

#### Scenario: Muscle group-specific warm-up
- **WHEN** user has completed the assessment and selected a specific muscle group
- **THEN** the warm-up routine includes exercises specific to that muscle group
- **AND** the routine is tailored to prepare those muscles for exercise
- **AND** the routine follows healthcare standards for that muscle group

#### Scenario: Muscle group-specific cooldown
- **WHEN** user has completed exercises targeting a specific muscle group
- **THEN** the cooldown routine includes exercises specific to that muscle group
- **AND** the routine is tailored to help those muscles recover
- **AND** the routine follows healthcare standards for that muscle group

### Requirement: Stretching Routine State Management
The exercise recording system SHALL maintain proper state management for stretching routines, including progress tracking and completion status.

#### Scenario: Stretching routine progress tracking
- **WHEN** user is performing a stretching routine
- **THEN** the system tracks the current exercise and remaining time
- **AND** progress is displayed to the user
- **AND** the user can navigate between exercises

#### Scenario: Stretching routine completion
- **WHEN** user completes all exercises in a stretching routine
- **THEN** the system records the completion in exercise history
- **AND** the user is congratulated on completion
- **AND** the system navigates to the next step in the workflow

#### Scenario: Stretching routine interruption
- **WHEN** user pauses or exits during a stretching routine
- **THEN** the current progress is saved
- **AND** the user can resume from where they left off
- **AND** the system handles state cleanup appropriately
