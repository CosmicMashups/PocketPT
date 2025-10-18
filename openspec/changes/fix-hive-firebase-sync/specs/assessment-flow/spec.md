## MODIFIED Requirements
### Requirement: Assessment Data Loading
Assessment widgets SHALL load data from Hive storage before displaying content to ensure users see their data immediately.

#### Scenario: Assessment widget initialization
- **WHEN** an assessment widget is loaded
- **THEN** the widget SHALL explicitly load UserAssess data from Hive
- **THEN** the widget SHALL copy Hive data to AssessmentData in-memory storage
- **THEN** the widget SHALL display the loaded data
- **THEN** the widget SHALL trigger background Firebase sync

#### Scenario: Assessment data persistence
- **WHEN** user completes assessment steps
- **THEN** data SHALL be saved to AssessmentData in-memory storage
- **THEN** data SHALL be saved to UserAssess Hive storage
- **THEN** data SHALL be queued for Firebase sync
- **THEN** UI SHALL reflect changes immediately

## ADDED Requirements
### Requirement: Explicit Data Loading
Assessment widgets SHALL not rely on data being pre-loaded in memory and SHALL explicitly load from Hive on initialization.

#### Scenario: Goal selection widget loads data
- **WHEN** AssessGoal1 widget is initialized
- **THEN** the widget SHALL call UserAssess.loadFromHive()
- **THEN** the widget SHALL copy UserAssess.rehabGoal to AssessmentData.rehabGoal
- **THEN** the widget SHALL display the current goal selection
- **THEN** the widget SHALL trigger background sync

#### Scenario: Muscle selection widget loads data
- **WHEN** muscle selection widget is initialized
- **THEN** the widget SHALL call UserAssess.loadFromHive()
- **THEN** the widget SHALL copy UserAssess.generalMuscle to AssessmentData.generalMuscle
- **THEN** the widget SHALL display the current muscle selection
- **THEN** the widget SHALL trigger background sync

### Requirement: Background Sync Integration
Assessment widgets SHALL trigger background Firebase sync after loading data to ensure cloud synchronization.

#### Scenario: Trigger background sync
- **WHEN** assessment data is loaded from Hive
- **THEN** the widget SHALL trigger DataSyncService.instance.syncAllData() in background
- **THEN** sync failures SHALL not block the UI
- **THEN** sync errors SHALL be logged for debugging

#### Scenario: Handle sync errors
- **WHEN** background sync fails
- **THEN** the error SHALL be logged
- **THEN** the UI SHALL continue to function normally
- **THEN** sync SHALL be retried on next app launch
