# Grovs Flutter Plugin

A Flutter plugin for integrating the Grovs SDK, enabling deep linking, universal linking, smart link generation with tracking parameters, and user attribution in your Flutter applications.

## Features

- 🔗 **Deep Linking**: Generate and handle Grovs links with automatic lifecycle management
- 📱 **Universal Links**: Support for both Android App Links and iOS Universal Links
- � **Attribution Tracking**: UTM campaign tracking with campaign, source, and medium parameters
- � **User Management**: Set user identifiers and attributes for personalized experiences
- 🎯 **Custom Redirects**: Platform-specific redirect URLs for iOS, Android, and desktop
- 🐛 **Debug Support**: Configurable debug levels for development
- ⚡ **Auto-Configuration**: Platform configuration via AndroidManifest.xml and Info.plist

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  grovs_flutter_plugin: ^1.0.0
```

Then run:

```bash
flutter pub get
```

## Platform Setup

### Android

1. **Add Configuration to AndroidManifest.xml**

Add the Grovs API key and environment setting to `android/app/src/main/AndroidManifest.xml`:

```xml
<application>
    <!-- Grovs Configuration -->
    <meta-data
        android:name="grovs_api_key"
        android:value="YOUR_API_KEY" />
    <meta-data
        android:name="grovs_use_test_environment"
        android:value="true" /> <!-- Set to false for production -->
    
    <!-- Your other configuration -->
</application>
```

2. **Add Intent Filters**

Configure deep link schemes in your main activity:

```xml
<activity android:name=".MainActivity">
    <!-- Custom URL Scheme -->
    <intent-filter>
        <data android:scheme="myapp" android:host="open" />
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
    </intent-filter>

    <!-- Universal links (production) -->
    <intent-filter android:autoVerify="true">
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="https" android:host="your-domain.com" />
    </intent-filter>
</activity>
```

**Note:** The plugin automatically handles `Grovs.onStart()` and `Grovs.onNewIntent()` lifecycle callbacks. No MainActivity code changes needed!

### iOS

1. **Add Configuration to Info.plist**

Add the Grovs API key and environment setting to `ios/Runner/Info.plist`:

```xml
<key>GROVS_API_KEY</key>
<string>YOUR_API_KEY</string>
<key>GROVS_USE_TEST_ENVIRONMENT</key>
<true/> <!-- Set to <false/> for production -->
```

2. **Configure URL Schemes**

Add custom URL scheme support:

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

3. **Install Dependencies**

```bash
cd ios && pod install && cd ..
```

**Note:** The plugin automatically handles `application(_:didFinishLaunchingWithOptions:)`, `application(_:continue:restorationHandler:)`, and `application(_:open:options:)`. No AppDelegate changes needed!

**Note:** The plugin automatically handles `application(_:didFinishLaunchingWithOptions:)`, `application(_:continue:restorationHandler:)`, and `application(_:open:options:)`. No AppDelegate changes needed!

## Quick Start

For a 5-minute quick start guide, see [QUICK_START.md](QUICK_START.md).

## Usage

### Handle Deep Links

The SDK is automatically configured from your platform configuration files. Just set up the deeplink listener:

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
    
    // Set up deeplink listener
    Grovs.setOnDeeplinkReceivedListener((details) {
      print('📱 Deeplink received!');
      print('Link: ${details.link}');
      print('Payload: ${details.payload}');
      print('Tracking: ${details.tracking}');
      
      // Navigate based on deeplink data
      if (details.payload != null) {
        final payload = details.payload!;
        if (payload['screen'] == 'product') {
          Navigator.pushNamed(context, '/product', 
            arguments: payload['productId']);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomeScreen(),
    );
  }
}
```

### Generate Links with Tracking

```dart
import 'package:grovs_flutter_plugin/grovs.dart';
import 'package:grovs_flutter_plugin/models/grovs_link.dart';

Future<String> generateShareLink() async {
  try {
    final link = await Grovs.generateLink(
      GenerateLinkParams(
        title: 'Check out this amazing product!',
        subtitle: 'Limited time offer',
        imageUrl: 'https://example.com/product-image.png',
        payload: {
          'screen': 'product',
          'productId': '12345',
          'source': 'share',
        },
        tags: ['promotion', 'product-share'],
        tracking: TrackingParams(
          utmCampaign: 'spring_sale',
          utmSource: 'email',
          utmMedium: 'newsletter',
        ),
        customRedirects: {
          'ios': 'https://apps.apple.com/app/myapp',
          'android': 'https://play.google.com/store/apps/details?id=com.myapp',
          'desktop': 'https://myapp.com/product/12345',
        },
      ),
    );
    
    print('Generated link: $link');
    return link;
  } on GrovsException catch (e) {
    print('Failed to generate link: ${e.message}');
    rethrow;
  }
}
```

### User Management

```dart
Future<void> setupUser() async {
  // Set user identifier
  await Grovs.setUserIdentifier('user-123');
  
  // Set user attributes
  await Grovs.setUserAttributes({
    'name': 'John Doe',
    'email': 'john@example.com',
    'age': 30,
    'premium': true,
    'signupDate': '2024-01-01',
  });
}
```

### Debug Logging

```dart
// Set debug level during development
await Grovs.setDebugLevel('info');

// Available levels: 'verbose', 'debug', 'info', 'warning', 'error', 'none'
```

### Push Notifications

```dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:grovs_flutter_plugin/grovs.dart';

Future<void> setupPushNotifications() async {
  final messaging = FirebaseMessaging.instance;
  
  // Request permission
  await messaging.requestPermission();
  
  // Get FCM token
  final token = await messaging.getToken();
  if (token != null) {
    await Grovs.setPushToken(token);
    print('FCM Token registered with Grovs');
  }
  
  // Listen for token updates
  messaging.onTokenRefresh.listen((newToken) {
    Grovs.setPushToken(newToken);
  });
}
```

## API Reference

### Grovs

Main class for interacting with the Grovs SDK.

#### Static Methods

- `static void setOnDeeplinkReceivedListener(Function(DeeplinkDetails) callback)` - Set callback for deeplink events
- `static Future<String> generateLink(GenerateLinkParams params)` - Generate a Grovs link
- `static Future<void> setPushToken(String token)` - Set push notification token
- `static Future<void> setUserIdentifier(String identifier)` - Set user identifier
- `static Future<void> setUserAttributes(Map<String, dynamic> attributes)` - Set user attributes
- `static Future<void> setDebugLevel(String level)` - Set debug level

### Models

#### GenerateLinkParams

Parameters for generating a Grovs link.

**Properties:**
- `title` (String, required) - The title of the link
- `subtitle` (String?, optional) - The subtitle of the link
- `imageUrl` (String?, optional) - URL to an image for the link preview
- `payload` (Map<String, dynamic>?, optional) - Custom data to be passed with the link
- `tags` (List<String>?, optional) - Tags for organizing links
- `tracking` (TrackingParams?, optional) - UTM tracking parameters
- `customRedirects` (Map<String, String>?, optional) - Platform-specific redirect URLs (keys: 'ios', 'android', 'desktop')

#### TrackingParams

UTM tracking parameters for attribution.

**Properties:**
- `utmCampaign` (String?, optional) - Campaign identifier
- `utmSource` (String?, optional) - Traffic source (e.g., 'email', 'social')
- `utmMedium` (String?, optional) - Marketing medium (e.g., 'newsletter', 'banner')

#### DeeplinkDetails

Details of a received deeplink.

**Properties:**
- `link` (String?) - The deeplink URL
- `payload` (Map<String, dynamic>?) - Custom data passed with the link (previously named `data`)
- `tracking` (TrackingParams?) - Tracking parameters associated with the link

#### GrovsException

Exception thrown by Grovs SDK operations.

**Properties:**
- `message` (String) - Error message
- `code` (String?) - Error code

## Testing Deep Links

### Android

Test custom URL schemes:
```bash
adb shell am start -W -a android.intent.action.VIEW -d "myapp://open?test=123"
```

Test universal links:
```bash
adb shell am start -W -a android.intent.action.VIEW -d "https://your-domain.com/path?test=123"
```

### iOS

Test custom URL schemes:
```bash
xcrun simctl openurl booted "myapp://open?test=123"
```

Test universal links:
```bash
xcrun simctl openurl booted "https://your-domain.com/path?test=123"
```

## Troubleshooting

### Android

**Deep links not working:**
- Verify your `AndroidManifest.xml` has the correct intent filters with your custom scheme
- Check that meta-data tags for `grovs_api_key` and `grovs_use_test_environment` are present
- Test with: `adb shell am start -W -a android.intent.action.VIEW -d "myapp://open"`

**Build errors:**
- Run `flutter clean && flutter pub get`
- Ensure Android SDK and build tools are up to date

### iOS

**Module 'Grovs' not found:**
- Run `cd ios && pod install && pod update && cd ..`
- Clean build folder in Xcode: Product → Clean Build Folder

**Deep links not working:**
- Verify `Info.plist` has `GROVS_API_KEY` and `GROVS_USE_TEST_ENVIRONMENT` configured
- Check that `CFBundleURLTypes` is properly configured for your custom scheme
- For universal links, ensure associated domains are configured in Xcode capabilities
- Test with: `xcrun simctl openurl booted "myapp://open"`

**Configuration issues:**
- Double-check your API key in Info.plist
- Ensure the plugin is properly registered (this is automatic)

### General

**Deeplink listener not receiving events:**
- Make sure `setOnDeeplinkReceivedListener` is called in `initState()` before the app receives any deep links
- For cold start deep links, the listener must be set up before the first frame renders

**Link generation fails:**
- Verify you're using a valid API key
- Check network connectivity
- Ensure required fields (title) are provided
- Check debug logs with `setDebugLevel('info')`

## Additional Resources

- 📖 [Quick Start Guide](QUICK_START.md) - Get up and running in 5 minutes
- 🤖 [Android Integration Guide](ANDROID_INTEGRATION.md) - Detailed Android setup
- 🍎 [iOS Integration Guide](IOS_INTEGRATION.md) - Detailed iOS setup
- ✅ [Integration Checklist](INTEGRATION_CHECKLIST.md) - Complete integration checklist
- 🌐 [Grovs.io](https://grovs.io) - Official website

## Platform Support

- **iOS**: 13.0+
- **Android**: API Level 21+ (Android 5.0 Lollipop)
- **Grovs SDK**:
  - Android: ~2.2
  - iOS: 2.2

## Package Information

- **Package name**: `grovs_flutter_plugin`
- **Android package**: `io.grovs.wrapper`
- **iOS CocoaPods**: `grovs_flutter_plugin`
- **Version**: 1.0.0

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For issues and questions:
- 📧 Visit [https://grovs.io](https://grovs.io)
- 🐛 Report issues on [GitHub](https://github.com/grovs-io/grovs-flutter/issues)
- 💬 Check existing documentation in this repository