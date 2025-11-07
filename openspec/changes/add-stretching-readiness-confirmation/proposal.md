## Why

Currently, stretching routines auto-start immediately when loaded, beginning the countdown timer without giving users time to read and understand the exercise instructions. This can cause users to feel rushed and may lead to improper form or missed safety precautions.

Additionally, when warmup or cooldown routines complete, the app immediately navigates to the next screen without user confirmation. This abrupt transition doesn't give users a moment to acknowledge completion or prepare for the next phase of their session.

## What Changes

- **Readiness Confirmation Before Timer Start**: Add a confirmation dialog that appears before starting the countdown timer, asking:
  - If the user is ready to begin
  - If the user understands what to do
  - Allow users to read steps and instructions before confirming
- **Warmup Completion Confirmation**: After completing all warmup exercises, show a confirmation dialog before proceeding to the exercise recording page
- **Cooldown Completion Confirmation**: After completing all cooldown exercises, show a confirmation dialog before proceeding to the Confirm Save page
- **Prevent Auto-Start**: Modify the routine loading behavior to not auto-start the timer, requiring explicit user confirmation first

## Impact

- Affected specs: stretching-routines
- Affected code:
  - `lib/stretching/providers/stretching_provider.dart` - Modify auto-start behavior, add readiness state
  - `lib/record/warmup_stretching_page.dart` - Add readiness dialog, completion confirmation dialog, update navigation
  - `lib/record/cooldown_stretching_page.dart` - Add readiness dialog, completion confirmation dialog, update navigation
  - `lib/stretching/widgets/exercise_instruction_widget.dart` - May need updates to support readiness state
- UX improvements: Better user control, reduced rush, improved safety through confirmation steps

