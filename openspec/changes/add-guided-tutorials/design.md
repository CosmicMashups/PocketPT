## Context
PocketPT lacks an in-app guidance system. Users confront dense multi-step flows (assessment, recording, reporting) with minimal onboarding. Introducing guided tooltips requires anchoring across heterogeneous widgets, camera overlays, and accessibility constraints.

## Goals / Non-Goals
- Goals: Provide reusable tutorial orchestration, minimize invasive UI changes, ensure accessibility, and support analytics/feature flags.
- Non-Goals: Replace existing navigation patterns, redesign page layouts, or alter business logic beyond key injection.

## Decisions
- Decision: Support dual implementation (ShowCaseView/TutorialCoachMark and custom OverlayEntry) to satisfy package preference and fallback control. Custom overlay handles camera-specific constraints.
- Decision: Store tutorial metadata in a centralized config (`TutorialRegistry`) with JSON export for translations and tests.
- Decision: Expose feature flags via shared service utilizing existing settings/preferences store hooks without enforcing specific persistence (callers provide bool providers).
- Alternatives considered: Relying solely on package overlays (rejected due to limited control over camera placement) and forcing implicit keys (rejected for readability).

## Risks / Trade-offs
- Risk: Anchor widgets without stable keys. Mitigation: Provide key injection patches and manual guidance when dynamic.
- Risk: Overlay performance on low-end devices. Mitigation: Keep overlay lightweight, use single OverlayEntry, and debounced orientation handling.
- Risk: Accessibility regressions if focus management misapplied. Mitigation: Add dedicated helper to request focus and provide tests with semantics assertions.

## Migration Plan
1. Introduce tutorial infrastructure behind feature toggles.
2. Inject keys incrementally into target widgets.
3. Register steps and enable tutorials for staged rollout.
4. Document process for future pages and translations.

## Open Questions
- Preferred persistence for per-user tutorial completion states (assume existing settings service can store booleans).
- Specific analytics backend (provide generic hook). 

