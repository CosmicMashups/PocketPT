<!-- OPENSPEC:START -->
# Proposal: Normalize CSV headers and web asset loading for plan generation

- change-id: normalize-csv-headers-web
- status: Draft
- owner: core-app
- related: csv ingestion, assessment plan generation, web deploy
- summary: Normalize CSV headers (BOM/CRLF/quotes/case/underscores) and bypass stale cache on web asset load so the "Other_Muscles" column (and variants) is reliably recognized on Web, matching Android behavior, without regressions to unrelated features.

## Problem
- On Web builds (GitHub Pages), plan generation reports the "Other_Muscles" column as missing from `assets/data/exercises.csv`, though console logs show it present.
- Android works, implying platform-specific differences (e.g., BOM, CRLF line endings, quoted headers, caching/CDN).

## Outcome
- Web and Android read CSV using the same normalized header mapping.
- Column presence checks operate on normalized header keys and degrade gracefully instead of aborting.
- Web asset loading avoids stale cache so updates to the CSV are reflected immediately after deploy.

## Scope
- Minimal utility to normalize headers and safe-read cells, applied only where CSV is consumed for plan generation.
- No parser replacement; keep existing CSV parsing but post-process headers and values.
- No unrelated feature changes.
<!-- OPENSPEC:END -->

