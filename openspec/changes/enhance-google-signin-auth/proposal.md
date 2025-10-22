## Why
The existing Google Sign-In functionality in `@login_page.dart` has configuration issues that prevent it from working properly across all platforms. The main problem is the missing SHA-1 certificate fingerprint configuration in `google-services.json`, which prevents Google Sign-In from authenticating users on Android. Additionally, the GoogleSignIn instance lacks proper configuration for web platform support and comprehensive error handling for different failure scenarios.

## What Changes
- **Fix SHA-1 Certificate Configuration**: Generate and configure proper SHA-1 fingerprint in google-services.json and Firebase Console
- **Enhance GoogleSignIn Configuration**: Add proper client ID configuration for web platform and improve scopes
- **Improve Error Handling**: Add comprehensive error handling for different failure scenarios including network issues, account linking conflicts, and authentication failures
- **Add Retry Logic**: Implement retry mechanism for temporary network failures with exponential backoff
- **Platform-Specific Configuration**: Ensure proper configuration for Android, iOS, and Web platforms
- **Account Linking Support**: Handle cases where users try to sign in with Google but have existing email/password accounts

## Impact
- Affected specs: authentication capability (new)
- Affected code: `lib/data/simple_auth_service.dart`, `lib/welcome/login_page.dart`, `android/app/google-services.json`, `web/index.html`, `ios/Runner/Info.plist`
- New capabilities: Production-ready Google Sign-In authentication with comprehensive error handling and platform support
