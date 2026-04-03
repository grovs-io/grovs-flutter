# Base URL & Revenue Tracking Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add base URL configuration and revenue tracking (in-app purchase + custom purchase) to the Flutter plugin, matching the native iOS and Android SDK APIs.

**Architecture:** The Flutter plugin reads config from Info.plist (iOS) and AndroidManifest.xml (Android). Base URL will follow this pattern — a new plist/manifest key. Revenue tracking adds two new Dart methods (`logInAppPurchase`, `logCustomPurchase`) that call through the method channel to native SDK methods. A `TransactionType` enum and method signatures mirror the native SDKs.

**Tech Stack:** Dart (Flutter plugin), Swift (iOS), Kotlin (Android), Method Channels

---

## Task 1: Add Base URL Support — iOS Native Side

**Files:**
- Modify: `ios/Classes/GrovsPlugin.swift:51-56` (the `application(_:didFinishLaunchingWithOptions:)` method)

**Step 1: Update iOS configure call to pass baseURL from Info.plist**

In `GrovsPlugin.swift`, update the `application(_:didFinishLaunchingWithOptions:)` method to read `GrovsBaseURL` from Info.plist and pass it to `Grovs.configure()`:

```swift
public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [AnyHashable : Any] = [:]) -> Bool {
    if let infoDictionary = Bundle.main.infoDictionary, let apiKey = infoDictionary["GrovsApiKey"] as? String {
        let useTestEnvironment = infoDictionary["GrovsUseTestEnvironment"] as? Bool ?? false
        let baseURL = infoDictionary["GrovsBaseURL"] as? String
        Grovs.configure(APIKey: apiKey, useTestEnvironment: useTestEnvironment, baseURL: baseURL, delegate: self)
    }
    
    return true
}
```

**Step 2: Verify the iOS native SDK `Grovs.configure` signature accepts `baseURL: String?`**

The iOS Grovs SDK (version ~> 2.2) already has this parameter. No podspec version bump needed — verify by building.

**Step 3: Commit**

```bash
git add ios/Classes/GrovsPlugin.swift
git commit -m "feat(ios): add base URL support from Info.plist"
```

---

## Task 2: Add Base URL Support — Android Native Side

**Files:**
- Modify: `android/src/main/kotlin/io/grovs/wrapper/GrovsPlugin.kt:78-82` (the `onAttachedToEngine` configure block)

**Step 1: Update Android configure call to pass baseURL from AndroidManifest meta-data**

In `GrovsPlugin.kt`, update the configure block inside `onAttachedToEngine` to read `grovs_base_url` and pass it:

```kotlin
val app = flutterPluginBinding.applicationContext as Application
val meta = app.packageManager.getApplicationInfo(app.packageName, PackageManager.GET_META_DATA).metaData
val apiKey = meta.getString("grovs_api_key")
val useTestEnvironment = meta.getBoolean("grovs_use_test_environment", false)
val baseURL = meta.getString("grovs_base_url")
Grovs.configure(application, apiKey ?: "", useTestEnvironment, baseURL)
```

**Step 2: Verify the Android native SDK `Grovs.configure` signature accepts `baseURL: String?`**

The Android Grovs SDK (version 1.1.0) already has this parameter. No version bump needed — verify by building.

**Step 3: Commit**

```bash
git add android/src/main/kotlin/io/grovs/wrapper/GrovsPlugin.kt
git commit -m "feat(android): add base URL support from AndroidManifest"
```

---

## Task 3: Add Revenue Tracking Models — Dart Side

**Files:**
- Modify: `lib/models/grovs_link.dart` (add `TransactionType` enum at end of file)

**Step 1: Add `TransactionType` enum to grovs_link.dart**

Append to the end of `lib/models/grovs_link.dart`:

```dart
/// Type of transaction for revenue tracking
enum TransactionType {
  /// A purchase transaction
  buy,

  /// A cancellation transaction
  cancel,

  /// A refund transaction
  refund,
}
```

**Step 2: Commit**

```bash
git add lib/models/grovs_link.dart
git commit -m "feat: add TransactionType enum for revenue tracking"
```

---

## Task 4: Add Revenue Tracking — Platform Interface

**Files:**
- Modify: `lib/grovs_platform_interface.dart:54` (add two new method stubs before the closing brace)

**Step 1: Add `logInAppPurchase` and `logCustomPurchase` to GrovsPlatform**

Add these methods after the `setDebugLevel` method (after line 54) in `grovs_platform_interface.dart`:

```dart
  /// Log an in-app purchase from the platform store
  ///
  /// iOS: [transactionId] is the StoreKit transaction ID (UInt64 as int)
  /// Android: [transactionId] is the purchase original JSON string
  Future<void> logInAppPurchase(String transactionId) {
    throw UnimplementedError('logInAppPurchase() has not been implemented.');
  }

  /// Log a custom purchase
  Future<void> logCustomPurchase({
    required TransactionType type,
    required int priceInCents,
    required String currency,
    required String productId,
    DateTime? startDate,
  }) {
    throw UnimplementedError('logCustomPurchase() has not been implemented.');
  }
```

Also add the import for models at the top (line 4):

```dart
import 'models/grovs_link.dart';
```

(This import already exists — verify it does.)

**Step 2: Commit**

```bash
git add lib/grovs_platform_interface.dart
git commit -m "feat: add revenue tracking methods to platform interface"
```

---

## Task 5: Add Revenue Tracking — Method Channel Implementation

**Files:**
- Modify: `lib/grovs_method_channel.dart:96` (add two new method implementations before the closing brace)

**Step 1: Implement `logInAppPurchase` in MethodChannelGrovs**

Add after the `setDebugLevel` method (after line 96):

```dart
  @override
  Future<void> logInAppPurchase(String transactionId) async {
    try {
      await methodChannel.invokeMethod('logInAppPurchase', {
        'transactionId': transactionId,
      });
    } on PlatformException catch (e) {
      throw GrovsException(
        e.message ?? 'Failed to log in-app purchase',
        code: e.code,
      );
    }
  }

  @override
  Future<void> logCustomPurchase({
    required TransactionType type,
    required int priceInCents,
    required String currency,
    required String productId,
    DateTime? startDate,
  }) async {
    try {
      await methodChannel.invokeMethod('logCustomPurchase', {
        'type': type.name,
        'priceInCents': priceInCents,
        'currency': currency,
        'productId': productId,
        'startDate': startDate?.toIso8601String(),
      });
    } on PlatformException catch (e) {
      throw GrovsException(
        e.message ?? 'Failed to log custom purchase',
        code: e.code,
      );
    }
  }
```

**Step 2: Commit**

```bash
git add lib/grovs_method_channel.dart
git commit -m "feat: implement revenue tracking in method channel"
```

---

## Task 6: Add Revenue Tracking — Public Dart API

**Files:**
- Modify: `lib/grovs.dart:117` (add two new public methods before the `onDeeplinkReceived` getter)

**Step 1: Add `logInAppPurchase` and `logCustomPurchase` to Grovs class**

Add before the `onDeeplinkReceived` stream getter (before line 119):

```dart
  /// Log an in-app purchase from the platform store
  ///
  /// Tracks a store purchase for revenue attribution.
  ///
  /// [transactionId] - The platform-specific transaction identifier:
  /// - iOS: The StoreKit transaction ID (pass as string, e.g. `transaction.id.description`)
  /// - Android: The purchase original JSON (e.g. `purchase.originalJson`)
  ///
  /// Throws [GrovsException] if the operation fails
  ///
  /// Example:
  /// ```dart
  /// await Grovs().logInAppPurchase('12345');
  /// ```
  Future<void> logInAppPurchase(String transactionId) {
    return GrovsPlatform.instance.logInAppPurchase(transactionId);
  }

  /// Log a custom purchase for revenue tracking
  ///
  /// Tracks a non-store purchase (e.g. Stripe, PayPal) for revenue attribution.
  ///
  /// [type] - The transaction type: buy, cancel, or refund
  /// [priceInCents] - The price in cents (e.g. 999 for $9.99)
  /// [currency] - ISO 4217 currency code (e.g. 'USD', 'EUR')
  /// [productId] - A unique product identifier
  /// [startDate] - Optional transaction date (defaults to now on the native side)
  ///
  /// Throws [GrovsException] if the operation fails
  ///
  /// Example:
  /// ```dart
  /// await Grovs().logCustomPurchase(
  ///   type: TransactionType.buy,
  ///   priceInCents: 999,
  ///   currency: 'USD',
  ///   productId: 'premium_monthly',
  /// );
  /// ```
  Future<void> logCustomPurchase({
    required TransactionType type,
    required int priceInCents,
    required String currency,
    required String productId,
    DateTime? startDate,
  }) {
    return GrovsPlatform.instance.logCustomPurchase(
      type: type,
      priceInCents: priceInCents,
      currency: currency,
      productId: productId,
      startDate: startDate,
    );
  }
```

**Step 2: Commit**

```bash
git add lib/grovs.dart
git commit -m "feat: add revenue tracking public API"
```

---

## Task 7: Add Revenue Tracking — iOS Native Handler

**Files:**
- Modify: `ios/Classes/GrovsPlugin.swift:71-212` (add two new cases in the `handle` switch statement)

**Step 1: Add `logInAppPurchase` case to iOS handle method**

Add before the `default:` case (before line 209) in the `handle` method:

```swift
        case "logInAppPurchase":
            guard let args = call.arguments as? [String: Any],
                  let transactionIdString = args["transactionId"] as? String,
                  let transactionId = UInt64(transactionIdString) else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "transactionId is required", details: nil))
                return
            }
            
            Grovs.logInAppPurchase(transactionID: transactionId) { success in
                if success {
                    result(nil)
                } else {
                    result(FlutterError(code: "PAYMENT_ERROR", message: "Failed to log in-app purchase", details: nil))
                }
            }
            
        case "logCustomPurchase":
            guard let args = call.arguments as? [String: Any],
                  let typeString = args["type"] as? String,
                  let priceInCents = args["priceInCents"] as? Int,
                  let currency = args["currency"] as? String,
                  let productId = args["productId"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "type, priceInCents, currency, and productId are required", details: nil))
                return
            }
            
            let type: TransactionType
            switch typeString {
            case "buy":
                type = .buy
            case "cancel":
                type = .cancel
            case "refund":
                type = .refund
            default:
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Invalid transaction type: \(typeString)", details: nil))
                return
            }
            
            var startDate: Date?
            if let dateString = args["startDate"] as? String {
                let formatter = ISO8601DateFormatter()
                startDate = formatter.date(from: dateString)
            }
            
            Grovs.logCustomPurchase(type: type, priceInCents: priceInCents, currency: currency, productID: productId, startDate: startDate) { success in
                if success {
                    result(nil)
                } else {
                    result(FlutterError(code: "PAYMENT_ERROR", message: "Failed to log custom purchase", details: nil))
                }
            }
```

**Step 2: Commit**

```bash
git add ios/Classes/GrovsPlugin.swift
git commit -m "feat(ios): add revenue tracking method channel handlers"
```

---

## Task 8: Add Revenue Tracking — Android Native Handler

**Files:**
- Modify: `android/src/main/kotlin/io/grovs/wrapper/GrovsPlugin.kt:95-257` (add two new cases in the `when` block)

**Step 1: Add imports for PaymentEventType**

Add to the imports at the top of `GrovsPlugin.kt`:

```kotlin
import io.grovs.model.events.PaymentEventType
import java.time.Instant
```

**Step 2: Add `logInAppPurchase` case to Android onMethodCall**

Add before the `else ->` case (before line 254) in the `when` block:

```kotlin
            "logInAppPurchase" -> {
                val transactionId = call.argument<String>("transactionId")
                
                if (transactionId == null) {
                    result.error("INVALID_ARGUMENT", "transactionId is required", null)
                    return
                }
                
                try {
                    Grovs.logInAppPurchase(transactionId)
                    result.success(null)
                } catch (e: Exception) {
                    result.error("PAYMENT_ERROR", e.message, null)
                }
            }
            
            "logCustomPurchase" -> {
                val typeString = call.argument<String>("type")
                val priceInCents = call.argument<Int>("priceInCents")
                val currency = call.argument<String>("currency")
                val productId = call.argument<String>("productId")
                val startDateString = call.argument<String>("startDate")
                
                if (typeString == null || priceInCents == null || currency == null || productId == null) {
                    result.error("INVALID_ARGUMENT", "type, priceInCents, currency, and productId are required", null)
                    return
                }
                
                val type = when (typeString) {
                    "buy" -> PaymentEventType.BUY
                    "cancel" -> PaymentEventType.CANCEL
                    "refund" -> PaymentEventType.REFUND
                    else -> {
                        result.error("INVALID_ARGUMENT", "Invalid transaction type: $typeString", null)
                        return
                    }
                }
                
                val startDate = startDateString?.let {
                    try {
                        InstantCompat.from(Instant.parse(it))
                    } catch (e: Exception) {
                        null
                    }
                }
                
                try {
                    Grovs.logCustomPurchase(type, priceInCents, currency, productId, startDate)
                    result.success(null)
                } catch (e: Exception) {
                    result.error("PAYMENT_ERROR", e.message, null)
                }
            }
```

> **Note:** The Android SDK uses `InstantCompat` for dates. Verify the exact import during implementation — it may be `io.grovs.model.InstantCompat` or from `java.time`. Check the Android SDK source. If `InstantCompat` is not directly constructable from `Instant`, pass `null` for `startDate` and let the SDK default to now — this is acceptable since the parameter is optional.

**Step 3: Commit**

```bash
git add android/src/main/kotlin/io/grovs/wrapper/GrovsPlugin.kt
git commit -m "feat(android): add revenue tracking method channel handlers"
```

---

## Task 9: Update README and Example App

**Files:**
- Modify: `README.md` (add base URL config and revenue tracking docs)
- Modify: `example/lib/main.dart` (add revenue tracking example usage)

**Step 1: Add base URL documentation to README**

Add a "Base URL Configuration" section after the existing configuration sections, documenting:
- iOS: Add `GrovsBaseURL` key to Info.plist with the custom domain
- Android: Add `<meta-data android:name="grovs_base_url" android:value="https://your-domain.com" />` to AndroidManifest.xml

**Step 2: Add revenue tracking documentation to README**

Add a "Revenue Tracking" section documenting:
- `logInAppPurchase` with platform-specific transactionId guidance
- `logCustomPurchase` with TransactionType enum values and example
- Code examples for both methods

**Step 3: Add revenue tracking example to example app**

Add example buttons/calls in `example/lib/main.dart` demonstrating:
- `await Grovs().logCustomPurchase(type: TransactionType.buy, priceInCents: 999, currency: 'USD', productId: 'premium')`

**Step 4: Commit**

```bash
git add README.md example/lib/main.dart
git commit -m "docs: add base URL and revenue tracking documentation"
```

---

## Task 10: Build Verification

**Step 1: Run Flutter analyze**

```bash
cd /Users/razvanchelemen/Clients_work/grovs/grovs-flutter
flutter analyze
```

Expected: No errors (warnings acceptable).

**Step 2: Run Flutter tests**

```bash
flutter test
```

Expected: All tests pass.

**Step 3: Verify iOS build**

```bash
cd example && flutter build ios --no-codesign
```

Expected: Build succeeds. This confirms the iOS native SDK accepts the `baseURL` parameter and has `logInAppPurchase`/`logCustomPurchase` methods.

**Step 4: Verify Android build**

```bash
cd example && flutter build apk --debug
```

Expected: Build succeeds. This confirms the Android native SDK accepts the `baseURL` parameter and has the revenue tracking methods.

**Step 5: Final commit if any fixes needed**

```bash
git add -A && git commit -m "fix: address build issues"
```
