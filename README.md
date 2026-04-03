# Grovs Flutter Plugin

A Flutter plugin for integrating the [Grovs](https://grovs.io) SDK, enabling deep linking, universal linking, smart link generation with tracking parameters, and user attribution in your Flutter applications.

## Features

- 🔗 **Deep Linking**: Generate and handle Grovs links with automatic lifecycle management
- 📱 **Universal Links**: Support for both Android App Links and iOS Universal Links
- � **Attribution Tracking**: UTM campaign tracking with campaign, source, and medium parameters
- � **User Management**: Set user identifiers and attributes for personalized experiences
- 🎯 **Custom Redirects**: Platform-specific redirect URLs for iOS, Android, and desktop
- 💰 **Revenue Tracking**: Track in-app purchases and custom transactions for revenue attribution
- ⚡ **Auto-Configuration**: Platform configuration via AndroidManifest.xml and Info.plist

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  grovs_flutter_plugin: ^1.0.1
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

    <!-- Optional: Custom base URL for self-hosted backends -->
    <meta-data
        android:name="grovs_base_url"
        android:value="https://your-custom-domain.com" />
    
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
        <data android:scheme="https" android:host="your_grovs_host" />
    </intent-filter>

    <!-- Universal links (test) -->
    <intent-filter android:autoVerify="true">
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="https" android:host="your_grovs_test_host" />
    </intent-filter>
</activity>
```

### iOS

1. **Add Configuration to Info.plist**

Add the Grovs API key and environment setting to `ios/Runner/Info.plist`:

```xml
<key>GrovsApiKey</key>
<string>YOUR_API_KEY</string>
<key>GrovsUseTestEnvironment</key>
<true/> <!-- Set to <false/> for production -->

<!-- Optional: Custom base URL for self-hosted backends -->
<key>GrovsBaseURL</key>
<string>https://your-custom-domain.com</string>
```

2. **Configure URL Schemes**

Add custom URL scheme support:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>your_grovs_url_scheme</string>
        </array>
    </dict>
</array>
```

3. **Configure Associated Domains in Xcode**

For universal links support:

- Open your project in Xcode
- Select your project in the Project Navigator
- Under **Targets**, select your app target
- Go to the **Signing & Capabilities** tab
- Click the **+ Capability** button
- Find and double-click **Associated Domains**
- In the Associated Domains section, click the **+** button to add a new domain
- Add your domains in the format `applinks:your_grovs_host`
  - Get these values from your Grovs dashboard
  - Add both production and test environment domains (e.g., `applinks:your_grovs_host` and `applinks:your_grovs_test_host`)

## Usage

### Set logging level and user

You can configure the logging level and set the user attributes using:

```dart
import 'package:grovs_flutter_plugin/grovs.dart';

// Initialize Grovs SDK
final grovs = Grovs();
try {
  await grovs.setDebugLevel('info');

  // Set user information (optional)
  await grovs.setUserIdentifier('demo-user-123');
  await grovs.setUserAttributes({
    'name': 'Demo User',
    'email': 'demo@example.com',
    'app': 'Flutter Demo',
  });
} catch (e) {
  print('Failed to configure Grovs: $e');
}
```

### Handle deeplinks

Handling the deeplinks that opened the app:

```dart
import 'package:grovs_flutter_plugin/grovs.dart';

StreamSubscription<DeeplinkDetails>? _deeplinkSubscription;

void setupDeeplinkListener() {
  _deeplinkSubscription = _grovs.onDeeplinkReceived.listen((deeplinkDetails) {
    // Handle your link
  });
}

@override
void dispose() {
  _deeplinkSubscription?.cancel();
  super.dispose();
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
          'ios': 'https://my-custom-ios-redirect.com',
          'android': 'https://my-custom-android-redirect.com',
          'desktop': 'https://my-custom-desktop-redirect.com',
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

### Revenue Tracking

Track in-app purchases and custom transactions for revenue attribution:

```dart
import 'package:grovs_flutter_plugin/grovs.dart';
import 'package:grovs_flutter_plugin/models/grovs_link.dart';

final grovs = Grovs();

// Log a platform store purchase
// iOS: pass the StoreKit transaction ID as a string
// Android: pass the purchase originalJson string
await grovs.logInAppPurchase('12345');

// Log a custom purchase (e.g. Stripe, PayPal)
await grovs.logCustomPurchase(
  type: TransactionType.buy,
  priceInCents: 999,    // $9.99
  currency: 'USD',
  productId: 'premium_monthly',
);

// Log a refund
await grovs.logCustomPurchase(
  type: TransactionType.refund,
  priceInCents: 999,
  currency: 'USD',
  productId: 'premium_monthly',
);
```

## Additional Resources

- 🌐 [Grovs.io](https://grovs.io) - Official website
- 📖 [Quick Start Guide](https://docs.grovs.io/s/docs) - Check out the official documentation

## Platform Support

- **iOS**: 13.0+
- **Android**: API Level 21+ (Android 5.0 Lollipop)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For issues and questions:
- 📧 Visit [https://grovs.io](https://grovs.io)
- 🐛 Report issues on [GitHub](https://github.com/grovs-io/grovs-flutter/issues)