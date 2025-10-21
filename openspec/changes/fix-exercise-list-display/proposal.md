## Why
The exercise list page is not displaying exercises from the CSV file, and the exercise detail page lacks a "Select" button to add exercises to the rehabilitation plan. Users cannot browse and select exercises for their rehabilitation plans.

## What Changes
- Fix CSV data loading and parsing in exercise_list.dart
- Ensure exercises are properly displayed in the list view
- Add "Select" button to exercise detail page that returns Exercise_ID
- Fix data mapping between CSV columns and Exercise model
- Handle placeholder image/video values (.jpg, .mp4) gracefully

## Impact
- Affected specs: exercise-management (new capability)
- Affected code: lib/exercise/exercise_list.dart, lib/exercise/exercise_detail.dart
- Users will be able to browse and select exercises for their rehabilitation plans
