## Context

The record exercise page needs a layout redesign to prioritize the camera feed, simplify controls, and align with the design patterns used in warmup_stretching_page.dart and cooldown_stretching_page.dart. The current implementation has visual clutter and usability issues that need to be addressed.

## Goals / Non-Goals

### Goals
- Camera feed becomes the primary visual focus
- Simplify interface by reducing visual clutter
- Consistent top bar design with dark red AppBar
- Optimize layout for 9:16 aspect ratio without scrolling
- Improve text readability in DraggableScrollableSheet
- Add camera toggle functionality
- Maintain all existing functionality (pain detection, timer, navigation)

### Non-Goals
- Changing pain detection functionality or logic
- Modifying exercise recording save logic
- Altering navigation flow
- Changing camera service architecture (only UI integration)

## Decisions

### Decision: Dark Red Top Bar Instead of Header Card
**Rationale**: 
- Consistent with warmup_stretching_page.dart (line 204: `backgroundColor: mainColor`) and cooldown_stretching_page.dart (uses AppBar with transparent background, but warmup uses dark red)
- Reduces visual clutter and frees up screen space for camera
- Maintains professional appearance with clear exercise name visibility

**Implementation**: 
- Replace `_buildEnhancedHeaderSection()` with standard AppBar
- Use `RecordingDesignSystem.primaryMedical` (Color(0xFF8B2E2E)) for background
- Display exercise name in AppBar title
- Include back button in AppBar leading

**Alternatives considered**:
- Keep enhanced header but reduce size - Rejected: Still creates clutter
- Use transparent AppBar like cooldown - Rejected: Warmup uses dark red, consistency preferred

### Decision: Simplified Button Design (Icon + Text Only)
**Rationale**:
- Saves horizontal space for camera widget
- Improves button clarity and reduces visual noise
- Aligns with minimalist medical design standards

**Implementation**:
- Remove decorative containers, extra icons, and padding
- Use Row with Icon on left and Text on right
- Maintain gradient backgrounds and colors for visual hierarchy
- Keep same functionality (navigation, pause, proceed)

**Alternatives considered**:
- Keep current enhanced buttons but reduce size - Rejected: Doesn't solve space issue
- Use icon-only buttons - Rejected: Less accessible, users need text labels

### Decision: Pain Overlay Repositioned to Camera Widget Bounds
**Rationale**:
- Currently positioned at screen edge (right: 20), making it disconnected from camera
- Should be within camera widget bounds for better visual association
- Top-right corner of camera preview is standard UI pattern for status overlays

**Implementation**:
- Change Positioned widget from `right: 20` to position relative to camera container
- Use `top: 20, right: 20` within camera Stack, not screen Stack
- Ensure overlay doesn't interfere with camera controls

**Alternatives considered**:
- Keep at screen edge but adjust styling - Rejected: Still disconnected from camera
- Move to bottom of camera - Rejected: May interfere with controls

### Decision: Camera Toggle Integration
**Rationale**:
- Users need ability to switch cameras during recording
- CameraService already has `switchCamera()` method (camera_service.dart:306)
- Common expectation in camera-based applications

**Implementation**:
- Add floating action button or icon button in camera preview area
- Use `CameraService.instance.switchCamera()` with camera index toggle
- Show camera icon (Icons.cameraswitch_rounded) in top-left or bottom-right of camera
- Handle camera initialization errors gracefully

**Alternatives considered**:
- Add to AppBar actions - Rejected: Less accessible during recording
- Add to control buttons row - Rejected: Takes space from primary actions

### Decision: DraggableScrollableSheet Text Readability Fix
**Rationale**:
- Current implementation uses white text (`Colors.white70`) which may not contrast well with white background in light mode
- Need proper contrast for accessibility and readability

**Implementation**:
- Use `RecordingDesignSystem.getTextPrimaryColor(context)` for text
- Adjust background color based on theme (dark/light)
- Increase font weight if needed for readability
- Ensure proper contrast ratios (WCAG AA minimum)

**Alternatives considered**:
- Keep white text but change background - Rejected: Background should match app theme
- Use semi-transparent overlay - Rejected: Reduces readability further

### Decision: 9:16 Layout Optimization
**Rationale**:
- Camera preview uses 9:16 aspect ratio
- All controls must be visible without scrolling
- Screen space is limited, requiring careful spacing

**Implementation**:
- Remove excessive padding and margins
- Optimize spacing between elements using RecordingDesignSystem constants
- Ensure camera preview doesn't exceed 50% of screen height
- Position controls in remaining space efficiently
- Use DraggableScrollableSheet for instructions (collapsed by default)

**Alternatives considered**:
- Make entire page scrollable - Rejected: Defeats purpose of fixed camera view
- Reduce camera size - Rejected: Camera is primary focus, should be prominent

## Risks / Trade-offs

### Risk: Camera Toggle May Cause Recording Interruption
**Mitigation**: 
- Test camera switching during active recording
- Ensure smooth transition without losing recording state
- Show loading indicator during camera switch if needed

### Risk: Simplified Buttons May Reduce Visual Hierarchy
**Mitigation**:
- Maintain gradient backgrounds and color coding
- Ensure sufficient size for touch targets (minimum 44x44)
- Test accessibility with screen readers

### Risk: Layout May Not Fit All Screen Sizes
**Mitigation**:
- Test on multiple device sizes during implementation
- Use responsive design patterns (MediaQuery)
- Consider adaptive layouts for tablets vs phones

### Trade-off: Reduced Header Information
**Trade-off**: Removing enhanced header reduces information display (exercise details, instructions)
**Solution**: Information moved to DraggableScrollableSheet which users can expand when needed

## Migration Plan

1. **Phase 1: Top Bar Replacement**
   - Replace enhanced header with AppBar
   - Test navigation and back button functionality
   - Verify exercise name display

2. **Phase 2: Camera Optimization**
   - Center camera widget
   - Reposition pain overlay
   - Add camera toggle button

3. **Phase 3: Button Simplification**
   - Simplify control buttons
   - Test all button functionality
   - Verify layout spacing

4. **Phase 4: DraggableScrollableSheet Fix**
   - Update text colors and contrast
   - Test readability in light/dark modes
   - Verify accessibility

5. **Phase 5: Layout Optimization**
   - Ensure 9:16 layout fits
   - Test on multiple screen sizes
   - Final visual consistency check

## Open Questions

- Should camera toggle be available immediately or only after camera initialization?
- Should pain overlay be dismissible or always visible?
- Should DraggableScrollableSheet default to expanded or collapsed state?




















