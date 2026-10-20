<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://s3.eu-north-1.amazonaws.com/grovs.io/full-white.svg">
    <img src="https://s3.eu-north-1.amazonaws.com/grovs.io/full-black.svg" width="120" alt="Grovs">
  </picture>
</p>

<p align="center">
  <a href="https://pub.dev/packages/grovs_flutter_plugin"><img src="https://img.shields.io/pub/v/grovs_flutter_plugin?style=flat-square&color=4F46E5" alt="Pub version"/></a>
  <a href="https://pub.dev/packages/grovs_flutter_plugin/score"><img src="https://img.shields.io/pub/points/grovs_flutter_plugin?style=flat-square&color=4F46E5" alt="Pub points"/></a>
  <a href="#"><img src="https://img.shields.io/badge/platforms-iOS%20%7C%20Android-4F46E5?style=flat-square" alt="Platforms"/></a>
  <a href="#"><img src="https://img.shields.io/badge/flutter-3.0%2B-4F46E5?style=flat-square&logo=flutter&logoColor=white" alt="Flutter"/></a>
  <a href="LICENSE"><img src="https://img.shields.io/github/license/grovs-io/grovs-flutter?style=flat-square&color=4F46E5" alt="MIT License"/></a>
  <a href="https://github.com/grovs-io/grovs-flutter/stargazers"><img src="https://img.shields.io/github/stars/grovs-io/grovs-flutter?style=flat-square&color=4F46E5" alt="GitHub stars"/></a>
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
- **In-app messages** — show messages and announcements from the Grovs dashboard, with controls and events
- **Push campaigns** — receive push notifications sent from the Grovs dashboard
- **Revenue tracking** — log App Store, Google Play, and custom purchases with automatic attribution
- **Analytics**: track custom events and screen views, with automatic screen tracking via `Grovs.navigatorObserver`
- **User identity** — attach user IDs and attributes for analytics and segmentation
- **Self-hosting support** — point the SDK at your own backend
- **Auto-configuration** — platform config via `AndroidManifest.xml` and `Info.plist`
- **Consent control**: start disabled and enable the SDK once the user agrees
- **Deferred deep linking**: resolve links tapped before installing via fingerprinting and clipboard

## Requirements

- Flutter 3.38.0+
- Dart 3.9.2+
- iOS 13.0+
- Android API 24+ (Android 7.0)

## Installation

Add the dependency to your `pubspec.yaml`:

```yaml
dependencies:
  grovs_flutter_plugin: ^3.2.0
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

    <!-- Optional: start the SDK disabled until the user gives consent (default true) -->
    <meta-data
        android:name="grovs_enabled"
        android:value="false" />

    <!-- Optional: extra hosts accepted for clipboard deferred deep linking, comma separated -->
    <meta-data
        android:name="grovs_clipboard_domains"
        android:value="links.example.com,promo.example.com" />
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

The main activity can extend either `FlutterActivity` or `FlutterFragmentActivity`. The plugin hooks the activity lifecycle itself, so no native code is needed to receive deep links or deferred deep links.

**3. Turn off Flutter's built-in deep linking**

Grovs passes every link on to other plugins, so Flutter's own deep linking would also open Grovs links as routes. Add this inside the main activity:

```xml
<meta-data android:name="flutter_deeplinking_enabled" android:value="false" />
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

<!-- Optional: start the SDK disabled until the user gives consent (default true) -->
<key>GrovsEnabled</key>
<false/>

<!-- Optional: extra hosts accepted for clipboard deferred deep linking -->
<key>GrovsClipboardDomains</key>
<array>
    <string>links.example.com</string>
    <string>promo.example.com</string>
</array>
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

**4. Turn off Flutter's built-in deep linking**

Grovs passes every link on to other plugins, so Flutter's own deep linking would also open Grovs links as routes, and send links without a matching route back to Safari. Add to `Info.plist`:

```xml
<key>FlutterDeepLinkingEnabled</key>
<false/>
```

**5. App lifecycle**

Nothing to add. The plugin works with both the UIScene lifecycle (`FlutterSceneDelegate`, the default for new Flutter apps) and AppDelegate-only apps. If you wrote your own scene delegate code that calls `Grovs.handleSceneDelegate`, remove it, otherwise every link is delivered twice. If your scene delegate does not extend `FlutterSceneDelegate`, follow https://flutter.dev/to/uiscene-migration so Flutter can pass scene events to plugins.

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

Subscribe to the `onDeeplinkReceived` stream to handle incoming deep links. Links tapped before the app was installed arrive on the same stream shortly after the first launch, once the SDK has resolved them:

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

### Links tapped inside your app

iOS and Android do not open your app for a link that your own app opens, so a Grovs link shown in your UI would open in a browser. Pass it to `handleUrl` instead. The result arrives on `onDeeplinkReceived`.

```dart
final handled = await grovs.handleUrl('https://your_app_host/abc');
```

The URL must be an absolute URL with a scheme and a host, otherwise a `GrovsException` with code `INVALID_ARGUMENT` is thrown. `handleUrl` returns `false` (and drops the link) when the SDK is disabled, and on Android when no activity is attached.

### Listen for SDK errors

```dart
import 'dart:async';
import 'package:grovs_flutter_plugin/models/grovs_link.dart';

StreamSubscription<GrovsError>? _errorSubscription;

_errorSubscription = grovs.onError.listen((error) {
  print('Grovs ${error.code.nativeName}: ${error.message}');
});
```

Emitted for authentication, network, event delivery, and link generation failures. iOS only for now; Android emits nothing. The latest 20 errors raised before subscribing are buffered. Cancel the subscription when disposing your widget.

## Consent

The SDK is enabled by default and authenticates on launch. For apps that need user consent first:

1. Set `GrovsEnabled` to `false` (iOS) and `grovs_enabled` to `false` (Android). The SDK is configured but makes no network calls, tracks nothing, and does not read the clipboard.
2. Once the user agrees, call `setSDK(true)`.

```dart
await grovs.setSDK(true);   // user gave consent
await grovs.setSDK(false);  // user withdrew consent
```

The SDK does not persist consent. Store the user's choice in your app and apply it on every launch. Start with the config key set to false and enable the SDK after restoring consent. Calling `setSDK(false)` from Dart cannot prevent native startup work when the config key is true.

While disabled, user identifier and attribute changes are kept and synced once enabled. A deep link that opened the app while disabled is processed and delivered on `onDeeplinkReceived` after `setSDK(true)`.

## Deferred deep linking via clipboard

When a user taps a link with `copyToClipboard` enabled and does not have the app installed, the preview page copies the link to the clipboard. On the first launch after install the native SDK checks the clipboard once to resolve that link:

- It runs only once per install, and only after the backend confirms the project had recent clipboard-enabled clicks.
- The clipboard is read only when its content looks like a URL. iOS may show the system paste notice.
- Accepted hosts are the Grovs link domains plus any `GrovsClipboardDomains` / `grovs_clipboard_domains` entries. Anything else is ignored and never leaves the device.
- There is no separate opt-out. Starting the SDK disabled (see Consent) prevents the read.

Set the flags per link with `copyToClipboardIos` and `copyToClipboardAndroid` on `GenerateLinkParams`, or leave them null to use the project default.

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

## In-app messages

> If in-app messages have **automatic display** enabled in your dashboard, they appear in your app without any additional code. The controls below are optional.

### Controls

```dart
final grovs = Grovs();

// Hold messages back, for example during checkout
await grovs.pauseInAppMessages();
await grovs.resumeInAppMessages();

// Drop queued messages. Messages stay paused until you resume.
await grovs.discardInAppMessages();
await grovs.discardInAppMessages(dismissCurrent: true); // also closes the one on screen

// Never show messages on these screens
await grovs.setInAppExcludedScreens(['Checkout', 'Login']);

// Log what the SDK is doing
await grovs.setInAppDebugLogging(true);
```

A message that is due on an excluded screen waits until the user navigates away.

Screen names come from `GrovsNavigatorObserver` or `trackScreenView`. Excluded screens are matched against the name after [screen aliases](#screen-aliases) are applied.

### Listen for message events

```dart
grovs.onInAppMessage.listen((event) {
  switch (event) {
    case InAppMessageShown(:final campaignId):
      print('Shown: $campaignId');
    case InAppMessageClicked(:final buttonId, :final payload):
      print('Clicked $buttonId with $payload');
    case InAppMessageDismissed(:final reason):
      print('Dismissed: $reason');
    case InAppMessageAnswered(:final value, :final comment):
      print('Answered $value, comment: $comment');
    case InAppMessageFailed(:final message):
      print('Failed: $message');
  }
});
```

On Android, an event that happens while no Flutter engine is attached is dropped. On iOS it is kept for the next engine.

### Testing

To try a message with **Send test message** in the dashboard, call `setUserIdentifier` first. The test message is sent to that user.

### Android extras

- Rating campaigns need the Google Play review library in `android/app/build.gradle`:

  ```groovy
  dependencies {
      implementation 'com.google.android.play:review:2.0.2'
  }
  ```

- Campaigns that ask for push permission need `POST_NOTIFICATIONS` in your manifest. `firebase_messaging` already declares it.

## Push campaigns

Push campaigns need your Firebase or APNs credentials in the [Grovs dashboard](https://app.grovs.io) under your platform's push notification settings.

> Push notifications require a physical device. They do not work in the iOS Simulator.

### iOS

**1. Set the notification center delegate.** Grovs shows and counts its pushes through the system notification center. Set the delegate in `ios/Runner/AppDelegate.swift`:

```swift
import UserNotifications

// In application(_:didFinishLaunchingWithOptions:), before returning
UNUserNotificationCenter.current().delegate = self
```

Without this line, taps on Grovs pushes are not counted and Grovs pushes do not show while the app is open.

**2. Token.** The plugin forwards the APNs token for you. You do not need to call `setPushToken` on iOS. If you do, it works, but it causes one extra attributes update.

**3. Foreground pushes.** While the app is open, Grovs pushes show as a banner, in the list and with sound (alert and sound on iOS 13). Pushes from other providers are left to your own code. They also show while the SDK is disabled. This is display only, nothing is tracked.

With `firebase_messaging` 16.x, this needs one more step. That version answers every notification before Grovs can, so nothing shows by default. Either upgrade to `firebase_messaging` 17 or newer, or call this once after Firebase starts:

```dart
await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
  alert: true,
  badge: true,
  sound: true,
);
```

With 16.x this also shows other Firebase pushes while the app is open.

**4. Images (optional).** To show a picture in the push, add a Notification Service Extension target to your Xcode project, then add this to the `Podfile`:

```ruby
target 'NotificationService' do
  pod 'GrovsNotificationService', '~> 3.1'
end
```

Make the extension's principal class inherit from the Grovs one:

```swift
import GrovsNotificationService

class NotificationService: GrovsNotificationServiceExtension {}
```

Use JPEG, PNG or GIF images. The iOS Simulator never runs the extension, so test on a device.

### Android

Android push needs Firebase Messaging in your app. Add `firebase_messaging`, or add `com.google.firebase:firebase-messaging` and the `google-services` plugin yourself. The Grovs SDK does not bring Firebase with it.

**1. Token.** When Firebase is in your app, the plugin fetches the first FCM token for you, and again each time the SDK is turned on. You can also send it yourself. To keep up with refreshes, listen to `onTokenRefresh`:

```dart
final token = await FirebaseMessaging.instance.getToken();
if (token != null) grovs.setPushToken(token);

FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
  grovs.setPushToken(newToken);
});
```

**2. Foreground pushes with `firebase_messaging`.** The plugin's messaging service runs at a lower priority, so `firebase_messaging` handles messages first. In that case Grovs does not draw pushes while the app is open. Draw them in your own `onMessage` handler, and use `isGrovsNotification` to tell Grovs pushes apart:

```dart
FirebaseMessaging.onMessage.listen((message) async {
  if (await grovs.isGrovsNotification(message.data)) {
    // Show the notification yourself, for example with flutter_local_notifications
  }
});
```

A notification you draw yourself does not carry the Grovs data, so its tap is not counted. In its tap handler, call `grovs.handleNotificationOpen(message.data)`.

Without `firebase_messaging`, Grovs draws foreground pushes itself.

**3. Taps.** Taps on notifications drawn by Grovs are counted without any code. For notifications you draw yourself, see step 2.

### Both platforms

When a user taps a Grovs push, the push data arrives on `onDeeplinkReceived`, like a deep link. `link` is null when the push has no link. On Android, the values in `data` are Strings.

```dart
grovs.onDeeplinkReceived.listen((details) {
  final link = details.link; // null for a push without a link
  final data = details.data;
});
```

`handleNotificationOpen(data)` counts a tap and opens the push's link. Use it when you draw the notification yourself (Android with `firebase_messaging`), or when the native tap handling cannot be used. It must be called from a tap handler, never when a push is only delivered. Use one path, not both. On iOS, setting the delegate and also calling `handleNotificationOpen` counts every tap twice.

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

## Analytics

Track custom events, screen views, and tags. Lifecycle events
(`install`, `app_open`, `time_spent`, `reactivation`) are recorded
automatically by the native SDK — no setup required.

### Custom events

```dart
await Grovs().track(
  'signup_completed',
  properties: {'plan': 'pro'},
  tags: ['onboarding'],
);
```

Event names must not be empty or one of the reserved names: `view`, `open`,
`install`, `reinstall`, `app_open`, `time_spent`, `reactivation`,
`user_referred`, `custom`, `screen_view`. Properties are capped at 8 KB and
tags at 20 (enforced natively).

### Global tags

```dart
await Grovs().setGlobalTags(['premium', 'beta']); // pass null to clear
```

### Automatic screen tracking

Add the observer to your `MaterialApp`:

```dart
MaterialApp(
  navigatorObservers: [Grovs.navigatorObserver],
  // ...
);
```

Screen names come from each route's `RouteSettings.name`. Unnamed routes fall
back to the route's runtime type, which is obfuscated in release builds — name
your routes or pass a `screenNameExtractor` to a custom
`GrovsNavigatorObserver` for stable names.

### Manual screen views

```dart
await Grovs().trackScreenView('Checkout', properties: {'step': 2});
```

### Screen aliases

Map raw screen names to friendly dashboard names:

```dart
await Grovs().setScreenAliases({'/p': 'Product', '/c': 'Cart'});
```

## API Reference

### Properties

| Property | Type | Description |
|---|---|---|
| `onError` | `Stream<GrovsError>` | Native SDK errors (iOS only for now) |
| `onDeeplinkReceived` | `Stream<DeeplinkDetails>` | Stream of deep link events and Grovs push taps |
| `onInAppMessage` | `Stream<InAppMessageEvent>` | Stream of in-app message events |

### Key Methods

| Method | Description |
|---|---|
| `setDebugLevel(level)` | Set logging level (`'info'`, `'error'`) |
| `handleUrl(url)` | Resolve a Grovs link tapped inside your app |
| `setPushToken(token)` | Set FCM/APNs push token |
| `setUserIdentifier(identifier)` | Set user ID for dashboard and reports |
| `setUserAttributes(attributes)` | Set user attributes for analytics |
| `setSDK(enabled)` | Enable or disable the SDK at runtime (consent) |
| `generateLink(params)` | Generate a smart link |
| `logInAppPurchase(transactionId)` | Log a store purchase |
| `logCustomPurchase(type, priceInCents, currency, productId, startDate)` | Log a custom purchase |
| `track(name, {properties, tags})` | Log a custom event |
| `trackScreenView(screenName, {properties})` | Log a screen view manually |
| `setGlobalTags(tags)` | Set tags applied to all future events |
| `setScreenAliases(aliases)` | Map raw screen names to friendly dashboard names |
| `Grovs.navigatorObserver` | `NavigatorObserver` for automatic screen tracking |
| `pauseInAppMessages()` | Hold in-app messages back |
| `resumeInAppMessages()` | Show in-app messages again |
| `discardInAppMessages({dismissCurrent})` | Drop queued in-app messages, optionally close the current one |
| `setInAppExcludedScreens(screens)` | Screens where in-app messages must not show |
| `setInAppDebugLogging(enabled)` | Turn in-app message logging on or off |
| `isGrovsNotification(data)` | Whether a push payload was sent by Grovs |
| `handleNotificationOpen(data)` | Count a tap on a Grovs push and open its link |

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
