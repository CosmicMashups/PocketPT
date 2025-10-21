## Why
The current assessment flow lacks detailed muscle-specific pain assessment capabilities. When users indicate they have previous injuries in the medical history assessment (`d_history.dart`), the system should capture which specific muscles were injured and their current pain levels. This information is crucial for generating safe and effective rehabilitation plans that avoid exercises targeting severely injured muscles.

## What Changes
- **BREAKING**: Add new muscle assessment page `d_muscle.dart` between `d_history.dart` and `e_summary.dart`
- **BREAKING**: Modify navigation flow in `d_history.dart` to route to muscle assessment when "Yes" is selected
- **BREAKING**: Extend data models in `UserAssess` and `AssessmentData` with muscle-specific pain tracking
- **BREAKING**: Update exercise generation logic in `generate_plan.dart` to filter exercises based on muscle injury data
- Create comprehensive muscle selection interface with 15 predefined muscles
- Implement pain level assessment (0-10 scale) for each selected muscle
- Integrate muscle data with exercise filtering using "Other_Muscles" column from exercises.csv
- Maintain consistent UI/UX patterns with existing assessment pages

## Impact
- Affected specs: assessment flow navigation, exercise generation, data persistence
- Affected code: `lib/assessment/d_history.dart`, `lib/assessment/d_muscle.dart` (new), `lib/assessment/e_summary.dart`, `lib/assessment/generate_plan.dart`, `lib/data/globals.dart`, `lib/assessment/assessment_data.dart`
- Breaking changes to navigation flow require careful testing of all assessment paths
- New data fields require migration considerations for existing user data
