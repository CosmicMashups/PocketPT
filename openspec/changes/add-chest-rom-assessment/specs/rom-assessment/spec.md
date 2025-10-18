## ADDED Requirements

### Requirement: Chest ROM Assessment
The system SHALL provide chest range of motion assessment using pose estimation keypoints to measure upward-forward arm movement.

#### Scenario: Chest ROM assessment with good range
- **WHEN** user selects "Chest" mode and raises arm forward and upward
- **THEN** system calculates hip-shoulder-wrist angle ≥ 90°
- **AND** displays "Chest ROM: Good (≥ 90°)" with green color
- **AND** assigns pain score of 1 (good ROM)

#### Scenario: Chest ROM assessment with moderate limitation
- **WHEN** user selects "Chest" mode and raises arm with limited forward elevation
- **THEN** system calculates hip-shoulder-wrist angle between 45° and 90°
- **AND** displays "Chest ROM: Moderate (45-90°)" with orange color
- **AND** assigns pain score of 6 (moderate limitation)

#### Scenario: Chest ROM assessment with severe limitation
- **WHEN** user selects "Chest" mode and raises arm with minimal forward elevation
- **THEN** system calculates hip-shoulder-wrist angle < 45°
- **AND** displays "Chest ROM: Severe (< 45°)" with red color
- **AND** assigns pain score of 9 (severe limitation)

#### Scenario: Chest ROM assessment with missing keypoints
- **WHEN** user selects "Chest" mode but required keypoints are not visible
- **THEN** system displays "Chest: Not visible" with white color
- **AND** assigns default pain score of 5 (moderate)
- **AND** provides instruction to adjust position

### Requirement: Chest Assessment Keypoint Tracking
The system SHALL track shoulder, elbow, wrist, and hip keypoints for chest ROM calculation.

#### Scenario: Keypoint validation for chest assessment
- **WHEN** performing chest ROM assessment
- **THEN** system validates presence of hip, shoulder, and wrist keypoints
- **AND** calculates forward elevation angle using hip-shoulder-wrist triangulation
- **AND** handles missing keypoints gracefully with appropriate error messages

### Requirement: Chest Assessment Integration
The system SHALL integrate chest assessment into existing ROM assessment workflow.

#### Scenario: Chest mode selection in camera UI
- **WHEN** user opens ROM assessment camera
- **THEN** "Chest" option appears in assessment mode dropdown
- **AND** selecting "Chest" updates assessment mode and instructions
- **AND** chest-specific instructions guide user positioning

#### Scenario: Chest assessment result display
- **WHEN** chest ROM assessment completes
- **THEN** results display in assessment overlay with angle measurement
- **AND** pain score updates in UserAssess.painScale
- **AND** clinical context provides appropriate guidance
