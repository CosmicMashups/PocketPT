# Extend Photo-Based ROM Assessment

## Summary

Extend the existing camera assessment functionality to support photo-based ROM assessments by implementing Google ML Kit Pose Detection for uploaded/taken photos, displaying pose skeletons with pain level detection, and creating a preview interface for user confirmation.

## Why

The current assessment system only supports real-time camera assessment, limiting user flexibility and assessment options. Users cannot upload existing photos or review assessment results before proceeding, which reduces the accuracy and user control of the ROM assessment process. This extension will provide users with more assessment options while maintaining the same high-quality pose detection and muscle assessment algorithms.

## What Changes

This change extends the existing camera assessment functionality to support photo-based ROM assessments by:

1. **Extending Upload Functionality**: Integrate pose detection and assessment for both photo capture and gallery upload options in `c_upload.dart`
2. **Creating Photo Preview Interface**: New `c_preview.dart` page showing photos with pose skeleton overlay and pain level detection
3. **Implementing Unified Assessment Pipeline**: Reuse existing muscle assessment algorithms and pose detection infrastructure
4. **Adding User Control Options**: Provide intuitive options to retake, proceed, or adjust assessment results

## Problem Statement

The current assessment system only supports real-time camera assessment with pose detection. Users cannot upload existing photos or capture photos for assessment, limiting the flexibility of the ROM assessment workflow. Additionally, there's no preview interface for users to review their captured/uploaded photos with pose detection results before proceeding with the assessment.

## Proposed Solution

### Core Changes

1. **Extend Upload Functionality**: Integrate pose detection and assessment for both photo capture and gallery upload options
2. **Create Photo Preview Interface**: New preview page showing photos with pose skeleton overlay and pain level detection
3. **Unified Assessment Pipeline**: Reuse existing muscle assessment algorithms and pose detection infrastructure
4. **Seamless User Flow**: Provide intuitive options to retake, proceed, or adjust assessment results

### Key Benefits

- **Enhanced Flexibility**: Users can assess from existing photos or capture new ones
- **Consistent Assessment**: Same pose detection and muscle assessment algorithms as camera mode
- **User Control**: Preview interface allows users to verify results before proceeding
- **Professional UX**: Maintains healthcare-focused design and user experience standards
- **Performance Optimized**: Efficient image processing with loading indicators and error handling

## Scope

### In Scope
- Extend `c_upload.dart` to integrate pose detection for photo capture and gallery upload
- Create new `c_preview.dart` page for photo review with pose skeleton overlay
- Implement pain level detection and display for uploaded photos
- Add user actions (retake, proceed, adjust) in preview interface
- Integrate with existing muscle assessment algorithms and pose detection services
- Maintain professional healthcare styling and user experience

### Out of Scope
- Video upload assessment (separate feature)
- New muscle assessment algorithms
- Changes to existing camera assessment functionality
- Modifications to pose detection service core functionality
- Changes to data persistence or sync systems

## Success Criteria

1. **Functional**: Photos automatically processed with pose detection and muscle assessment
2. **UX**: Intuitive preview interface with clear pain level visualization
3. **Integration**: Seamless integration with existing assessment workflow
4. **Performance**: Fast photo processing with appropriate loading indicators
5. **Reliability**: Robust error handling for edge cases and poor image quality

## Dependencies

- Existing `PoseDetectionService` for image-based pose detection
- Current `AssessmentService` and muscle assessment algorithms
- Existing muscle-to-algorithm mapping from camera assessment
- Current `UserAssess.specificMuscle` data flow
- Professional healthcare styling and UI components

## Risks

- **Image Quality**: Poor quality photos may result in inaccurate pose detection
- **Performance**: Large image processing may impact app performance
- **User Experience**: Additional steps in assessment flow may confuse users
- **Memory Management**: Large images may cause memory issues on low-end devices
- **Error Handling**: Complex error scenarios need comprehensive handling

## Implementation Notes

- Reuse existing pose detection infrastructure (`PoseDetectionService.detectFromImageFile`)
- Leverage current muscle assessment algorithms via `AssessmentService.assess()`
- Maintain consistency with camera assessment workflow and styling
- Implement proper loading states and error recovery mechanisms
- Ensure responsive design for different screen sizes and orientations
