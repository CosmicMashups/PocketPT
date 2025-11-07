<!-- OPENSPEC:START -->
## MODIFIED Requirements: Web Asset Loading

- Requirement: CSV load on Web MUST bypass stale cache by default for plan generation.
  - Use `rootBundle.loadString(path, cache: false)`.

#### Scenario: CDN cached CSV older than app
- Given GitHub Pages may serve a cached asset,\
  When loading CSV,\
  Then the latest content is fetched (cache bypass) preventing header mismatch.

- Requirement: Asset path MUST remain `assets/data/exercises.csv` and be declared in `pubspec.yaml`.

#### Scenario: Asset resolution on `/PocketPT/` base href
- Given a web build with base href `/PocketPT/`,\
  When requesting asset via Flutter asset system,\
  Then the fetch resolves successfully without path rewrites in app code.
<!-- OPENSPEC:END -->

