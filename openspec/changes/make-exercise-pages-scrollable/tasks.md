## 1. Warmup Stretching Page Scrollability
- [x] 1.1 Wrap main `Column` in `SingleChildScrollView` within `SafeArea`
- [x] 1.2 Replace `Expanded` widget for exercise instruction with `ConstrainedBox` or `Flexible`
- [x] 1.3 Add appropriate padding inside `SingleChildScrollView` for consistent spacing
- [ ] 1.4 Test scrolling behavior with different content lengths
- [ ] 1.5 Verify all content (header, progress, instructions, buttons) is accessible via scrolling
- [ ] 1.6 Test on different screen sizes (small, medium, large)
- [ ] 1.7 Test in portrait and landscape orientations

## 2. Cooldown Stretching Page Scrollability
- [x] 2.1 Wrap main `Column` in `SingleChildScrollView` within `SafeArea`
- [x] 2.2 Replace `Expanded` widget for exercise instruction with `ConstrainedBox` or `Flexible`
- [x] 2.3 Add appropriate padding inside `SingleChildScrollView` for consistent spacing
- [ ] 2.4 Test scrolling behavior with different content lengths
- [ ] 2.5 Verify all content (header, progress, instructions, buttons) is accessible via scrolling
- [ ] 2.6 Test on different screen sizes (small, medium, large)
- [ ] 2.7 Test in portrait and landscape orientations

## 3. Record Exercise Page Scrollability Verification
- [x] 3.1 Verify `SingleChildScrollView` is properly implemented
- [x] 3.2 Check for any `Expanded` widgets that might conflict with scrolling
- [x] 3.3 Verify camera preview widget works correctly within scrollable context
- [ ] 3.4 Test scrolling behavior with all content elements
- [ ] 3.5 Verify pain detection overlay and banner work correctly with scrolling
- [ ] 3.6 Test on different screen sizes
- [ ] 3.7 Test in portrait and landscape orientations

## 4. Layout Adjustments
- [x] 4.1 Ensure consistent padding and spacing across all three pages
- [x] 4.2 Verify `Expanded` widgets are properly replaced with scrollable-compatible alternatives
- [x] 4.3 Check that control buttons remain accessible when scrolling
- [x] 4.4 Verify header sections remain visible or scroll naturally
- [x] 4.5 Ensure no content is cut off or inaccessible

## 5. Exercise Instruction Widget Handling
- [x] 5.1 Update warmup page exercise instruction to use `ConstrainedBox` instead of `Expanded`
- [x] 5.2 Update cooldown page exercise instruction to use `ConstrainedBox` instead of `Expanded`
- [x] 5.3 Set appropriate `maxHeight` constraints (e.g., 40% of screen height)
- [ ] 5.4 Verify exercise instruction widget displays correctly with constraints
- [ ] 5.5 Test with different exercise instruction lengths

## 6. Testing and Validation
- [ ] 6.1 Test scrolling on small screen devices (< 5 inches)
- [ ] 6.2 Test scrolling on medium screen devices (5-6 inches)
- [ ] 6.3 Test scrolling on large screen devices (> 6 inches)
- [ ] 6.4 Test scrolling in portrait orientation
- [ ] 6.5 Test scrolling in landscape orientation
- [ ] 6.6 Test with long exercise instructions
- [ ] 6.7 Test with short exercise instructions
- [ ] 6.8 Verify no overflow errors occur
- [ ] 6.9 Test scrolling performance (smooth scrolling)
- [ ] 6.10 Verify all interactive elements remain functional during/after scrolling

## 7. Edge Cases
- [ ] 7.1 Test with very long exercise descriptions
- [ ] 7.2 Test with many exercise steps
- [ ] 7.3 Test when keyboard appears (if applicable)
- [ ] 7.4 Test with dynamic content changes (exercise progression)
- [ ] 7.5 Test with different font sizes (accessibility settings)
- [ ] 7.6 Verify scrolling works when content is updated dynamically

## 8. Code Quality
- [x] 8.1 Ensure consistent implementation across all three pages
- [x] 8.2 Remove any unused code or imports
- [x] 8.3 Add comments explaining scrollable structure if needed
- [x] 8.4 Verify no linting errors
- [x] 8.5 Ensure code follows project conventions

