# Design: Unified history merge + widget preload

## Current
- syncAllData() merges user, assess, progress, settings by lastModified; pushes histories only.
- loadAllFromFirebase() loads histories, but not part of the usual sync path.
- Widgets: some pages already preload Hive (fixed), others follow the pattern now.

## Proposed
### A. Sync Service Enhancements
- Add _fetchHistoriesFromFirebase() returning pain/exercise histories.
- Add _mergeHistories(local, remote):
  - PainHistory: unique by date (day-granularity); if conflict, keep max(lastModified) or prefer remote.
  - ExerciseHistory: unique by (date, exerciseId); same conflict policy.
- Integrate results into _mergeData and _saveAllToHive.

### B. Widget Preload Pattern
- Each assessment page:
  - await UserAssess.loadFromHive() in initState -> copy to AssessmentData -> set state -> render.
  - Trigger DataSyncService.instance.syncAllData() in a post-frame callback.

## Data Contracts
- Histories in Hive remain list-of-map; merging operates on in-memory lists then saved to Hive.

## Alternatives Considered
- Full CRDT-like merge: overkill for current needs.

## Testing
- Unit: merging scenarios (duplicates, remote-only, local-only).
- Widget: preload guards render non-empty content after restart.
