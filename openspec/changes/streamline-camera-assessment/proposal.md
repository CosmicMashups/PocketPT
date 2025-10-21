# Streamline Camera Assessment Interface

## Summary

Transform the camera assessment interface by removing the manual muscle selection dropdown and implementing automatic muscle group detection based on user selection from previous assessment screens. Enhance the UI/UX with improved design, layout, and comprehensive help functionality.

## Problem Statement

The current camera assessment interface requires users to manually select the muscle group for assessment via a dropdown menu, even though they have already selected a specific muscle in previous assessment screens. This creates redundancy and potential for user error. Additionally, the current interface lacks comprehensive help functionality and could benefit from improved visual design and user guidance.

## Proposed Solution

### Core Changes

1. **Remove Manual Muscle Selection**: Eliminate the dropdown menu for muscle selection in the app bar
2. **Implement Automatic Detection**: Use `UserAssess.specificMuscle` from previous screens to determine assessment algorithm
3. **Enhanced UI/UX**: Improve visual design, layout, and add comprehensive help system
4. **Dynamic Algorithm Mapping**: Map selected muscles to appropriate AROM assessment algorithms

### Key Benefits

- **Streamlined UX**: Eliminates redundant muscle selection step
- **Reduced User Error**: Automatic detection prevents mismatched assessments
- **Enhanced Guidance**: Comprehensive help system improves user confidence
- **Professional Design**: Healthcare-focused visual improvements
- **Better Accessibility**: Clear instructions and visual feedback

## Scope

### In Scope
- Remove muscle selection dropdown from camera assessment interface
- Implement automatic muscle-to-algorithm mapping
- Add comprehensive help dialog with step-by-step instructions
- Enhance visual design and layout of camera interface
- Maintain existing functionality for side selection and skeleton overlay
- Update assessment instructions to be muscle-specific

### Out of Scope
- Changes to other assessment screens (b_lowerbody, b_core, b_upperbody)
- Modifications to AROM assessment algorithms themselves
- Changes to pose detection or ML services
- Modifications to data persistence or sync functionality

## Success Criteria

1. **Functional**: Camera assessment automatically uses correct algorithm based on `UserAssess.specificMuscle`
2. **UX**: No manual muscle selection required, streamlined user flow
3. **Design**: Enhanced visual design with professional healthcare styling
4. **Help**: Comprehensive help system provides clear guidance for each muscle group
5. **Compatibility**: Maintains existing functionality for side selection and skeleton overlay

## Dependencies

- Existing AROM assessment algorithms in `lib/assessment/arom/`
- Current `UserAssess.specificMuscle` data flow from previous assessment screens
- Existing pose detection and camera services
- Current `AssessmentService` implementation

## Risks

- **Data Inconsistency**: If `UserAssess.specificMuscle` is empty or invalid, need fallback handling
- **Algorithm Mapping**: Ensuring all muscle groups map to appropriate algorithms
- **UI Complexity**: Adding help system without cluttering the interface
- **Performance**: Maintaining smooth camera performance with enhanced UI

## Implementation Notes

- Use existing muscle-to-algorithm mapping in `AssessmentService`
- Maintain backward compatibility with existing assessment flow
- Ensure graceful fallback for unknown muscle groups
- Preserve all existing camera and pose detection functionality
