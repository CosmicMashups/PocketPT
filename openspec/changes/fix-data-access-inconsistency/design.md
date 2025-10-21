## Context

The PocketPT application has three main pages that display exercise and treatment data: DashboardPage, EditPlanPage, and ReportsPage. Currently, only DashboardPage successfully displays actual exercise names, descriptions, and treatment details. EditPlanPage and ReportsPage show placeholder data or fail to display detailed information due to inconsistent data access patterns.

## Goals / Non-Goals

### Goals
- Standardize data access patterns across all pages to use individual FutureBuilder loading
- Ensure all pages display actual exercise and treatment data instead of placeholders
- Improve error handling and loading states for better user experience
- Maintain performance while ensuring data consistency

### Non-Goals
- Changing the underlying data models or ExerciseDataService architecture
- Modifying the CSV data loading mechanism
- Changing the overall page layouts or UI design
- Implementing new caching mechanisms beyond existing ones

## Decisions

### Decision: Standardize on Individual Loading Pattern
- **Rationale**: DashboardPage's individual FutureBuilder pattern works reliably and handles loading states properly
- **Implementation**: Replace bulk loading in EditPlanPage and provider-based access in ReportsPage with individual FutureBuilder calls
- **Alternatives considered**: 
  - Fixing bulk loading issues - more complex and error-prone
  - Keeping provider pattern - fundamentally incompatible with async data loading

### Decision: Remove Provider Pattern from ReportsPage
- **Rationale**: Riverpod providers are synchronous and cannot perform async operations, leading to placeholder data
- **Implementation**: Replace provider-based data access with direct FutureBuilder usage
- **Alternatives considered**: 
  - Making providers async - not supported by Riverpod
  - Pre-loading data in providers - complex and error-prone

### Decision: Improve ExerciseDataService Error Handling
- **Rationale**: Better error handling will prevent silent failures and provide debugging information
- **Implementation**: Add validation, logging, and graceful handling of missing data
- **Alternatives considered**: 
  - Leaving error handling as-is - continues to cause silent failures
  - Complete rewrite of data service - unnecessary complexity

## Risks / Trade-offs

### Risk: Performance Impact of Individual Loading
- **Mitigation**: ExerciseDataService already has caching, so individual calls will be fast after initial load
- **Trade-off**: Slightly more FutureBuilder widgets but better error handling and consistency

### Risk: Breaking Existing Functionality
- **Mitigation**: Careful testing and gradual implementation
- **Trade-off**: Some refactoring required but maintains existing behavior

### Risk: Increased Code Complexity
- **Mitigation**: Standardized patterns will actually reduce complexity over time
- **Trade-off**: Short-term complexity increase for long-term maintainability

## Migration Plan

1. **Phase 1**: Fix EditPlanPage data access patterns
2. **Phase 2**: Fix ReportsPage provider architecture
3. **Phase 3**: Improve ExerciseDataService error handling
4. **Phase 4**: Add consistent loading states
5. **Phase 5**: Comprehensive testing and validation

## Open Questions

- Should we implement any additional caching mechanisms for frequently accessed data?
- Are there any other pages that might have similar data access issues?
- Should we consider implementing a unified data access service for all pages?
