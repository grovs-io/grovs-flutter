## 3.1.1

Added:

* Link details: `linkDetails(path)` returns a `GrovsLinkDetails` for a link path, matching the native SDKs.
* In-app messages: `pauseInAppMessages`, `resumeInAppMessages`, `discardInAppMessages`, `setInAppExcludedScreens`, `setInAppDebugLogging` and the `onInAppMessage` stream of `InAppMessageEvent`.
* Push campaigns: `isGrovsNotification` and `handleNotificationOpen`. Taps on Grovs pushes arrive on `onDeeplinkReceived`, with `link` null when the push has no link.
* iOS: the push token is forwarded automatically, taps on Grovs pushes are counted, and Grovs pushes show while the app is open. Set `UNUserNotificationCenter.current().delegate = self` in your `AppDelegate`.
* Android: when Firebase is present, the plugin fetches the FCM token and sends it to Grovs at start and each time the SDK is turned on. Nothing is sent while the SDK is disabled.

Changed:

* Updated the native SDKs to Grovs 3.1.
* Android: the Grovs messaging service now has priority -1, so `firebase_messaging` handles messages first when your app uses it.

Removed:

* iOS: the hidden inbox handlers, which the native SDK no longer has.

## 3.1.0

Requires Flutter 3.38.0 or later.

Added:

* iOS: Swift Package Manager support. CocoaPods still works.
* `handleUrl(url)` resolves a Grovs link tapped inside your app. The system does not hand a universal link or app link back to the app that opened it, so these links used to open in a browser.

Changed:

* iOS: the plugin no longer claims incoming links, the same as on Android. Other plugins, such as login callbacks, now always receive their links. Set `FlutterDeepLinkingEnabled` to `false` in `Info.plist` (and `flutter_deeplinking_enabled` to `false` in the Android manifest), otherwise Flutter's own deep linking also opens Grovs links and can send them to Safari.

Fixed:

* iOS: apps using the UIScene lifecycle lost the link that launched the app from a closed state. This includes new Flutter apps and apps that Flutter 3.41 or later migrated automatically. The plugin now receives scene events itself. If you added your own SceneDelegate code that forwards links to Grovs, remove it, or links will be delivered twice.
* iOS: the privacy manifest is now included in CocoaPods builds.

## 3.0.3

Changed:

* Android: updated the native SDK to `io.grovs:Grovs:3.0.1`.

## 3.0.2

Fixed:

* Android: the SDK is now started from the host activity's own lifecycle instead of application-wide activity callbacks. A `FlutterFragmentActivity` attaches the Flutter engine during `onStart`, after those callbacks have fired, so the first launch was missed and deferred deep links only resolved after the app went to the background and back. 3.0.1 accepted `FlutterFragmentActivity` hosts but did not cover this.

## 3.0.1

Fixed:

* Android: deferred deep links were never resolved on first launch when the host activity extends `FlutterFragmentActivity`. The plugin only started the SDK for `FlutterActivity` hosts. Both host activities now start it.

## 3.0.0

Aligned with native Grovs SDKs 3.0.0 (Android `io.grovs:Grovs:3.0.0`, iOS `Grovs ~> 3.0`).

Added:

* Consent gate: `GrovsEnabled` (Info.plist) and `grovs_enabled` (AndroidManifest.xml) set the initial state, `setSDK(bool)` changes it at runtime. A deep link that opened the app while disabled is delivered after enabling.
* `GrovsClipboardDomains` / `grovs_clipboard_domains` config for clipboard deferred deep linking.
* `copyToClipboardIos` and `copyToClipboardAndroid` on `GenerateLinkParams`.
* `onError` stream with `GrovsError` and `GrovsErrorCode` (iOS only for now).
* Analytics: `track`, `trackScreenView`, `setGlobalTags`, `setScreenAliases`, and `Grovs.navigatorObserver` for automatic screen views.

Behavior changes on upgrade:

* The SDK is enabled by default and authenticates on launch as before. Apps with a consent flow must set the config key to false and call `setSDK(true)` after consent.
* On first launch after install the native SDK may read the clipboard to resolve a deferred deep link. iOS may show the system paste notice.
* Native automatic screen tracking is disabled in the Flutter wrapper. Screen views come from `Grovs.navigatorObserver` when installed.
* Android: the native SDK is configured once per process even when several Flutter engines attach.
* iOS: a deep link lookup that was in flight when `setSDK(false)` was called is dropped by the plugin. If consent is granted again before that lookup completes, the native SDK may still deliver it.

Fixed:

* `logCustomPurchase` now forwards `startDate` on both platforms. Before, it was ignored and the native SDK used the current time.

## 1.1.0

* Added custom base URL support via Info.plist (iOS) and AndroidManifest.xml (Android)
* Added revenue tracking with `logInAppPurchase` and `logCustomPurchase` methods
* Added `TransactionType` enum (buy, cancel, refund)
* Bumped iOS SDK to ~> 2.3 and Android SDK to 1.1.1

## 1.0.1

* Documentation improvements
* Added iOS Associated Domains configuration instructions
* Enhanced API documentation with comprehensive examples
* Updated README with complete setup guide
* Improved code comments and inline documentation

## 1.0.0

* Initial release of Grovs Flutter Plugin
* Deep linking support for iOS and Android
* Link generation with custom redirects and tracking parameters
* UTM campaign tracking (utm_campaign, utm_source, utm_medium)
* User identification and custom attributes
* Push notification token management
* In-app messaging support
* Configurable debug levels
* Stream-based deeplink event handling
* Platform-specific configuration via Info.plist (iOS) and AndroidManifest.xml (Android)
* Support for iOS 13.0+ and Android API 21+
