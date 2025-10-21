## Why
The current ROM assessment system supports individual muscle group assessments for upper and lower body, but lacks a comprehensive trunk assessment module that can evaluate core muscles (abdominals, obliques, lower back, and multifidus) through trunk flexion and extension movements. Adding this unified trunk assessment capability will provide clinicians with a comprehensive tool for evaluating core stability and trunk mobility, which are crucial for overall rehabilitation and movement analysis.

## What Changes
- Add b_trunk_assessment.dart module that can evaluate all four trunk muscle groups (abdominals, obliques, lower back, multifidus)
- Integrate all trunk assessments into the assessment service routing with unified logic
- Add trunk clinical thresholds to assessment constants
- Maintain consistency with existing assessment result structure and pain scale mapping
- Support unified trunk muscle group evaluation using shoulder-hip-knee landmark angles

## Impact
- Affected specs: rom-assessment capability
- Affected code: lib/assessment/arom/ (new b_trunk_assessment.dart, updates to assessment_service.dart and assessment_constants.dart)
- Integration: Camera assessment UI will support trunk muscle group mode selection
