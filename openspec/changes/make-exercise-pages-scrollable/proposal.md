## Why

Currently, the warmup and cooldown stretching pages use `Column` widgets directly without scrollable wrappers, which can cause content overflow issues on smaller screens or when content exceeds the viewport height. The record exercise page already has `SingleChildScrollView`, but we need to ensure all three pages in the exercise flow are consistently scrollable.

When content exceeds the available screen space, users cannot access all information without scrolling. This is particularly problematic for:
- Smaller screen devices
- Pages with long exercise instructions
- Pages with multiple UI elements (header, progress, instructions, buttons)
- Landscape orientation

Making all three pages scrollable ensures:
- All content is accessible regardless of screen size
- Consistent user experience across the exercise flow
- Prevention of overflow errors and layout issues
- Better accessibility for users with different device sizes

## What Changes

- **Warmup Stretching Page**: Wrap the main content `Column` in `SingleChildScrollView` to enable scrolling
- **Cooldown Stretching Page**: Wrap the main content `Column` in `SingleChildScrollView` to enable scrolling
- **Record Exercise Page**: Verify and ensure `SingleChildScrollView` is properly configured (already has it, but verify implementation)
- **Layout Adjustments**: Ensure `Expanded` widgets are properly handled within scrollable contexts
- **Consistent Behavior**: All three pages should have the same scrolling behavior and constraints

## Impact

- Affected specs: recording-ui
- Affected code:
  - `lib/record/warmup_stretching_page.dart` - Add SingleChildScrollView wrapper
  - `lib/record/cooldown_stretching_page.dart` - Add SingleChildScrollView wrapper
  - `lib/record/record_exercise.dart` - Verify SingleChildScrollView implementation
- UX improvements: Better accessibility, no content overflow, consistent scrolling behavior
- No functional changes: All existing functionality remains unchanged, only layout structure modified

