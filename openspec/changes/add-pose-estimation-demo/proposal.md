## Why

The application has a trained pose estimation model (`pose_estimation_model.pt`) that provides enhanced pose detection capabilities beyond the current Google ML Kit implementation. Users need a way to test and experience this custom model's functionality through a dedicated demo page accessible from the profile settings.

## What Changes

- **ADDED**: New pose estimation model demo page with camera integration
- **ADDED**: Custom pose detection service using the trained model
- **ADDED**: Skeleton overlay visualization matching ML Kit functionality
- **ADDED**: Demo page access card in profile page
- **ADDED**: Model conversion utilities for mobile deployment

## Impact

- Affected specs: pose-detection, camera-integration, profile-settings
- Affected code: 
  - New demo page: `lib/demo/pose_estimation_demo.dart`
  - Enhanced pose detection: `lib/data/custom_pose_detection_service.dart`
  - Profile page integration: `lib/profile/profile_page.dart`
  - Model management: `lib/data/pose_model_manager.dart`
