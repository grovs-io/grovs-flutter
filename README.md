<p align="center">
  <a href="https://grovs.io">
    <img src="https://s3.eu-north-1.amazonaws.com/grovs.io/full-black.svg" alt="Grovs" width="220" />
  </a>
</p>

<p align="center">
  Deep linking, attribution, and smart links for Flutter.<br/>
  Part of the <a href="https://github.com/grovs-io">Grovs</a> open-source mobile linking platform.
</p>

<p align="center">
  <a href="https://docs.grovs.io/docs/sdk/flutter/quick-start">Quick Start</a> ·
  <a href="https://docs.grovs.io/docs/sdk/flutter/api-reference">API Reference</a> ·
  <a href="https://docs.grovs.io">Full Docs</a>
</p>

---

The Grovs Flutter SDK provides deep linking, app links, universal links, link generation, in-app messaging, revenue tracking, and attribution for your Flutter apps. It wraps the native iOS and Android SDKs.

## Features

- **Deep linking & universal links** — route users to the right in-app screen, even after install
- **Smart link generation** — create trackable links with metadata, custom redirects, and UTM parameters
- **In-app messaging** — display messages and announcements from the Grovs dashboard
- **Push notifications** — receive push notifications for dashboard-sent messages
- **Revenue tracking** — log App Store, Google Play, and custom purchases with automatic attribution
- **User identity** — attach user IDs and attributes for analytics and segmentation
- **Self-hosting support** — point the SDK at your own backend
- **Auto-configuration** — platform config via `AndroidManifest.xml` and `Info.plist`

## Requirements

- Flutter 3.3.0+
- Dart 3.9.2+
- iOS 13.0+
- Android API 21+ (Android 5.0)

## Installation

Add the dependency to your `pubspec.yaml`:

```yaml
dependencies:
  grovs_flutter_plugin: ^1.1.0
```

Then run:

```bash
flutter pub get
```

## Platform Setup

### Android

**1. Add configuration to `AndroidManifest.xml`**

Add the Grovs API key and environment setting inside the `<application>` tag in `android/app/src/main/AndroidManifest.xml`:

```xml
<application>
    <meta-data
        android:name="grovs_api_key"
        android:value="YOUR_API_KEY" />
    <meta-data
        android:name="grovs_use_test_environment"
        android:value="true" /> <!-- Set to false for production -->

    <!-- Optional: Custom base URL for self-hosted backends -->
    <meta-data
        android:name="grovs_base_url"
        android:value="https://your-domain.com" />
</application>
```

**2. Add intent filters**

Add these to your main activity for deep link handling:

```xml
<activity android:name=".MainActivity">
    <!-- Custom URL scheme -->
    <intent-filter>
        <data android:scheme="your_app_scheme" android:host="open" />
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
    </intent-filter>

    <!-- App links (production) -->
    <intent-filter android:autoVerify="true">
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="https" android:host="your_app_host" />
    </intent-filter>

    <!-- App links (test) -->
    <intent-filter android:autoVerify="true">
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="https" android:host="your_app_test_host" />
    </intent-filter>
</activity>
```

### iOS

**1. Add configuration to `Info.plist`**

Add to `ios/Runner/Info.plist`:

```xml
<key>GrovsApiKey</key>
<string>YOUR_API_KEY</string>
<key>GrovsUseTestEnvironment</key>
<true/> <!-- Set to <false/> for production -->

<!-- Optional: Custom base URL for self-hosted backends -->
<key>GrovsBaseURL</key>
<string>https://your-domain.com</string>
```

**2. Configure URL schemes**

Add custom URL scheme support to `Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>your_app_scheme</string>
        </array>
    </dict>
</array>
```

**3. Configure Associated Domains**

1. Open your project in Xcode
2. Select your app target → **Signing & Capabilities** tab
3. Click **+ Capability** → add **Associated Domains**
4. Add `applinks:your_app_host` and `applinks:your_app_test_host`

## Quick Start

### Initialize and configure

```dart
import 'package:grovs_flutter_plugin/grovs.dart';

final grovs = Grovs();

// Optional: enable debug logging
await grovs.setDebugLevel('info');

// Optional: set user identity for analytics
await grovs.setUserIdentifier('user_id_from_your_app');
await grovs.setUserAttributes({
  'name': 'John Doe',
  'plan': 'premium',
});
```

### Handle deep links

Subscribe to the `onDeeplinkReceived` stream to handle incoming deep links:

```dart
import 'dart:async';
import 'package:grovs_flutter_plugin/grovs.dart';

StreamSubscription<DeeplinkDetails>? _subscription;

@override
void initState() {
  super.initState();
  _subscription = grovs.onDeeplinkReceived.listen((details) {
    final link = details.link;
    final payload = details.data;
    final tracking = details.tracking;

    print('Opened from: $link');

    // Route the user based on payload
    if (payload?['screen'] == 'product') {
      navigateToProduct(payload?['productId']);
    }
  });
}

@override
void dispose() {
  _subscription?.cancel();
  super.dispose();
}
```

## Link Generation

Create smart links with metadata, payload data, and tracking parameters:

```dart
import 'package:grovs_flutter_plugin/grovs.dart';
import 'package:grovs_flutter_plugin/models/grovs_link.dart';

try {
  final link = await grovs.generateLink(
    GenerateLinkParams(
      title: 'Check out this product',
      subtitle: 'Limited time offer',
      imageURL: 'https://example.com/image.jpg',
      data: {
        'screen': 'product',
        'productId': '12345',
      },
      tags: ['promotion', 'share'],
      tracking: TrackingParams(
        utmCampaign: 'spring_sale',
        utmSource: 'in_app',
        utmMedium: 'share_button',
      ),
    ),
  );
  print('Generated: $link');
} on GrovsException catch (e) {
  print('Error: ${e.message}');
}
```

### Custom redirects

Override where a link sends users on each platform:

```dart
final link = await grovs.generateLink(
  GenerateLinkParams(
    title: 'Special offer',
    data: {'promoId': 'summer25'},
    customRedirects: CustomRedirects(
      ios: CustomLinkRedirect(url: 'https://example.com/ios-promo'),
      android: CustomLinkRedirect(url: 'https://example.com/android-promo'),
      desktop: CustomLinkRedirect(url: 'https://example.com/desktop-promo', openAppIfInstalled: false),
    ),
  ),
);
```

### Share dialog

Launch the platform share sheet after generating a link:

```dart
import 'package:share_plus/share_plus.dart';

final link = await grovs.generateLink(
  GenerateLinkParams(title: 'Share this', data: {'itemId': 'abc'}),
);
Share.share(link);
```

## Messages

> If console messages have **automatic display** enabled in your dashboard, they will appear in your app without any additional integration.

### Push notifications

Pass the device token to receive push notifications for dashboard-sent messages:

```dart
import 'package:firebase_messaging/firebase_messaging.dart';

// Get and set the token
final token = await FirebaseMessaging.instance.getToken();
if (token != null) {
  await grovs.setPushToken(token);
}

// Listen for token refreshes
FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
  grovs.setPushToken(newToken);
});
```

Upload your Firebase or APNs credentials in the [Grovs dashboard](https://app.grovs.io) under your platform's push notification settings.

> Push notifications require a physical device. They do not work in the iOS Simulator.

## Revenue Tracking

> Revenue tracking is currently in **beta**.

### Setup

1. Enable revenue tracking in the [Grovs dashboard](https://app.grovs.io) under **Settings → Revenue Tracking**
2. Configure platform notifications:
   - **Android** — Set up Google Play Real-Time Developer Notifications
   - **iOS** — Configure App Store Server Notifications in App Store Connect

### Platform store purchases

```dart
// iOS: pass the StoreKit transaction ID as a string
// Android: pass the purchase originalJson string
await grovs.logInAppPurchase('transaction_id_or_json');
```

> The SDK automatically extracts price, currency, and product info. Duplicates are filtered.

### Custom purchases

```dart
import 'package:grovs_flutter_plugin/models/grovs_link.dart';

await grovs.logCustomPurchase(
  type: TransactionType.buy,
  priceInCents: 999,       // $9.99
  currency: 'USD',
  productId: 'premium_monthly',
);
```

Use `.cancel` and `.refund` transaction types for cancellations and refunds. For store purchases, these are detected automatically via platform server notifications.

## API Reference

### Properties

| Property | Type | Description |
|---|---|---|
| `onDeeplinkReceived` | `Stream<DeeplinkDetails>` | Stream of deep link events |

### Key Methods

| Method | Description |
|---|---|
| `setDebugLevel(level)` | Set logging level (`'info'`, `'error'`) |
| `setPushToken(token)` | Set FCM/APNs push token |
| `setUserIdentifier(identifier)` | Set user ID for dashboard and reports |
| `setUserAttributes(attributes)` | Set user attributes for analytics |
| `generateLink(params)` | Generate a smart link |
| `logInAppPurchase(transactionId)` | Log a store purchase |
| `logCustomPurchase(type, priceInCents, currency, productId, startDate)` | Log a custom purchase |

Full API reference: [docs.grovs.io/docs/sdk/flutter/api-reference](https://docs.grovs.io/docs/sdk/flutter/api-reference)

## Example App

A demo project is included in the [`example/`](example/) directory.

## Migration Guides

- [Migrate from Firebase Dynamic Links](https://docs.grovs.io/docs/migration-guides/firebase-dynamic-links/android)
- [Migrate from Branch.io](https://docs.grovs.io/docs/migration-guides/branch-io/android)

## Documentation

Full documentation at [docs.grovs.io](https://docs.grovs.io).

## Support

For technical support and inquiries, contact [support@grovs.io](mailto:support@grovs.io).

## License

This project is licensed under the MIT License — see [LICENSE](LICENSE) for details.
