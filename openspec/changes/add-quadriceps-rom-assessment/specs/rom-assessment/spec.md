## ADDED Requirements

### Requirement: Quadriceps ROM Assessment
The system SHALL provide quadriceps assessment capability that evaluates pain levels based on knee flexion and extension angles using Google ML Kit's pose detection service.

#### Scenario: Quadriceps assessment with severe pain (extended leg)
- **WHEN** a quadriceps assessment is requested with pose landmarks showing knee angle >= 160°
- **THEN** the quadriceps assessment module returns severe ROM limitation
- **AND** maps to pain score 8-10 (severe pain)
- **AND** displays "Quadriceps ROM: Severe (>= 160°)"

#### Scenario: Quadriceps assessment with moderate pain (mid-range flexion)
- **WHEN** a quadriceps assessment is requested with pose landmarks showing knee angle between 100° and 160°
- **THEN** the quadriceps assessment module returns moderate ROM limitation
- **AND** maps to pain score 5-7 (moderate pain)
- **AND** displays "Quadriceps ROM: Moderate (100-160°)"

#### Scenario: Quadriceps assessment with low pain (fully flexed leg)
- **WHEN** a quadriceps assessment is requested with pose landmarks showing knee angle < 100°
- **THEN** the quadriceps assessment module returns low ROM limitation
- **AND** maps to pain score 2-4 (low pain)
- **AND** displays "Quadriceps ROM: Low (< 100°)"

#### Scenario: Quadriceps assessment with missing landmarks
- **WHEN** a quadriceps assessment is requested but required landmarks (hip, knee, ankle) are missing
- **THEN** the quadriceps assessment module returns AssessmentResult.notVisible('Quadriceps')
- **AND** provides appropriate error messaging

### Requirement: Quadriceps Assessment Integration
The quadriceps assessment module SHALL integrate seamlessly with the existing modular assessment architecture.

#### Scenario: Quadriceps mode selection in camera UI
- **WHEN** user selects "Quadriceps" from the assessment mode dropdown
- **THEN** the camera UI displays quadriceps-specific instructions
- **AND** real-time assessment shows quadriceps ROM evaluation

#### Scenario: Quadriceps assessment result display
- **WHEN** quadriceps assessment is performed
- **THEN** results are displayed using standardized assessment result format
- **AND** pain score integrates with existing pain scale system
- **AND** clinical context provides appropriate guidance
