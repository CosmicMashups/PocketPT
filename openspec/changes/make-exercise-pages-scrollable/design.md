# Design: Making Exercise Pages Scrollable

## Overview

This design document outlines the changes needed to make warmup, record exercise, and cooldown pages scrollable, ensuring all content is accessible regardless of screen size.

## Current Implementation Analysis

### Warmup Stretching Page
- **Current Structure**: `SafeArea` → `Column` (direct children)
- **Issue**: `Column` is not scrollable, causing potential overflow
- **Solution**: Wrap `Column` in `SingleChildScrollView`

### Cooldown Stretching Page
- **Current Structure**: `SafeArea` → `Column` (direct children)
- **Issue**: `Column` is not scrollable, causing potential overflow
- **Solution**: Wrap `Column` in `SingleChildScrollView`

### Record Exercise Page
- **Current Structure**: `Stack` → `SingleChildScrollView` → `Column`
- **Status**: Already has `SingleChildScrollView`
- **Action**: Verify implementation is correct and handles all edge cases

## Design Considerations

### 1. Expanded Widgets in Scrollable Context

**Problem**: `Expanded` widgets cannot be used directly inside `SingleChildScrollView` because scrollable widgets have unbounded height.

**Solution**: 
- Replace `Expanded` with `Flexible` or remove it
- Use `ConstrainedBox` with `maxHeight` if needed
- Use `IntrinsicHeight` for equal-height children if required

### 2. Layout Structure

**Pattern for Warmup/Cooldown:**
```
SafeArea
  └─ SingleChildScrollView
      └─ Column
          ├─ Header Section
          ├─ Start Button (conditional)
          ├─ Progress Section (conditional)
          ├─ Exercise Instruction (with constraints)
          └─ Control Buttons (conditional)
```

**Pattern for Record Exercise:**
```
Stack
  ├─ SingleChildScrollView (already exists)
  │   └─ Column
  │       ├─ Title
  │       ├─ Camera Preview
  │       ├─ Timer
  │       └─ Control Buttons
  └─ DraggableScrollableSheet (instructions)
```

### 3. Exercise Instruction Widget Handling

**Current Issue**: Exercise instruction widget uses `Expanded` in warmup/cooldown pages.

**Solution Options**:
1. Remove `Expanded` and let widget size naturally
2. Use `ConstrainedBox` with `maxHeight` based on screen size
3. Use `Flexible` with `fit: FlexFit.loose`

**Recommended**: Use `ConstrainedBox` with `maxHeight: MediaQuery.of(context).size.height * 0.4` to ensure reasonable sizing while allowing scrolling.

### 4. Control Buttons Positioning

**Current**: Control buttons are at the bottom of the `Column`.

**With Scrolling**:
- Buttons will scroll with content (natural behavior)
- Alternative: Use `Stack` with positioned buttons (not recommended for consistency)
- Keep buttons in scrollable content for consistent UX

### 5. SafeArea and Padding

**Current**: `SafeArea` wraps the content.

**With Scrolling**:
- Keep `SafeArea` to respect system UI
- Add padding inside `SingleChildScrollView` for consistent spacing
- Ensure padding doesn't interfere with scrolling

## Implementation Approach

### Phase 1: Warmup Page
1. Wrap main `Column` in `SingleChildScrollView`
2. Replace `Expanded` with `ConstrainedBox` for exercise instruction
3. Test scrolling behavior
4. Verify all content is accessible

### Phase 2: Cooldown Page
1. Wrap main `Column` in `SingleChildScrollView`
2. Replace `Expanded` with `ConstrainedBox` for exercise instruction
3. Test scrolling behavior
4. Verify all content is accessible

### Phase 3: Record Exercise Page
1. Verify `SingleChildScrollView` implementation
2. Check for any `Expanded` widgets that might cause issues
3. Test scrolling behavior
4. Verify camera preview and other elements work correctly

## Edge Cases

1. **Very Long Content**: Ensure scrolling works smoothly with long exercise instructions
2. **Small Screens**: Verify all content is accessible on small devices
3. **Landscape Orientation**: Test scrolling in both portrait and landscape
4. **Keyboard Appearance**: Ensure scrolling works when keyboard appears (if applicable)
5. **Dynamic Content**: Verify scrolling works when content changes (e.g., exercise progression)

## Accessibility

- Ensure scrolling is smooth and responsive
- Maintain proper focus management during scrolling
- Verify screen reader compatibility
- Test with different font sizes (accessibility settings)

## Performance Considerations

- `SingleChildScrollView` is efficient for most use cases
- Consider `ListView.builder` if content becomes very long (not needed for current implementation)
- Ensure no unnecessary rebuilds during scrolling

