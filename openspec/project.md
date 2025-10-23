# Project Context

## Purpose
PocketPT is a cross‑platform rehabilitation companion app that guides patients through assessment, personalized plan generation, daily exercise tracking, and progress reporting. It aims to:
- Provide an accessible, mobile‑first experience for physical rehabilitation.
- Capture baseline and ongoing data (pain, ROM, exercise adherence) via assessment and recording flows.
- Generate and adapt rehabilitation plans and treatments based on collected data.
- Work reliably offline with seamless background sync when the network is available.
- Maintain a responsive, professional UX across Android, iOS, web, desktop.

## Current Implementation Status

### Core Features (Implemented)
- **Authentication System**: Email/password login, Google Sign-in, guest mode, persistent sessions
- **Assessment Workflow**: Complete multi-step assessment including pain evaluation, ROM assessment, camera-based pose detection
- **Exercise Management**: Exercise library, rehabilitation plan generation, custom exercise support
- **Recording System**: Camera-based exercise recording with pose detection and pain recognition
- **Progress Tracking**: User progress, exercise history, pain history, streak tracking
- **Reporting**: PDF export, progress analytics, exercise calendar
- **Profile Management**: User settings, notification preferences, data management

### Data Architecture (Fully Implemented)
- **Dual Storage**: Hive (local) + Firebase (cloud) with comprehensive sync
- **13 Hive Models**: Complete data persistence for all user data
- **Firebase Collections**: Structured user data with proper subcollections
- **Offline-First**: Full functionality without internet connection
- **Data Sync**: Automatic synchronization with conflict resolution

### ML/AI Features (Implemented)
- **Pose Detection**: ML Kit integration for real-time pose analysis
- **Pain Recognition**: Facial pain detection using PyTorch models
- **ROM Assessment**: Camera-based range of motion evaluation
- **Exercise Form Analysis**: Real-time form feedback during exercises

## Tech Stack
- Primary: Flutter (Dart), Material Design
- Platforms: Android, iOS, Web, macOS, Windows (Linux planned)
- Backend/Cloud: Firebase (Auth, Firestore, Storage), Firebase Messaging
- Local storage: Hive with 13 custom adapters (`lib/data/hive_models.dart` + `hive_models.g.dart`)
- Notifications: Local notifications (non‑web)
- ML/Computer Vision: 
  - ML Kit for pose detection
  - PyTorch models for facial pain recognition (`assets/model/`)
  - Real-time camera processing with throttling
- UI: Google Fonts (Poppins, PT Sans), CurvedNavigationBar, custom medical design system

## Project Conventions

### Code Style
- Dart/Flutter idiomatic style, with explicit and descriptive naming (no 1–2 char names).
- Prefer early returns, limited nesting, and meaningful guard clauses.
- Comments only for non‑obvious rationale, invariants, and edge cases.
- Keep widgets and services focused; avoid mixing UI with persistence/sync logic.
- Respect existing formatting and whitespace; do not reformat unrelated code in edits.

### Architecture Patterns
- App shell in `lib/main.dart` initializes Firebase and Hive (non‑web) in parallel, then starts the UI and defers background loads.
- Layered services in `lib/data/` handle auth persistence, data persistence, sync, loading, performance, and notifications.
- Offline‑first: Hive is the system of record on mobile/desktop; Firebase is the cloud source with background sync.
- Platform awareness: Hive and certain services are skipped on web; Firebase‑only mode for web.
- Routing: Auth state stream → `AuthWrapper` → assessment gate (`assessment/preliminary.dart`) → `HomePage` (`IndexedStack` of feature tabs).
- Feature folders (`assessment/`, `dashboard/`, `exercise/`, `record/`, `reports/`, `profile/`) own UI; shared widgets in `lib/widgets/` for loading, responsiveness, and visualization.
- ML services (pose/facial pain) are encapsulated under `lib/data/` and used by recording/assessment features.

### Data Persistence Architecture
- **Hive Models**: 13 registered adapters for complete data persistence
  - UserDetails, UserProgress, UserAssess, UserSettings
  - ActiveProgram, RehabilitationPlan, TreatmentReference
  - PainHistory, ExerciseHistory, CustomExercises
  - ExerciseReference, TreatmentReference with ID-based storage
- **Firebase Collections**: Structured user data with proper subcollections
  - `users/{userId}` - Main user document
  - `users/{userId}/rehabilitationPlans/plans` - Exercise plans
  - `users/{userId}/treatments/treatments` - Treatment data
  - Additional collections for progress, assessment, settings, histories
- **Sync Strategy**: Timestamp-based conflict resolution with automatic background sync
- **Offline Support**: Full functionality without network, with graceful degradation

### Testing Strategy
- Widget/integration test scaffolds under `lib/test_*.dart` and `test/widget_test.dart`.
- Smoke tests for Firebase configuration and auth flows (`lib/test_firebase_integration.dart`, `lib/test_firebase_page.dart`).
- Persistence tests validating Hive read/write and data integrity (`lib/test_persistence_page.dart`, `lib/test_optimized_loading.dart`).
- Manual E2E flows for assessment gating and navigation via `AuthWrapper` and main tabs.
- Performance checks: lightweight frame timing logs enabled in `MyApp` to flag jank during profiling.
- Comprehensive test suite with 7 test categories covering all data operations

### Git Workflow
- Branching: `main` is stable; feature branches `feat/<area>`; fixes `fix/<scope>`; experiments `exp/<topic>`.
- Commits: Conventional Commits style (`feat:`, `fix:`, `chore:`, `perf:`, `refactor:`, `test:`).
- Pull Requests: Small, focused; include before/after notes for UX or performance‑impacting changes; link to any spec in `openspec/changes/` when relevant.

## Domain Context
- Rehabilitation domain with workflows around pain assessment, joint/area focus, ROM, and plan generation.
- Core flows:
  - Authentication (email/password + guest mode), optional email verification and password reset.
  - Assessment wizard (pain type/level/duration, joint selection, history, camera/video capture and upload, summary) → generates plan/treatments (`assessment/generate_plan.dart`, `generate_treatment.dart`).
  - Daily usage: exercise manager, recording (pose tracking), reports, and profile.
- Users may operate offline; data must be preserved and later synced.
- Sensitive health‑related data requires careful handling and clear user consent.

## Current App Structure

### Main Navigation (HomePage)
- **Dashboard**: User progress, recent activities, quick actions
- **Exercise**: Exercise library, rehabilitation plans, custom exercises
- **Record**: Camera-based exercise recording with pose detection
- **Report**: Progress analytics, PDF export, exercise calendar
- **Profile**: User settings, data management, logout

### Assessment Workflow
1. **Preliminary Assessment**: Goal setting and process overview
2. **Core Assessment**: Pain evaluation, muscle selection, history
3. **Camera Assessment**: ROM evaluation with pose detection
4. **Video Assessment**: Movement recording and analysis
5. **Pain Level**: Final pain scale evaluation
6. **Plan Generation**: Personalized rehabilitation plan creation
7. **Treatment Generation**: Custom treatment recommendations

### Recording System
- **Pre-Record**: Exercise selection and camera setup
- **Record Exercise**: Real-time pose detection and pain recognition
- **Confirm Save**: Exercise completion and data storage
- **Cooldown/Stretching**: Post-exercise recommendations

## Important Constraints
- Offline‑first on mobile/desktop: all critical data must persist locally via Hive; avoid blocking UI on network.
- Web mode must skip Hive and Hive‑dependent services; Firebase‑only data access.
- Smooth UX on low‑end devices: optimized image cache, minimal overdraw, reduced glow effects, and prefetching page data.
- Healthcare context: prioritize privacy, least‑privilege access, and clear user messaging for data capture and uploads.
- Long‑running ML/IO work must not block the main isolate; perform asynchronously with progress indicators.
- App must remain usable when Firebase is temporarily unavailable; log and degrade gracefully.

## External Dependencies
- Firebase: Auth, Firestore/Storage (per `firebase_options.dart` multi‑platform configuration).
- Hive: Local key‑value storage with custom adapters for domain models (`lib/data/hive_models.dart`).
- Local Notifications: Device‑level notifications for reminders (non‑web).
- Google Fonts: Poppins (headings), PT Sans (body).
- CurvedNavigationBar: Bottom navigation component used by `HomePage`.
- ML/Inference tooling: On‑device pose and facial pain recognition services; model assets under `assets/model/` (PyTorch). Other platform glue (e.g., ML Kit) may be used per `ML_KIT_INTEGRATION_README.md`.
