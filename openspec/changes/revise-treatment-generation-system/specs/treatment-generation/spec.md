## ADDED Requirements

### Requirement: Mandatory Treatment Sequence
The treatment generation system SHALL always include treatment IDs T001, T002, and T003 in strict chronological order at the beginning of every treatment plan, regardless of user-selected filtering criteria (muscle, pain level, pain duration).

#### Scenario: Generate treatment plan with mandatory treatments
- **WHEN** a treatment plan is generated via `generateTreatmentPlan()`
- **THEN** the returned treatment list MUST begin with T001, followed by T002, followed by T003 in positions 0, 1, and 2 respectively
- **AND** any additional optional treatments matching user criteria are appended after T001, T002, T003

#### Scenario: Mandatory treatments with matching filter criteria
- **WHEN** one or more of T001, T002, T003 match the user's filter criteria (muscle, pain level, pain duration)
- **THEN** those treatments SHALL still appear only once at the beginning of the list
- **AND** duplicate entries SHALL be removed from optional treatment results

#### Scenario: Treatment plan with no optional matches
- **WHEN** user filter criteria match no optional treatments (T004+)
- **THEN** the treatment plan SHALL contain only T001, T002, T003
- **AND** the plan SHALL be valid and persistable

### Requirement: Optional Treatment Filtering
The treatment generation system SHALL preserve existing filtering logic for optional treatments (T004 and higher), applying user-selected criteria (muscle, pain level, pain duration) to select matching optional treatments.

#### Scenario: Filter optional treatments by muscle
- **WHEN** optional treatments are filtered with a specific muscle parameter
- **THEN** only optional treatments (T004+) matching that muscle SHALL be included
- **AND** mandatory treatments (T001-T003) SHALL always appear first regardless of muscle match

#### Scenario: Filter optional treatments by pain level
- **WHEN** optional treatments are filtered with a specific pain level parameter
- **THEN** only optional treatments (T004+) matching that pain level SHALL be included
- **AND** mandatory treatments SHALL appear first regardless of pain level match

#### Scenario: Limit optional treatments to 3
- **WHEN** more than 3 optional treatments match the filter criteria
- **THEN** the system SHALL return the first 3 matching optional treatments
- **AND** total treatment count SHALL be 6 (3 mandatory + 3 optional)

### Requirement: Manual Optional Treatment Addition
The plan editing interface SHALL provide a mechanism for users to manually add optional treatments to their treatment plan.

#### Scenario: User adds optional treatments via UI
- **WHEN** user navigates to edit_plan.dart and clicks "Add Optional Treatments"
- **THEN** a modal dialog SHALL display a list of available optional treatments (T004+)
- **AND** user SHALL be able to select one or more optional treatments
- **AND** selected treatments SHALL be appended to the treatment plan after mandatory treatments
- **AND** manually added treatments SHALL be persisted to both Hive and Firebase

#### Scenario: Add treatments with existing optional treatments
- **WHEN** user adds optional treatments to a plan that already contains optional treatments
- **THEN** newly added treatments SHALL be appended after existing optional treatments
- **AND** mandatory treatment order (T001-T003) SHALL remain unchanged at the beginning

#### Scenario: Prevent duplicate optional treatments
- **WHEN** user attempts to add an optional treatment that already exists in the plan
- **THEN** the system SHALL either prevent the duplicate addition or inform the user
- **AND** the existing treatment order SHALL be preserved

### Requirement: Treatment Instruction Column
The treatment.csv file SHALL include a "Treatment_Instruction" column as the seventh column, and all CSV parsing logic SHALL read and map this column into the Treatment data model.

#### Scenario: Parse Treatment_Instruction from CSV
- **WHEN** treatment.csv is loaded with 7 columns including Treatment_Instruction
- **THEN** the CSV parser SHALL read column 6 (0-indexed) as the Treatment_Instruction field
- **AND** the Treatment object SHALL be created with the treatmentInstruction field populated from the CSV
- **AND** all Treatment objects SHALL have a treatmentInstruction field value

#### Scenario: Handle missing Treatment_Instruction column
- **WHEN** treatment.csv is loaded with only 6 columns (legacy format without Treatment_Instruction)
- **THEN** the CSV parser SHALL default treatmentInstruction to an empty string
- **AND** a warning SHALL be logged indicating the missing column
- **AND** Treatment objects SHALL be created successfully with empty treatmentInstruction

#### Scenario: Parse Treatment_Instruction via column name
- **WHEN** treatment.csv is loaded using column name mapping (via `col('Treatment_Instruction')`)
- **THEN** the parser SHALL correctly identify the Treatment_Instruction column regardless of column order
- **AND** the treatmentInstruction field SHALL be populated from the correct column
- **AND** the parser SHALL handle column name variations (case-insensitive, space variations)

## MODIFIED Requirements

### Requirement: Treatment Data Model
The Treatment class SHALL include a treatmentInstruction field that stores instructions on how to perform or apply the treatment.

#### Scenario: Treatment object with treatmentInstruction
- **WHEN** a Treatment object is created
- **THEN** it SHALL include a treatmentInstruction field of type String
- **AND** the treatmentInstruction field SHALL be initialized from the Treatment_Instruction CSV column
- **AND** the treatmentInstruction field SHALL be accessible for display and processing

#### Scenario: Treatment toString includes treatmentInstruction
- **WHEN** a Treatment object's toString() method is called
- **THEN** the output SHALL include the treatmentInstruction field value
- **AND** the output SHALL be formatted consistently with other Treatment fields

### Requirement: Treatment Plan Storage
Treatment plans SHALL be stored in both Hive (local) and Firebase (cloud) with treatment order preserved. Treatment lists SHALL always begin with mandatory treatments T001, T002, T003 in strict order.

#### Scenario: Save treatment plan with mandatory treatments
- **WHEN** a treatment plan is saved to Hive or Firebase
- **THEN** the treatment list SHALL be validated to ensure T001, T002, T003 are the first three treatments
- **AND** if validation fails, the system SHALL inject mandatory treatments before saving
- **AND** the complete treatment list with preserved order SHALL be persisted

#### Scenario: Load existing treatment plan
- **WHEN** a treatment plan is loaded from Hive or Firebase
- **THEN** if mandatory treatments (T001, T002, T003) are missing or not in correct order
- **THEN** the system SHALL automatically inject them at the beginning
- **AND** the migrated plan SHALL be saved back to storage
- **AND** the loaded plan SHALL always contain mandatory treatments in correct order

#### Scenario: Preserve treatment order across save/load
- **WHEN** a treatment plan with mandatory and optional treatments is saved and reloaded
- **THEN** the treatment order SHALL be identical to the original
- **AND** mandatory treatments SHALL remain in positions 0, 1, 2
- **AND** optional treatments SHALL retain their relative order after mandatory treatments

### Requirement: Treatment Plan Display
Treatment plans SHALL be displayed in the user interface with clear visual distinction between mandatory (T001-T003) and optional treatments.

#### Scenario: Display treatment plan with mandatory and optional
- **WHEN** a treatment plan is displayed in generate_plan.dart or edit_plan.dart
- **THEN** mandatory treatments (T001, T002, T003) SHALL be displayed first
- **AND** optional treatments SHALL be displayed after mandatory treatments
- **AND** visual indicators (labels, badges, or section headers) SHALL distinguish mandatory from optional treatments

#### Scenario: Display treatments-only plan
- **WHEN** a treatment plan contains only mandatory treatments (no optional matches)
- **THEN** the plan SHALL display all three mandatory treatments
- **AND** the UI SHALL indicate that these are core foundational treatments
- **AND** the option to add optional treatments SHALL be available in edit_plan.dart

#### Scenario: Display treatment instruction in UI
- **WHEN** a treatment is displayed in generate_plan.dart or edit_plan.dart
- **THEN** the treatmentInstruction field SHALL be displayed to the user
- **AND** the treatmentInstruction SHALL be visually distinguished from the treatment description
- **AND** the treatmentInstruction SHALL be shown in treatment cards and detail dialogs

#### Scenario: Display treatment instruction in detail dialog
- **WHEN** user views treatment details in edit_plan.dart detail dialog
- **THEN** the treatmentInstruction SHALL be displayed in a dedicated section or field
- **AND** the treatmentInstruction SHALL be clearly labeled (e.g., "Instructions" or "How to Apply")
- **AND** if treatmentInstruction is empty, the section SHALL be hidden or show a default message

