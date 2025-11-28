## ADDED Requirements

### Requirement: Gluteal ROM Assessment
The system SHALL provide gluteal assessment capability that evaluates pain levels based on hip flexion and extension angles using Google ML Kit's pose detection service.

#### Scenario: Gluteal assessment with severe pain (extended leg)
- **WHEN** a gluteal assessment is requested with pose landmarks showing shoulder-hip-knee angle >= 180°
- **THEN** the gluteal assessment module returns severe ROM limitation
- **AND** maps to pain score 8-10 (severe pain)
- **AND** displays "Gluteal ROM: Severe (>= 180°)"

#### Scenario: Gluteal assessment with moderate pain (mid-range flexion)
- **WHEN** a gluteal assessment is requested with pose landmarks showing shoulder-hip-knee angle between 140° and 159°
- **THEN** the gluteal assessment module returns moderate ROM limitation
- **AND** maps to pain score 5-7 (moderate pain)
- **AND** displays "Gluteal ROM: Moderate (140-159°)"

#### Scenario: Gluteal assessment with low pain (flexed leg)
- **WHEN** a gluteal assessment is requested with pose landmarks showing shoulder-hip-knee angle < 140°
- **THEN** the gluteal assessment module returns low ROM limitation
- **AND** maps to pain score 2-4 (low pain)
- **AND** displays "Gluteal ROM: Low (< 140°)"

### Requirement: Enhanced Hamstring ROM Assessment
The system SHALL provide enhanced hamstring assessment capability that evaluates pain levels based on hip-knee-ankle angles using Google ML Kit's pose detection service.

#### Scenario: Enhanced hamstring assessment with severe pain (extended leg)
- **WHEN** a hamstring assessment is requested with pose landmarks showing hip-knee-ankle angle >= 180°
- **THEN** the hamstring assessment module returns severe ROM limitation
- **AND** maps to pain score 8-10 (severe pain)
- **AND** displays "Hamstring ROM: Severe (>= 180°)"

#### Scenario: Enhanced hamstring assessment with moderate pain (mid-range flexion)
- **WHEN** a hamstring assessment is requested with pose landmarks showing hip-knee-ankle angle between 140° and 159°
- **THEN** the hamstring assessment module returns moderate ROM limitation
- **AND** maps to pain score 5-7 (moderate pain)
- **AND** displays "Hamstring ROM: Moderate (140-159°)"

#### Scenario: Enhanced hamstring assessment with low pain (flexed leg)
- **WHEN** a hamstring assessment is requested with pose landmarks showing hip-knee-ankle angle < 140°
- **THEN** the hamstring assessment module returns low ROM limitation
- **AND** maps to pain score 2-4 (low pain)
- **AND** displays "Hamstring ROM: Low (< 140°)"

#### Scenario: Missing landmarks for both muscle groups
- **WHEN** gluteal or hamstring assessment is requested but required landmarks are missing
- **THEN** the assessment module returns AssessmentResult.notVisible('Gluteals') or AssessmentResult.notVisible('Hamstrings')
- **AND** provides appropriate error messaging

### Requirement: Combined Assessment Module Integration
The gluteal and hamstring assessments SHALL integrate seamlessly with the existing modular assessment architecture using a unified module.

#### Scenario: Gluteal mode selection in camera UI
- **WHEN** user selects "Gluteals" from the assessment mode dropdown
- **THEN** the camera UI displays gluteal-specific instructions
- **AND** real-time assessment shows gluteal ROM evaluation using shoulder-hip-knee landmarks

#### Scenario: Enhanced hamstring mode selection in camera UI
- **WHEN** user selects "Hamstrings" from the assessment mode dropdown
- **THEN** the camera UI displays hamstring-specific instructions
- **AND** real-time assessment shows hamstring ROM evaluation using hip-knee-ankle landmarks

#### Scenario: Combined assessment result display
- **WHEN** gluteal or hamstring assessment is performed
- **THEN** results are displayed using standardized assessment result format
- **AND** pain score integrates with existing pain scale system
- **AND** clinical context provides appropriate guidance
