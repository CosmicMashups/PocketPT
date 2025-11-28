## 1. Data Model & Validation
- [x] 1.1 Add `treatmentInstruction` field to `Treatment` class in `lib/data/treatment.dart`
- [x] 1.2 Update `Treatment` constructor to include `treatmentInstruction` parameter (make optional for backward compatibility)
- [x] 1.3 Update `Treatment.toString()` to include treatmentInstruction field
- [x] 1.4 Add `_validateMandatoryTreatments()` helper function to validate T001, T002, T003 are first in treatment list
- [x] 1.5 Add `_injectMandatoryTreatments()` helper to prepend T001, T002, T003 to treatment list if missing
- [x] 1.6 Add `_ensureMandatoryTreatmentsPresent()` helper that combines validation and injection logic
- [ ] 1.7 Test helpers with various treatment list scenarios (empty, partial mandatory, all mandatory, wrong order)

## 2. CSV Parsing & Treatment Loading
- [x] 2.1 Update `loadTreatmentsFromCSV()` in `generate_treatment.dart` to parse 7 columns (was 6)
- [x] 2.2 Update expectedColumnCount from 6 to 7 in `generate_treatment.dart`
- [x] 2.3 Update Treatment object creation in `loadTreatmentsFromCSV()` to include `row[6]` as treatmentInstruction
- [x] 2.4 Update `ExerciseDataService.loadAllTreatments()` in `rehabilitation_plan.dart` to parse 7 columns (was 6)
- [x] 2.5 Update expectedColumnCount from 6 to 7 in `rehabilitation_plan.dart` loadAllTreatments()
- [x] 2.6 Update Treatment object creation in `loadAllTreatments()` to use `row[col('Treatment_Instruction')]` for treatmentInstruction
- [x] 2.7 Add backward compatibility: default treatmentInstruction to empty string if column missing or row has < 7 columns
- [x] 2.8 Add logging/warning when Treatment_Instruction column is missing in CSV
- [ ] 2.9 Test CSV parsing with 6-column CSV (backward compatibility)
- [ ] 2.10 Test CSV parsing with 7-column CSV (new format)
- [ ] 2.11 Test CSV parsing with malformed rows (handle gracefully)

## 3. Treatment Generation Logic
- [x] 3.1 Modify `generateTreatmentPlan()` in `generate_treatment.dart` to always include T001, T002, T003 first
- [x] 3.2 Update filtering logic to exclude T001-T003 from optional treatment filtering (they're always included)
- [x] 3.3 Ensure deduplication logic preserves mandatory treatment order (deduplicate only from optional treatments)
- [x] 3.4 Update `generateTreatmentPlanFromService()` with same mandatory treatment logic
- [x] 3.5 Add comprehensive logging for mandatory treatment injection
- [ ] 3.6 Test generation with all filter combinations (severe pain, recent pain, various muscles, etc.)

## 4. Storage Layer Updates - Hive
- [x] 4.1 Update `UserRehabilitation.savePlansToHive()` to validate mandatory treatments before saving
- [x] 4.2 Update `UserRehabilitation.loadPlansFromHive()` to inject mandatory treatments if missing (migration)
- [ ] 4.3 Test Hive save/load cycle preserves treatment order
- [ ] 4.4 Test migration of existing Hive data to include mandatory treatments

## 5. Storage Layer Updates - Firebase
- [x] 5.1 Update `UserRehabilitation.savePlansToFirebase()` to validate mandatory treatments before saving
- [x] 5.2 Update `UserRehabilitation.loadPlansFromFirebase()` to inject mandatory treatments if missing (migration)
- [x] 5.3 Ensure Firebase map-to-list conversion preserves treatment order (treatment1, treatment2, etc.)
- [ ] 5.4 Test Firebase save/load cycle preserves treatment order
- [ ] 5.5 Test migration of existing Firebase data to include mandatory treatments

## 6. Plan Generation Integration
- [x] 6.1 Update `generate_plan.dart` `_loadPlan()` to ensure mandatory treatments are validated after generation (automatic via generateTreatmentPlan)
- [ ] 6.2 Test plan generation in all output states (treatments only, exercises + treatments, error states)
- [ ] 6.3 Ensure mandatory treatments appear in generate_plan.dart UI correctly
- [ ] 6.4 Test backward compatibility with plans that had no treatments

## 7. UI Display Updates - Treatment Instruction
- [x] 7.1 Update `_buildTreatmentCard()` in `generate_plan.dart` to display treatmentInstruction
- [x] 7.2 Add treatmentInstruction display section in treatment card UI (e.g., "Instructions" detail row)
- [x] 7.3 Update `_buildTreatmentCard()` in `edit_plan.dart` to display treatmentInstruction
- [x] 7.4 Update `_showTreatmentDetail()` dialog in `edit_plan.dart` to display treatmentInstruction
- [x] 7.5 Add visual styling for treatmentInstruction (distinguish from description)
- [ ] 7.6 Test treatmentInstruction display in generate_plan.dart treatment cards
- [ ] 7.7 Test treatmentInstruction display in edit_plan.dart treatment cards and detail dialog
- [ ] 7.8 Update dashboard_page.dart treatment display (if applicable) to include treatmentInstruction

## 8. Edit Plan UI - Optional Treatment Addition
- [x] 8.1 Add "Add Optional Treatments" button/section to treatment area in `edit_plan.dart`
- [x] 8.2 Create `_showAddOptionalTreatmentsDialog()` method with treatment selection UI
- [x] 8.3 Implement treatment list display (load all treatments or filter by user criteria)
- [x] 8.4 Implement multi-select functionality for optional treatments
- [x] 8.5 Wire up selected treatments to append after mandatory treatments
- [x] 8.6 Add visual distinction between mandatory (T001-T003) and optional treatments in UI
- [x] 8.7 Implement save logic to persist manually added treatments to Hive and Firebase
- [x] 8.8 Add loading states and error handling for treatment addition

## 9. UI Polish & User Experience
- [x] 9.1 Add visual indicators (badges, labels) to distinguish "Core Treatments" (T001-T003) from "Additional Treatments"
- [x] 9.2 Ensure treatment cards display correctly with mandatory/optional distinction
- [x] 9.3 Add informational tooltip explaining mandatory treatments
- [x] 9.4 Prevent removal/reordering of mandatory treatments in UI (if applicable) - Note: No delete/reorder functionality exists for treatments currently, tooltips added to explain mandatory status
- [x] 9.5 Update treatment section headers to reflect mandatory vs optional

## 10. Testing & Validation
- [ ] 10.1 Unit tests for Treatment class with treatmentInstruction field
- [ ] 10.2 Unit tests for CSV parsing with 7 columns (Treatment_Instruction)
- [ ] 10.3 Unit tests for CSV parsing backward compatibility (6 columns)
- [ ] 10.4 Unit tests for mandatory treatment validation helpers
- [ ] 10.5 Unit tests for mandatory treatment injection logic
- [ ] 10.6 Integration tests for treatment generation with mandatory treatments
- [ ] 10.7 Integration tests for treatment loading with treatmentInstruction field
- [ ] 10.8 Integration tests for Hive persistence with mandatory treatments
- [ ] 10.9 Integration tests for Firebase persistence with mandatory treatments
- [ ] 10.10 Update test data in `exercise_data_service_test.dart` to include treatmentInstruction
- [ ] 10.11 Update test validations in `data_validation_test.dart` to validate treatmentInstruction
- [ ] 10.12 E2E test: Complete assessment flow → verify mandatory treatments present with treatmentInstruction
- [ ] 10.13 E2E test: Load existing plan → verify mandatory treatments injected via migration
- [ ] 10.14 E2E test: Add optional treatments → verify order preserved (mandatory first, then optional)
- [ ] 10.15 E2E test: Display treatment cards → verify treatmentInstruction displays correctly
- [ ] 10.16 Test with various treatment CSV configurations (ensure T001, T002, T003 exist)
- [ ] 10.17 Test error handling when mandatory treatment IDs don't exist in CSV
- [ ] 10.18 Test error handling when Treatment_Instruction column is missing in CSV

## 11. Documentation
- [ ] 11.1 Update code comments in `treatment.dart` explaining treatmentInstruction field
- [ ] 11.2 Update code comments in `generate_treatment.dart` explaining mandatory treatment logic and CSV parsing
- [ ] 11.3 Update code comments in `rehabilitation_plan.dart` explaining CSV parsing with 7 columns
- [ ] 11.4 Update code comments in storage methods explaining order preservation
- [ ] 11.5 Document treatment order requirements in relevant data model files
- [ ] 11.6 Document Treatment_Instruction column in CSV format documentation
- [ ] 11.7 Update any architecture documentation referencing treatment generation
- [ ] 11.8 Update DATABASE_STRUCTURE_DOCUMENTATION.md with treatmentInstruction field

## 12. UX Recommendations (Deferred - Awaiting Approval)
- [ ] 10.1 Document UX enhancement recommendations for treatment adherence tracking
- [ ] 10.2 Prepare proposal for sequence locking (T001 must complete before T002)
- [ ] 10.3 Prepare proposal for visual progress indicators
- [ ] 10.4 Prepare proposal for treatment completion tracking
- [ ] 10.5 Prepare proposal for treatment reminders and notifications

