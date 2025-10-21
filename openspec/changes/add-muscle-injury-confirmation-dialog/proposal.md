## Why
The current exercise generation system filters out exercises targeting muscles with severe pain levels to ensure user safety. However, this can result in insufficient exercise options (< 3 exercises) for users with multiple muscle injuries, leaving them with inadequate rehabilitation plans. Users should have the option to include exercises targeting previously injured muscles when exercise options are limited, but this requires explicit informed consent due to safety considerations.

## What Changes
- **BREAKING**: Add user confirmation dialog system for insufficient exercise scenarios
- **BREAKING**: Modify `generateRehabilitationPlanFromCSV()` to trigger dialog when < 3 exercises after muscle filtering
- **BREAKING**: Create new dialog widget and service for muscle injury confirmation
- **BREAKING**: Update exercise generation flow to handle user choices (include all, keep safe, cancel)
- Add enum for user choice tracking and state management
- Integrate dialog with existing assessment and plan generation flows
- Maintain safety warnings and healthcare consultation recommendations

## Impact
- Affected specs: exercise generation, user safety, assessment flow
- Affected code: `lib/data/rehabilitation_plan.dart`, `lib/assessment/generate_plan.dart`, new dialog widget and service
- Breaking changes to exercise generation logic require careful testing of all assessment paths
- New user interaction flow requires UX validation and accessibility compliance
- Safety considerations require clear user communication and consent mechanisms
