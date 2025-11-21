## ADDED Requirements

### Requirement: Historical Pain Entry Preservation
The system SHALL preserve all historical pain entries when recording daily pain assessments, ensuring that each day's pain data creates a new entry in the pain history collection without overwriting previous entries.

#### Scenario: Initial assessment creates first entry
- **WHEN** a user completes the initial assessment and pain data is recorded
- **THEN** the system creates a new pain history entry with the current date, painScale, and painLevel
- **AND** the entry is saved to both Hive and Firebase storage
- **AND** the entry is available for future retrieval and PDF export

#### Scenario: Daily assessment creates new entry preserving history
- **WHEN** a user performs a daily pain assessment on a subsequent day
- **THEN** the system creates a new pain history entry for that day
- **AND** all previous day's entries remain intact in the pain history collection
- **AND** the new entry is appended to the existing history without overwriting previous entries
- **AND** all entries are saved to both Hive and Firebase storage

#### Scenario: Multiple days of pain tracking
- **WHEN** a user records pain assessments over multiple consecutive days
- **THEN** each day creates a distinct entry in the pain history collection
- **AND** all historical entries are preserved in chronological order
- **AND** the PDF export service can access all entries for comprehensive reporting

#### Scenario: Same-day multiple recordings update that day's entry
- **WHEN** a user records pain multiple times on the same calendar day
- **THEN** the system updates the entry for that day with the latest values
- **AND** previous days' entries remain unchanged
- **AND** only one entry exists per calendar day in the pain history

## ADDED Requirements

### Requirement: Pain History Entry Management
The pain history system SHALL manage entries such that each calendar day has exactly one entry, and new entries are created for new days without overwriting previous days' entries.

#### Scenario: Daily entry creation
- **WHEN** `PainHistory.recordToday()` is called with painScale and painLevel
- **THEN** the system checks if an entry exists for the current date
- **IF** no entry exists for the current date, a new entry is created and added to the history
- **IF** an entry exists for the current date, that entry is updated with the new values
- **AND** entries for previous dates are never modified or removed
- **AND** all entries are maintained in chronological order

#### Scenario: Historical data preservation
- **WHEN** pain history is saved to Hive or Firebase
- **THEN** all entries in the `PainHistory.entries` list are persisted
- **AND** no entries are lost during save operations
- **AND** the complete history is available for loading on subsequent app sessions

#### Scenario: PDF export with complete history
- **WHEN** the PDF export service requests pain history data
- **THEN** all historical pain entries are retrieved from storage
- **AND** the PDF report includes all entries in chronological order
- **AND** pain trend analysis can be performed using the complete historical data

