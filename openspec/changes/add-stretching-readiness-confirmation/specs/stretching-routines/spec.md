## ADDED Requirements

### Requirement: Stretching Routine Readiness Confirmation
The system SHALL require user confirmation before starting the countdown timer for any stretching exercise, ensuring users have time to read and understand instructions.

#### Scenario: Readiness confirmation before timer start
- **WHEN** a stretching routine is loaded and ready to begin
- **THEN** the system SHALL display a readiness confirmation dialog
- **AND** the dialog SHALL ask if the user is ready to begin
- **AND** the dialog SHALL ask if the user understands what to do
- **AND** the dialog SHALL display the current exercise information (description, steps, benefits, precautions) for review
- **AND** the countdown timer SHALL NOT start until the user confirms readiness
- **AND** the user SHALL be able to dismiss the dialog to review instructions further before starting

#### Scenario: Manual start option
- **WHEN** a user dismisses the readiness dialog without confirming
- **THEN** the system SHALL display a "Start" button on the page
- **AND** the user SHALL be able to click "Start" at any time to confirm readiness and begin the timer
- **AND** the timer SHALL only start after explicit user confirmation

#### Scenario: Readiness state persistence
- **WHEN** a user confirms readiness for a stretching routine
- **THEN** the readiness state SHALL be preserved for that routine session
- **AND** if the user pauses and resumes, they SHALL NOT need to re-confirm readiness
- **AND** the readiness state SHALL reset when a new routine is loaded

### Requirement: Warmup Completion Confirmation
The system SHALL require user confirmation before navigating from the warmup stretching page to the exercise recording page.

#### Scenario: Warmup completion dialog
- **WHEN** all warmup exercises in a routine are completed
- **THEN** the system SHALL display a completion confirmation dialog
- **AND** the dialog SHALL congratulate the user on completing the warmup
- **AND** the dialog SHALL ask if the user is ready to start the main exercise session
- **AND** the system SHALL NOT navigate to the exercise recording page until the user confirms
- **AND** the user SHALL be able to choose to review the warmup before proceeding

#### Scenario: Warmup completion navigation
- **WHEN** the user confirms completion in the warmup dialog
- **THEN** the system SHALL navigate to the `RecordExercisePage` with the first exercise
- **AND** the navigation SHALL only occur after explicit user confirmation
- **WHEN** the user chooses to review the warmup
- **THEN** the system SHALL remain on the warmup page
- **AND** the user SHALL be able to proceed later via a "Start Exercise" button

### Requirement: Cooldown Completion Confirmation
The system SHALL require user confirmation before navigating from the cooldown stretching page to the confirm save page.

#### Scenario: Cooldown completion dialog
- **WHEN** all cooldown exercises in a routine are completed
- **THEN** the system SHALL display a completion confirmation dialog
- **AND** the dialog SHALL congratulate the user on completing the cooldown
- **AND** the dialog SHALL ask if the user is ready to finish and save the session
- **AND** the system SHALL NOT navigate to the confirm save page until the user confirms
- **AND** the user SHALL be able to choose to review the cooldown before proceeding

#### Scenario: Cooldown completion navigation
- **WHEN** the user confirms completion in the cooldown dialog
- **THEN** the system SHALL navigate to the `ConfirmSavePage`
- **AND** the navigation SHALL only occur after explicit user confirmation
- **WHEN** the user chooses to review the cooldown
- **THEN** the system SHALL remain on the cooldown page
- **AND** the user SHALL be able to proceed later via a "Finish Session" button

## MODIFIED Requirements

### Requirement: Stretching Routine Timer Start (Modified)
The system SHALL NOT automatically start the countdown timer when a routine is loaded, but instead wait for explicit user confirmation of readiness.

#### Scenario: Prevented auto-start
- **WHEN** a stretching routine is loaded
- **THEN** the system SHALL NOT automatically start the countdown timer
- **AND** the routine SHALL be in a "ready but not started" state
- **AND** the readiness confirmation dialog SHALL be displayed
- **AND** the timer SHALL only start after the user explicitly confirms readiness

#### Scenario: Timer start after confirmation
- **WHEN** the user confirms readiness in the readiness dialog
- **THEN** the system SHALL start the countdown timer for the first exercise
- **AND** the routine SHALL transition to an active state
- **AND** the exercise instructions SHALL remain visible during the countdown

### Requirement: Exercise Instruction Display (Modified)
The exercise instruction widget SHALL support a "preview" mode where exercise information is displayed before the timer starts, allowing users to read and understand instructions.

#### Scenario: Instruction preview before timer
- **WHEN** a routine is loaded but readiness is not yet confirmed
- **THEN** the system SHALL display the current exercise information (description, steps, benefits, precautions)
- **AND** the timer SHALL NOT be running
- **AND** the user SHALL be able to scroll through and read all instructions
- **AND** the user SHALL be able to navigate between exercises to preview them
- **AND** the system SHALL clearly indicate that the timer has not started yet

