### Testing Phase – PocketPT

---

## Overview of Test Strategy

PocketPT is a Flutter / Firebase rehabilitation assistant with: camera-based pose and pain estimation, CSV-driven exercise/treatment planning, Hive-based local storage, Firebase sync, and a multi-page guided UI.  
The **testing strategy** combines: **functional tests** (module-by-module logic and error states), **integration tests** (end-to-end pipelines and data flows), **usability evaluation** (ISO 25010-aligned task-based tests and SUS), and **bug tracking** (structured defect logging and predicted high-risk areas).

---

## System Scope & Dependency Map (High-Level)

- **App shell & navigation**
  - **Entry point**: `main.dart` – initializes Firebase, Hive, adapters, `DataSyncService`, `AuthPersistenceService`, `DataPersistenceService`, notifications, tutorials, and themes; routes via `MyApp` → `AuthWrapper` → `HomePage`.
  - **Navigation**:
    - `AuthWrapper` → `AssessPrelim` (assessment) vs `HomePage` based on `UserDetails.hasCompletedAssessment`.
    - `HomePage` uses bottom nav + `CurvedNavigationBar` to switch: `DashboardPage`, `EditPlanPage`, `PreRecordPage`, `ReportPage`, `ProfilePage`.
- **State & data layer**
  - **Local storage (Hive)**: `main.dart` registers Hive adapters for user data, progress, assessment, plans, exercises, treatments, custom exercises; `DataPersistenceService` orchestrates auto-save and full-load; `User*` models in `data/globals.dart` hold in-memory state.
  - **Sync (Firebase)**: `DataSyncService` uses offline-first logic; merges Hive and Firebase with timestamp-based conflict resolution; uses Firestore collections (`users`, `assessment`, `progress`, `settings`, `painHistory`, `exerciseHistory`, custom exercises).
  - **Guest mode**: `GuestModeService` (web/offline) initializes and saves guest data without Firebase login.
- **Assessment & planner**
  - **Assessment flows**: multiple pages in `lib/assessment/` (`a_goal1.dart`, `b_*` muscle/joint pages, `c_*` pain level/type/duration/media pages, `d_*` history/muscle, `e_summary.dart`), sharing `AssessmentData` and `UserAssess` (Hive).
  - **ROM photo/video AROM**: `assessment/arom/*.dart` with `AssessmentService` / `AssessmentResult`; used by `PoseDetectionService` for photo/video analysis.
  - **Decision-tree planner**:
    - `generate_plan.dart` (UI + controller): sets `UserRehabilitation.instance` fields from `UserAssess`, generates rehab `RehabilitationPlan` from CSV via `ExerciseDataService`, and `TreatmentReference` via `generate_treatment.dart`.
    - `generate_treatment.dart`: CSV-driven filtering (muscle, pain level, duration) and treatment plan generation (core treatments T001–T003).
    - `data/rehabilitation_plan.dart`, `data/treatment.dart`, `data/hive_models.dart` (and generated `.g.dart`) define models and CSV ID mappings.
- **Camera / pose pipeline**
  - **Camera lifecycle**: `record/camera_service.dart` (singleton `CameraService`) manages `CameraController`, available cameras, switching, and error/loading UI; used by record pages and demos.
  - **Pose detection**: `data/pose_detection_service.dart` uses `google_mlkit_pose_detection` on camera or static images, normalizes landmarks (front-camera mirroring), computes joint angles, ROM, and compensations; integrates with `AssessmentService` for muscle-specific assessments and outputs clinical-context pain scores.
  - **ROM AROM flows**: `dailyAssessment/cameraPose.dart`, `demo/pose_estimation_demo.dart`, assessment AROM pages connect camera → pose → ROM assessment → UI.
- **Pain recognition pipeline**
  - **Facial pain**: `data/facial_pain_recognition_service.dart` manages PyTorch Lite model lifecycle via MethodChannel; converts `CameraImage` (YUV420) → RGB → face crop → normalized Float32 tensor; runs inference and maps logits to Low/Moderate/Severe pain with confidence; tracks stuck/confidence diagnostics.
  - Integrated into camera-based flows (daily assessment, recording) to adjust decision trees and UI messaging.
- **Exercise & recording flows**
  - **Exercise pages**: `exercise_list.dart`, `exercise_detail.dart`, `edit_plan.dart` read exercise CSV/plan data via `ExerciseDataService` and `UserRehabilitation`.
  - **Recording**: `record/pre_record_page.dart`, `record_exercise.dart`, `confirm_save_page.dart`, `warmup_stretching_page.dart`, `cooldown_stretching_page.dart`, `stopwatch_service.dart`, `exercise_cache_service.dart` manage the recording pipeline and logging to Hive/Firebase.
- **Stretching & tutorials**
  - **Stretching**: `stretching/` models, providers, services, widgets – uses same data stack with custom flows.
  - **Tutorials**: `tutorials/*` (config, models, preferences, analytics, overlay tooltip, showcase integration) plugged into `MyApp` and `HomePage` (FAB / keyboard shortcuts) for guided UX.
- **Authentication & onboarding**
  - **Auth**: `welcome/auth.dart` wraps `FirebaseAuth`.  
    Pages: `login_page.dart`, `register_page.dart`, `email_verification_page.dart`, `verification_code_page.dart`, `forgot_password_page.dart`, `new_password_page.dart`.
  - **Persistence**: `core/secure_auth_service.dart`, `data/auth_persistence_service.dart`, `data/firebase_auth_diagnostics.dart` (diagnostics); Hive-based auth state used by `AuthWrapper`.
- **Reports & exports**
  - `reports/report_page.dart`, `expanded_report_page.dart`, widgets (charts, calendars), and services (`reports_data_service.dart`, `pdf_export_service.dart`, `reports_repository.dart`) generate and export progress and pain charts.
- **Settings & misc**
  - `home_dialog.dart`, `profile/profile_page.dart`, settings in `data/globals.dart` / `UserSettings`, and global widgets (`widgets/*`) for loading, dialogs, sliders, skeleton overlays, etc.

---

## Functional Test Cases

**Conventions**

- **Columns**: ID, Module, Objective, Preconditions, Steps, Expected Result, Actual Output, Pass/Fail, Severity.
- **Placeholders**: *Actual Output* and *Pass/Fail* to be filled during execution; *Severity* used when Pass/Fail = Fail.
- Test IDs roughly grouped by module: `FT-AUTH-*`, `FT-ASS-*`, `FT-PLAN-*`, `FT-CAM-*`, `FT-POSE-*`, `FT-PAIN-*`, `FT-REC-*`, `FT-DATA-*`, `FT-REPORT-*`, `FT-UI-*`.

### 1. Authentication & Onboarding

| Test Case ID | Module | Objective | Preconditions | Test Steps | Expected Result | Actual Output | Pass/Fail | Severity (if fail) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| FT-AUTH-01 | Auth / `Auth.signInWithEmailAndPassword` | Verify successful login with valid credentials | Test user exists; email verified | 1. Launch app. 2. On `LoginPage`, enter valid email/password. 3. Tap Login. | User authenticated; `FirebaseAuth.currentUser` non-null; `AuthWrapper` shown; no error toast. |  |  | High |
| FT-AUTH-02 | Auth | Handle invalid password | Same email, wrong password | 1. Enter valid email but wrong password. 2. Tap Login. | Login fails; user remains unauthenticated; error message visible and clear; no crash. |  |  | High |
| FT-AUTH-03 | Auth | Handle unregistered email | Email not in Firebase | 1. Enter unknown email + any password. 2. Tap Login. | Error indicating account not found; no crash; no user created. |  |  | Medium |
| FT-AUTH-04 | Registration | Create new user | Unique test email | 1. Open `RegisterPage`. 2. Enter valid email/password. 3. Submit. | User created in Firebase; auth state non-null; user routed either to email verification or assessment flow per spec. |  |  | High |
| FT-AUTH-05 | Forgot password | Request reset email | Email exists | 1. Open `ForgotPasswordPage`. 2. Enter email. 3. Submit. | Reset email sent; confirmation message shown; no crash. |  |  | Medium |
| FT-AUTH-06 | Email verification | Verify flow gating | New unverified user | 1. Register. 2. Attempt navigation to main app without verifying. | App requests verification or restricts access per project rules; no silent bypass. |  |  | High |
| FT-AUTH-07 | Auth persistence | Restore auth from Hive on cold start | User logged in and state saved | 1. Log in. 2. Kill app. 3. Relaunch. | `AuthWrapper` sees authenticated user via `AuthPersistenceService.loadAuthStateFromHive`; auto-login without credential prompt. |  |  | High |
| FT-AUTH-08 | Logout | Clear auth and user data | User logged in | 1. Trigger logout from profile/settings. 2. Confirm. | Firebase session signed out; `DataSyncService.clearAllData` clears local user data; returned to login; no residual personal data in UI. |  |  | High |

### 2. Assessment Flow (Forms, Pain Inputs, AROM)

| Test Case ID | Module | Objective | Preconditions | Test Steps | Expected Result | Actual Output | Pass/Fail | Severity |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| FT-ASS-01 | Assessment pages (`a_goal1`, `b_*`, `c_*`, `d_*`, `e_summary`) | Complete full assessment with valid inputs | New authenticated or guest user; `UserAssess.isAssessed = false` | 1. From `AuthWrapper`, start assessment. 2. Fill rehab goal, region, specific muscle, pain scale, pain type, duration, history, etc. 3. Reach summary. | All inputs stored in `UserAssess` and `AssessmentData`; summary shows correct values; no crashes. |  |  | High |
| FT-ASS-02 | Assessment validation | Prevent incomplete submission | Leave mandatory fields blank | 1. Attempt to proceed from each page without required fields. | Inline validation shown; cannot proceed until fixed; no data corruption. |  |  | Medium |
| FT-ASS-03 | Pain scale mapping | Verify `UserAssess.painScale` matches selected slider / widget | None | 1. Set pain scale at multiple values (e.g., 0, 3, 7, 10). 2. Proceed and inspect stored value (via debug/log or test hook). | `UserAssess.painScale` equals UI selection; no off-by-one or rounding errors. |  |  | High |
| FT-ASS-04 | Severe pain branch | Ensure severe recent pain triggers different planning path | User selects Severe pain and pain within last 48h | 1. Set pain level = Severe, duration = “Less than 48 hours ago”. 2. Complete assessment, open `GeneratePlanPage`. | `generate_plan.dart` skips rehab plan generation; only treatments shown; `_getExerciseStatusMessage` explains caution; completion still possible. |  |  | High |
| FT-ASS-05 | AROM selection | Muscle-specific AROM assessment pages route correctly | AROM feature enabled | 1. Choose shoulder/arm AROM from assessment. 2. Follow prompts to photo/video assessment page. | Correct AROM page opens; correct `muscleGroup`/`side` passed to `PoseDetectionService` / `AssessmentService`. |  |  | Medium |
| FT-ASS-06 | Guest mode assessment | Assessment works offline guest | Web offline or mobile airplane mode; guest mode enabled | 1. Start app offline. 2. Run full assessment as guest. | All flows work; `GuestModeService` creates in-memory/Hive data; no Firebase calls; no crashes. |  |  | High |

### 3. Decision-Tree Exercise Planner / CSV Picker

| Test Case ID | Module | Objective | Preconditions | Steps | Expected Result | Actual Output | Pass/Fail | Severity |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| FT-PLAN-01 | `generate_plan.dart` basic plan | Generate plan for non-severe pain | `UserAssess` with moderate pain, appropriate muscle | 1. Set `UserAssess.specificMuscle`, `painLevel`, `painDuration` to a common combination with CSV entries. 2. Navigate to `GeneratePlanPage`. | `generateRehabilitationPlanFromCSV` returns non-null plan; `_rehabPlan.exerciseReferences` non-empty; exercises loaded and displayed. |  |  | High |
| FT-PLAN-02 | Treatments only branch | Severe or very recent pain path | `UserAssess` painScale ≥7 OR duration “Less than 48 hours ago” | 1. Configure assessment accordingly. 2. Open `GeneratePlanPage`. | No exercises; `_treatmentReferences` non-empty; UI shows status message about focusing on treatments; core treatments T001–T003 present. |  |  | High |
| FT-PLAN-03 | No matches error | Handle missing CSV matches | Use rare muscle/duration combination known to have no entries | 1. Set `UserAssess` to values with no CSV entries. 2. Generate plan. | `_error` set to “Not enough matching exercises or treatments”; error state UI shown; app remains responsive. |  |  | Medium |
| FT-PLAN-04 | CSV header robustness | Handle extra columns and malformed header | Treatment CSV includes extra columns or BOM | 1. Use real `treatment.csv` with known header quirks. 2. Trigger `loadTreatmentsFromCSV`. | Header normalized and truncated to expected columns; no crash; treatments count > 0. |  |  | Medium |
| FT-PLAN-05 | Treatment filtering | Verify `filterTreatments` logic for multi-valued levels/durations | Known row with multi-valued pain level/duration | 1. Provide `allTreatments` including multi-valued entries. 2. Call `filterTreatments` with exact and subset matches. | Matching treatments include those where `painLevel` and `painDuration` lists contain the target strings; no duplicates. |  |  | Medium |
| FT-PLAN-06 | Persistence after completion | Ensure plans and treatments saved to Hive/Firebase | Completed assessment and generated plan | 1. On `GeneratePlanPage`, tap “Complete Assessment & Go Home”. 2. Relaunch app. | `UserRehabilitation` plans and treatments restored; `ActiveProgram.startDate` set; `UserDetails.hasCompletedAssessment = true`; `AuthWrapper` routes to `HomePage`. |  |  | High |

### 4. Camera & Pose Estimation Pipeline

| Test Case ID | Module | Objective | Preconditions | Steps | Expected Result | Actual Output | Pass/Fail | Severity |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| FT-CAM-01 | `CameraService.initialize` basic | Initialize main camera successfully | Device with at least one camera | 1. Enter recording or AROM camera page. 2. Wait for initialization. | `CameraService.isReady == true`; preview shows live feed; `initializationStream` emits true; no error in `errorStream`. |  |  | High |
| FT-CAM-02 | Camera fallback | Handle failure and try next camera | Simulate failure of first camera (e.g., revoke permission or mock exception) | 1. Trigger initialization. | If first camera fails, service tries next index; either another camera succeeds or final failure surfaces via `errorStream` and UI error widget. |  |  | High |
| FT-CAM-03 | Disposed lifecycle | Prevent use after dispose | Initialize, then dispose | 1. Open camera page. 2. Navigate away causing `dispose`. 3. Return. | `_isDisposed` respected; old controller disposed; new initialization succeeds; no race conditions. |  |  | Medium |
| FT-POSE-01 | `detectFromCameraImage` success | Get pose list for valid image | Simulated `CameraImage` with person | 1. Pass test frame and camera description. | Returns non-empty `List<Pose>`; `_lastImageSize` updated; `_isFrontCamera` set correctly. |  |  | High |
| FT-POSE-02 | `detectFromCameraImage` error | Graceful handling of MLKit errors | Force invalid metadata or bad buffer | 1. Pass malformed image/metadata. | Function returns empty list; logs error; no throw to caller. |  |  | Medium |
| FT-POSE-03 | Landmark normalization | Correct mirroring and range | Known pose with distinct left/right coordinates | 1. Call `getPoseLandmarks`. | All offsets within \[0,1]; for front camera, x-coordinates mirrored; keys (`leftShoulder`, `rightShoulder`, etc.) populated as expected. |  |  | High |
| FT-POSE-04 | ROM assessment map | `performComprehensiveROMAssessment` returns structured result | Synthetic landmarks with known angles | 1. Provide landmarks that yield angles in severe, moderate, low, good ranges. | `overallPainScore` matches ROM → pain mapping; `overallROMStatus` correct; `clinicalContext` non-empty; compensations present when thresholds exceeded. |  |  | High |
| FT-POSE-05 | Photo assessment | `processPhotoForAssessment` | Valid photo with clear posture | 1. Call with real or test image. | When pose detected: `success=true`, non-null `assessmentResult` and `landmarks`, confidence between 0–1; error suggestions only on failure. |  |  | High |

### 5. Pain Recognition Pipeline (Facial)

| Test Case ID | Module | Objective | Preconditions | Steps | Expected Result | Actual Output | Pass/Fail | Severity |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| FT-PAIN-01 | Model initialization | Load PyTorch Lite model and initialize | Device with PyTorch Mobile integration; asset present | 1. Call `FacialPainRecognitionService.initialize()`. | Model bytes loaded from assets to temp; `_modelPath` set; `_usePyTorchMobile = true`; `_verifyPyTorchMobile` completes; no thrown exception. |  |  | High |
| FT-PAIN-02 | Null model handling | Error when model not loaded | Skip `initialize` | 1. Call `detectFacialPain` with any frame. | Returns error “Model not loaded”; `painLevel` remains last or null; app does not crash. |  |  | High |
| FT-PAIN-03 | YUV conversion | Correct RGB output size | Valid `CameraImage` | 1. Call `_convertYUV420ToRGB`. | Output length = width × height × 3; no out-of-range reads; no exceptions. |  |  | Medium |
| FT-PAIN-04 | Preprocessing variation | Ensure `_preprocessImageForPyTorch` produces non-constant tensor for varied images | Use two different face crops | 1. Preprocess two distinct images. | Float32 arrays differ; min/max not all zero; `normalizeMean`/`normalizeStd` applied correctly. |  |  | High |
| FT-PAIN-05 | Inference path | Softmax + argmax mapping correct | Model initialized; deterministic test input | 1. Run `_runPyTorchInference` on a fixed image. | Output logits length ≥3; probabilities sum to 1; predicted index in 0..2; label from `['Low','Moderate','Severe']`. |  |  | High |
| FT-PAIN-06 | Timeout | Processing timeout handled | Inject long-running `_processPainDetection` | 1. Call `detectFacialPain`. | After 5s, returns cached last prediction without hang; logged TimeoutException; UI remains responsive. |  |  | High |
| FT-PAIN-07 | Confidence history | Diagnostics when confidence stuck | Simulate identical frames repeatedly | 1. Feed identical input 10 times. | `_recentConfidences` filled; “confidence stuck” diagnostics logged; prediction still returned; no crash. |  |  | Medium |

### 6. Recording & History Logging

| Test Case ID | Module | Objective | Preconditions | Steps | Expected Result | Actual Output | Pass/Fail | Severity |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| FT-REC-01 | Start recording flow | Pre-record → record → confirm | Plan exists; recording permitted | 1. From `HomePage` tab or nav item, open `PreRecordPage`. 2. Start recording. 3. Complete exercise. 4. Confirm save. | Exercise entry added to `ExerciseHistory`; Hive updated; optional Firebase sync; UI transitions correct. |  |  | High |
| FT-REC-02 | Cancel recording | Ensure cancelled sessions not logged | Start but cancel before save | 1. Start recording and back out/cancel. | No new history entry; any temp caches cleared. |  |  | Medium |
| FT-REC-03 | Warmup/cooldown | Warmup/cooldown flows | Plan present | 1. Start warmup; perform exercise; complete. 2. Repeat for cooldown. | Entries recorded (if designed); UI and timers behave; no double-logging. |  |  | Medium |
| FT-REC-04 | Stopwatch accuracy | `StopwatchService` timing | None | 1. Start stopwatch; wait known interval; stop. | Duration matches real time within tolerance; persisted duration used in history entry. |  |  | Low |

### 7. Data Persistence & Sync (Hive / Firebase)

| Test Case ID | Module | Objective | Preconditions | Steps | Expected Result | Actual Output | Pass/Fail | Severity |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| FT-DATA-01 | Auto-save timer | `DataPersistenceService` periodic save | User has some data | 1. Interact to change data. 2. Wait > `_autoSaveDelay`. | `_performAutoSave` triggered; Hive box contains updated data; `lastSaveTimestamp` set. |  |  | High |
| FT-DATA-02 | Force save | `forceSave` concurrency | Existing save in progress | 1. Trigger auto-save. 2. Immediately call `forceSave`. | Second call waits until first completes; eventually performs new save; no deadlock. |  |  | High |
| FT-DATA-03 | Backup/restore | `createBackup` and `restoreFromBackup` | Non-empty Hive box | 1. Create backup. 2. Modify data. 3. Restore from backup. | State after restore matches snapshot; all keys restored except metadata; app functions. |  |  | High |
| FT-DATA-04 | Offline sync skip | `DataSyncService.syncAllData` when unauthenticated | No Firebase user | 1. Call `syncAllData`. | Returns `success=false`, message “Sync skipped - user not authenticated”; Hive remains unchanged. |  |  | Medium |
| FT-DATA-05 | Sync merge | Timestamp-based merge logic | Both Hive and Firebase have user/assessment/progress/settings with different timestamps | 1. Prepare test data with local newer vs remote newer. 2. Call `syncAllData`. | For each category, newer side “wins”; merged data applied to memory and Hive; no duplication of history. |  |  | High |
| FT-DATA-06 | Force save to Firebase | `forceSaveToFirebase` | User logged in | 1. Modify local data. 2. Call `forceSaveToFirebase`. | All relevant collections updated; timestamp returned; no errors for existing collections. |  |  | High |
| FT-DATA-07 | Data integrity | `validateDataIntegrity` | Some data present | 1. Call validation. | Returns `success=true` for consistent data; turning off data (e.g., missing userDetails) yields `success=false`. |  |  | Medium |

### 8. Reports & Export

| Test Case ID | Module | Objective | Preconditions | Steps | Expected Result | Actual Output | Pass/Fail | Severity |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| FT-REPORT-01 | Report data rendering | `ReportPage` summary | History entries present | 1. Open `ReportPage`. | Charts reflect actual pain/exercise history; no exceptions when arrays empty; tooltips and legends visible. |  |  | Medium |
| FT-REPORT-02 | PDF export | `pdf_export_service.dart` | Some data; storage permission granted | 1. Tap “Export to PDF”. | PDF generated, saved, or shared; contains correct charts and tables; error message on permission errors. |  |  | High |

### 9. UI / Navigation / Theming

| Test Case ID | Module | Objective | Preconditions | Steps | Expected Result | Actual Output | Pass/Fail | Severity |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| FT-UI-01 | Bottom navigation | `HomePage` tab switching | Authenticated, completed assessment | 1. Tap each tab; 2. Switch back and forth. | Correct pages shown; `IndexedStack` preserves state; record tab opens `PreRecordPage` with route name `/pre-record`. |  |  | Medium |
| FT-UI-02 | Theme persistence | ThemeController via Hive | Dark mode toggles available | 1. Switch to dark theme. 2. Restart app. | Theme remains dark; `ThemeController.loadFromHive` successful; no flicker. |  |  | Low |
| FT-UI-03 | Offline banner | Web offline mode | Web offline | 1. Start web app offline. | `web_offline.isWebOffline()` true; `DashboardPage` as home; offline copy and guest mode active; no Firebase initialization attempt. |  |  | Medium |
| FT-UI-04 | Tutorial shortcuts | Tutorial shortcut keys | Desktop keyboard | 1. On `HomePage`, press Shift+/ or F1. | `_ShowTutorialIntent` triggers; tutorial flow starts for appropriate tab; snack shown if no tutorial. |  |  | Low |

---

## Integration Test Cases

**Focus**: end-to-end flows, async interactions, race conditions, and frame-time constraints.

### 1. Camera → Pose Model → ROM → Exercise Validation

| Test Case ID | Integration | Objective | Preconditions | Steps | Expected Result | Actual Output | Pass/Fail | Severity |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| IT-POSE-01 | Camera → PoseDetectionService (stream) | Validate streaming pose detection pipeline | Device with camera; MLKit available | 1. Open AROM or demo pose page. 2. Keep camera on moving subject. | Continuous `detectFromCameraImage` results; UI overlay (skeleton) updates; no frame drops beyond acceptable; no memory leaks. |  |  | High |
| IT-POSE-02 | Camera → Pose → `AssessmentService` | Verify ROM score used in page UI | Same as above | 1. Perform shoulder/triceps movements. 2. Observe ROM labels/pain score. | UI displays consistent ROM category and pain (severe/moderate/low/good) in line with underlying angles. |  |  | High |
| IT-POSE-03 | ROM → Plan generator | ROM output modifies plan | ROM-driven pain scale integrated with `UserAssess` | 1. Complete AROM; ensure produced ROM status “severe”. 2. Generate plan. | Decision tree sees severe ROM/pain; shows treatments-only or restricted exercises per spec. |  |  | High |

### 2. Camera → Pain Model → Decision Tree Modification

| Test Case ID | Integration | Objective | Preconditions | Steps | Expected Result | Actual Output | Pass/Fail | Severity |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| IT-PAIN-01 | Camera → FacialPainRecognitionService | Real-time pain overlay | Camera and PyTorch ready | 1. Open pain-recognition-enabled view. 2. Change facial expression (neutral vs pain mimic). | Real-time `painLevel` and confidence change; no constant outputs; UI updates overlay; frame processing within ~16–32ms budget on modern device. |  |  | High |
| IT-PAIN-02 | Pain → Assessment/Plan | Pain model informs decisions | Pain model enabled; thresholds defined | 1. Run facial pain detection during assessment/recording. 2. Continue to plan generation. | If model indicates high pain, plan adjusted or warnings shown (per integration design); logs reflect correct branch. |  |  | High |

### 3. User Assessment Form → Database → Plan Generator

| Test Case ID | Integration | Objective | Preconditions | Steps | Expected Result | Actual Output | Pass/Fail | Severity |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| IT-PLAN-01 | Assessment → Hive → GeneratePlanPage | Confirm plan uses stored assessment | Fresh user | 1. Complete assessment. 2. Kill app. 3. Relaunch; open generate plan. | `UserAssess` reloaded from Hive; `UserRehabilitation.selected*` set; generated plan matches original criteria. |  |  | High |
| IT-PLAN-02 | Assessment → Firebase → New device | Cross-device consistent plan | Same user logs in on second device | 1. Device A: complete assessment and generate plan. 2. Force save to Firebase. 3. Device B: login, run `DataSyncService.loadAllFromFirebase`, open plan page. | Plan and treatments replicate; progress consistent; no divergence between devices. |  |  | High |

### 4. Local Storage (Hive) ↔ Firebase Sync

| Test Case ID | Integration | Objective | Preconditions | Steps | Expected Result | Actual Output | Pass/Fail | Severity |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| IT-SYNC-01 | Offline use → Sync queue → Firebase | Offline-first robustness | User logs in; network offline | 1. Go offline. 2. Log several exercises & pain entries. 3. Bring network online. 4. Call `syncAllData` or auto-sync. | All offline actions queued and then persisted in Firebase; no duplicate or lost entries; lastModified amalgamated correctly. |  |  | High |
| IT-SYNC-02 | Conflict resolution | Newer side wins | Modify data on both local and remote | 1. Device A offline: update settings. 2. Device B online: change same settings later. 3. Sync. | Latest timestamp (Device B) takes precedence; Device A’s Hive updated; no loops. |  |  | High |
| IT-SYNC-03 | Force save + auto-save | Ensure no race | Auto-save timer enabled; user triggers force save | 1. Let auto-save start; call `forceSaveToFirebase` mid-process. | Saves serialized and not interleaved incorrectly; final state consistent in Hive and Firebase. |  |  | Medium |

### 5. UI Interaction → State Manager → Inference Cycle

| Test Case ID | Integration | Objective | Preconditions | Steps | Expected Result | Actual Output | Pass/Fail | Severity |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| IT-UI-01 | Play/pause camera flows | Avoid multiple controllers | Rapid tab and route changes | 1. Open camera recording. 2. Rapidly navigate back and forth across tabs and routes. | At most one active `CameraController`; no thrown exceptions; preview always comes back. |  |  | High |
| IT-UI-02 | Tutorial + camera | Shortcuts + overlay with camera active | Tutorials configured | 1. On camera tab, start tutorial (FAB or shortcut). | Tutorial overlay does not break camera stream; gestures still functional; overlay instructions visible. |  |  | Medium |

**Concurrency & Frame-Time Checks**

- Measure frame timings (already instrumented in `MyApp` via `SchedulerBinding.addTimingsCallback`):
  - Validate no systematic slow frames during:
    - Continuous pose detection.
    - Pain model inference.
    - Combined camera + recording UI.
- Introduce stress tests (rapid UI navigation while background saves and syncs run) to catch race conditions around:
  - `CameraService.initialize`/`dispose`.
  - `DataPersistenceService.forceSave`.
  - `DataSyncService.syncAllData`.

---

## Usability Testing Framework

### 1. Framework Alignment

- **Standards**
  - **ISO 25010**: Focus on **Usability** attributes – appropriateness recognizability, learnability, operability, user error protection, attractiveness, accessibility.
  - **SUS (System Usability Scale)**: 10-item SUS questionnaire after tasks; compute SUS score (0–100).
- **Participants**
  - Target: 8–15 representative users (mixed clinical/lay users).
- **Data Types**
  - **Quantitative**: Task completion time, success rate, error counts, SUS score, subjective ratings (1–7 Likert).
  - **Qualitative**: Think-aloud comments, post-task interviews.

### 2. Core User Tasks

For each task: define **Goal**, **Scenario**, **Success Criteria**, **Metrics**, and **Observation Checklist**.

#### Task U1 – Completing an Initial Assessment

- **Goal**: User can complete the full assessment without assistance.
- **Scenario**: “You’ve just installed PocketPT and want a personalized rehab plan.”
- **Steps** (for participant, loosely guided):
  1. Log in or proceed as guest (if offered).
  2. Complete each assessment page (goals, body region, muscle, pain, history).
  3. Reach summary and generate a plan.
- **Success Criteria**:
  - Completed without hard failure.
  - Max 1 clarification request.
- **Metrics**:
  - Time to complete.
  - Number of validation errors.
  - Number of navigation missteps (backtracking, wrong pages).
  - User rating of ease-of-use (1–7).
- **Observation**:
  - Are labels and hints clear?
  - Do users understand “rehab goal” and muscle names?
  - Confusion around severe pain warnings?

#### Task U2 – Starting Camera-Based Pose Tracking / AROM Assessment

- **Goal**: User can start and interpret an AROM camera assessment.
- **Scenario**: “You want to check your shoulder mobility using your camera.”
- **Steps**:
  1. From main app, navigate to an AROM camera assessment.
  2. Start camera; allow permissions.
  3. Perform prompt (e.g., shoulder raise).
  4. View ROM result and interpretation.
- **Metrics**:
  - Time to find and start assessment.
  - Number of failed attempts due to camera permissions or orientation.
- **Observation**:
  - Are low-light and camera errors clearly communicated?
  - Do users understand overlay skeleton and ROM labels?

#### Task U3 – Performing Guided Exercises from a Plan

- **Goal**: User follows daily plan and completes an exercise session.
- **Scenario**: “Follow today’s rehab plan and complete at least one set.”
- **Steps**:
  1. Open dashboard and find today’s plan.
  2. Open a recommended exercise.
  3. Start recording (if required); follow instructions.
  4. Save/completion; verify it appears in logs.
- **Metrics**:
  - Time to start the first exercise.
  - Errors (wrong exercise, confusion about sets/reps).
- **Observation**:
  - Understanding of icons, reps/sets, pain-level prompts.
  - Clarity of call-to-action for starting/stopping.

#### Task U4 – Viewing Activity Logs and Reports

- **Goal**: User finds and interprets progress and pain reports.
- **Scenario**: “Check how your pain has changed over the last week.”
- **Steps**:
  1. Navigate to reports tab.
  2. Locate pain history chart and daily summary.
  3. Optionally export PDF.
- **Metrics**:
  - Time to locate reports.
  - Ability to correctly answer comprehension questions (e.g., “Was your pain better on day X?”).
- **Observation**:
  - Chart labeling and legend clarity.
  - Overload vs summarization (too much data?).

#### Task U5 – Adjusting Settings (Reminders, Theme) and Handling Errors

- **Goal**: User adjusts preferences and responds correctly to transient errors.
- **Scenario**: “Adjust your reminder time and handle a low-light camera warning.”
- **Steps**:
  1. Find settings (profile or settings area).
  2. Change exercise reminder time.
  3. Start a camera-based feature in low light to provoke a warning.
- **Metrics**:
  - Time to locate settings.
  - Number of misclicks.
- **Observation**:
  - Comprehension of error messages (low light, network, model loading delay).
  - Perception of helpfulness and tone of system feedback.

### 3. SUS Questionnaire (Post-Session)

- Administer standard SUS 10-item questionnaire.
- Compute SUS score; target:
  - **≥ 80**: Excellent.
  - **70–80**: Acceptable.
  - **< 70**: Usability improvements required.

---

## Bug Tracking Template

Use this table for manuscript appendix and internal QA:

| Field | Description |
| --- | --- |
| **Bug ID** | Unique ID, e.g., `BUG-CAM-001` |
| **Title** | Short summary of the issue |
| **Module / Area** | e.g., CameraService, PoseDetection, GeneratePlanPage, DataSyncService |
| **Environment** | Device, OS, app version, network (online/offline), web/mobile |
| **Severity** | Critical / High / Medium / Low |
| **Priority** | P1 / P2 / P3 |
| **Reporter** | Name or tester ID |
| **Date Reported** | Date |
| **Preconditions** | Setup steps or state before reproduction |
| **Steps to Reproduce** | Step-by-step reproduction instructions |
| **Expected Result** | What should have happened |
| **Actual Result** | What actually happened |
| **Logs / Screenshots** | Relevant logs (stack traces, debug prints) and screenshots |
| **Workaround** | Temporary mitigation if any |
| **Status** | Open / In Progress / Fixed / Won’t Fix / Deferred |
| **Fix Version** | Version containing the fix |
| **Root Cause** | Summary of underlying cause after triage |
| **Resolution Details** | Code and design changes applied to fix |

---

## Predicted Bug List (Risk-Based)

These are **likely defect areas** based on code patterns and integration complexity; they should be prioritized in exploratory and regression testing.

- **Camera & lifecycle**
  - **BUG-RISK-CAM-01**: `CameraService.initialize` race when multiple pages request camera nearly simultaneously, leading to `isDisposed` true while initialization is in progress.
  - **BUG-RISK-CAM-02**: Switching cameras or navigating away during initialization yields disposed `CameraController` exceptions.
  - **BUG-RISK-CAM-03**: Aspect ratio mismatch between camera preview and overlay widgets causing stretched or misaligned skeleton.

- **Pose & ROM**
  - **BUG-RISK-POSE-01**: `_lastImageSize` not set for static images, resulting in fallback `(0.5,0.5)` landmarks and bogus ROM outputs.
  - **BUG-RISK-POSE-02**: Front-camera mirroring inconsistencies: stored landmarks mirrored while UI or decision logic assumes non-mirrored coordinates.
  - **BUG-RISK-POSE-03**: `calculateAngle` degeneracies for near-collinear points causing noisy ROM classification at angle thresholds.

- **Pain recognition (PyTorch)**
  - **BUG-RISK-PAIN-01**: Path or permission errors for model file writing in `_loadModel`, especially on web or constrained storage environments.
  - **BUG-RISK-PAIN-02**: MethodChannel contract mismatch (input type or shape) causing `run` method failures or null outputs.
  - **BUG-RISK-PAIN-03**: Confidence “stuck” scenarios where either preprocessing or model output is effectively constant, leading to non-varying pain levels.
  - **BUG-RISK-PAIN-04**: Timeouts in `detectFacialPain` under heavy load; repeated fallbacks to cached predictions reduce responsiveness to real facial changes.

- **Decision tree & CSV**
  - **BUG-RISK-PLAN-01**: CSV header normalization fails on subtle BOM/spacing variations, silently resulting in zero or incorrect matches.
  - **BUG-RISK-PLAN-02**: Index mismatches between `RehabilitationPlan.exerciseReferences` and actual CSV rows cause broken exercise lookups or missing videos.
  - **BUG-RISK-PLAN-03**: Edge cases where no exercises and no treatments are found but severe pain logic still expects treatments, leading to confusing status messages.

- **Data persistence & sync**
  - **BUG-RISK-DATA-01**: `DataPersistenceService.saveAllDataToHive` called when Hive box is not open or adapters not registered on some platforms (web vs mobile divergence).
  - **BUG-RISK-DATA-02**: Infinite or repeated sync attempts when Firebase write fails, leading to high battery/network usage.
  - **BUG-RISK-DATA-03**: Time-window conflicts where `lastModified` fields are null or inconsistent across User/Assess/Settings, leading to wrong side “winning” in `_merge*Data`.
  - **BUG-RISK-DATA-04**: `DataSyncService.loadAllFromFirebase` combined with `DataPersistenceService.loadAllDataFromHive` causing overwrites in unexpected order.

- **Reports & export**
  - **BUG-RISK-REPORT-01**: Empty histories causing chart widget crashes (null arrays, division by zero, missing domain axes).
  - **BUG-RISK-REPORT-02**: PDF generation failing on platforms without storage permission or with limited file system access.

- **Usability / UI**
  - **BUG-RISK-UI-01**: Overly dense UI in `GeneratePlanPage` causing slow frames (complex layout + many cards) on low-end devices.
  - **BUG-RISK-UI-02**: Tutorial overlays conflicting with gestures on camera and recording pages, blocking critical buttons.
  - **BUG-RISK-UI-03**: Inconsistent error messaging for low-light, model loading, or network issues leading to user confusion.

---

## Final Testing Phase Documentation (Manuscript-Ready Outline)

### 1. Overview of Test Strategy

PocketPT was tested using a multi-layered strategy combining **automated and manual functional tests**, **integration tests across sensor/ML/data boundaries**, and **task-based usability evaluations** following ISO 25010 and SUS. The system under test included Flutter-based UI, Hive-based local persistence, Firebase-backed cloud sync, ML-based pose and facial pain inference, a CSV-driven exercise/treatment planner, and camera-based AROM and pain modules.

### 2. Functional Testing Summary

Functional test suites were defined per module (authentication/onboarding, assessment forms, decision-tree planner, ROM and pain models, recording, data persistence, reports, and UI navigation). Test cases achieved coverage of:
- All user input branches, including severe vs non-severe pain, recent vs chronic pain, and guest vs authenticated usage.
- Error handling for camera initialization, ML inference failures, malformed CSV data, Hive/Firebase availability, and offline mode.
- Data lifecycle operations, including creation, update, auto-save, backup/restore, and integrity checks.

A representative subset of functional test cases is included in **Appendix A** (tables FT-XXXX), with fields for objective, preconditions, steps, expected/actual result, and severity.

### 3. Integration Testing Summary

Integration tests exercised the **camera → pose → ROM → plan** pipeline, the **camera → facial pain model → decision logic** path, and the **assessment → local storage → cloud sync → plan generation** flows. Offline-first behavior was validated by simulating connectivity loss and reconnection, verifying correct operation of the sync queue and timestamp-based conflict resolution. Stress scenarios (rapid navigation during background saves and syncs) were used to detect race conditions, particularly for camera lifecycle and data persistence.

Integration test matrices and scenarios are summarized in **Appendix B** (IT-XXXX), with particular focus on frame-time constraints and concurrency.

### 4. Usability Testing Summary

Usability was evaluated via structured user tasks:
- Completing the initial assessment and generating a plan.
- Starting camera-based pose/AROM tracking.
- Following guided exercises and recording sessions.
- Reviewing progress and pain reports.
- Adjusting reminders and themes, and handling error conditions.

Participants completed tasks under think-aloud protocols; task completion rates, times, and error counts were recorded. SUS questionnaires were administered at the end of each session, and scores were aggregated to derive an overall usability rating. Qualitative findings highlighted areas of strength (visual design consistency, onboarding flow) and areas for refinement (medical terminology clarity, error message specificity).

### 5. Testing Outcomes & QA Sign-Off

Testing outcomes were documented in a structured bug log (see **Appendix C**), with defects categorized by severity and mapped back to modules and integration paths. Critical and high-severity defects were addressed prior to sign-off, in particular:
- Camera lifecycle stability across navigation.
- Robustness of pose and pain inference in low-quality input scenarios.
- Correctness of CSV-driven planner logic and data sync behavior.

A QA sign-off was issued once:
- All critical/high-severity issues were resolved or explicitly waived with justification.
- Regression testing confirmed stability of camera, ML, and data flows on target platforms.
- Usability metrics met the predefined thresholds (e.g., SUS ≥ target score).

### 6. Bug Documentation & Resolution Workflow

Bugs were recorded using the standardized template (Bug ID, title, module, environment, severity, reproduction steps, expected vs actual, root cause, and fix version). The workflow consisted of:
1. **Triage**: Assign severity/priority and owner.
2. **Diagnosis**: Use logs (`debugPrint`, ML model diagnostics, sync stats) to localize defects.
3. **Resolution**: Apply minimal, spec-aligned code changes, with unit/integration tests added for regressions.
4. **Verification**: Re-run affected functional and integration tests.
5. **Regression & Closure**: Regress critical paths (auth, assessment, recording, sync) before closing issues.

Detailed bug and test-case tables are intended for inclusion as appendices to the manuscript, providing transparent evidence of system validation across functionality, integration robustness, and user-centered usability.









