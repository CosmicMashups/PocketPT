## Why

The current exercise recording workflow lacks proper warm-up and cooldown routines, which are essential for injury prevention and optimal recovery. Users need guided stretching exercises before starting their rehabilitation exercises and after completing them to ensure safe and effective physical therapy sessions.

## What Changes

- **ADDED**: Warm-up stretching integration before exercise recording starts
- **ADDED**: Cooldown stretching integration after completing all exercises
- **ADDED**: Muscle group-specific stretching routines based on assessment data
- **ADDED**: Stretching exercise data models and CSV-based exercise database
- **ADDED**: Optional stretching workflows with clear benefits explanation
- **MODIFIED**: Pre-record page to include warm-up option dialog
- **MODIFIED**: Record exercise page to include cooldown option after last exercise

## Impact

- Affected specs: exercise-recording, stretching-routines (new capability)
- Affected code: lib/record/pre_record_page.dart, lib/record/record_exercise.dart, new stretching pages and services
- User experience: Enhanced safety through proper warm-up and cooldown routines
- Healthcare compliance: Evidence-based stretching exercises following physical therapy standards
