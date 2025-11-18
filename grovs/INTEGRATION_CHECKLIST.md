# Grovs Flutter Plugin - Integration Checklist

Use this checklist to ensure your Grovs integration is complete.

## ✅ Plugin Setup

- [ ] Plugin is added to `pubspec.yaml`
- [ ] `flutter pub get` has been run
- [ ] No build errors in the plugin code

## ✅ Flutter/Dart Implementation

- [ ] Grovs SDK is configured in `main.dart`
- [ ] API key is set (replace `'your-api-key'` with actual key)
- [ ] Environment is set (production or test)
- [ ] Deeplink listener is set up
- [ ] User identifier is set (optional but recommended)
- [ ] User attributes are set (optional)

### Example:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final grovs = Grovs();
  await grovs.configure('YOUR-ACTUAL-API-KEY', useTestEnvironment: false);
  await grovs.setUserIdentifier('user-123');
  
  runApp(MyApp());
}

// Setup deeplink listener
grovs.onDeeplinkReceived.listen((details) {
  // Handle deeplink
});
```

## ✅ Android Integration

### Build Configuration
- [ ] Grovs SDK dependency is in `android/build.gradle` (plugin)
- [ ] Minimum SDK version is 24 or higher
- [ ] Build succeeds without errors

### MainActivity
- [ ] `Grovs.onStart(this)` is called in `onStart()`
- [ ] `Grovs.onNewIntent(intent, this)` is called in `onNewIntent()`
- [ ] MainActivity imports: `import io.grovs.Grovs`

### AndroidManifest.xml
- [ ] Internet permission is added
- [ ] Custom URL scheme intent filter is added
- [ ] Universal links intent filter is added (production)
- [ ] Universal links intent filter is added (test, if needed)
- [ ] `android:launchMode="singleTop"` is set on MainActivity
- [ ] `android:autoVerify="true"` is set on universal link intent filters

### Deep Link Configuration
- [ ] Custom URL scheme is decided (e.g., `myapp://`)
- [ ] Production domain is configured (e.g., `https://myapp.com`)
- [ ] Test domain is configured if needed (e.g., `https://test.myapp.com`)
- [ ] Digital Asset Links file is hosted at `https://yourdomain.com/.well-known/assetlinks.json`

### Testing
- [ ] Custom URL scheme works: `adb shell am start -W -a android.intent.action.VIEW -d "yourscheme://open"`
- [ ] Universal links work: `adb shell am start -W -a android.intent.action.VIEW -d "https://yourdomain.com/path"`
- [ ] Deeplink callbacks are received in Flutter
- [ ] Link generation works

## ✅ iOS Integration

### Build Configuration
- [ ] CocoaPods dependencies are installed (`cd ios && pod install`)
- [ ] Build succeeds without errors
- [ ] Deployment target is iOS 13.0 or higher

### AppDelegate.swift
- [ ] Import statement added: `import Grovs`
- [ ] `Grovs.handleAppDelegate(continue:restorationHandler:)` is called
- [ ] `Grovs.handleAppDelegate(open:options:)` is called
- [ ] Push token registration is implemented (if using push)

### SceneDelegate.swift (if applicable)
- [ ] Import statement added: `import Grovs`
- [ ] `Grovs.handleSceneDelegate(options:)` is called
- [ ] `Grovs.handleSceneDelegate(openURLContexts:)` is called
- [ ] `Grovs.handleSceneDelegate(continue:)` is called

### Info.plist
- [ ] Custom URL scheme is configured in `CFBundleURLTypes`
- [ ] URL scheme name matches bundle identifier
- [ ] Background modes includes `remote-notification` (if using push)

### Xcode Project
- [ ] Associated Domains capability is added
- [ ] Domains are added (e.g., `applinks:yourdomain.com`)
- [ ] Push Notifications capability is added (if using push)
- [ ] Signing is configured correctly

### AASA Configuration
- [ ] AASA file is created
- [ ] Team ID is correct in AASA file
- [ ] Bundle ID is correct in AASA file
- [ ] AASA file is hosted at `https://yourdomain.com/.well-known/apple-app-site-association`
- [ ] AASA file is accessible via HTTPS
- [ ] AASA file has correct Content-Type (`application/json`)

### Testing
- [ ] Custom URL scheme works: `xcrun simctl openurl booted "yourscheme://open"`
- [ ] Universal links work: Open link in Safari on device
- [ ] Deeplink callbacks are received in Flutter
- [ ] Link generation works
- [ ] Push notifications work (on physical device only)

## ✅ Push Notifications (Optional)

### Android (FCM)
- [ ] Firebase project is created
- [ ] `google-services.json` is added to Android app
- [ ] Firebase Messaging dependency is added
- [ ] FCM token is retrieved in Flutter
- [ ] Token is passed to Grovs: `await grovs.setPushToken(token)`
- [ ] Token refresh is handled

### iOS (APNs)
- [ ] APNs certificate is configured in Apple Developer Portal
- [ ] Push Notifications capability is enabled in Xcode
- [ ] Token registration is implemented in AppDelegate
- [ ] Token is passed to Grovs: `Grovs.pushToken = token`
- [ ] Testing on physical device (simulator doesn't support push)

## ✅ Feature Testing

### Link Generation
- [ ] Basic link generation works
- [ ] Link with title and subtitle works
- [ ] Link with image URL works
- [ ] Link with custom data works
- [ ] Link with tags works
- [ ] Link with custom redirects works
- [ ] Link with platform-specific previews works
- [ ] Generated links can be shared
- [ ] Generated links can be copied

### Deep Link Handling
- [ ] App opens from custom URL scheme
- [ ] App opens from universal link
- [ ] Deeplink callback is triggered
- [ ] Payload data is received correctly
- [ ] Navigation based on payload works
- [ ] Deep links work when app is closed
- [ ] Deep links work when app is in background
- [ ] Deep links work when app is in foreground

### Messages
- [ ] Unread message count is retrieved
- [ ] Message count badge is displayed
- [ ] Messages view opens correctly
- [ ] Message count updates after viewing messages
- [ ] Push notifications are received (if configured)
- [ ] Tapping push notification opens app

### User Management
- [ ] User identifier is set successfully
- [ ] User attributes are set successfully
- [ ] User data persists across app restarts

### Debug & Logging
- [ ] Debug level can be changed
- [ ] Logs appear in console/logcat
- [ ] Error messages are clear and helpful

## ✅ Production Readiness

### Configuration
- [ ] Production API key is used
- [ ] `useTestEnvironment: false` is set
- [ ] Production domains are configured
- [ ] Test code and API keys are removed

### Security
- [ ] API key is not hardcoded (use environment variables or secure storage)
- [ ] Sensitive user data is handled securely
- [ ] HTTPS is used for all links

### Performance
- [ ] Link generation is reasonably fast
- [ ] Deeplink handling doesn't block UI
- [ ] No memory leaks from stream subscriptions
- [ ] App doesn't crash when handling deeplinks

### Error Handling
- [ ] Network errors are handled gracefully
- [ ] Invalid API keys show clear error messages
- [ ] Failed link generation is handled
- [ ] User is notified of errors appropriately

### Documentation
- [ ] Integration steps are documented for your team
- [ ] Deeplink URL format is documented
- [ ] Custom data payload format is documented
- [ ] Troubleshooting steps are documented

## ✅ Final Verification

- [ ] App builds successfully on Android
- [ ] App builds successfully on iOS
- [ ] All tests pass
- [ ] App is tested on real devices (Android & iOS)
- [ ] Deeplinks work end-to-end
- [ ] No console errors or warnings
- [ ] Performance is acceptable
- [ ] Ready for App Store / Play Store submission

## Common Issues & Solutions

### "Failed to configure Grovs"
- ✓ Check API key is correct
- ✓ Check internet connection
- ✓ Check if useTestEnvironment matches your setup

### "Deeplinks not received"
- ✓ Check MainActivity/AppDelegate implementation
- ✓ Check intent filters/URL schemes configuration
- ✓ Check deeplink listener is set up before link is opened
- ✓ Test with adb/xcrun commands first

### "Universal links open in browser instead of app"
- ✓ Check AASA/Digital Asset Links file
- ✓ Verify domains match exactly
- ✓ Try reinstalling the app
- ✓ Check associated domains configuration

### "Push notifications not working"
- ✓ Test on physical device (not simulator)
- ✓ Check token is being sent to Grovs
- ✓ Verify push certificates are valid
- ✓ Check notification permissions are granted

## Resources

- [Main README](README.md)
- [Android Integration Guide](ANDROID_INTEGRATION.md)
- [iOS Integration Guide](IOS_INTEGRATION.md)
- [Implementation Summary](IMPLEMENTATION_SUMMARY.md)
- [Grovs Documentation](https://grovs.io)

---

**Need Help?** Check the troubleshooting sections in the integration guides or visit [https://grovs.io](https://grovs.io)
