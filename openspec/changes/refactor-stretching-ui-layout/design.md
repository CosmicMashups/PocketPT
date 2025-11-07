# Design: Stretching UI Layout Refactoring

## Overview

This design document outlines the UI refactoring approach for combining header and progress cards, removing redundant content, and better utilizing exercise data fields in the warmup and cooldown stretching pages.

## Current Layout Issues

1. **Excessive Vertical Space**: Two separate cards (header + progress) consume significant screen space
2. **Redundant Information**: Muscle group name, duration badges, and generic badges don't provide actionable guidance
3. **Underutilized Data**: Rich exercise data (steps, benefits, precautions) is not prominently displayed
4. **Poor Information Hierarchy**: Important exercise instructions are buried below decorative elements

## Proposed Layout

### Combined Header/Progress Card

The new combined card should include:
- **Title**: "Prepare Your Muscles" (warmup) or "Recovery & Relaxation" (cooldown) - keep the main title
- **Progress Indicator**: Compact progress bar showing current exercise (X of Y) and percentage
- **Current Exercise Name**: Display the name of the current exercise being performed
- **Timer**: Show remaining time for current exercise
- **Remove**: Muscle group text, generic badges, "Routine Progress" label and icon

### Enhanced Exercise Instruction Display

The exercise instruction widget should prominently display:
- **Description**: Exercise description at the top
- **Step-by-Step Instructions**: All available steps (step_1 through step_8) in a numbered list
- **Benefits Section**: Display benefit_1, benefit_2, benefit_3 in a visually distinct section
- **Precautions Section**: Display precaution_1, precaution_2, precaution_3 with warning styling

## Implementation Approach

1. **Refactor `_buildHeaderSection()`**: Combine with progress information, remove redundant elements
2. **Update `RoutineProgressWidget`**: Make it more compact, integrate into header section
3. **Enhance `ExerciseInstructionWidget`**: Better utilize all exercise data fields
4. **Maintain Design System**: Use existing `RecordingDesignSystem` constants for consistency

## Visual Hierarchy

1. **Primary**: Current exercise name and timer (most important during exercise)
2. **Secondary**: Progress indicator and exercise description
3. **Tertiary**: Step-by-step instructions
4. **Supporting**: Benefits and precautions (important but not primary focus)

## Space Savings

- **Before**: ~400-500px vertical space for header + progress cards
- **After**: ~200-250px for combined card
- **Gained**: ~200-250px additional space for exercise instructions

## Accessibility Considerations

- Maintain clear visual hierarchy for screen readers
- Ensure all text remains readable
- Keep touch targets appropriately sized
- Maintain color contrast ratios

