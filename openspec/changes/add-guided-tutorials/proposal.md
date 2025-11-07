## Why
Users struggle to discover critical rehabilitation features across the assessment, recording, and reporting flows. A guided tutorial system is required to highlight primary controls, camera actions, and dashboard insights without disrupting ongoing sessions.

## What Changes
- Add an in-app guided tutorial framework with both package-based (ShowCaseView/TutorialCoachMark) and custom overlay implementations.
- Instrument major feature pages with stable anchors, step copy, accessibility semantics, and analytics events.
- Provide configuration, localization scaffolding, feature flags, and documentation for extending tutorials.
- Deliver automated tests validating tutorial sequencing, overlay positioning, and analytics hooks.

## Impact
- Affected specs: `ui-tutorials`
- Affected code: `lib/tutorials/*`, representative feature pages (dashboard, record, assessment, profile, welcome), testing suites, documentation

