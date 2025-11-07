<!-- OPENSPEC:START -->
# Design: CSV header normalization and web asset caching behavior

## Approach
- Introduce a small CSV utility layer to normalize headers and safely access cells after parsing. This avoids replacing the CSV parser and minimizes change scope.
- Normalization rules for header keys (applied before lookups):
  - Strip UTF-8 BOM (U+FEFF) if present.
  - Remove `\r` for CRLF compatibility.
  - Trim leading/trailing whitespace.
  - Strip surrounding double quotes if the entire header cell is quoted.
  - Lowercase and convert spaces to underscores to derive a canonical key.
- Field access uses canonical names (e.g., `other_muscles`), so variants like `Other_Muscles`, `Other Muscles`, or `"Other_Muscles"` match.
- On Web, load the CSV via `rootBundle.loadString(..., cache: false)` to avoid stale CDN-cached assets after deploy.

## Alternatives considered
- Replace CSV parser: unnecessary; normalization suffices and lowers risk.
- Enforce a single header spelling in content: brittle during content edits.

## Risk mitigation
- Only header keys and trivial cell cleanup are normalized; data values remain intact.
- Missing columns log warnings and degrade gracefully to avoid breaking plan generation.
- Scope limited to CSV consumers in the plan generation path.
<!-- OPENSPEC:END -->

