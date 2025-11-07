## Why

The current `record_exercise.dart` page has several usability and design issues that reduce focus on the primary activity (exercise recording) and create visual clutter:

1. **Visual Clutter**: The enhanced header section with gradients and info banners takes up valuable screen space and competes with the camera feed for attention
2. **Camera Not Centered**: The camera widget is not properly centered, making it appear flushed left and less prominent
3. **Overly Complex Buttons**: Control buttons contain multiple decorative elements (extra icons, symbols, padding) that waste horizontal space
4. **Poor Text Readability**: The DraggableScrollableSheet uses white text on white background, making instructions unreadable
5. **Inconsistent Top Bar**: Missing the dark red top bar consistent with other pages (warmup_stretching_page.dart, cooldown_stretching_page.dart)
6. **Pain Overlay Positioning**: Pain recognition overlay is positioned at the far right edge instead of within the camera widget bounds
7. **No Camera Toggle**: Users cannot switch between front and rear cameras during recording

These issues reduce usability, hinder focus on exercise recording, and create inconsistency with the established design patterns in warmup and cooldown pages.

## What Changes

- **Replace Header Card with Dark Red Top Bar**: Remove the enhanced header section card and replace it with a dark red AppBar consistent with warmup_stretching_page.dart and cooldown_stretching_page.dart
- **Simplify Button Design**: Remove decorative elements from control buttons (Back, Pause, Proceed), keeping only icon on left and text on right
- **Center Camera Widget**: Ensure camera preview is properly centered and becomes the primary visual focus
- **Reposition Pain Overlay**: Move pain detection overlay to top-right corner within camera widget bounds (not at screen edge)
- **Add Camera Toggle**: Implement camera switching functionality to allow users to toggle between front and rear cameras
- **Fix DraggableScrollableSheet Readability**: Adjust text colors, background opacity, and font weights to ensure proper contrast and readability
- **Optimize 9:16 Layout**: Ensure all UI elements fit within 9:16 aspect ratio without requiring scrolling
- **Maintain Medical Design Standards**: Retain professional, minimalist aesthetic suitable for clinical contexts

## Impact

- Affected specs: recording-ui
- Affected code:
  - `lib/record/record_exercise.dart` - Layout redesign, camera positioning, button simplification
  - `lib/record/camera_service.dart` - Camera toggle functionality (may need enhancement)
- UX improvements: 
  - Improved focus on camera/exercise recording
  - Better text readability
  - Consistent top bar design
  - Enhanced usability with camera toggle
- Functional changes:
  - Camera toggle feature added
  - Pain overlay repositioned
  - Layout optimized for 9:16 aspect ratio

