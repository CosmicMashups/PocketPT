## Context

The PocketPT application currently has a robust pose detection system for real-time camera assessment, but the uploaded media processing pipeline has significant gaps. The `c_upload.dart` file attempts to use `PoseDetectionService.processPhotoForAssessment` but lacks proper preprocessing, comprehensive error handling, and seamless integration with the pain level assessment workflow.

## Goals / Non-Goals

### Goals:
- Fix and enhance pose detection for uploaded images and videos
- Implement proper image/video preprocessing before ML Kit processing
- Create comprehensive muscle angle analysis based on pose landmarks
- Integrate pose detection results seamlessly with pain level assessment
- Provide clear user feedback and error handling throughout the pipeline
- Maintain consistency with existing camera-based assessment functionality

### Non-Goals:
- Replacing the existing camera-based pose detection system
- Modifying the core ML Kit integration (only enhancing usage)
- Changing the overall assessment workflow structure
- Implementing new ML models (using existing Google ML Kit)

## Decisions

### Decision: Enhance existing PoseDetectionService rather than create new service
- **Rationale**: Maintains consistency with existing architecture and reuses proven ML Kit integration
- **Alternatives considered**: Creating separate service for uploaded media processing
- **Trade-offs**: Requires careful modification of existing service but ensures consistency

### Decision: Use same muscle angle analysis logic as camera assessment
- **Rationale**: Ensures consistency between camera and uploaded media assessments
- **Alternatives considered**: Creating separate analysis logic for uploaded media
- **Trade-offs**: Maintains consistency but requires careful parameter handling

### Decision: Integrate directly with existing pain level assessment screen
- **Rationale**: Provides seamless user experience and maintains existing UI patterns
- **Alternatives considered**: Creating separate pain level screen for uploaded media
- **Trade-offs**: Requires careful state management but provides better UX

## Risks / Trade-offs

- **Risk**: Modified pose detection service might affect existing camera functionality
- **Mitigation**: Thorough testing of both camera and uploaded media flows

- **Risk**: Performance issues with large video files
- **Mitigation**: Implement proper video preprocessing and frame sampling

- **Risk**: Inconsistent results between camera and uploaded media
- **Mitigation**: Use identical preprocessing and analysis logic

## Migration Plan

1. Enhance `PoseDetectionService.processPhotoForAssessment` with proper preprocessing
2. Add video processing support using existing ML Kit infrastructure
3. Update `c_upload.dart` to handle enhanced pose detection results
4. Modify `c_preview.dart` to display pose landmarks and assessment results
5. Add "Proceed" button functionality to `c_painlevel.dart`
6. Test thoroughly with various media types and conditions

## Open Questions

- Should we implement frame sampling for video processing to improve performance?
- How should we handle cases where pose detection fails completely?
- Should we add image quality validation before attempting pose detection?

