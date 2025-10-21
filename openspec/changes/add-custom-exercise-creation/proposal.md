## Why

The current exercise system in PocketPT only supports pre-loaded exercises from CSV files. Users need the ability to create custom exercises that are tailored to their specific rehabilitation needs, pain levels, and functional goals. This will enhance the personalization of rehabilitation plans and allow healthcare providers to prescribe exercises that aren't in the standard dataset.

## What Changes

- **ADDED**: Custom exercise creation form with validation
- **ADDED**: Local storage for custom exercises using CSV format
- **ADDED**: Integration of custom exercises with existing exercise list
- **MODIFIED**: Add Exercise button to show two options (existing vs custom)
- **ADDED**: CustomExerciseService for managing custom exercise persistence
- **MODIFIED**: ExerciseDataService to load both default and custom exercises

## Impact

- Affected specs: exercise-management (new capability)
- Affected code: 
  - `lib/exercise/edit_plan.dart` (UI modifications)
  - `lib/exercise/exercise_list.dart` (integration)
  - `lib/data/custom_exercise_service.dart` (new service)
  - `lib/data/rehabilitation_plan.dart` (ExerciseDataService updates)
- **BREAKING**: None - this is purely additive functionality