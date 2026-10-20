# grovs_example

Demonstrates how to use the grovs plugin.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Push notifications (optional)

The example builds and runs without any Firebase files. The push section then
shows "Push not configured".

To try push campaigns, add your own Firebase config:

- Android: `android/app/google-services.json`
- iOS: `ios/Runner/GoogleService-Info.plist` (add it to the Runner target)

Both files are git-ignored. On iOS, also enable the Push Notifications
capability and use a real device. Call `Grovs().setPushToken` as the push
section does; taps are handled natively, so the example does not call
`handleNotificationOpen`.
