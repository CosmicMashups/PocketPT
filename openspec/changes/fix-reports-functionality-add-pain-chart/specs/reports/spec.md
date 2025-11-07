## ADDED Requirements

### Requirement: Daily Pain Level Chart Visualization
The system SHALL provide a visual chart displaying tracked daily pain levels over time to help users understand their pain progression.

#### Scenario: Display pain level chart
- **WHEN** user views the reports page
- **THEN** system displays a pain level chart widget
- **AND** chart shows daily pain scale values over time
- **AND** chart uses appropriate visual styling (line chart or bar chart)
- **AND** chart handles empty data gracefully with appropriate message
- **AND** chart displays loading state while data is being fetched

#### Scenario: Chart data loading
- **WHEN** pain history data is loaded
- **THEN** chart displays all available pain level entries
- **AND** chart groups data by date
- **AND** chart shows pain scale values on y-axis and dates on x-axis
- **AND** chart handles missing data points appropriately

### Requirement: Assessment Data in PDF Export
The system SHALL include assessment collection data from Firebase in the first page of exported PDF reports for comprehensive clinical documentation.

#### Scenario: Include assessment data in PDF
- **WHEN** user exports PDF report
- **THEN** system includes assessment data section on first page
- **AND** assessment section includes: generalMuscle, injuredMuscles, painDuration, painLevel, painScale, painType, rehabGoal, specificMuscle, lastUpdated
- **AND** assessment data is formatted in professional clinical layout
- **AND** assessment data is loaded from Firebase assessment collection before PDF generation

#### Scenario: Assessment data loading
- **WHEN** PDF export is initiated
- **THEN** system loads assessment data from Firebase assessment collection
- **AND** system handles missing assessment data gracefully
- **AND** system displays appropriate error if assessment data cannot be loaded

## MODIFIED Requirements

### Requirement: Exercise Calendar Grid
The system SHALL provide a functional exercise calendar grid displaying exercise completion history with proper data loading, date handling, and error management.

#### Scenario: Calendar data display
- **WHEN** user views the reports page
- **THEN** system displays exercise calendar grid
- **AND** calendar shows current month by default
- **AND** calendar displays exercise records for each day with proper visual indicators
- **AND** calendar handles date normalization correctly (timezone and time components)
- **AND** calendar properly groups exercise records by date

#### Scenario: Calendar navigation
- **WHEN** user navigates between months
- **THEN** calendar updates to show selected month
- **AND** exercise records are filtered for the selected month
- **AND** calendar maintains proper state during navigation

#### Scenario: Calendar data loading
- **WHEN** exercise history is loaded
- **THEN** calendar displays all exercise records
- **AND** calendar shows loading state while data is being fetched
- **AND** calendar displays error state if data loading fails
- **AND** calendar handles empty data gracefully

#### Scenario: Calendar date selection
- **WHEN** user taps on a calendar day with exercises
- **THEN** system displays day details dialog
- **AND** dialog shows all exercises recorded for that day
- **AND** dialog displays exercise status (completed, partial) correctly

### Requirement: PDF Report Export
The system SHALL provide reliable PDF report generation with comprehensive data inclusion, proper error handling, and assessment information.

#### Scenario: PDF export generation
- **WHEN** user initiates PDF export
- **THEN** system generates PDF report with all available data
- **AND** PDF includes assessment data on first page
- **AND** PDF includes exercise history, pain history, and rehabilitation plans
- **AND** PDF uses proper formatting and professional layout
- **AND** system displays loading indicator during PDF generation

#### Scenario: PDF export data loading
- **WHEN** PDF export is requested
- **THEN** system loads all required data from Firebase (force refresh)
- **AND** system includes assessment data from assessment collection
- **AND** system handles missing data gracefully
- **AND** system provides user feedback on export progress

#### Scenario: PDF export error handling
- **WHEN** PDF export fails
- **THEN** system displays clear error message to user
- **AND** system maintains user interface state appropriately
- **AND** system allows user to retry export
- **AND** system logs error details for debugging

