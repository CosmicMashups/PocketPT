## Why

The current AROM assessment camera flow (`c_camera.dart`) only performs pose detection and ROM measurement but lacks real-time pain recognition during the assessment. This creates a gap where users may experience pain during ROM exercises that goes undetected, potentially leading to unsafe exercise recommendations or missed opportunities for pain intervention.

The existing `FacialPainRecognitionService` is already implemented for exercise recording but is not integrated into the assessment flow. Users currently must manually report pain levels in a separate step (`c_painlevel.dart`), which may not accurately reflect the pain experienced during the actual ROM movement.

## What Changes

- **ADDED**: Real-time pain recognition during AROM assessment camera flow
- **ADDED**: Pain detection dialog for moderate/severe pain confirmation
- **ADDED**: Automatic pain level determination when face detection fails (3-second position hold)
- **MODIFIED**: Assessment flow to skip video preview and proceed directly to pain level confirmation
- **MODIFIED**: Integration of `FacialPainRecognitionService` into `c_camera.dart`
- **MODIFIED**: Enhanced recording flow to maintain both pose detection and pain recognition simultaneously

## Impact

- Affected specs: assessment capability
- Affected code: 
  - `lib/assessment/c_camera.dart` (main integration)
  - `lib/data/facial_pain_recognition_service.dart` (service integration)
  - `lib/assessment/c_painlevel.dart` (flow modification)
  - `lib/assessment/c_videopreview.dart` (bypass for direct flow)
- **BREAKING**: Assessment flow changes - users will no longer see video preview step
- **BREAKING**: Navigation flow modification - direct path from camera to pain level confirmation
