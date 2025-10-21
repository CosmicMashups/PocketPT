## Why

The current profile page allows users to edit their email address, which is not a standard practice in most applications and can lead to authentication issues. Additionally, the first name, last name, and password editing functionality needs to be properly implemented with validation and proper data persistence.

## What Changes

- **REMOVED**: Email field from profile editing dialog
- **FIXED**: First name and last name editing with proper validation and immediate UI updates
- **FIXED**: Password change functionality with proper validation, Firebase authentication update, and local storage persistence
- **IMPROVED**: User feedback and error handling for all profile editing operations

## Impact

- Affected specs: user-profile (new capability)
- Affected code: `lib/profile/profile_page.dart`, `lib/data/functions.dart` (showCustomInputDialog), `lib/data/globals.dart` (UserDetails)
- Breaking changes: None - this is a UI/UX improvement that maintains existing functionality while fixing broken features
