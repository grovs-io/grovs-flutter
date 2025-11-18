# Quick Start Guide - Grovs Flutter Plugin

Get deep linking and attribution working in your Flutter app in under 5 minutes.

## What You'll Get

- ✅ Deep link handling
- ✅ Link generation with tracking
- ✅ Basic attribution

## Prerequisites

- Flutter SDK
- Android Studio (for Android)
- Xcode (for iOS)
- Grovs account with API key ([grovs.io](https://grovs.io))

## 1. Add Dependency

Add to your `pubspec.yaml`:

```yaml
dependencies:
  grovs_flutter_plugin: ^1.0.0
```

Run:
```bash
flutter pub get
```

## 2. Platform Configuration

No Dart code configuration needed! Configure via native platform files:

### Android Setup

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<application>
    <!-- Grovs Configuration -->
    <meta-data
        android:name="grovs_api_key"
        android:value="YOUR_API_KEY" />
    <meta-data
        android:name="grovs_use_test_environment"
        android:value="true" /> <!-- Set to false for production -->
</application>
```

### iOS Setup

Add to `ios/Runner/Info.plist`:

```xml
<key>GROVS_API_KEY</key>
<string>YOUR_API_KEY</string>
<key>GROVS_USE_TEST_ENVIRONMENT</key>
<true/> <!-- Set to <false/> for production -->
```

Then run:
```bash
cd ios && pod install && cd ..
```

## 3. Handle Deeplinks

```dart
import 'package:grovs_flutter_plugin/grovs.dart';

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    
    // Listen for deeplinks
    Grovs.setOnDeeplinkReceivedListener((details) {
      print('📱 Deeplink received!');
      print('Link: ${details.link}');
      print('Payload: ${details.payload}');
      print('Tracking: ${details.tracking}');
      
      // Navigate based on deeplink data
      // Example: Navigator.pushNamed(context, details.payload['screen']);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: HomeScreen());
  }
}
```

## 4. Generate Links with Tracking

```dart
import 'package:grovs_flutter_plugin/grovs.dart';
import 'package:grovs_flutter_plugin/models/grovs_link.dart';

Future<String> createShareLink() async {
  final link = await Grovs.generateLink(
    GenerateLinkParams(
      title: 'Check this out!',
      subtitle: 'Amazing content',
      imageUrl: 'https://example.com/image.jpg',
      payload: {'screen': 'product', 'id': '123'},
      customRedirects: {
        'ios': 'https://apps.apple.com/app/myapp',
        'android': 'https://play.google.com/store/apps/details?id=com.myapp',
      },
      tracking: TrackingParams(
        utmCampaign: 'spring_sale',
        utmSource: 'email',
        utmMedium: 'newsletter',
      ),
    ),
  );
  
  return link; // Share this link
}
```

## 5. Setup Deep Link Schemes

### Android Setup

**AndroidManifest.xml:**
```xml
<activity android:name=".MainActivity">
    <!-- Custom URL Scheme -->
    <intent-filter>
        <data android:scheme="myapp" android:host="open" />
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
    </intent-filter>
</activity>
```

**Note:** The plugin automatically handles `Grovs.onStart()` and `Grovs.onNewIntent()` lifecycle callbacks. No MainActivity changes needed!

### iOS Setup

Add to `ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>myapp</string>
        </array>
    </dict>
</array>
```

**Note:** The plugin automatically handles `application(_:didFinishLaunchingWithOptions:)`, `application(_:continue:restorationHandler:)`, and `application(_:open:options:)`. No AppDelegate changes needed!

## 6. Test It!

**Android:**
```bash
adb shell am start -W -a android.intent.action.VIEW -d "myapp://open?test=123"
```

**iOS:**
```bash
xcrun simctl openurl booted "myapp://open?test=123"
```

## ✅ You're Done!

Your app now supports:
- ✅ Deep linking with custom URL schemes
- ✅ Link generation with tracking parameters
- ✅ Automatic deeplink handling
- ✅ Attribution tracking

## Next Steps

1. **Configure Universal Links** - See [ANDROID_INTEGRATION.md](ANDROID_INTEGRATION.md) and [IOS_INTEGRATION.md](IOS_INTEGRATION.md)
2. **Add Push Notifications** - See README.md
3. **Set User Attributes** - See README.md
4. **Test on Real Devices** - Required for full testing

## Common First Issues

### "iOS: Module 'Grovs' not found"
→ Run `cd ios && pod install && cd ..`

### "Deeplink not received"
→ Make sure listener is set up BEFORE opening the link. The listener should be in `initState()`.

### "Build failed"
→ Run `flutter clean && flutter pub get`

### "Configuration not working"
→ Double-check your API key in AndroidManifest.xml (Android) and Info.plist (iOS)

## Need More Help?

- 📖 [Full README](README.md)
- 🤖 [Android Guide](ANDROID_INTEGRATION.md)
- 🍎 [iOS Guide](IOS_INTEGRATION.md)
- ✅ [Integration Checklist](INTEGRATION_CHECKLIST.md)
- 🌐 [Grovs.io](https://grovs.io)
