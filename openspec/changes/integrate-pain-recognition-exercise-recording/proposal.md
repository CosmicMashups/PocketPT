## Why

The current exercise recording flow in `record_exercise.dart` lacks real-time pain detection capabilities. Users performing exercises may experience pain that goes undetected, potentially leading to injury or overexertion. The app has a trained 3-class pain recognition model (`pain_detection_model.pth`) that can detect Low/Moderate/Severe pain levels, but it's not integrated into the exercise recording workflow.

## What Changes

- **ADDED**: Real-time pain detection during exercise recording using the trained pain recognition model
- **ADDED**: Pain level-based user notifications and safety interventions
- **ADDED**: Integration with existing camera service for continuous pain monitoring
- **MODIFIED**: Exercise recording UI to display pain detection status and warnings
- **ADDED**: Pain-based exercise flow control (pause recommendations, safety dialogs)

## Impact

- **Affected specs**: exercise-recording capability
- **Affected code**: 
  - `lib/record/record_exercise.dart` - Main recording page
  - `lib/data/facial_pain_recognition_service.dart` - Pain detection service
  - `lib/record/camera_service.dart` - Camera integration
  - New pain detection UI components
- **Dependencies**: PyTorch model integration, face detection, camera processing
- **User Experience**: Enhanced safety through real-time pain monitoring and intervention
