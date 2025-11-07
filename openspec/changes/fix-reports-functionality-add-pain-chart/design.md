## Context

The reports functionality needs fixes for calendar and PDF export processes, and requires new features for pain level visualization and comprehensive assessment data inclusion. The current implementation has issues with data loading, date handling, and missing visualization capabilities.

## Goals / Non-Goals

### Goals:
- Fix calendar functionality to properly display and handle exercise records
- Fix PDF export to reliably generate reports with all data
- Add daily pain level chart visualization for better user insights
- Include assessment collection data from Firebase in PDF exports
- Maintain existing data access patterns and architecture
- Ensure proper error handling and loading states

### Non-Goals:
- Complete redesign of reports architecture
- Real-time data synchronization features
- Advanced analytics beyond pain level tracking
- Custom chart library implementation

## Decisions

### Decision: Use fl_chart for Pain Visualization
- **Rationale**: Lightweight, performant, well-maintained Flutter charting library with good documentation
- **Alternatives considered**: 
  - flutter_charts (less maintained)
  - syncfusion_flutter_charts (heavyweight, commercial)
  - Custom Canvas drawing (too complex)
- **Trade-offs**: Adds dependency, but provides professional charting capabilities with minimal overhead

### Decision: Load Assessment Data from Firebase Directly
- **Rationale**: Assessment data is already stored in Firebase assessment collection, no need for additional caching layer
- **Structure**: ReportsRepository → ReportsDataService → Provider → Widget/PDF
- **Benefits**: Direct access to latest assessment data, consistent with existing Firebase patterns

### Decision: Add Assessment Data to First Page of PDF
- **Rationale**: Assessment data is foundational clinical information that should appear prominently
- **Layout**: First page after header, before summary statistics
- **Benefits**: Provides context for all subsequent data in the report

### Decision: Maintain Existing Calendar Grid Structure
- **Rationale**: Calendar UI is functional, only needs fixes to data loading and date handling
- **Changes**: Fix date normalization, improve error handling, ensure proper data refresh
- **Benefits**: Minimal disruption, fixes issues without architectural changes

## Risks / Trade-offs

### Risk: Chart Library Performance with Large Datasets
- **Mitigation**: Implement data aggregation (e.g., show daily averages), limit visible range, add pagination
- **Monitoring**: Profile chart rendering with large datasets

### Risk: Assessment Data Loading Delay in PDF Export
- **Mitigation**: Load assessment data in parallel with other data, cache results, show progress indicator
- **Fallback**: If assessment data fails to load, continue PDF generation with available data

### Risk: Date Normalization Issues Across Timezones
- **Mitigation**: Use UTC dates for storage, normalize to local timezone only for display
- **Testing**: Test with various timezones and date edge cases

## Implementation Approach

### Phase 1: Fix Existing Functionality
1. Fix calendar date normalization and data loading
2. Fix PDF export error handling and data refresh
3. Test fixes thoroughly

### Phase 2: Add Assessment Data Loading
1. Add assessment data loading to ReportsRepository
2. Add assessment data to ReportsDataService
3. Create provider for assessment data
4. Test Firebase data loading

### Phase 3: Add Pain Level Chart
1. Add fl_chart dependency
2. Create PainLevelChart widget
3. Integrate chart into report page
4. Style and test chart functionality

### Phase 4: Update PDF Export
1. Add assessment data section to PDF first page
2. Format assessment data professionally
3. Test PDF generation with assessment data
4. Verify all data is included correctly

## Open Questions

- Should the pain chart show all historical data or allow date range filtering?
- Should assessment data be editable in the PDF export or read-only?
- How should we handle assessment data updates during PDF generation?

