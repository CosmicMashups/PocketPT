# Design: Enhanced Record Exercise Page Design

## Overview

This design document outlines the application of enhanced design patterns from warmup and cooldown stretching pages to the record exercise page, while preserving all existing functionality including the camera widget with pain detection.

## Current Design Issues

1. **Inconsistent Styling**: Record exercise page uses basic Material Design components that don't match the enhanced aesthetic of warmup/cooldown pages
2. **Basic AppBar**: Current AppBar is simple and doesn't use the enhanced header pattern
3. **Plain Buttons**: Control buttons lack the gradient styling and enhanced appearance
4. **Inconsistent Spacing**: Spacing doesn't follow the design system constants consistently
5. **Basic Timer Display**: Timer display is functional but lacks the enhanced styling

## Design Patterns to Apply

### 1. Enhanced Header Section

**Pattern from warmup/cooldown:**
- Container with gradient background
- Icon in styled container with gradient
- Title with proper typography hierarchy
- Info banner with gradient background
- Proper spacing using design system constants

**Application to record_exercise:**
- Replace AppBar with enhanced header section
- Include exercise name prominently
- Add info banner about exercise recording
- Use gradient backgrounds and proper styling

### 2. Enhanced Timer Display

**Pattern from warmup/cooldown:**
- Gradient background container
- Icon + text layout
- Proper spacing and padding
- Design system shadows

**Application to record_exercise:**
- Update timer display to match enhanced styling
- Use gradient background
- Add timer icon
- Apply proper spacing

### 3. Enhanced Control Buttons

**Pattern from warmup/cooldown:**
- Gradient backgrounds
- Icon + label layout
- Proper padding and spacing
- Design system shadows and borders
- Enhanced visual feedback

**Application to record_exercise:**
- Replace Back, Pause, and Proceed buttons with enhanced versions
- Apply gradient styling
- Use design system constants
- Maintain all existing functionality

### 4. Camera Widget Integration

**Critical Requirement:**
- Camera preview widget must remain unchanged
- Pain detection overlay must remain functional
- All camera-related functionality preserved
- Pain detection UI elements (overlay, banner, dialogs) unchanged

### 5. Layout Improvements

**Pattern from warmup/cooldown:**
- Consistent use of `RecordingDesignSystem.spacing*` constants
- Proper use of `RecordingDesignSystem.radius*` constants
- Design system shadows (`RecordingDesignSystem.shadow*`)
- Proper use of gradients (`RecordingDesignSystem.*Gradient`)

**Application to record_exercise:**
- Update all spacing to use design system constants
- Apply consistent border radii
- Use design system shadows
- Apply gradients where appropriate

## Visual Hierarchy

1. **Header Section**: Top of page, enhanced styling, exercise information
2. **Camera Preview**: Prominent, full-width, retains all functionality
3. **Timer Display**: Enhanced styling, clear visibility
4. **Control Buttons**: Enhanced styling, clear hierarchy
5. **Instructions Sheet**: Bottom sheet remains unchanged

## Color Scheme

- Use `RecordingDesignSystem.primaryMedical` for primary actions
- Use `RecordingDesignSystem.successColor` for positive actions
- Use `RecordingDesignSystem.warningColor` for pause actions
- Use `RecordingDesignSystem.errorColor` for error states
- Use gradients from design system for enhanced visual appeal

## Spacing and Layout

- Header: `RecordingDesignSystem.spacingL` padding
- Camera: Full width with minimal padding
- Timer: `RecordingDesignSystem.spacingM` padding
- Buttons: `RecordingDesignSystem.spacingL` padding
- Consistent use of design system spacing constants

## Accessibility

- Maintain all existing accessibility features
- Ensure enhanced buttons remain accessible
- Preserve screen reader support
- Maintain keyboard navigation

## Implementation Approach

1. **Phase 1**: Update header section to enhanced design
2. **Phase 2**: Update timer display styling
3. **Phase 3**: Update control buttons with enhanced styling
4. **Phase 4**: Apply consistent spacing and layout improvements
5. **Phase 5**: Verify camera and pain detection functionality unchanged

## Edge Cases

1. **Camera Not Available**: Loading state should use enhanced styling
2. **Pain Detection Disabled**: Overlay should gracefully handle disabled state
3. **Different Screen Sizes**: Enhanced design should be responsive
4. **Dark Mode**: All enhanced elements should support dark mode via design system

