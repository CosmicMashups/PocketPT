## MODIFIED Requirements

### Requirement: Exercise List Display
The system SHALL display a list of exercises loaded from the CSV file in a scrollable card-based interface optimized for Android smartphone dimensions.

#### Scenario: Exercise cards display properly on Android
- **WHEN** user navigates to the exercise list page on an Android device
- **THEN** exercise cards are properly sized for smartphone screens
- **AND** no UI elements overlap or are cut off
- **AND** touch targets are appropriately sized for mobile interaction

#### Scenario: Exercise cards have proper spacing
- **WHEN** user views the exercise list
- **THEN** cards have adequate spacing between elements
- **AND** text is readable without crowding
- **AND** buttons are clearly separated from other content

### Requirement: Exercise Selection
The system SHALL allow users to select exercises with properly positioned selection buttons.

#### Scenario: Select button is properly positioned
- **WHEN** user views an exercise card in selection mode
- **THEN** the "Select" button is clearly visible and not overlapping other elements
- **AND** the button has adequate touch target size for mobile interaction
- **AND** the button is positioned logically within the card layout
