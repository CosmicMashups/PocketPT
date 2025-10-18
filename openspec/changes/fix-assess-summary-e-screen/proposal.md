## Why
The "E goal" summary screen (`AssessSummary`) intermittently fails to render properly and can get stuck during data load. Navigation from `AssessHistory` to `AssessSummary` lacks diagnostics, and layout uses `Material` directly, causing safe area and background issues on some devices.

## What Changes
- Add diagnostic logging around navigation from `AssessHistory` to `AssessSummary`.
- Improve `AssessSummary` data loading: explicit logs, timeout guard, graceful error handling, and state updates.
- Replace top-level `Material` usage with `Scaffold` in `AssessSummary` and loading state.
- Add robust Hive box opening helper to avoid hangs on corrupted boxes.
- Optional dev-only helper for direct navigation to `AssessSummary` for testing.

## Impact
- Affected specs: assessment flow rendering and persistence (no breaking API changes).
- Affected code: `lib/assessment/d_history.dart`, `lib/assessment/e_summary.dart`, `lib/data/globals.dart`.


