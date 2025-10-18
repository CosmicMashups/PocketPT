# Proposal: Unify history fetch+merge in syncAllData and standardize widget preload

## Summary
Add fetch+merge for PainHistory and ExerciseHistory into the unified offline-first sync path, and standardize the assessment widget preload pattern (Hive → AssessmentData → UI, with non-blocking background sync) to eliminate blank screens and ensure data consistency after restarts.

## Motivation
- Remote changes to histories are not merged during `syncAllData()`, only pushed. This breaks offline-first symmetry and can lead to divergence.
- Some assessment pages previously relied on in-memory state without an explicit Hive preload, causing blank/empty UIs after a cold start.

## Scope (Minimal, targeted)
1) Extend `syncAllData()` to fetch and merge PainHistory and ExerciseHistory (append-or-timestamp strategy) alongside user, assess, progress, and settings.
2) Provide a simple, reusable preload pattern for assessment widgets: await `UserAssess.loadFromHive()`, copy to `AssessmentData`, render UI with loading guard, then trigger `DataSyncService.instance.syncAllData()` post-frame.

## Non-Goals
- Full rearchitecture of sync service.
- Complex multi-source conflict resolution (stick to lastModified or append-only for histories, as applicable).

## Acceptance Criteria
- Opening any assessment page shows data from Hive immediately and never a blank white screen.
- `syncAllData()` pulls (fetches) and merges pain/exercise histories in addition to pushing.
- After a remote update to histories, running `syncAllData()` reflects merged state in Hive.
- Analyzer: no errors; warnings are tolerated but preloading widgets must not introduce new issues.

## Risks
- Merge policy for histories must avoid duplicates. Use deterministic keys (date for pain entries; date+exerciseId for exercises) or last write wins.

## Rollout
- Behind no flags; change is backward compatible.


