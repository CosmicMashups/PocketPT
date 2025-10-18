## ADDED Requirements

### Requirement: Modular Assessment Architecture
The system SHALL provide separate assessment modules for different muscle groups, enabling independent testing and maintenance of assessment logic.

#### Scenario: Triceps assessment module
- **WHEN** a triceps assessment is requested with pose landmarks
- **THEN** the triceps assessment module calculates ROM and pain scores using clinical thresholds
- **AND** returns standardized assessment results with pain scale mapping

#### Scenario: Shoulders assessment module
- **WHEN** a shoulders assessment is requested with pose landmarks
- **THEN** the shoulders assessment module calculates ROM and pain scores using clinical thresholds
- **AND** returns standardized assessment results with pain scale mapping

#### Scenario: Hamstrings assessment module
- **WHEN** a hamstrings assessment is requested with pose landmarks
- **THEN** the hamstrings assessment module calculates ROM and pain scores using clinical thresholds
- **AND** returns standardized assessment results with pain scale mapping

#### Scenario: Calves assessment module
- **WHEN** a calves assessment is requested with pose landmarks
- **THEN** the calves assessment module calculates ROM and pain scores using clinical thresholds
- **AND** returns standardized assessment results with pain scale mapping

### Requirement: Assessment Module API Consistency
All assessment modules SHALL provide a consistent API interface for integration with camera UI components.

#### Scenario: Standardized assessment interface
- **WHEN** any assessment module is called with pose landmarks
- **THEN** it returns a standardized result structure containing ROM level, pain score, and clinical context
- **AND** the result format is consistent across all muscle group assessments

### Requirement: Clinical Threshold Preservation
Assessment modules SHALL maintain existing clinical thresholds and pain scale mappings to ensure assessment accuracy.

#### Scenario: Triceps clinical thresholds
- **WHEN** triceps ROM is assessed
- **THEN** severe limitation is defined as angle < 90°
- **AND** moderate limitation is defined as 90° ≤ angle < 135°
- **AND** good ROM is defined as angle ≥ 135°

#### Scenario: Hamstrings clinical thresholds
- **WHEN** hamstrings ROM is assessed
- **THEN** severe limitation is defined as angle < 60°
- **AND** moderate limitation is defined as 60° ≤ angle < 80°
- **AND** good ROM is defined as angle ≥ 80°

#### Scenario: Calves clinical thresholds
- **WHEN** calves dorsiflexion is assessed
- **THEN** severe limitation is defined as normalized displacement < 0.15
- **AND** moderate limitation is defined as 0.15 ≤ displacement < 0.30
- **AND** good ROM is defined as displacement ≥ 0.30

## MODIFIED Requirements

### Requirement: Camera Assessment Integration
The camera assessment UI SHALL use modular assessment services instead of inline assessment logic.

#### Scenario: Real-time assessment with modules
- **WHEN** the camera captures pose landmarks during assessment
- **THEN** the UI calls the appropriate assessment module based on selected muscle group
- **AND** displays real-time results without performance regression
- **AND** maintains existing skeleton overlay and recording functionality
