## Why

The current warmup and cooldown stretching pages (`warmup_stretching_page.dart` and `cooldown_stretching_page.dart`) have redundant UI elements that consume excessive screen space. The "Prepare Your Muscles" / "Recovery & Relaxation" header card and the "Routine Progress" card contain overlapping information and take up valuable screen real estate that could be better utilized for displaying exercise instructions, steps, benefits, and precautions.

The current implementation doesn't fully leverage the rich exercise data available (description, step_1 through step_8, benefit_1 through benefit_3, precaution_1 through precaution_3) from the stretching exercise model, instead showing generic information that doesn't guide users effectively through the exercises.

## What Changes

- **Combine Header and Progress Cards**: Merge the "Prepare Your Muscles"/"Recovery & Relaxation" card with the "Routine Progress" card into a single, more compact combined card
- **Remove Redundant Content**: Remove the following elements that don't add value:
  - Muscle group text (e.g., "Warm-up/Cooldown stretching for Deltoids")
  - "Injury Prevention" / "Recovery Aid" badge
  - "5-10 min" duration badge
  - "Routine Progress" icon and title
- **Enhance Exercise Data Display**: Make better use of exercise data fields:
  - Display exercise `description` prominently
  - Show all available steps (`step_1` through `step_8`) in a clear, numbered format
  - Display benefits (`benefit_1`, `benefit_2`, `benefit_3`) in an organized manner
  - Show precautions (`precaution_1`, `precaution_2`, `precaution_3`) with appropriate visual emphasis
- **Improve Space Utilization**: Create a more efficient layout that prioritizes exercise guidance over decorative elements

## Impact

- Affected specs: stretching-routines
- Affected code:
  - `lib/record/warmup_stretching_page.dart`
  - `lib/record/cooldown_stretching_page.dart`
  - `lib/stretching/widgets/routine_progress_widget.dart`
  - `lib/stretching/widgets/exercise_instruction_widget.dart`
- UI/UX improvements: More focused, instructional interface with better use of available screen space

