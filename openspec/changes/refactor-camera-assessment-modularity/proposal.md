## Why

The current `c_camera.dart` file contains 1628 lines with mixed concerns - camera UI components and assessment logic are tightly coupled. This creates maintenance challenges, reduces code reusability, and makes it difficult to test assessment algorithms independently. The file contains assessment logic for multiple muscle groups (triceps, shoulders, hamstrings, calves) that should be modularized for better organization and maintainability.

## What Changes

- **BREAKING**: Extract assessment logic from `c_camera.dart` into dedicated modules
- Create new `lib/assessment/arom/` directory with specialized assessment modules
- Implement `triceps_assessment.dart`, `shoulders_assessment.dart`, `hamstrings_assessment.dart`, and `calves_assessment.dart`
- Refactor `c_camera.dart` to use clean API calls to assessment modules
- Maintain existing AI model integration and pose detection functionality
- Preserve all current assessment capabilities and clinical thresholds

## Impact

- Affected specs: assessment-modularity (new capability)
- Affected code: 
  - `lib/assessment/c_camera.dart` (major refactor)
  - New files: `lib/assessment/arom/*.dart` (4 new assessment modules)
  - `lib/data/pose_detection_service.dart` (minimal changes for integration)
- Dependencies: Maintains existing pose detection and AI model pipelines
