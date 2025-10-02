# Guest Mode Implementation

## Overview

This document describes the Guest Mode feature implementation for the PocketPT application. Guest Mode allows users to use the application without creating an account, with all data stored locally using Hive database instead of Firebase.

## Architecture

### Components

1. **GuestModeService** (`lib/data/guest_mode_service.dart`)
   - Core service managing guest sessions and local-only data storage
   - Handles guest session lifecycle (start, load, save, end)
   - Manages guest user data initialization

2. **Updated UserDetails** (`lib/data/globals.dart`)
   - Added `isGuest` and `guestSessionId` fields
   - Updated Hive persistence methods to handle guest data
   - Enhanced data clearing methods for guest mode

3. **Updated HiveUserDetails** (`lib/data/hive_models.dart`)
   - Added guest fields to Hive model for persistence
   - Maintains backward compatibility with existing data

4. **Updated RehabilitationPlan** (`lib/data/rehabilitation_plan.dart`)
   - Added `isGuestPlan` field to distinguish guest plans
   - Enhanced plan structure with metadata fields

5. **Updated SimpleDataSyncService** (`lib/data/simple_data_sync_service.dart`)
   - Added guest mode detection and handling
   - Separate sync logic for guest vs authenticated users
   - Local-only data operations for guest mode

6. **Updated LoginPage** (`lib/welcome/login_page.dart`)
   - Added "Continue as Guest" button
   - Integrated guest mode initialization

## Features

### Guest Session Management
- **Unique Session IDs**: Each guest session gets a unique identifier
- **Session Persistence**: Guest sessions persist across app restarts
- **Session Cleanup**: Automatic cleanup when guest session ends

### Local Data Storage
- **Hive Database**: All guest data stored locally using Hive
- **No Firebase**: Guest mode completely bypasses Firebase operations
- **Data Isolation**: Guest data is separate from authenticated user data

### User Experience
- **Seamless Access**: Users can start using the app immediately
- **Data Persistence**: All progress and data saved locally
- **Session Continuity**: Data persists when app is closed and reopened

## Technical Implementation

### Guest Session Lifecycle

#### 1. Session Start
```dart
// Initialize guest mode service
await _guestModeService.initialize();

// Start guest session
final result = await _guestModeService.startGuestSession();
```

#### 2. Data Management
```dart
// Save data (Hive only)
await _guestModeService.saveData();

// Load data (Hive only)
await _guestModeService.loadData();
```

#### 3. Session End
```dart
// End guest session and clear data
await _guestModeService.endGuestSession();
```

### Data Structure

#### Guest User Details
```dart
UserDetails.firstName = 'Guest';
UserDetails.lastName = 'User';
UserDetails.email = 'guest@local.app';
UserDetails.isGuest = true;
UserDetails.guestSessionId = 'guest_1234567890_1234';
```

#### Guest Rehabilitation Plan
```dart
RehabilitationPlan(
  weekNumber: 1,
  exerciseReferences: [],
  id: 'guest_default_plan',
  name: 'Guest Exercise Plan',
  description: 'A basic exercise plan for guest users',
  isGuestPlan: true,
);
```

### Hive Storage Structure
```dart
// Guest session metadata
'guest_mode': true
'guest_session_id': 'guest_1234567890_1234'
'guest_session_start': '2024-01-01T00:00:00.000Z'
'guest_session_last_activity': '2024-01-01T12:00:00.000Z'

// User details with guest flags
'userDetails': HiveUserDetails(
  firstName: 'Guest',
  lastName: 'User',
  email: 'guest@local.app',
  isGuest: true,
  guestSessionId: 'guest_1234567890_1234',
)
```

## User Flow

### Guest Mode Entry
1. User opens the app
2. User sees login page with "Continue as Guest" option
3. User clicks "Continue as Guest"
4. System initializes guest session
5. User is taken to home page with guest data

### Data Persistence
1. All user actions (exercises, assessments, progress) are saved to Hive
2. Data persists across app restarts
3. No network connection required for data operations

### Session Management
1. Guest session continues until explicitly ended
2. Data can be cleared at any time
3. Session can be converted to authenticated account (future feature)

## Security Considerations

### Data Isolation
- Guest data is completely separate from authenticated user data
- No risk of data mixing between guest and authenticated sessions
- Local storage only - no cloud synchronization

### Privacy
- No personal information required for guest mode
- All data stays on the device
- No tracking or analytics in guest mode

### Session Security
- Unique session IDs prevent session conflicts
- Automatic session cleanup prevents data accumulation
- Clear separation between guest and authenticated data

## Configuration

### Guest Mode Settings
```dart
// Session timeout (optional)
static const Duration _sessionTimeout = Duration(hours: 24);

// Data retention (optional)
static const Duration _dataRetention = Duration(days: 30);
```

### Hive Configuration
```dart
// Initialize Hive for guest mode
if (!Hive.isBoxOpen('rehabBox')) {
  await Hive.openBox('rehabBox');
}
```

## Testing

### Test Scenarios
1. **Guest Session Start**
   - Verify guest session initialization
   - Check unique session ID generation
   - Confirm guest user data setup

2. **Data Persistence**
   - Save data in guest mode
   - Restart app and verify data persistence
   - Check data isolation from authenticated users

3. **Session Management**
   - Test session continuation across app restarts
   - Verify session cleanup on end
   - Check data clearing functionality

4. **UI Integration**
   - Test "Continue as Guest" button
   - Verify loading states and error handling
   - Check navigation flow

### Edge Cases
- App crash during guest session
- Multiple guest sessions (should not occur)
- Data corruption in Hive storage
- Insufficient storage space

## Future Enhancements

### Potential Improvements
1. **Session Conversion**
   - Allow guests to convert to authenticated accounts
   - Migrate guest data to Firebase
   - Preserve user progress and history

2. **Data Export**
   - Export guest data for backup
   - Import data to new device
   - Data portability features

3. **Guest Analytics**
   - Track guest usage patterns
   - Identify conversion opportunities
   - Improve guest experience

4. **Session Limits**
   - Time-based session expiration
   - Data usage limits
   - Feature restrictions for guests

## Troubleshooting

### Common Issues
1. **Guest Session Not Starting**
   - Check Hive initialization
   - Verify service initialization
   - Check for storage permissions

2. **Data Not Persisting**
   - Verify Hive box is open
   - Check data saving methods
   - Confirm guest mode detection

3. **Session Conflicts**
   - Clear existing guest data
   - Restart guest session
   - Check for multiple service instances

### Debug Information
```dart
// Enable debug logging
print('GuestModeService: Debug information');
print('Session ID: ${_guestSessionId}');
print('Guest Mode: ${_isGuestMode}');
print('Data Count: ${UserRehabilitation.instance.rehabPlans.length}');
```

## Conclusion

The Guest Mode feature provides a seamless way for users to experience the PocketPT application without creating an account. All data is stored locally using Hive, ensuring privacy and offline functionality. The implementation is robust, secure, and provides a foundation for future enhancements like session conversion and data export.

The modular design allows for easy maintenance and testing, while the comprehensive error handling ensures a smooth user experience even in edge cases.
