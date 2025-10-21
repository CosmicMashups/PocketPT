## Why
The current ROM assessment system supports individual muscle group assessments, but lacks a comprehensive gluteal and hamstring assessment module that can evaluate both muscle groups through hip flexion and extension movements. Adding this combined assessment capability will provide clinicians with a unified tool for evaluating posterior chain muscles, which are crucial for lower body rehabilitation and movement analysis.

## What Changes
- Add glute_ham_assessment.dart module that can evaluate both gluteals and hamstrings
- Integrate both gluteal and hamstring assessments into the assessment service routing
- Add gluteal and hamstring clinical thresholds to assessment constants
- Maintain consistency with existing assessment result structure and pain scale mapping
- Support dual muscle group evaluation in a single module

## Impact
- Affected specs: rom-assessment capability
- Affected code: lib/assessment/arom/ (new glute_ham_assessment.dart, updates to assessment_service.dart and assessment_constants.dart)
- Integration: Camera assessment UI will support gluteal and hamstring mode selection
