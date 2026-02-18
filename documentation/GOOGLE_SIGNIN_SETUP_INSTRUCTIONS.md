# Google Sign-In Setup Instructions

## SHA-1 Fingerprint Generation

To complete the Google Sign-In setup, you need to generate the SHA-1 fingerprint for your debug keystore and update the Firebase configuration.

### Step 1: Generate SHA-1 Fingerprint

Run the following command in your terminal:

```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

**Windows users:**
```bash
keytool -list -v -keystore "C:\Users\sheila brown\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

**Alternative method if keytool is not in PATH:**
```bash
# Find your Java installation
"C:\Program Files\Java\jdk-*\bin\keytool.exe" -list -v -keystore "C:\Users\sheila brown\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

### Step 2: Extract SHA-1 Fingerprint

Look for the line that says `SHA1:` and copy the fingerprint value (it should look like: `AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD`)

### Step 3: Update Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your PocketPT project
3. Go to Project Settings (gear icon)
4. Scroll down to "Your apps" section
5. Find your Android app and click on it
6. Add the SHA-1 fingerprint you copied in Step 2
7. Click "Save"

### Step 4: Download Updated Configuration

1. After adding the SHA-1 fingerprint, click "Download google-services.json"
2. Replace the existing `android/app/google-services.json` file with the new one

### Step 5: Verify Configuration

The `google-services.json` file should now have the actual SHA-1 fingerprint in the `certificate_hash` field instead of just "sha1".

## Testing Google Sign-In

After completing the setup:

1. Clean and rebuild your Flutter app:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

2. Test Google Sign-In functionality:
   - Try signing in with a new Google account
   - Try signing in with an existing Google account
   - Test error scenarios (network issues, cancellation)

## Troubleshooting

### Common Issues:

1. **"Google Sign-In is not enabled"**
   - Ensure Google Sign-In is enabled in Firebase Console > Authentication > Sign-in method

2. **"Invalid SHA-1 fingerprint"**
   - Double-check the SHA-1 fingerprint was added correctly to Firebase Console
   - Ensure you're using the correct keystore (debug vs release)

3. **"Network request failed"**
   - Check internet connection
   - Verify Firebase project configuration
   - Check if Google services are accessible

4. **Web platform issues**
   - Ensure the Google Sign-In script is loaded in `web/index.html`
   - Verify the web client ID is configured correctly

## Configuration Files Updated

The following files have been updated to support Google Sign-In:

- `lib/data/simple_auth_service.dart` - Enhanced configuration and error handling
- `web/index.html` - Added Google Sign-In script
- `ios/Runner/Info.plist` - Already configured with proper URL schemes
- `android/app/google-services.json` - Needs to be updated with SHA-1 fingerprint

## Features Implemented

- ✅ Enhanced GoogleSignIn configuration with proper client IDs
- ✅ Web platform support
- ✅ Comprehensive error handling
- ✅ Retry logic with exponential backoff
- ✅ Account linking support
- ✅ Cross-platform compatibility (Android, iOS, Web)

## Next Steps

1. Complete the SHA-1 fingerprint setup as described above
2. Test the Google Sign-In functionality on all platforms
3. Monitor for any authentication issues
4. Consider adding analytics tracking for sign-in success rates
