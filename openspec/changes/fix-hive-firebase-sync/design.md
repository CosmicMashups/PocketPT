## Context
PocketPT currently has race conditions in its Hive-Firebase sync architecture where widgets display empty content due to ambiguous data flow. The sync logic inconsistently handles local vs remote data, and widgets don't explicitly load from Hive before displaying content.

## Goals / Non-Goals
- Goals: Make Hive the single source of truth, eliminate race conditions, ensure widgets display data immediately, implement deterministic conflict resolution
- Non-Goals: Complete rewrite of existing architecture, breaking existing user data, changing Firebase schema

## Decisions
- Decision: Use timestamp-based conflict resolution with last-write-wins strategy
- Alternatives considered: Manual conflict resolution UI, server-side conflict resolution
- Rationale: Simple, deterministic, and works well for rehabilitation data that doesn't have complex merge requirements

- Decision: Remove Firebase fallback from loadFromHive() methods
- Alternatives considered: Keep fallback but add flags, add separate fallback methods
- Rationale: Eliminates circular dependencies and makes data flow predictable

- Decision: Implement background Firebase sync that doesn't block UI
- Alternatives considered: Blocking sync, user-triggered sync only
- Rationale: Maintains responsive UX while ensuring data consistency

## Risks / Trade-offs
- Risk: Data loss during sync conflicts → Mitigation: Always save merged result to Hive, comprehensive logging
- Risk: Increased complexity in sync logic → Mitigation: Clear separation of concerns, extensive testing
- Risk: Performance impact from timestamp tracking → Mitigation: Minimal overhead, only for modified data

## Migration Plan
1. Add lastModified fields to existing data models
2. Update sync service with new architecture
3. Update widgets to explicitly load from Hive
4. Add sync queue for offline operations
5. Test thoroughly with existing user data

## Open Questions
- Should we implement sync conflict notifications to users?
- How should we handle sync failures when user is offline for extended periods?
