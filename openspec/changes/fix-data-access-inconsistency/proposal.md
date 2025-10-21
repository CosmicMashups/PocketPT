## Why

The analysis reveals a critical data access pattern inconsistency across three key pages (DashboardPage, EditPlanPage, and ReportsPage). While all pages successfully detect exercise and treatment counts, only DashboardPage properly displays the actual exercise and treatment data. EditPlanPage and ReportsPage fail to display detailed information due to different data access approaches and missing async data loading implementations, resulting in placeholder data being shown instead of actual exercise names, descriptions, and treatment details.

## What Changes

- **MODIFIED**: EditPlanPage to use individual exercise loading pattern like DashboardPage instead of bulk loading
- **MODIFIED**: ReportsPage to replace provider-based approach with direct FutureBuilder usage for async data loading
- **MODIFIED**: ExerciseDataService to improve error handling and validation for bulk operations
- **ADDED**: Consistent loading states and error handling across all pages
- **ADDED**: Standardized data access patterns for exercise and treatment display

## Impact

- Affected specs: data-access (new capability)
- Affected code: 
  - `lib/exercise/edit_plan.dart` - Exercise display logic
  - `lib/reports/report_page.dart` - Report data access
  - `lib/reports/providers/report_providers.dart` - Provider architecture
  - `lib/data/rehabilitation_plan.dart` - ExerciseDataService methods
- User experience: Users will now see actual exercise names and treatment details instead of placeholder data across all pages
