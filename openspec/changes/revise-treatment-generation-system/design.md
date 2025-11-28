## Context
The treatment generation system currently filters treatments from CSV based on user-selected criteria (muscle, pain level, pain duration) and returns up to 3 matching treatments. There is no mechanism to ensure foundational treatments (T001-T003) are always included, nor is there a way for users to manually add optional treatments beyond the initial generation phase.

Treatment storage uses `List<TreatmentReference>?` with sequential IDs saved to both Hive and Firebase. Firebase stores treatments as `treatment1`, `treatment2`, `treatment3` in plan documents. Hive stores treatment references in UserRehabilitation instance.

The treatment.csv file has been updated to include a new "Treatment_Instruction" column, bringing the total column count from 6 to 7. This column contains instructions on how to perform or apply the treatment, which must be parsed, stored, and displayed throughout the application.

## Goals / Non-Goals
### Goals
- Guarantee T001, T002, T003 always appear first in every treatment plan, in strict order
- Preserve existing optional treatment filtering logic (T004+)
- Enable manual addition of optional treatments through edit_plan.dart UI
- Maintain treatment order across Hive and Firebase persistence
- Migrate existing plans to include mandatory treatments

### Non-Goals
- Changing the treatment CSV structure or format beyond the already-added Treatment_Instruction column
- Adding treatment editing/deletion capabilities (beyond optional addition)
- Implementing treatment adherence tracking (deferred to future enhancement)
- Modifying exercise generation logic
- Changing Firebase collection structure (only enhancing data within existing schema)

## Decisions

### Decision 1: Mandatory Treatment Injection Strategy
**Approach**: Inject mandatory treatments at generation time, not at display time.

**Rationale**: 
- Ensures mandatory treatments are always persisted with plans
- Simplifies UI logic - no need to merge mandatory treatments on every render
- Makes data consistent across sessions and devices
- Easier to validate and audit treatment plans

**Implementation**: 
- Modify `generateTreatmentPlan()` to prepend T001, T002, T003 to filtered results
- Deduplicate to avoid duplicates if T001-T003 match filter criteria
- Ensure mandatory treatments are always in positions 0, 1, 2

### Decision 2: Treatment Order Storage
**Approach**: Rely on list order in `List<TreatmentReference>` to preserve sequence.

**Rationale**:
- `List` already maintains insertion order in Dart
- No need for additional sequence fields or indices
- Hive and Firebase both preserve list order when serializing
- Minimal data model changes required

**Implementation**:
- Ensure all code that modifies treatment lists preserves order
- Validate order on load (mandatory treatments must be first three)
- Migrate existing plans by injecting mandatory treatments at load time

### Decision 3: Optional Treatment Addition UI
**Approach**: Modal dialog with searchable/filterable treatment list for selecting optional treatments.

**Rationale**:
- Consistent with existing "Add Exercise" UI pattern in edit_plan.dart
- Allows users to browse and select from full treatment catalog
- Can reuse existing filtering logic for consistency
- Non-intrusive to existing plan display

**Implementation**:
- Add "Add Optional Treatments" button in treatment section
- Show modal with treatment list (filtered or full catalog)
- Allow multi-select
- Append selected treatments after mandatory treatments
- Persist immediately to Hive and Firebase

### Decision 4: Data Migration Strategy
**Approach**: Lazy migration - inject mandatory treatments on load if missing.

**Rationale**:
- No breaking changes to existing data
- Handles migration automatically without user intervention
- Works for both Hive and Firebase data
- Minimal performance impact (only on load)

**Implementation**:
- In `loadPlansFromHive()` and `loadPlansFromFirebase()`, check if T001, T002, T003 are present
- If missing or not in correct order, prepend them before setting treatmentReferences
- Save migrated data back to storage
- Log migration events for debugging

### Decision 5: Mandatory Treatment Validation
**Approach**: Validate mandatory treatments exist and are in correct order before saving.

**Rationale**:
- Prevents data corruption
- Ensures consistency across all save operations
- Catches bugs early
- Provides clear error messages

**Implementation**:
- Create `_validateMandatoryTreatments()` helper
- Check first three treatment IDs are T001, T002, T003
- Throw descriptive error if validation fails
- Call validation before all save operations

### Decision 6: Treatment Instruction Column Handling
**Approach**: Parse Treatment_Instruction column from CSV, default to empty string if missing for backward compatibility.

**Rationale**:
- Maintains backward compatibility with existing CSV files
- Graceful degradation if column is missing
- No breaking changes to existing Treatment objects
- Clear error logging when column is missing

**Implementation**:
- Update CSV parsing in both `generate_treatment.dart` and `rehabilitation_plan.dart`
- Change expectedColumnCount from 6 to 7
- Read row[6] or col('Treatment_Instruction') for treatmentInstruction
- Default to empty string if column missing or row has < 7 columns
- Log warning when column is missing
- Add treatmentInstruction field to Treatment class constructor
- Update all Treatment object instantiations
- Display treatmentInstruction in UI components (treatment cards, detail dialogs)

## Risks / Trade-offs

### Risk: Mandatory Treatments May Not Match User Criteria
**Mitigation**: Mandatory treatments always included regardless of filters. User-selected criteria only affect optional treatments (T004+). If user's condition doesn't match mandatory treatments, they still receive them as foundational care.

### Risk: Existing Plans Missing Mandatory Treatments
**Mitigation**: Lazy migration on load ensures all existing plans are updated automatically. Migration is transparent to users and happens once per plan load.

### Risk: Performance Impact of Validation
**Mitigation**: Validation is O(1) operation (checking first 3 list elements). Minimal overhead added to save operations.

### Risk: Firebase Order Preservation
**Trade-off**: Firebase stores treatments as map with sequential keys (`treatment1`, `treatment2`). List order is preserved when converting to/from maps. This is acceptable as long as conversion logic maintains order.

**Mitigation**: Test order preservation across save/load cycles thoroughly. Consider storing order explicitly if issues arise (add sequence field to TreatmentReference).

### Risk: User Confusion with Mandatory vs Optional
**Mitigation**: Clear UI indicators (e.g., "Core Treatments" vs "Additional Treatments") to distinguish mandatory from optional. Visual separation in edit_plan.dart treatment section.

## Migration Plan

### Phase 1: Data Model Preparation
1. Ensure `TreatmentReference` and `HiveTreatmentReference` support current use case
2. Add validation helpers for mandatory treatments
3. Add migration helpers to inject mandatory treatments

### Phase 2: Generation Logic Updates
1. Modify `generateTreatmentPlan()` to inject mandatory treatments
2. Update filtering logic to exclude T001-T003 from optional filtering
3. Test with various filter combinations

### Phase 3: Storage Updates
1. Update `savePlansToHive()` to validate mandatory treatments
2. Update `savePlansToFirebase()` to validate mandatory treatments  
3. Update `loadPlansFromHive()` with migration logic
4. Update `loadPlansFromFirebase()` with migration logic

### Phase 4: UI Enhancement
1. Add "Add Optional Treatments" button to edit_plan.dart
2. Implement treatment selection modal
3. Wire up persistence for manually added treatments

### Phase 5: Testing & Validation
1. Test mandatory treatment injection in all scenarios
2. Test migration of existing plans
3. Test manual treatment addition and persistence
4. Validate order preservation across save/load cycles

### Rollback Plan
- Revert changes to `generateTreatmentPlan()` if issues arise
- Optional treatment addition feature can be disabled via feature flag
- Migration logic can be disabled if causing issues (though data will remain inconsistent)

## Open Questions
- Should mandatory treatments be editable/removable, or strictly locked? **Decision**: Strictly locked - cannot be removed or reordered.
- Should we track which treatments are mandatory vs optional in the data model? **Decision**: No - derive from position (first 3 = mandatory).
- What happens if T001, T002, or T003 don't exist in treatment.csv? **Decision**: Log warning and continue, but ensure those IDs are always in treatment.csv.
- Should there be a maximum limit on optional treatments? **Decision**: No hard limit initially, but consider UI/performance if users add many.
- What happens if Treatment_Instruction column is missing in older CSV files? **Decision**: Default to empty string for backward compatibility; log warning if column not found.
- Should Treatment_Instruction be stored separately in Hive/Firebase? **Decision**: No - full Treatment objects are loaded from CSV when needed; TreatmentReference only stores IDs. Treatment_Instruction is part of the Treatment object.

