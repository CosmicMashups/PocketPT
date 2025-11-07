## Why

The `record_exercise.dart` page currently uses a basic design that doesn't match the enhanced, medical-grade aesthetic established in the warmup and cooldown stretching pages. The warmup and cooldown pages feature:

- Enhanced header sections with gradients, icons, and professional styling
- Consistent use of `RecordingDesignSystem` throughout
- Enhanced control buttons with gradients and better visual hierarchy
- Improved spacing and layout using design system constants
- Better visual feedback and professional appearance

Applying these design patterns to `record_exercise.dart` will:
- Create visual consistency across the exercise recording flow
- Improve user experience with a more polished, professional interface
- Maintain the medical-grade aesthetic throughout the app
- Enhance usability without changing functionality

The camera widget with pain detection must be retained as it's a critical feature for exercise monitoring.

## What Changes

- **Enhanced Header Section**: Replace the current AppBar with an enhanced header section matching warmup/cooldown design (gradients, icons, styled containers)
- **Enhanced Timer Display**: Update timer display to use enhanced styling with gradients and better visual hierarchy
- **Enhanced Control Buttons**: Replace current buttons with enhanced versions using gradients, better spacing, and design system styling
- **Improved Layout**: Apply consistent spacing, padding, and layout patterns from warmup/cooldown pages
- **Design System Consistency**: Ensure all UI elements use `RecordingDesignSystem` constants for colors, spacing, radii, shadows, etc.
- **Camera Widget Retention**: Keep the camera preview widget with pain detection overlay intact and functional

## Impact

- Affected specs: recording-ui
- Affected code:
  - `lib/record/record_exercise.dart` - Apply enhanced design patterns while retaining camera functionality
- UX improvements: Visual consistency, professional appearance, improved usability
- No functional changes: All existing functionality (camera, pain detection, navigation, exercise recording) remains unchanged

