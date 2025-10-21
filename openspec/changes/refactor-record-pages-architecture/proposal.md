## Why

The record pages (`lib/record/`) suffer from critical stability and usability issues that significantly impact the exercise recording workflow. Users experience camera loading failures when proceeding between exercises, widget overflow on different screen sizes, navigation state inconsistencies, performance bottlenecks from redundant operations, and poor error handling that leaves users without clear feedback when issues occur.

## What Changes

- **REFACTOR**: Camera management across all record pages using a shared CameraService singleton
- **FIX**: Widget overflow issues with responsive layouts and proper text wrapping
- **SIMPLIFY**: Navigation and state management with centralized flow coordination
- **OPTIMIZE**: Performance by eliminating redundant operations and implementing proper caching
- **STRENGTHEN**: Error handling with user-friendly feedback and recovery mechanisms
- **MAINTAIN**: All existing functionality including stopwatch, data tracking, and UI design consistency

## Impact

- Affected specs: exercise-recording, camera-management, state-management
- Affected code: `lib/record/` directory (all files)
- User experience: Stable camera loading, responsive UI, clear error feedback, smooth navigation
- Performance: Reduced memory usage, faster page transitions, optimized data loading
