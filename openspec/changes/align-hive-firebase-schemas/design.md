## Context
PocketPT currently has significant data schema inconsistencies between Hive and Firebase storage systems. The analysis reveals:

1. **Field Naming Inconsistencies**: Hive uses snake_case while Firebase uses camelCase
2. **Data Type Mismatches**: DateTime handling differs between systems (milliseconds vs Timestamp)
3. **Null Safety Issues**: Inconsistent handling of nullable fields and default values
4. **Storage Structure Conflicts**: Hive uses complex nested objects while Firebase uses flat document structures
5. **Sync Logic Problems**: Race conditions and circular dependencies in data loading/saving

## Goals / Non-Goals
- Goals: Create unified data schema, eliminate sync failures, ensure data integrity, maintain backward compatibility
- Non-Goals: Complete rewrite of existing architecture, breaking existing user data, changing core business logic

## Decisions
- Decision: Use camelCase naming convention for all fields (matches Firebase standard)
- Alternatives considered: snake_case (Hive standard), PascalCase
- Rationale: Firebase is the authoritative source, camelCase is more common in Flutter/Dart

- Decision: Standardize on DateTime with millisecondsSinceEpoch for Hive and Timestamp for Firebase
- Alternatives considered: String dates, custom date formats
- Rationale: Maintains type safety while allowing proper conversion between systems

- Decision: Implement strict null-safety with explicit default values
- Alternatives considered: Nullable fields with runtime checks, optional fields
- Rationale: Prevents runtime exceptions and ensures predictable data behavior

- Decision: Use flat document structure in Firebase with ID-only references
- Alternatives considered: Nested documents, embedded objects
- Rationale: Simplifies sync logic and reduces data duplication

## Risks / Trade-offs
- Risk: Data migration complexity for existing users → Mitigation: Comprehensive migration scripts with rollback capability
- Risk: Performance impact from schema validation → Mitigation: Lightweight validation, only on data changes
- Risk: Breaking changes to existing code → Mitigation: Gradual migration with compatibility layers

## Migration Plan
1. Create unified data model interfaces
2. Implement data migration scripts for existing Hive data
3. Update Firebase document structure to match new schema
4. Refactor sync services to use unified models
5. Add comprehensive validation and error handling
6. Test with existing user data and rollback procedures

## Open Questions
- Should we implement automatic data repair for corrupted records?
- How should we handle version conflicts during migration?
- What is the rollback strategy if migration fails?
