## Why
The reports page currently has issues with calendar and PDF export functionality that need to be fixed. Additionally, users need better visualization of their pain tracking data through a daily pain level chart, and the PDF export should include comprehensive assessment data from Firebase for clinical reporting purposes.

## What Changes
- **Fix Calendar Functionality**: Resolve any issues with exercise calendar grid data loading, display, and date selection
- **Fix PDF Export Functionality**: Ensure PDF export works correctly with all data sources and proper error handling
- **Add Pain Level Tracking Chart**: Implement a daily pain level chart widget showing tracked pain levels over time
- **Add Assessment Data to PDF**: Include assessment collection data (generalMuscle, injuredMuscles, painDuration, painLevel, painScale, painType, rehabGoal, specificMuscle, lastUpdated) on the first page of exported PDF reports

## Impact
- Affected specs: `reports` (new capability)
- Affected code: 
  - `lib/reports/report_page.dart`
  - `lib/reports/providers/report_providers.dart`
  - `lib/reports/services/reports_data_service.dart`
  - `lib/reports/services/reports_repository.dart`
  - `lib/reports/widgets/exercise_calendar_grid.dart`
  - `lib/reports/widgets/export_pdf_button.dart`
  - `lib/reports/widgets/rehab_plan_expansion_panel.dart`
  - `lib/reports/expanded_report_page.dart`
- New dependencies: Chart library (flutter_charts or fl_chart) for pain level visualization

