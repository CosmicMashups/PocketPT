## Why
The assessment module flow has several critical issues that prevent proper AI model integration and create navigation problems. The current flow incorrectly routes from `c_paintype.dart` directly to `c_upload.dart`, bypassing the proper sequence. The "Take Photo" and "Upload from Gallery" buttons in `c_upload.dart` are non-functional placeholders. The AI model integration exists but is not properly connected to the media capture workflow. The navigation from `c_paintype.dart` should go to `c_painduration.dart` instead of `c_upload.dart`, and `c_upload.dart` should only be accessible when "Record Video" is toggled.

## What Changes
- **BREAKING**: Fix navigation sequence so `c_paintype.dart` proceeds to `c_painduration.dart` instead of `c_upload.dart`
- **BREAKING**: Ensure `c_upload.dart` comes after all `b_*.dart` files except `b_focus1.dart` in the flow
- **BREAKING**: Make `c_video.dart` only accessible when "Record Video" option is toggled
- Implement functional "Take Photo" and "Upload from Gallery" buttons with proper camera/gallery access
- Integrate AI model preparation into photo/video capture functions
- Connect pose estimation model to return skeleton-overlayed media with keypoint coordinates
- Connect pain recognition model to use keypoint values for muscle pain evaluation
- Ensure AI processing runs asynchronously without freezing UI
- Verify smooth integration with Hive and Firebase synchronization
- Confirm no widget layout or rendering issues occur throughout the flow

## Impact
- Affected specs: assessment flow navigation, AI model integration, media capture functionality
- Affected code: `lib/assessment/c_paintype.dart`, `lib/assessment/c_upload.dart`, `lib/assessment/c_video.dart`, `lib/assessment/c_painduration.dart`, `lib/assessment/c_camera.dart`, `lib/data/pose_detection_service.dart`, `lib/data/cnn_pose_detection_service.dart`, `lib/data/facial_pain_recognition_service.dart`
- Breaking changes to navigation flow require careful testing of all assessment paths
