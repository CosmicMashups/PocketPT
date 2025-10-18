# Tasks: sync-histories-preload-001

- [ ] Add _fetchHistoriesFromFirebase() in data_sync_service.dart
- [ ] Add _mergeHistories(local, remote) for pain/exercise histories
- [ ] Wire histories into _fetchAllFromFirebase(), _mergeData(), and _saveAllToHive()
- [ ] Update DataPersistenceService tests to validate saved histories after sync
- [ ] Standardize widget preload in remaining assessment pages (verify all)
- [ ] Add unit tests for merge (duplicate dates; remote wins vs local)
- [ ] Run flutter analyze and ensure zero errors
- [ ] Manual validation: open pages after restart; confirm data shows and background sync runs
