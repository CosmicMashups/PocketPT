## Why

The current implementation of Google ML Kit Pose Detection for uploaded images and videos in `c_upload.dart` has several critical gaps that prevent proper pose detection, muscle angle analysis, and pain level assessment. The existing `processPhotoWithAssessment` method calls `PoseDetectionService.processPhotoForAssessment` but lacks proper preprocessing, error handling, and integration with the pain level assessment screen.

## What Changes

- **BREAKING**: Enhance `PoseDetectionService.processPhotoForAssessment` to include proper image preprocessing and validation
- **BREAKING**: Add comprehensive video processing support for uploaded videos using ML Kit pose detection
- **BREAKING**: Implement proper muscle angle analysis based on detected pose landmarks
- **BREAKING**: Create seamless integration between pose detection results and pain level assessment screen
- **BREAKING**: Add "Proceed" button functionality that automatically applies detected pain levels to the slider in `c_painlevel.dart`
- **BREAKING**: Enhance error handling and user feedback throughout the pose detection pipeline

## Impact

- Affected specs: pose-detection capability
- Affected code: 
  - `lib/data/pose_detection_service.dart` - Core pose detection logic
  - `lib/assessment/c_upload.dart` - Upload interface and processing
  - `lib/assessment/c_painlevel.dart` - Pain level assessment integration
  - `lib/assessment/c_preview.dart` - Preview screen for pose detection results

