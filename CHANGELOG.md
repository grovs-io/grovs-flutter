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
