## Why
The current PocketPT Hive-Firebase sync implementation has critical race conditions and ambiguous data flow that causes widgets to display empty content and creates data loss risks. The sync logic is inconsistent between "local exists → push" vs "no local → pull" approaches, and widgets don't explicitly load from Hive before displaying data.

## What Changes
- **BREAKING**: Refactor DataSyncService to use clear offline-first architecture with Hive as single source of truth
- **BREAKING**: Add timestamp-based conflict resolution to all data models
- **BREAKING**: Remove Firebase fallback from loadFromHive() methods to eliminate circular dependencies
- **BREAKING**: Fix widget loading to explicitly load from Hive before displaying content
- Add sync queue system for offline operations with retry logic
- Implement background Firebase sync that doesn't block UI
- Add comprehensive error handling and logging for sync operations

## Impact
- Affected specs: data-sync, data-persistence, assessment-flow
- Affected code: lib/data/data_sync_service.dart, lib/data/globals.dart, lib/assessment/*.dart, lib/data/data_persistence_service.dart
- Performance: Faster app startup with Hive-first loading, non-blocking Firebase sync
- UX: Widgets display data immediately instead of showing blank content
