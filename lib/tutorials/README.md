# Guided Tutorial Framework

This module provides a reusable in-app guidance system that highlights primary controls across PocketPT using both package-based tour widgets and a lightweight custom overlay.

## Contents

- `tutorial_config.dart` – Central registry for tutorial steps, anchors, and flow metadata.
- `tutorial_models.dart` – Shared enums and data classes for placements, priorities, and analytics events.
- `tutorial_service.dart` – Orchestrates step sequencing, feature flags, and integration hooks.
- `tutorial_preferences.dart` – Stores per-user preferences and completion state using `SharedPreferences`.
- `tutorial_analytics.dart` – Default analytics handler that logs lifecycle events and persists completion state.
- `overlay_tooltip.dart` – Custom `OverlayEntry` implementation for lightweight spotlights with accessibility support.
- `showcase_integration.dart` – Utilities for using the `showcaseview` and `tutorial_coach_mark` packages.
- `i18n/tutorials_en.json` – English copy stub for tutorial text (extend for other locales).

## Quick Start

1. Call `TutorialRegistry.registerAll()` during app bootstrap (already wired in `main.dart`).
2. Wrap the root `MaterialApp` with `TutorialPackageIntegration.showcaseRoot` (already configured).
3. Inject the provided `GlobalKey` anchors into each target widget (see references in `tutorial_config.dart`).
4. Trigger tutorials via:
   - App start: `TutorialService.instance.startFlow(context, 'onboarding_dashboard');`
   - Settings/Profile replay: `await _replayTutorialFlow(context, flowId);` (see `ProfilePage`).
   - Page-specific first visit: `_scheduleDashboardTutorial()` / `_scheduleCameraTutorial()` helpers.
5. Use the global FAB or keyboard shortcut (`Shift + ?` or `F1`) on `HomePage` to reopen tutorials.

## Feature Flags & User Preferences

- Completion state and enablement are stored in `TutorialPreferences` (SharedPreferences).
- Global toggle lives in the Profile settings under **Tutorials & Guidance**.
- `TutorialService` registers a default feature flag resolver that checks `TutorialPreferences.tutorialsEnabled`.
- Per-flow replay resets completions before launching (e.g., `ProfilePage._replayTutorialFlow`).

## Implementation Approaches

Two delivery methods are available:

### Custom Overlay (`tutorials/overlay_tooltip.dart`)

- Uses an `OverlayEntry` with automatic positioning, arrow indicators, animations, and accessible semantics.
- Supports sequence navigation (next/previous/skip/done) and non-blocking fallbacks when anchors are missing.
- Recommended for camera or 9:16 views where layout control is critical.

### Package Integrations (`showcaseview`, `tutorial_coach_mark`)

- Wrapped via `TutorialPackageIntegration` for optional package experiences.
- Register additional implementations with `TutorialService.registerImplementation` and invoke via the `implementation` argument.

## Accessibility & Analytics

- Each overlay bubble moves focus to the tooltip, surfaces screen reader labels, and accepts keyboard navigation (left/right/esc).
- `DefaultTutorialAnalyticsHandler` logs lifecycle events, updates completion state, and is extendable for custom analytics sinks.
- Events emitted: `tutorial_started`, `step_shown`, `step_advanced`, `tutorial_skipped`, `tutorial_completed`.

## Testing

Tests live under `test/tutorials/` and cover configuration parsing, overlay fallback behavior, and sequence smoke tests. Run them with:

```bash
flutter test test/tutorials
```

## Localization

- `i18n/tutorials_en.json` mirrors the copy defined in `TutorialRegistry.steps`.
- Add new locales by creating additional JSON files and wiring them into your localization pipeline.

## Resetting Progress Programmatically

```dart
Future<void> resetTutorials() async {
  await TutorialPreferences.instance.ensureInitialized();
  for (final step in TutorialRegistry.steps) {
    await TutorialPreferences.instance.resetStep(step.id);
  }
  for (final flow in {
    for (final step in TutorialRegistry.steps) if (step.flowId != null) step.flowId!
  }) {
    await TutorialPreferences.instance.resetFlow(flow);
  }
}
```

This snippet is implemented in `ProfilePage` for the “Reset All Tutorials” action.

## Resources

- [showcaseview package](https://pub.dev/packages/showcaseview)
- [tutorial_coach_mark package](https://pub.dev/packages/tutorial_coach_mark)
- Flutter accessibility docs: <https://docs.flutter.dev/development/accessibility>

## ASCII Mockups

```
Dashboard Tooltip (Notifications)
┌──────────────────────────────────────────────┐
│ 🔔  Check Alerts                             │
│ Open the bell to review reminders and plans. │
│ [Skip]                         [Next ▶]       │
└──────────────────────────────────────────────┘

Camera Tooltip (Pause)
┌───────────────┐
│⏸ Pause & Rest │◄─ anchored above bottom controls
│Log a rest and review tips.                   │
│ [Skip]              [Done]                   │
└───────────────┘

Settings Toggle Tooltip
┌──────────────────────────────────────┐
│?  Enable Guided Tutorials            │
│Turn contextual walkthroughs on/off. │
│ [Skip]                  [Next ▶]     │
└──────────────────────────────────────┘
```

