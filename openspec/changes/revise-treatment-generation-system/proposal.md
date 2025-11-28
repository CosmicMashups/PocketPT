## Why
The current treatment generation system filters and returns treatments based on user criteria, but lacks mandatory treatment sequences and manual optional treatment management. Users need a predictable treatment foundation (T001 → T002 → T003) that always appears, with the ability to add optional treatments through the plan editing interface. This ensures consistent rehabilitation protocols while maintaining flexibility for personalized care plans.

## What Changes
- **Mandatory Treatments**: T001, T002, T003 must ALWAYS be included in strict chronological order at the beginning of every treatment plan, regardless of filtering criteria
- **Optional Treatment Filtering**: Existing filtering logic preserved for optional treatments (T004+), which append after mandatory treatments
- **Manual Treatment Addition**: New "Add Optional Treatments" UI feature in edit_plan.dart for users to manually select and add optional treatments
- **Treatment Instruction Column**: New "Treatment_Instruction" column added to treatment.csv requiring updates to all CSV parsing, data models, storage, and UI display
- **Data Model Enhancements**: Treatment class updated with treatmentInstruction field; Treatment storage updated to preserve chronological order and distinguish mandatory vs optional treatments
- **Storage Layer Updates**: Hive and Firebase persistence updated to enforce mandatory treatment inclusion, preserve treatment sequence, and store treatmentInstruction field
- **CSV Parsing Updates**: All functions reading treatment.csv updated to parse 7 columns (was 6) and map Treatment_Instruction column correctly
- **UI Display Updates**: Treatment cards and detail views updated to display treatmentInstruction field
- **Backward Compatibility**: Data migration support for existing plans to ensure mandatory treatments are included; CSV parsing handles missing Treatment_Instruction column gracefully

## Impact
- Affected specs: Treatment generation capability (new), treatment management capability (modified), treatment data model capability (modified)
- Affected code: 
  - `lib/data/treatment.dart` - Treatment class model (add treatmentInstruction field)
  - `lib/assessment/generate_treatment.dart` - CSV parsing (update to 7 columns), mandatory treatment injection logic
  - `lib/data/rehabilitation_plan.dart` - ExerciseDataService.loadAllTreatments() CSV parsing (update to 7 columns), UserRehabilitation class storage methods
  - `lib/assessment/generate_plan.dart` - Treatment plan integration, UI display of treatmentInstruction
  - `lib/exercise/edit_plan.dart` - New UI for manual treatment addition, UI display of treatmentInstruction
  - `lib/dashboard/dashboard_page.dart` - Treatment display (if applicable)
  - `test/exercise_data_service_test.dart` - Test data models (add treatmentInstruction)
  - `test/data_validation_test.dart` - Test validations (add treatmentInstruction)
  - Any other files that create Treatment objects or display treatment data
- Breaking changes: None - existing plans will be migrated automatically; CSV parsing handles missing column gracefully
- Migration required: Yes - existing treatment plans must have mandatory treatments injected on load
- CSV Schema Change: treatment.csv now requires 7 columns instead of 6 (adds Treatment_Instruction column)

