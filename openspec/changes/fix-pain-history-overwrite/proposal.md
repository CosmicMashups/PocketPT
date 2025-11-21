## Why

The daily pain recording system currently overwrites previous pain entries instead of creating new historical entries. The `PainHistory.recordToday()` method in `lib/data/globals.dart` replaces any existing entry for the current date, which means:

1. When users complete the initial assessment, their pain data is saved correctly
2. However, when they perform daily assessments on subsequent days, the system replaces the previous day's entry instead of creating a new entry
3. This causes historical pain data to be lost, breaking PDF report generation which requires all daily pain entries for trend analysis

The PDF export service (`lib/reports/services/pdf_export_service.dart`) expects multiple pain history entries to generate comprehensive reports, but currently only receives the most recent entry due to the overwrite behavior.

## What Changes

- **MODIFIED**: `PainHistory.recordToday()` method to always create new entries instead of replacing existing entries for the same date
- **MODIFIED**: Pain history storage logic to ensure each day's assessment creates a distinct historical entry
- **ENHANCED**: Data persistence to preserve all historical pain entries in both Hive and Firebase
- **VERIFIED**: PDF export compatibility to ensure all historical entries are available for report generation

## Impact

- Affected specs: `pain-tracking` (new capability)
- Affected code:
  - `lib/data/globals.dart` (PainHistory.recordToday method)
  - `lib/dailyAssessment/painLevel.dart` (daily pain recording)
  - `lib/dailyAssessment/cameraPose.dart` (daily assessment recording)
  - `lib/assessment/c_camera.dart` (initial assessment recording)
  - `lib/reports/services/pdf_export_service.dart` (PDF export - verification only)
  - `lib/reports/services/reports_repository.dart` (data loading - verification only)




