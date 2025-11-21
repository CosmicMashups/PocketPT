## 1. Analysis and Planning
- [x] 1.1 Review current `PainHistory.recordToday()` implementation in `lib/data/globals.dart`
- [x] 1.2 Identify all call sites of `PainHistory.recordTodayAndSave()` to understand usage patterns
- [x] 1.3 Verify current Firebase and Hive storage structure for pain history
- [x] 1.4 Document expected behavior: each day should create a new entry, not replace

## 2. Core Implementation
- [x] 2.1 Modify `PainHistory.recordToday()` to always append new entries instead of replacing
- [x] 2.2 Update method comment to reflect new behavior (create new entry per day)
- [x] 2.3 Ensure date comparison logic correctly identifies unique days
- [x] 2.4 Add validation to prevent duplicate entries for the same date (if needed for edge cases)

## 3. Data Persistence Updates
- [x] 3.1 Verify `PainHistory.saveToHive()` correctly saves all entries (not just latest)
- [x] 3.2 Verify `PainHistory.saveToFirebase()` correctly saves all entries to Firebase
- [x] 3.3 Ensure `PainHistory.loadFromHive()` loads all historical entries
- [x] 3.4 Ensure `PainHistory.loadFromFirebase()` loads all historical entries
- [x] 3.5 Enhanced `recordTodayAndSave()` to also save to Firebase (matching ExerciseHistory pattern)
- [x] 3.6 Updated Hive storage to use `HivePainRecordEntry` objects for type safety and multiple entries support
- [x] 3.7 Enhanced Firebase loading with better error handling and validation for multiple entries
- [x] 3.8 Added backward compatibility for legacy Map format in Hive loading

## 4. Integration Verification
- [x] 4.1 Verify initial assessment (`lib/assessment/c_camera.dart`) creates first entry correctly
- [x] 4.2 Verify daily assessment (`lib/dailyAssessment/painLevel.dart`) creates new entry on subsequent days
- [x] 4.3 Verify daily assessment (`lib/dailyAssessment/cameraPose.dart`) creates new entry correctly
- [x] 4.4 Verified all call sites use `recordTodayAndSave()` correctly
- [x] 4.5 Verify PDF export (`lib/reports/services/pdf_export_service.dart`) can access all historical entries

## 5. Testing and Validation
- [ ] 5.1 Test pain recording on Day 1 (initial assessment)
- [ ] 5.2 Test pain recording on Day 2 (should create new entry, preserve Day 1)
- [ ] 5.3 Test pain recording on Day 3 (should create new entry, preserve Day 1 and Day 2)
- [ ] 5.4 Verify Hive storage contains all entries after multiple days
- [ ] 5.5 Verify Firebase storage contains all entries after sync
- [ ] 5.6 Test PDF export with multiple historical entries
- [ ] 5.7 Verify reports page displays all historical pain entries correctly

## 6. Edge Cases
- [ ] 6.1 Test recording pain multiple times on the same day (should update that day's entry)
- [ ] 6.2 Test app restart between days to ensure persistence
- [ ] 6.3 Test offline mode: ensure entries are saved locally and synced when online
- [ ] 6.4 Test timezone edge cases (midnight boundary)
- [ ] 6.5 Verify no data loss when switching between authenticated and guest modes

