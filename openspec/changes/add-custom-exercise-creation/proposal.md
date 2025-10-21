## Why
The current exercise management system only allows users to select from predefined exercises in the CSV database. Users and therapists need the ability to create custom exercises that are not available in the standard library, enabling personalized rehabilitation plans that adapt to specific patient needs and therapeutic requirements.

## What Changes
- **ADDED**: Custom exercise creation dialog with comprehensive form fields matching CSV structure
- **ADDED**: CustomExerciseService for persisting custom exercises to local storage
- **MODIFIED**: Exercise Manager "Add Exercise" button to show two options (existing vs custom)
- **MODIFIED**: ExercisesPage to load and display both default and custom exercises
- **ADDED**: Local CSV file management for custom exercises with proper error handling

## Impact
- Affected specs: exercise-management (new capability)
- Affected code: 
  - `lib/exercise/edit_plan.dart` - Enhanced add exercise functionality
  - `lib/exercise/exercise_list.dart` - Extended to load custom exercises
  - `lib/data/custom_exercise_service.dart` - New service for custom exercise management
  - Local storage integration for custom exercise persistence
