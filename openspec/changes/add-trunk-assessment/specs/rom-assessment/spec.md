## ADDED Requirements

### Requirement: Unified Trunk ROM Assessment
The system SHALL provide unified trunk assessment capability that evaluates pain levels for all four trunk muscle groups (abdominals, obliques, lower back, multifidus) based on trunk flexion and extension angles using Google ML Kit's pose detection service.

#### Scenario: Trunk assessment with severe pain (upright/extended trunk)
- **WHEN** a trunk assessment is requested with pose landmarks showing shoulder-hip-knee angle >= 160°
- **THEN** the trunk assessment module returns severe ROM limitation for the specified muscle group
- **AND** maps to pain score 8-10 (severe pain)
- **AND** displays "Trunk ROM: Severe (>= 160°)" for the specific muscle group

#### Scenario: Trunk assessment with moderate pain (mid-range flexion)
- **WHEN** a trunk assessment is requested with pose landmarks showing shoulder-hip-knee angle between 60° and 160°
- **THEN** the trunk assessment module returns moderate ROM limitation for the specified muscle group
- **AND** maps to pain score 5-7 (moderate pain)
- **AND** displays "Trunk ROM: Moderate (60-160°)" for the specific muscle group

#### Scenario: Trunk assessment with low pain (fully flexed trunk)
- **WHEN** a trunk assessment is requested with pose landmarks showing shoulder-hip-knee angle < 60°
- **THEN** the trunk assessment module returns low ROM limitation for the specified muscle group
- **AND** maps to pain score 2-4 (low pain)
- **AND** displays "Trunk ROM: Low (< 60°)" for the specific muscle group

#### Scenario: Trunk assessment with missing landmarks
- **WHEN** trunk assessment is requested but required landmarks (shoulders, hips, knees) are missing
- **THEN** the trunk assessment module returns AssessmentResult.notVisible('Trunk')
- **AND** provides appropriate error messaging

### Requirement: Multi-Muscle Group Trunk Assessment
The trunk assessment module SHALL support evaluation of four specific muscle groups using unified logic with muscle type specification.

#### Scenario: Abdominal assessment
- **WHEN** user selects "Abdominals" from the assessment mode dropdown
- **THEN** the camera UI displays abdominal-specific instructions
- **AND** real-time assessment shows abdominal ROM evaluation using trunk flexion/extension angles

#### Scenario: Oblique assessment
- **WHEN** user selects "Obliques" from the assessment mode dropdown
- **THEN** the camera UI displays oblique-specific instructions
- **AND** real-time assessment shows oblique ROM evaluation using trunk flexion/extension angles

#### Scenario: Lower back assessment
- **WHEN** user selects "Lower Back" from the assessment mode dropdown
- **THEN** the camera UI displays lower back-specific instructions
- **AND** real-time assessment shows lower back ROM evaluation using trunk flexion/extension angles

#### Scenario: Multifidus assessment
- **WHEN** user selects "Multifidus" from the assessment mode dropdown
- **THEN** the camera UI displays multifidus-specific instructions
- **AND** real-time assessment shows multifidus ROM evaluation using trunk flexion/extension angles

### Requirement: Trunk Assessment Integration
The unified trunk assessment module SHALL integrate seamlessly with the existing modular assessment architecture.

#### Scenario: Unified trunk assessment result display
- **WHEN** any trunk muscle group assessment is performed
- **THEN** results are displayed using standardized assessment result format
- **AND** pain score integrates with existing pain scale system
- **AND** clinical context provides appropriate guidance for the specific muscle group
- **AND** assessment uses center body side for trunk evaluation
