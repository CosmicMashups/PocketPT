## Why
The current PocketPT codebase has critical data schema inconsistencies between Hive (local storage) and Firebase (cloud storage) that cause data loss, sync failures, and runtime exceptions. Analysis reveals mismatched field names, incompatible data types, inconsistent null-safety handling, and conflicting storage structures that prevent reliable data synchronization.

## What Changes
- **BREAKING**: Unify all data model field names between Hive and Firebase to use consistent camelCase naming
- **BREAKING**: Standardize data types across both storage systems (DateTime handling, nullable fields, list types)
- **BREAKING**: Implement consistent null-safety patterns with proper default values and safe access
- **BREAKING**: Align Hive box structure with Firebase collection/document structure for 1:1 mapping
- **BREAKING**: Fix synchronization logic to prevent race conditions and data conflicts
- Add comprehensive data validation and integrity checks
- Implement proper error handling for missing or corrupted data
- Add migration logic for existing user data to new unified schema

## Impact
- Affected specs: data-persistence, data-sync, assessment-flow
- Affected code: lib/data/hive_models.dart, lib/data/globals.dart, lib/data/rehabilitation_plan.dart, lib/data/firebase_helper.dart, all sync services
- Performance: Eliminates sync failures and data corruption, improves reliability
- UX: Prevents data loss and ensures consistent user experience across devices
- Data integrity: Ensures all user data is properly preserved and synchronized
