## 1. Remove Email Editing
- [x] 1.1 Remove email field from profile editing dialog in `_buildProfileSection()`
- [x] 1.2 Update `showCustomInputDialog` call to only include first name and last name fields
- [x] 1.3 Ensure email remains visible as read-only in profile display
- [x] 1.4 Test that email field is no longer editable

## 2. Fix First Name & Last Name Editing
- [x] 2.1 Implement proper validation for first name and last name (non-empty)
- [x] 2.2 Ensure changes are saved to `UserDataNotifier.instance.updateUserData()`
- [x] 2.3 Verify changes are persisted to Hive via `UserDetails.saveToHive()`
- [x] 2.4 Verify changes are synced to Firebase via `UserDetails.updateInFirebase()`
- [x] 2.5 Test immediate UI updates after successful changes
- [x] 2.6 Add proper error handling and user feedback

## 3. Fix Password Change Functionality
- [x] 3.1 Implement password validation (minimum length, confirmation matching)
- [x] 3.2 Add Firebase authentication password update using `FirebaseAuth.currentUser?.updatePassword()`
- [x] 3.3 Ensure password changes are saved to local storage via `UserDetails.saveToHive()`
- [x] 3.4 Add proper error handling for Firebase authentication failures
- [x] 3.5 Add proper error handling for network connectivity issues
- [x] 3.6 Provide clear success/error feedback to users
- [x] 3.7 Test password changes work for both authenticated and guest users

## 4. Testing & Validation
- [x] 4.1 Test profile editing with authenticated users
- [x] 4.2 Test profile editing with guest users
- [x] 4.3 Test error scenarios (network failures, validation errors)
- [x] 4.4 Verify data persistence across app restarts
- [x] 4.5 Test immediate UI updates after successful changes
- [x] 4.6 Validate that email field is read-only and not editable
