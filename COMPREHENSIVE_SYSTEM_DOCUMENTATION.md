# PocketPT Comprehensive System Documentation

This document fulfills the comprehensive documentation requirements in `openspec/changes/comprehensive-app-review` by providing:

1. A full-system functional analysis of every significant software component and the way it collaborates with related modules.
2. A developer- and user-facing design specification that doubles as a user manual, covering the structure and interface contract of every screen.
3. A complete installation and deployment guide that explains both Android APK sideload distribution (e.g., Google Drive) and the GitHub Pages-based web deployment pipeline.

---

## 1. Functional Software Component Analysis

### 1.1 Application Shell, Lifecycle, and Navigation
| Component | Location | Role | Interactions |
| --- | --- | --- | --- |
| `main.dart` entry point | `lib/main.dart` | Initializes Flutter bindings, enforces portrait orientation on mobile, conditionally initializes Firebase/Hive, registers Hive adapters, boots core services, and launches the Riverpod `ProviderScope`. | Depends on `Firebase.initializeApp`, `Hive.initFlutter`, `GuestModeService`, `DataSyncService`, `AuthPersistenceService`, `AssetLoadingService`, `LocalNotificationsService`, `ThemeController`, `AuthPersistenceService`, `DataPersistenceService`, `AutoSaveService`, and tutorial services to establish global infrastructure before rendering UI. |
| `MyApp` + lifecycle observer | `lib/main.dart` | Wraps the app in Material theme, monitors lifecycle changes (`didChangeAppLifecycleState`), triggers `DataPersistenceService.forceSave` and `DataSyncService.forceSaveToFirebase` on backgrounding, and re-syncs authentication on resume. | Uses `kIsWeb` guards to avoid Hive writes on web, calls `AuthPersistenceService.forceAuthCheck`, `AuthPersistenceService.instance.syncAllData`, and ensures data reload is deferred to feature dashboards. |
| `HomePage` navigation shell | `lib/main.dart` | Hosts the CurvedNavigationBar tabs: Dashboard, Edit Plan, Pre-Record (recording flow), Reports, Profile. Also exposes a Drawer with branding copy and keyboard shortcuts (Shift+/ or F1) to replay tutorials. | Each tab widget is a rich feature module that can trigger service calls; `HomePage` notifies `DataPersistenceService.instance.unloadUserData` when leaving Dashboard and pushes dedicated routes (e.g., `MedicalPageRoute` to `PreRecordPage`). |

### 1.2 Core Data & Service Layer
| Component | Location | Responsibilities | Consumers |
| --- | --- | --- | --- |
| `DataPersistenceService` | `lib/data/data_persistence_service.dart` | Debounced auto-saving of all Hive-backed domain models, lazy loading (`loadUserDataIfNeeded`), backup/restore helpers, integrity validation, and metadata tracking. | `main.dart`, Dashboard, Reports, Profile, plan/treatment screens call into it to ensure in-memory caches mirror Hive. |
| `DataSyncService` | `lib/data/data_sync_service.dart` | Offline-first orchestrator that loads Hive, ensures auth, flushes `SyncQueue`, fetches Firebase collections, merges/normalizes data, saves merged state to Hive, and pushes local changes back to Firebase. Also exposes `forceSaveToFirebase`, `loadAllFromFirebase`, and diagnostic integrity checks. | `AuthPersistenceService`, `main.dart`, manual sync triggers (Profile, reports), record flows prior to saving sessions. |
| `AuthPersistenceService` | `lib/data/auth_persistence_service.dart` | Wraps `FirebaseAuth`, tracks auth state in Hive, handles login/logout transitions, ensures tokens stay fresh, seeds `DataSyncService`. Provides `ensureAuthentication`, `saveAuthStateToHive`, `loadAuthStateFromHive`, and `syncAllData`. | All authentication UI flows, lifecycle hooks, background sync, and guest-mode toggles. |
| `UserDataNotifier` | `lib/data/user_data_notifier.dart` | Bridges static domain singletons (e.g., `UserDetails`, `UserRehabilitation`) with widgets via `ChangeNotifier`, broadcasting when plan/treatment data changes and relaying user profile metadata. | Dashboard, Reports, Profile, plan/treatment editors subscribe to reflect latest data. |
| Repository scaffolding | `lib/core/providers/app_providers.dart` et al. | Riverpod providers for error handling (`ErrorHandler`), secure auth (`SecureAuthService`), and user repository implementations (Hive-backed). Also defines `AuthStateNotifier` for future Riverpod-based auth flows. | Future migrations to replace static classes; currently provides injection points for new screens/tests. |
| Auxiliary Services | `lib/data/*` | Includes `GuestModeService` (web-offline fallback), `LocalNotificationsService`, `AutoSaveService`, `AssetLoadingService`, `NavigationService`, `CustomExerciseService`, `ExerciseDataService`, `FacialPainRecognitionService`, `PoseDetectionService`, and multiple diagnostics utilities. | Feature modules surface their functionality (e.g., recording uses camera + pain service, plan editors rely on exercise/treatment services). |

### 1.3 Welcome & Authentication Module
| Screen/Component | Location | Functionality | Key Interactions |
| --- | --- | --- | --- |
| `LoginPage` | `lib/welcome/login_page.dart` | Provides email/password login, Google Sign-In hook, guest mode entry, progressive loading UI, and web-only prototype disclaimer. Initiates background data prefetch after navigation. | Calls `SimpleAuthService.signInWithEmailAndPassword`, `GuestModeService.initialize/startGuestSession`, `OptimizedDataService.preloadData`, and eventually `AuthPersistenceService`/`DataSyncService` via `HomePage`. |
| `RegisterPage`, `ForgotPasswordPage`, `NewPasswordPage`, `VerificationCodePage` | `lib/welcome/*` | Manage account creation, password reset, and verification code entry flows with consistent UI theming. | Use `SimpleAuthService` and Firebase Auth to create accounts, send verification codes, and update credentials. |
| `SimpleEmailVerificationPage` | `lib/welcome/email_verification_page.dart` | Polls for email verification, auto-signs user back in using stored temp credentials, rate-limits resend attempts, and navigates home or back to login when complete. | Uses `SimpleAuthService.isEmailVerified()`, `sendEmailVerification()`, `signInWithEmailAndPassword()`, interacts with Navigator stack for post-verification routing. |

### 1.4 Assessment Module
Key files: `lib/assessment/*` (e.g., `preliminary.dart`, `a_goal1.dart`, `b_*`, `c_*`, `d_*`, `e_summary.dart`).

* **Workflow:** Users proceed through goal selection, muscle targeting, pain characterization (`c_painlevel.dart`, `c_paintype.dart`, etc.), recording uploads, muscle history, and summary review.
* **Services:** Screens rely on `AssessmentData` (session-local state), `UserAssess` (persistent state), `muscle_injury_dialog_service.dart`, and `UserRehabilitation` for plan generation parameters.
* **Generate Plan:** `generate_plan.dart` orchestrates CSV-backed exercise plan creation plus treatment recommendations. It sets `UserRehabilitation.instance` fields, calls `generateRehabilitationPlanFromCSV`, and always generates treatments via `generate_treatment.dart`. It persists plan/treatment IDs to Hive/Firebase and toggles severity-specific warning UI.

### 1.5 Daily Assessment & Pain Tracking
* `dailyAssessment/painLevel.dart` renders a slider with emoji/description states, writes to `UserAssess`, and can launch `dailyAssessment/cameraPose.dart` or `dailyAssessment/instructionVideo.dart` for ROM capture reminders.
* `dailyAssessment/cameraPose.dart` leverages pose detection utilities to capture quick daily metrics.

### 1.6 Dashboard Module
* `dashboard/dashboard_page.dart` lazy-loads all data (via `DataPersistenceService` + `UserDataNotifier`), displays plan cards, progress stats, notification center, and rehydrates tutorials. 
* It caches exercise/treatment futures per ID to avoid redundant Hive/CSV reads and re-triggers `UserDataNotifier` when plans change.

### 1.7 Exercise & Treatment Module
* `exercise/exercise_list.dart` + `exercise_detail.dart`: parse CSV assets and custom exercises, provide searchable cards, support selection mode for replacements/additions.
* `exercise/edit_plan.dart`: loads treatment details, maps plan IDs to user-friendly names, allows notes, refresh/regenerate treatments, and injects custom exercises via `CustomExerciseService`. Tracks dependencies on `UserRehabilitation` and `ExerciseDataService`.
* `CustomExerciseService` (data layer) manages Hive persistence (`rehabBox`), Firestore storage (per-user subcollection), caching, conflict merges, and deletion.

### 1.8 Recording Module
| Component | File | Responsibilities |
| --- | --- | --- |
| `PreRecordPage`, `warmup_stretching_page.dart`, `cooldown_stretching_page.dart` | `lib/record` | Guide the user through setup steps, optional stretches, and environment preparation before and after recording. |
| `RecordExercisePage` | `lib/record/record_exercise.dart` | Core recorder: binds to `CameraService`, orchestrates `FacialPainRecognitionService` (PyTorch Lite model), uses `ExerciseCacheService` for fetch and caching, logs stopwatch timing, triggers tutorials, monitors pain levels with threshold-based interventions (banners, dialogs) and toggles camera (front/back). |
| `CameraService`, `StopwatchService`, `ExerciseCacheService` | `lib/record/*.dart` | Manage multi-camera initialization, ensure stream disposal, keep stopwatch state, and cache heavy exercise metadata for quick reuse. |
| `FacialPainRecognitionService` | `lib/data/facial_pain_recognition_service.dart` | Loads `assets/model/pain_recognition_model.ptl`, copies it to temp storage, initializes PyTorch Mobile via `MethodChannel`, processes `CameraImage` frames at ~5 FPS, extracts facial pain predictions with confidences, and exposes last-known prediction for analytics. |
| `PoseDetectionService` | `lib/data/pose_detection_service.dart` | Wraps Google ML Kit pose detection for live camera streams and still photos, provides ROM assessments through `AssessmentService`, and normalizes landmarks for UI overlays. |

### 1.9 Reports & Analytics Module
* `reports/report_page.dart`: Riverpod-driven page that listens to `reportsDataProvider` (in `reports/services/reports_data_service.dart`), surfaces charts (`pain_level_chart.dart`), rehab plan expansions, calendar views, and PDF export controls.
* `reports/widgets/export_pdf_button.dart`: orchestrates loading state, errors, and action triggers for `PDFExportService`.
* `PDFExportService` in `reports/services/pdf_export_service.dart` fetches latest Firestore data, composes professional multi-page PDF reports (assessment summary, data freshness, progress stats, history tables), and uses `printing` package to share/print both on mobile and web.

### 1.10 Profile & Settings Module
* `profile/profile_page.dart`: Displays user identity, reminders, guest mode indicators, diagnostics (PDF export shortcuts, pose demo), and integrates with `UserSettings`, `AuthPersistenceService`, `GuestModeService`, and `DataPersistenceService`.
* Handles logout by clearing Hive data (through `DataSyncService.clearAllData`) and re-routing to `LoginPage`.

### 1.11 Tutorials, Widgets, and Shared UI
* `tutorials/*`: Maintains `TutorialRegistry`, `TutorialPreferences`, analytics hooks, overlays (`showcase_integration.dart`, `tutorial_service.dart`) used in Dashboard, Record, Report, and Profile to provide step-by-step onboarding.
* `widgets/*`: Contains UI primitives (responsive dialogs, loading indicators, progressive loading widget) reused across modules.

### 1.12 Notifications, Guest Mode, and Background Services
* `data/local_notifications_service.dart`: Manages scheduling, cancellation, and initialization of local notifications (non-web platforms).
* `data/guest_mode_service.dart`: Enables offline-only operation, starting guest sessions when Firebase is unavailable (most relevant on web offline detection via `web/offline_web.dart`).
* `data/navigation_service.dart`, `data/widget_cache_service.dart`, `data/performance_service.dart`: provide asynchronous navigation, caching, and telemetry utilities leveraged by high-level flows.

### 1.13 Data Flow Summary
1. **UI layer (pages/widgets)** emits intents (e.g., login, assessment submission, recording completion).
2. **State/Notifier layer** (`UserDataNotifier`, Riverpod providers) updates domain singletons and notifies interested widgets.
3. **Service layer** (Auth/Data persistence/sync, custom services) handles persistence, remote calls, ML inference, and other side effects.
4. **Storage layer** (Hive `rehabBox`, Firebase Auth/Firestore/Storage) persists final state and acts as sync source of truth.

Cross-module dependencies include:
* Assessment screens -> `AssessmentData` -> `UserAssess` & `UserRehabilitation`.
* Dashboard, Reports, Profile -> `UserDataNotifier` -> data services.
* Recording -> `CameraService` + `FacialPainRecognitionService` -> `ExerciseHistory` (persisted via `DataPersistenceService`).
* Reports -> `ReportsDataService` -> `UserProgress`, `PainHistory`, `ExerciseHistory`.

---

## 2. Design Specification Document (User Manual Guide)

### 2.1 Modular Layout Overview
| Module | Screens | Primary Interfaces |
| --- | --- | --- |
| Welcome & Auth | Login, Register, Forgot Password, New Password, Verification Code, Email Verification | `SimpleAuthService`, `AuthPersistenceService`, `DataSyncService`, Navigator routes |
| Dashboard | DashboardPage | `UserDataNotifier`, `DataPersistenceService`, plan/treatment caches |
| Assessment | Preliminary, Goal selection (`a_goal1`), muscle focus (`b_*`), camera/pain (`c_*`), history (`d_*`), summary (`e_summary`), plan generation (`generate_plan`, `generate_treatment`) | `AssessmentData`, `UserAssess`, `UserRehabilitation`, `generateRehabilitationPlanFromCSV`, `generateTreatmentPlan` |
| Exercise Management | Exercise list/detail, edit plan | `ExerciseDataService`, `CustomExerciseService`, `UserRehabilitation` |
| Recording | PreRecord, RecordExercise, ConfirmSave, Warmup/Cooldown, design system components | `CameraService`, `FacialPainRecognitionService`, `PoseDetectionService`, `StopwatchService`, `ExerciseCacheService`, `ExerciseHistory`, `PainHistory` |
| Daily Assessment | PainLevel, InstructionVideo, CameraPose | `UserAssess`, `AssessmentData`, `PoseDetectionService` |
| Reports | ReportPage, expanded report, providers/services/widgets, PDF export | `ReportsDataService`, Riverpod providers, `PDFExportService` |
| Profile | ProfilePage | `UserDataNotifier`, `AuthPersistenceService`, `UserSettings`, `GuestModeService` |
| Tutorials | Tutorial registry/preferences/services | `TutorialPreferences`, `TutorialService`, `TutorialRegistry` |

### 2.2 Screen-by-Screen Interface Contracts & UX

#### Welcome Flow
1. **Login Page**
   * Inputs: email, password (validated via `_formKey`).
   * Actions: sign in (calls `_authService.signInWithEmailAndPassword`), Google sign-in (optional), guest mode.
   * Feedback: progressive indicator (`_loadingMessage`, `_loadingProgress`), error strings.
   * Navigation: successful login -> `HomePage`, unverified -> `SimpleEmailVerificationPage`, guest -> `HomePage` with guest session banner.
2. **Register Page**
   * Collects identity plus password, calls Firebase Auth create user, then navigates to email verification.
3. **Email Verification Page**
   * Periodically polls `SimpleAuthService.isEmailVerified`.
   * Auto-login path uses stored password.
   * Provides resend with cap (`maxResendAttempts=3`).

#### Assessment & Plan Generation
1. **Preliminary & Multi-step forms** (Goal, body focus, pain type/level/duration, video uploads, muscle history).
2. **Summary** consolidates inputs, ensures `AssessmentData.isComplete`.
3. **Generate Plan**
   * Auto-launches `_loadPlan()` to set selected muscle/pain info on `UserRehabilitation`.
   * Conditionals: severe pain + recent injury skip exercise plan, show treatment-only warning.
   * When plan generated: display week cards, treatment list, save to Hive + Firebase.

#### Daily Pain Tracking
* On `PainLevelPage`, slider writes `UserAssess.painScale`, shows emoji + description, and updates `selectedPainLevel`.
* `Complete` button persists to Hive (`UserAssess.saveToHive()` invoked upstream) and optionally navigates to ROM capture.

#### Dashboard
* Upon mount: `DataPersistenceService.loadUserDataIfNeeded()`, `UserDataNotifier.initialize()`.
* UI sections: hero card (assessment completion), plan/treatment cards (with asynchronous details), notifications dialog (dynamic action cards), CTA buttons (start assessment, open record).
* Listeners: `UserDataNotifier.addListener` to refresh caches.

#### Exercise Management
* `ExercisesPage` loads CSV + custom exercises, caches results, and provides selection mode for plan editing.
* `EditPlanPage` displays plan-based exercises/treatments, note field, refresh/regenerate actions, and handles custom insertions or replacements via `ExercisesPage`.

#### Recording Flow
1. **PreRecordPage** ensures camera permission, shows instructions, optionally offers warmup.
2. **RecordExercisePage**
   * UI sections: HUD (timer, exercise details), live camera preview, pain overlay, capture controls (start, pause, finish, switch camera, toggle flashlight if available).
   * Pain detection overlay: color-coded banners, severity-specific dialogs, cooldown suggestions.
   * When user finishes: transitions to `ConfirmSavePage` to review metrics and save to history.
3. **Warmup/Cooldown pages** provide curated stretching routines with timers and instructions.

#### Reports & PDF Export
* `ReportPage` tabs/cards: rehab plan expansion, exercise calendar grid, pain chart, PDF export CTA.
* Riverpod provider fetches aggregated data; refresh button invalidates provider.
* `ExportPDFButton` states: loading spinner, error card with details, action button with icon.
* `PDFExportService` ensures data freshness, builds multi-section PDF (header, data freshness, assessment table, summary stats, trend charts), and triggers `Printing.sharePdf` (mobile) or `Printing.layoutPdf` (web).

#### Profile & Settings
* Displays profile photo, name, email, streak stats, reminder toggles, plan metadata, quick actions (export PDF, open pose demo).
* Buttons: edit settings, manage guest mode, log out (calls `_auth.signOut()` via service and clears Hive).

### 2.3 Workflow Explanations

#### Registration & Email Verification
1. User signs up on `RegisterPage`.
2. Firebase sends verification email; app opens `SimpleEmailVerificationPage`.
3. Page polls verification status every 3 seconds.
4. Once verified, `_autoSignInAfterVerification` logs in, shows success message, and navigates to `HomePage`.

#### Pain Assessment Flow
1. Launch from Dashboard CTA (`Start Assessment`).
2. Step-by-step forms populate `AssessmentData`.
3. On summary confirmation, data propagates to `UserAssess`.
4. `GeneratePlanPage` auto-runs, produces plan/treatments.
5. Saves to Hive/Firebase and updates Dashboard state.

#### Daily Pain Tracking
1. Navigate to Daily Assessment (via Dashboard or dedicated entry).
2. `PainLevelPage` slider updates `UserAssess`.
3. Optionally record ROM via `CameraPosePage`.
4. Data saved to Hive and, upon sync, to Firebase histories.

#### Exercise & Treatment Plan Generation
1. Completed assessment seeds `UserRehabilitation`.
2. `generate_plan.dart` calls `generateRehabilitationPlanFromCSV` (CSV assets) and `generate_treatment.dart` to map severity/muscle combos to treatments.
3. Results saved to Hive (`rehabBox`) and Firebase for cross-device availability.

#### Optional Treatment Editing & Custom Exercise Creation
1. `EditPlanPage` loads current plan + treatments.
2. User can refresh treatments (regenerate via `generateTreatmentPlan`) or replace exercises.
3. Custom exercises created via dedicated UI (not shown) call `CustomExerciseService.saveExercise`, storing to Hive and Firestore `customExercises/{userId}/exercises`.
4. `ExercisesPage` automatically merges CSV + custom entries for future selections.

#### ML Model Integration
* **Pose Estimation:** `PoseDetectionService` streams frames into ML Kit, normalizes landmarks, and passes them to `AssessmentService` for ROM evaluation (used in AROM flows and daily camera assessments).
* **Pain Recognition:** `FacialPainRecognitionService` loads PyTorch Lite model, runs inference on camera frames, and returns `painLevel` + `confidence`. `RecordExercisePage` subscribes to updates to show UI interventions and log analytics.

#### PDF Report Export
1. User taps “Export Reports” on Report or Profile pages.
2. `ExportPDFButton` fetches `ReportsDataService` entries (pain/exercise histories, plan/treatment metadata, assessment summary).
3. `PDFExportService` constructs PDF with header, data freshness, assessment table, summary metrics, charts/trends, treatment/exercise sections, and optional custom notes.
4. On mobile, `Printing.sharePdf` opens OS share sheet; on web, `Printing.layoutPdf` triggers browser download/print.

### 2.4 Assumptions, Limitations, and Expected Behavior
* Offline-first on mobile/desktop (Hive is authoritative during offline periods); web offline auto-enters guest mode with local-only Hive.
* Firebase collections must exist; `FirebaseHelper.ensureAllCollectionsExist` is called prior to loads/saves.
* Severe pain cases skip exercise plan generation per rehab guidelines.
* Pain detection gracefully degrades if PyTorch fails—recording continues without overlays.
* Guest mode restricts cloud sync; data stored in Hive until login.

---

## 3. Installation & Deployment Guide

### 3.1 Prerequisites
* **Development Environment**
  - Flutter SDK compatible with Dart `^3.7.2`.
  - Android Studio (for platform tooling) and Xcode (if iOS builds needed later).
  - Firebase project configured via `lib/firebase_options.dart`.
  - Hive assets generated (`build_runner` for `hive_models.g.dart` if schema changes).
* **Runtime Dependencies**
  - Firebase Auth/Firestore/Storage.
  - Hive storage (`rehabBox`).
  - Google ML Kit pose detection, PyTorch Mobile (Android).
  - For web builds: GitHub repository with Pages enabled.

### 3.2 Android Mobile Deployment (APK via Google Drive)
1. **Build the Release APK**
   ```powershell
   flutter clean
   flutter pub get
   flutter build apk --release
   ```
   *Optional:* run `.\copy_apk.ps1` to move the APK into `build\app\outputs\flutter-apk`.
2. **Upload to Google Drive**
   - Create a shared folder `PocketPT Releases`.
   - Upload `app-release.apk` (rename to `PocketPT-v<version>.apk` for clarity).
   - Set sharing to “Anyone with the link” (view only).
3. **Install on Device (Tester Instructions)**
   - Open the Google Drive link on the Android device.
   - Download the APK; Android will prompt for “Install unknown apps” permission—grant it for the browser or Files app.
   - Tap the downloaded APK to install. If updating an existing build, uninstall the previous version or allow signature mismatch resolution.
4. **Permissions & First Run**
   - On launch, accept camera permission for recording and pose detection.
   - If notifications are required, grant them (Android 13+ prompts explicitly).
   - The app initializes Firebase/Hive; when offline, it enters guest mode automatically.
5. **Troubleshooting**
   - **App not installing:** verify `flutter build apk --release` used and package name matches installed version; run `adb uninstall com.example.pocketpt`.
   - **Firebase auth errors:** confirm the tester’s email is whitelisted or enable proper sign-in providers.
   - **Hive corruption:** reinstall after clearing app data; `openRehabBox()` will recreate corrupted boxes.
   - **ML model load failure:** ensure `assets/model/pain_recognition_model.ptl` is included; rebuild if missing.

### 3.3 Web Deployment via GitHub Actions & GitHub Pages

#### Automated CI/CD (Recommended)
1. **GitHub Workflows**
   - `deploy-web.yml` and `flutter-web-deploy.yml` (in `.github/workflows/`) both listen to `main` branch pushes.
   - Steps: checkout, install Flutter (`subosito/flutter-action@v2` pinned to `3.29.2`), `flutter pub get`, `flutter build web --release`, upload artifact, deploy to GitHub Pages (either via `actions/deploy-pages@v4` or `peaceiris/actions-gh-pages@v3`).
2. **Accessing the Site**
   - After pipeline completes, GitHub Pages hosts the app at `https://<github-username>.github.io/PocketPT/` (respect case sensitivity used during build).
3. **Redeploying**
   - Push to `main` or invoke `workflow_dispatch`.
   - Monitor Actions logs for Flutter build warnings, ensure `FLUTTER_VERSION` matches local environment for reproducibility.

#### Manual / Scripted Deployment
1. **Use `deploy_web.ps1`**
   ```powershell
   .\deploy_web.ps1
   ```
   - Cleans build, reinstalls dependencies, builds web with `--debug --base-href /PocketPT/ --pwa-strategy none`, adds `.nojekyll` and SPA fallback `404.html`, force-adds `build/web`, creates a temporary commit, splits subtree, and pushes to `gh-pages`.
   - Verifies presence of critical files (`index.html`, `flutter_bootstrap.js`, CSV assets) before pushing.
2. **Manual Command Sequence**
   ```bash
   flutter clean
   flutter pub get
   flutter build web --debug --base-href /PocketPT/
   echo > build/web/.nojekyll
   cp build/web/index.html build/web/404.html
   git add -f build/web/
   git commit -m "chore(deploy): web build"
   git subtree split --prefix build/web -b gh-pages-temp
   git push origin gh-pages-temp:gh-pages --force
   git branch -D gh-pages-temp
   git reset --soft HEAD~1 && git restore --staged build/web
   ```
3. **Configuration Notes**
   - Base href must match repository casing (`/PocketPT/`).
   - `.nojekyll` prevents GitHub Pages from stripping directories.
   - `404.html` ensures Flutter SPA routing works on refresh/deep links.

### 3.4 Local Development & Testing
1. **Install Dependencies**
   ```bash
   flutter pub get
   ```
2. **Run Unit/Widget Tests**
   ```bash
   flutter test
   ```
3. **Launch App**
   ```bash
   flutter run -d <device-id>
   ```
4. **Web Preview**
   ```bash
   flutter run -d chrome --web-port 6006 --web-renderer canvaskit
   ```
5. **Smoke Tests**
   - Log in, complete assessment, generate plan, edit plan, record exercise (verify pain detection overlay), check reports, export PDF, and confirm profile settings reflect changes.

### 3.5 Troubleshooting Reference
| Issue | Symptoms | Resolution |
| --- | --- | --- |
| Firebase initialization fails | Console logs “Initialization failure” | Verify network connectivity, confirm `google-services.json`/`firebase_options.dart` match environment, rerun with `flutter clean`. |
| Hive box open error | Crashes when opening `rehabBox` | `openRehabBox()` already attempts deletion/reopen; if persistent, delete app data or remove `rehabBox` from file system during development. |
| Web missing assets | 404 on CSV or model | Ensure `flutter build web --base-href` ran after `flutter clean`, confirm `.nojekyll` in build output. |
| PyTorch pain detection not running | Logs channel errors | Ensure Android build includes `pain_recognition_model.ptl`, check native channel initialization, verify device supports PyTorch Lite. |

---

## 4. Change Management & Task Mapping
* This document satisfies multiple tasks in `openspec/changes/comprehensive-app-review`:
  - **8.6 Create comprehensive developer documentation** by detailing every module and workflow.
  - **10.7 Create comprehensive deployment procedures** by providing Android and web deployment guides with troubleshooting steps.
  - **1.7 Create comprehensive documentation standards** by establishing structure and expectations for future docs.

Future contributors should update this file whenever modules, flows, or deployment procedures change to keep the documentation accurate and aligned with OpenSpec requirements.


