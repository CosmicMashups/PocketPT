## Why
The current ROM assessment system supports upper body assessments (triceps, shoulders, biceps, chest) and lower body assessments (hamstrings, calves). Adding quadriceps assessment capability will complete the lower body muscle coverage for comprehensive rehabilitation evaluation, enabling clinicians to assess quadriceps pain levels based on knee flexion and extension angles.

## What Changes
- Add quadriceps assessment module following existing modular architecture patterns
- Integrate quadriceps assessment into the assessment service routing
- Add quadriceps clinical thresholds to assessment constants
- Maintain consistency with existing assessment result structure and pain scale mapping

## Impact
- Affected specs: rom-assessment capability
- Affected code: lib/assessment/arom/ (new quadriceps_assessment.dart, updates to assessment_service.dart and assessment_constants.dart)
- Integration: Camera assessment UI will support quadriceps mode selection
