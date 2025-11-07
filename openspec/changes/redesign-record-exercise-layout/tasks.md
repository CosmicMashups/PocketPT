## 1. Top Bar Replacement
- [x] 1.1 Remove `_buildEnhancedHeaderSection()` method
- [x] 1.2 Replace with standard AppBar using `RecordingDesignSystem.primaryMedical` background
- [x] 1.3 Display exercise name in AppBar title
- [x] 1.4 Add back button in AppBar leading with proper styling
- [ ] 1.5 Test navigation and back button functionality
- [ ] 1.6 Verify visual consistency with warmup_stretching_page.dart

## 2. Camera Widget Optimization
- [x] 2.1 Ensure camera preview is properly centered in layout
- [x] 2.2 Verify camera widget takes appropriate screen space (max 50% height)
- [ ] 2.3 Test camera initialization and preview display
- [x] 2.4 Ensure 9:16 aspect ratio is maintained

## 3. Pain Overlay Repositioning
- [x] 3.1 Move pain detection overlay from screen edge to camera widget bounds
- [x] 3.2 Position overlay at top-right corner within camera Stack
- [ ] 3.3 Test overlay visibility and positioning
- [x] 3.4 Verify overlay doesn't interfere with camera controls
- [ ] 3.5 Test overlay animations and transitions

## 4. Camera Toggle Implementation
- [x] 4.1 Add camera toggle button in camera preview area
- [x] 4.2 Integrate with `CameraService.instance.switchCamera()` method
- [x] 4.3 Handle camera switching logic (front/rear toggle)
- [x] 4.4 Add loading indicator during camera switch if needed
- [ ] 4.5 Test camera switching during active recording
- [x] 4.6 Handle errors gracefully (no second camera, initialization failures)
- [x] 4.7 Verify camera state persistence after switch

## 5. Button Simplification
- [x] 5.1 Simplify `_buildEnhancedCustomButton()` to icon + text only
- [x] 5.2 Remove decorative containers and extra icons
- [x] 5.3 Remove unnecessary padding and spacing
- [x] 5.4 Maintain gradient backgrounds and color coding
- [x] 5.5 Ensure minimum touch target size (44x44)
- [ ] 5.6 Test all button functionality (back, pause, proceed)
- [ ] 5.7 Verify button accessibility (screen readers, keyboard navigation)

## 6. DraggableScrollableSheet Readability Fix
- [x] 6.1 Update text colors to use `RecordingDesignSystem.getTextPrimaryColor(context)`
- [x] 6.2 Fix background color based on theme (dark/light)
- [x] 6.3 Adjust font weights for better readability
- [x] 6.4 Ensure proper contrast ratios (WCAG AA minimum)
- [ ] 6.5 Test readability in light mode
- [ ] 6.6 Test readability in dark mode
- [ ] 6.7 Verify accessibility standards

## 7. Layout Optimization for 9:16
- [x] 7.1 Remove excessive padding and margins
- [x] 7.2 Optimize spacing using RecordingDesignSystem constants
- [x] 7.3 Ensure camera preview doesn't exceed screen constraints
- [x] 7.4 Position controls efficiently in remaining space
- [x] 7.5 Verify no scrolling required for main content
- [ ] 7.6 Test layout on multiple screen sizes
- [ ] 7.7 Test layout in portrait orientation
- [x] 7.8 Ensure DraggableScrollableSheet works correctly when collapsed

## 8. Design System Consistency
- [x] 8.1 Verify all colors use RecordingDesignSystem methods
- [x] 8.2 Verify all spacing uses RecordingDesignSystem constants
- [x] 8.3 Verify all border radii use RecordingDesignSystem constants
- [x] 8.4 Verify shadows use RecordingDesignSystem shadows
- [x] 8.5 Ensure typography uses RecordingDesignSystem styles
- [x] 8.6 Compare with warmup_stretching_page.dart and cooldown_stretching_page.dart for consistency

## 9. Functionality Preservation
- [ ] 9.1 Verify camera initialization works correctly
- [ ] 9.2 Verify pain detection overlay functions correctly
- [ ] 9.3 Verify pain detection banner functions correctly
- [ ] 9.4 Verify pain detection dialogs function correctly
- [ ] 9.5 Verify timer functionality unchanged
- [ ] 9.6 Verify navigation (back, proceed, pause) works correctly
- [ ] 9.7 Verify exercise recording and saving works correctly
- [ ] 9.8 Test all pain detection scenarios (low, moderate, severe)

## 10. Testing and Validation
- [ ] 10.1 Test on Android devices (various screen sizes)
- [ ] 10.2 Test on iOS devices (various screen sizes)
- [ ] 10.3 Test on web (if applicable)
- [ ] 10.4 Test dark mode support
- [ ] 10.5 Test light mode support
- [ ] 10.6 Test accessibility (screen readers, keyboard navigation)
- [ ] 10.7 Test camera toggle on devices with single camera
- [ ] 10.8 Test camera toggle on devices with multiple cameras
- [ ] 10.9 Performance test (frame rate, memory usage)
- [ ] 10.10 Visual regression test (compare before/after screenshots)

## 11. Code Quality
- [ ] 11.1 Remove unused imports
- [ ] 11.2 Ensure code follows project conventions
- [ ] 11.3 Add comments for complex layout logic
- [ ] 11.4 Verify no linting errors
- [ ] 11.5 Ensure proper widget organization
- [ ] 11.6 Verify no memory leaks (camera controller disposal)

