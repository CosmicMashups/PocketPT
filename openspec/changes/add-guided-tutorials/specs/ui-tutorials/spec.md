## ADDED Requirements
### Requirement: Tutorial Framework
The app SHALL provide a guided tutorial framework capable of spotlighting key controls across assessment, recording, reporting, and profile flows using both package-based and custom overlay implementations.

#### Scenario: Trigger tutorial sequence
- **WHEN** a user launches onboarding or manually replays tutorials
- **THEN** the framework SHALL present a sequenced set of anchored tooltips with next/previous/skip navigation and analytics events for start, step, skip, and completion.

#### Scenario: Highlight individual control on demand
- **WHEN** the user requests help for a specific control
- **THEN** the framework SHALL display a single anchored tooltip without starting a full sequence, respecting accessibility focus and camera-safe placement rules.

### Requirement: Tutorial Accessibility and Analytics
The tutorial overlays MUST provide screen-reader friendly semantics, keyboard navigation, and emit analytics hooks for lifecycle events with optional payload data.

#### Scenario: Screen reader focus
- **WHEN** a tutorial step is shown
- **THEN** the overlay SHALL move semantics focus to the tooltip and expose descriptive labels for assistive technologies.

#### Scenario: Analytics emission
- **WHEN** tutorial lifecycle events occur (started, step shown, skipped, completed)
- **THEN** the app SHALL call registered analytics callbacks with the step identifier and optional metadata.

### Requirement: Tutorial Configuration and Feature Flags
Tutorial steps SHALL be defined via centralized configuration supporting localization stubs, priority metadata, and per-page feature toggles.

#### Scenario: Feature flag disabled
- **WHEN** a tutorial’s feature flag resolves to disabled for the current user
- **THEN** the step SHALL be skipped and no overlay is rendered for that step.

#### Scenario: Missing anchor fallback
- **WHEN** the configured anchor GlobalKey is unavailable at runtime
- **THEN** the framework SHALL use a fallback placement (e.g., safe corner overlay with navigation hint) instead of throwing.

