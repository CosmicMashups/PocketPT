## ADDED Requirements

### Requirement: Unified Data Model Schema
The system SHALL maintain consistent data models between Hive and Firebase storage with identical field names, data types, and null-safety patterns.

#### Scenario: Field naming consistency
- **WHEN** data is saved to Hive using field name `first_name`
- **THEN** the same data is saved to Firebase using field name `firstName`
- **AND** both systems use camelCase naming convention

#### Scenario: Data type consistency
- **WHEN** a DateTime value is stored in Hive as milliseconds since epoch
- **THEN** the same value is stored in Firebase as a Timestamp object
- **AND** conversion between formats is handled transparently

#### Scenario: Null safety consistency
- **WHEN** a nullable field is stored in Hive with a default value
- **THEN** the same field is stored in Firebase with the same default value
- **AND** both systems handle null values identically

### Requirement: Data Validation and Integrity
The system SHALL validate all data before storage and ensure integrity across both storage systems.

#### Scenario: Data validation before save
- **WHEN** data is about to be saved to either Hive or Firebase
- **THEN** the system validates field types, required fields, and data ranges
- **AND** invalid data is rejected with appropriate error messages

#### Scenario: Data integrity verification
- **WHEN** data is loaded from storage
- **THEN** the system verifies data integrity and consistency
- **AND** corrupted data is automatically repaired or flagged for manual review

### Requirement: Migration Support
The system SHALL provide migration capabilities for existing user data to the new unified schema.

#### Scenario: Automatic data migration
- **WHEN** existing user data is detected with old schema
- **THEN** the system automatically migrates data to new unified schema
- **AND** original data is preserved as backup

#### Scenario: Migration rollback
- **WHEN** data migration fails or causes issues
- **THEN** the system can rollback to previous schema
- **AND** user data is restored to pre-migration state

## MODIFIED Requirements

### Requirement: Hive Storage Structure
The Hive storage structure SHALL be aligned with Firebase document structure for 1:1 mapping and simplified synchronization.

#### Scenario: Flat document structure
- **WHEN** user data is stored in Hive
- **THEN** it uses the same flat structure as Firebase documents
- **AND** nested objects are flattened with consistent field naming

#### Scenario: ID-only references
- **WHEN** rehabilitation plans reference exercises or treatments
- **THEN** only IDs are stored in both Hive and Firebase
- **AND** full object data is resolved from CSV sources when needed

### Requirement: Firebase Document Structure
The Firebase document structure SHALL be optimized for consistency with Hive storage and efficient synchronization.

#### Scenario: Consistent field mapping
- **WHEN** data is saved to Firebase
- **THEN** field names match exactly with Hive storage
- **AND** data types are compatible between systems

#### Scenario: Timestamp handling
- **WHEN** timestamps are stored in Firebase
- **THEN** they use FieldValue.serverTimestamp() for creation
- **AND** they use Timestamp.fromDate() for specific dates

## REMOVED Requirements

### Requirement: Legacy Hive Model Classes
**Reason**: Replaced with unified data models that work with both storage systems
**Migration**: Existing Hive model classes will be deprecated and replaced with unified models

### Requirement: Separate Firebase and Hive Sync Logic
**Reason**: Unified sync logic eliminates inconsistencies and race conditions
**Migration**: Separate sync methods will be consolidated into unified sync service
