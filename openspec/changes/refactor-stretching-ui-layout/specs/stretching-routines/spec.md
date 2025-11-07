## MODIFIED Requirements

### Requirement: Stretching Routine UI Layout
The system SHALL display stretching routine information in a compact, efficient layout that prioritizes exercise guidance over decorative elements.

#### Scenario: Combined header and progress display
- **WHEN** user views a warmup or cooldown stretching page
- **THEN** the header card and progress information are combined into a single card
- **AND** the combined card displays the routine title, current exercise name, progress indicator, and timer
- **AND** redundant elements (muscle group text, generic badges, "Routine Progress" label) are removed
- **AND** the layout uses space efficiently to maximize area for exercise instructions

#### Scenario: Exercise data utilization
- **WHEN** user is performing a stretching exercise
- **THEN** the exercise description is prominently displayed
- **AND** all available step-by-step instructions (step_1 through step_8) are shown in a numbered format
- **AND** all available benefits (benefit_1, benefit_2, benefit_3) are displayed in a dedicated section
- **AND** all available precautions (precaution_1, precaution_2, precaution_3) are displayed with appropriate warning styling
- **AND** the information hierarchy prioritizes actionable guidance over decorative elements

#### Scenario: Space-efficient layout
- **WHEN** user views a stretching routine page
- **THEN** the combined header/progress card uses approximately 50% less vertical space than the previous two-card layout
- **AND** the saved space is utilized for displaying exercise instructions, steps, benefits, and precautions
- **AND** the layout remains responsive across different screen sizes
- **AND** all essential information remains accessible and readable

### Requirement: Exercise Instruction Display (Modified)
The system SHALL provide comprehensive exercise guidance using all available exercise data fields in a clear, organized manner.

#### Scenario: Complete exercise information display
- **WHEN** user is performing a stretching exercise
- **THEN** the exercise description field is displayed at the top of the instruction area
- **AND** all non-empty step fields (step_1 through step_8) are displayed in a numbered list
- **AND** all non-empty benefit fields (benefit_1, benefit_2, benefit_3) are displayed in a visually distinct benefits section
- **AND** all non-empty precaution fields (precaution_1, precaution_2, precaution_3) are displayed in a warning-styled precautions section
- **AND** the information is organized with clear visual hierarchy

#### Scenario: Data field handling
- **WHEN** an exercise has fewer than 8 steps or fewer than 3 benefits/precautions
- **THEN** only the available, non-empty fields are displayed
- **AND** empty fields are not shown as placeholders or empty entries
- **AND** the layout adapts gracefully to varying amounts of content

