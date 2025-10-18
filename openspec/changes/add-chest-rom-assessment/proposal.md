## Why
The current ROM assessment system supports Triceps, Shoulders, Hamstrings, and Calf assessments, but lacks a comprehensive chest/upper body ROM assessment. Adding chest ROM assessment will provide clinicians with a complete upper body evaluation tool that measures upward-forward arm motion, which is critical for assessing chest wall mobility and shoulder girdle function.

## What Changes
- **ADDED** Chest ROM assessment mode to the existing assessment system
- **ADDED** Chest-specific keypoint tracking using shoulder, elbow, wrist, and hip landmarks
- **ADDED** Forward elevation angle calculation using hip-shoulder-wrist triangulation
- **ADDED** Chest ROM thresholds (severe < 45°, moderate 45-90°, good ≥ 90°)
- **ADDED** Chest assessment instructions and UI integration
- **MODIFIED** AssessmentService to include chest assessment logic
- **MODIFIED** Camera UI dropdown to include "Chest" option

## Impact
- Affected specs: rom-assessment capability
- Affected code: 
  - `lib/assessment/arom/assessment_service.dart` - Add chest case
  - `lib/assessment/arom/assessment_constants.dart` - Add chest thresholds
  - `lib/assessment/arom/chest_assessment.dart` - New chest assessment module
  - `lib/assessment/c_camera.dart` - Add chest to dropdown and instructions
- New capability: Chest ROM assessment with pose-based angle measurement
