## Why

The custom exercise creation feature in PocketPT currently has several critical issues that prevent it from functioning correctly:

1. **Hive Adapter Not Registered**: Custom exercises cannot be saved because `HiveCustomExerciseAdapter` (typeId: 13) is not registered in `main.dart` or `globals.dart`, causing HiveError exceptions when creating exercises.

2. **UI Overflow Issues**: The "Create Custom Exercise" dialog title overflows horizontally, and the Medical Support help dialog overflows vertically on smaller screens, making content inaccessible.

3. **Missing UI Simplification**: The dialog includes unnecessary "Image Filename" and "Video URL" fields that should be automatically set to default values (".jpg" and ".mp4") rather than requiring user input.

4. **Incorrect Muscle Group Options**: The muscle group dropdown contains outdated options (e.g., "Chest", "Ankle", "Cervical Muscle") that don't match the standardized muscle list used elsewhere in the app.

5. **Other Muscles Field Type**: The "Other Muscles" field is a free-text input when it should be a dropdown with the same standardized muscle options, excluding the primary muscle group to prevent duplicates.

6. **Dialog Button Color Bug**: The "Delete" confirmation dialog has red text on a dark-red button background, making the text invisible.

## What Changes

- **FIXED**: Register `HiveCustomExerciseAdapter` (typeId: 13) in both `main.dart` and `globals.dart` to resolve HiveError exceptions
- **FIXED**: Change dialog title from "Create Custom Exercise" to "Custom Exercise" to prevent horizontal overflow
- **REMOVED**: Remove "Image Filename" and "Video URL" text fields from custom exercise dialog
- **MODIFIED**: Automatically set `imageUrl` to ".jpg" and `videoUrl` to ".mp4" for all newly created custom exercises
- **MODIFIED**: Update muscle group dropdown to include only the standardized muscle list: Deltoids, Biceps, Triceps, Upper Back, Lower Back, Abdominals, Obliques, Multifidus, Quadriceps, Hamstrings, Calf, Gluteals
- **MODIFIED**: Convert "Other Muscles" text field into a dropdown with the same standardized muscle options, automatically excluding the selected primary muscle group
- **FIXED**: Make Medical Support dialog scrollable to prevent vertical overflow on any screen size
- **FIXED**: Correct button text color in exercise removal confirmation dialog to use visible color (white) instead of red-on-red

## Impact

- Affected specs: custom-exercise-management (MODIFIED requirements)
- Affected code: 
  - `lib/main.dart` (Hive adapter registration)
  - `lib/data/globals.dart` (Hive adapter registration)
  - `lib/exercise/edit_plan.dart` (dialog UI fixes, field updates, muscle dropdown changes)
  - `lib/data/custom_exercise_service.dart` (default image/video URL handling)
- **BREAKING**: None - these are bug fixes and UI improvements that maintain backward compatibility

