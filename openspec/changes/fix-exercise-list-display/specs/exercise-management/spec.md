## ADDED Requirements

### Requirement: Exercise List Display
The system SHALL display a list of exercises loaded from the CSV file in a scrollable card-based interface.

#### Scenario: Exercise list loads successfully
- **WHEN** user navigates to the exercise list page
- **THEN** the system displays all exercises from the CSV file in card format
- **AND** each card shows exercise name, muscle group, pain level, and basic details

#### Scenario: Exercise list handles loading states
- **WHEN** the system is loading exercise data from CSV
- **THEN** a loading indicator is displayed
- **AND** the system gracefully handles loading errors

### Requirement: Exercise Selection
The system SHALL allow users to select exercises from the detail page and add them to their rehabilitation plan.

#### Scenario: User selects exercise for rehabilitation plan
- **WHEN** user taps on an exercise card
- **THEN** the system navigates to the exercise detail page
- **AND** the detail page displays a "Select" button
- **AND** when user taps "Select", the system returns the Exercise_ID to the calling page

#### Scenario: Exercise detail displays all information
- **WHEN** user views an exercise detail page
- **THEN** the system displays all exercise information from CSV (name, description, muscle, pain level, goal, reps, sets, other muscles)
- **AND** placeholder image/video values are handled gracefully

### Requirement: CSV Data Integration
The system SHALL properly load and parse exercise data from the CSV file with correct column mapping.

#### Scenario: CSV data loads correctly
- **WHEN** the system loads exercise data
- **THEN** it correctly maps CSV columns to Exercise model fields
- **AND** Exercise_ID maps to id field
- **AND** Exercise column maps to name field
- **AND** all other columns map to their respective fields

#### Scenario: Placeholder values handled
- **WHEN** CSV contains placeholder values (.jpg, .mp4)
- **THEN** the system displays appropriate fallback content
- **AND** no errors occur due to missing image/video files
