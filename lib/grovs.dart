import 'grovs_platform_interface.dart';
import 'models/grovs_link.dart';

/// Main class for interacting with the Grovs SDK
class Grovs {
  /// Get the platform version
  Future<String?> getPlatformVersion() {
    return GrovsPlatform.instance.getPlatformVersion();
  }

  /// Generate a Grovs link with the specified parameters
  ///
  /// Returns the generated link URL as a String
  ///
  /// Throws [GrovsException] if link generation fails
  ///
  /// Example:
  /// ```dart
  /// final link = await Grovs().generateLink(
  ///   GenerateLinkParams(
  ///     title: 'Check this out',
  ///     subtitle: 'Amazing content',
  ///     imageURL: 'https://example.com/image.png',
  ///     data: {'screen': 'product', 'productId': '123'},
  ///     tags: ['promotion'],
  ///     tracking: TrackingParams(
  ///       utmCampaign: 'spring_sale',
  ///       utmSource: 'email',
  ///       utmMedium: 'newsletter',
  ///     ),
  ///     customRedirects: CustomRedirects(
  ///       ios: CustomLinkRedirect(url: 'https://my_website.com/ios', openAppIfInstalled: true),
  ///       android: CustomLinkRedirect(url: 'https://my_website.com/android', openAppIfInstalled: true),
  ///     desktop: CustomLinkRedirect(url: 'https://my_website.com/desktop', openAppIfInstalled: false),
  ///     ),
  ///   ),
  /// );
  /// ```
  Future<String> generateLink(GenerateLinkParams params) {
    return GrovsPlatform.instance.generateLink(params);
  }

  /// Set the user identifier
  ///
  /// Associates a unique identifier with the current user for tracking and attribution
  ///
  /// [identifier] - A unique identifier for the current user
  ///
  /// Throws [GrovsException] if the operation fails
  ///
  /// Example:
  /// ```dart
  /// await Grovs().setUserIdentifier('user-123');
  /// ```
  Future<void> setUserIdentifier(String identifier) {
    return GrovsPlatform.instance.setUserIdentifier(identifier);
  }

  /// Set user attributes
  ///
  /// Associates custom attributes with the current user for segmentation and personalization
  ///
  /// [attributes] - A map of key-value pairs representing user attributes
  ///
  /// Throws [GrovsException] if the operation fails
  ///
  /// Example:
  /// ```dart
  /// await Grovs().setUserAttributes({
  ///   'name': 'John Doe',
  ///   'email': 'john@example.com',
  ///   'age': 30,
  ///   'premium': true,
  ///   'signupDate': '2024-01-01',
  /// });
  /// ```
  Future<void> setUserAttributes(Map<String, dynamic> attributes) {
    return GrovsPlatform.instance.setUserAttributes(attributes);
  }

  /// Set debug level for logging
  ///
  /// Controls the verbosity of SDK logs for debugging purposes
  ///
  /// [level] - Debug level: 'info' or 'error'
  ///
  /// Throws [GrovsException] if the operation fails
  ///
  /// Example:
  /// ```dart
  /// await Grovs().setDebugLevel('info');
  /// ```
  Future<void> setDebugLevel(String level) {
    return GrovsPlatform.instance.setDebugLevel(level);
  }

  /// Set push notification token
  ///
  /// Registers the FCM (Firebase Cloud Messaging) or APNS (Apple Push Notification Service) token
  /// with the Grovs SDK for push notification support
  ///
  /// [token] - The push notification token from FCM or APNS
  ///
  /// Throws [GrovsException] if the operation fails
  ///
  /// Example:
  /// ```dart
  /// // FCM token
  /// final messaging = FirebaseMessaging.instance;
  /// final token = await messaging.getToken();
  /// if (token != null) {
  ///   await Grovs().setPushToken(token);
  /// }
  /// ```
  Future<void> setPushToken(String token) {
    return GrovsPlatform.instance.setPushToken(token);
  }

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

  /// Stream of deeplink events
  ///
  /// Listen to this stream to receive deeplink events when a user opens your app via a Grovs link.
  /// The stream emits [DeeplinkDetails] objects containing the link URL, payload data, and tracking parameters.
  ///
  /// Note: Set up the listener in initState() to ensure it's ready before any deeplinks are received.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// void initState() {
  ///   super.initState();
  ///   _subscription = Grovs().onDeeplinkReceived.listen((deeplinkDetails) {
  ///     print('Received deeplink: ${deeplinkDetails.link}');
  ///     print('Payload: ${deeplinkDetails.data}');
  ///     print('Tracking: ${deeplinkDetails.tracking?.toMap()}');
  ///
  ///     // Navigate based on payload
  ///     if (deeplinkDetails.data?['screen'] == 'product') {
  ///       Navigator.pushNamed(context, '/product',
  ///         arguments: deeplinkDetails.data?['productId']);
  ///     }
  ///   });
  /// }
  ///
  /// @override
  /// void dispose() {
  ///   _subscription?.cancel();
  ///   super.dispose();
  /// }
  /// ```
  Stream<DeeplinkDetails> get onDeeplinkReceived {
    return GrovsPlatform.instance.onDeeplinkReceived;
  }
}
