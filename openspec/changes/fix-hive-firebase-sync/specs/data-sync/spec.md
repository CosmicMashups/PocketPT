## MODIFIED Requirements
### Requirement: Data Synchronization
The system SHALL synchronize data between local Hive storage and Firebase cloud storage using an offline-first architecture where Hive is the single source of truth for the application.

#### Scenario: App startup data loading
- **WHEN** the application starts
- **THEN** all data SHALL be loaded from Hive first (blocking operation)
- **THEN** the UI SHALL display data immediately from Hive
- **THEN** Firebase sync SHALL occur in the background (non-blocking)

#### Scenario: User makes changes
- **WHEN** user modifies data in the application
- **THEN** changes SHALL be saved to Hive immediately
- **THEN** changes SHALL be queued for Firebase sync
- **THEN** UI SHALL update immediately from Hive data

#### Scenario: Offline operation
- **WHEN** user is offline and makes changes
- **THEN** changes SHALL be saved to Hive only
- **THEN** Firebase operations SHALL be queued for later sync
- **THEN** queue SHALL be persisted to Hive

#### Scenario: Conflict resolution
- **WHEN** local and remote data have conflicting changes
- **THEN** the system SHALL use timestamp-based last-write-wins resolution
- **THEN** the merged result SHALL be saved to Hive
- **THEN** the merged result SHALL be pushed to Firebase

## ADDED Requirements
### Requirement: Timestamp-based Conflict Resolution
The system SHALL track lastModified timestamps for all data entities and use these timestamps to resolve conflicts deterministically.

#### Scenario: Newer local data wins
- **WHEN** local data has a more recent lastModified timestamp than remote data
- **THEN** local data SHALL be used as the authoritative version
- **THEN** local data SHALL be pushed to Firebase

#### Scenario: Newer remote data wins
- **WHEN** remote data has a more recent lastModified timestamp than local data
- **THEN** remote data SHALL be merged with local data
- **THEN** merged data SHALL be saved to Hive with updated timestamp

### Requirement: Sync Queue for Offline Operations
The system SHALL maintain a queue of pending Firebase operations that can be executed when connectivity is restored.

#### Scenario: Queue offline operations
- **WHEN** user makes changes while offline
- **THEN** Firebase operations SHALL be added to sync queue
- **THEN** queue SHALL be persisted to Hive
- **THEN** operations SHALL be retried when connectivity returns

#### Scenario: Process sync queue
- **WHEN** connectivity is restored
- **THEN** queued operations SHALL be processed in order
- **THEN** successful operations SHALL be removed from queue
- **THEN** failed operations SHALL be retried with exponential backoff

### Requirement: Background Firebase Sync
The system SHALL perform Firebase synchronization in the background without blocking the user interface.

#### Scenario: Non-blocking sync
- **WHEN** background sync is triggered
- **THEN** sync operations SHALL not block UI updates
- **THEN** sync failures SHALL not affect local data access
- **THEN** sync progress SHALL be logged for debugging

#### Scenario: Sync retry logic
- **WHEN** Firebase sync fails
- **THEN** the system SHALL retry with exponential backoff
- **THEN** failed operations SHALL be logged with error details
- **THEN** sync SHALL be retried on next app launch if needed
