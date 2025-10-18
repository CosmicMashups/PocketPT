## Why
The current ROM assessment system supports triceps, shoulders, hamstrings, calves, and chest assessments. Adding biceps assessment capability will expand the system's muscle coverage for comprehensive upper body rehabilitation evaluation, enabling clinicians to assess biceps pain levels based on elbow flexion and extension angles.

## What Changes
- Add biceps assessment module following existing modular architecture patterns
- Integrate biceps assessment into the assessment service routing
- Add biceps clinical thresholds to assessment constants
- Maintain consistency with existing assessment result structure and pain scale mapping

## Impact
- Affected specs: rom-assessment capability
- Affected code: lib/assessment/arom/ (new biceps_assessment.dart, updates to assessment_service.dart and assessment_constants.dart)
- Integration: Camera assessment UI will support biceps mode selection
