# Grovs test app

This app tests every feature of the Grovs Flutter SDK in a few taps. Use it to
check links, events, purchases, in-app messages and push on a real project.

## What is in the app

The app has four tabs, a Settings screen and a logs panel.

- **Home**: SDK on/off switch, project info, push status and token, the link
  the app was opened from, your identity and attributes, and quick actions
  (generate link, open clipboard, track event, log purchase). Hold a quick
  action to edit its values.
- **Links**: build a link with all options, then copy, share, show the QR code,
  open it, copy the adb or simctl command, or inspect it. You can also paste any
  link and inspect it.
- **Events**: track events with properties and tags, send screen views, set
  global tags and screen aliases, and log purchases (App Store or Play).
- **In-app**: trigger a campaign, discard waiting messages, close the current
  one, switch debug logging, and open an excluded screen.
- **Settings**: open it from Home. It shows what the SDK was configured with
  and sets the debug level.
- **Logs**: tap the strip above the tab bar. Every call and result is listed
  here. You can filter, open an entry, run it again, share or clear the log.

Forms start with valid sample values and remember the last values you used.

## Project config

The SDK reads its config natively. Change these files to point the app at
another project:

- Android: `android/app/src/main/AndroidManifest.xml`, the `grovs_*`
  meta-data entries (`grovs_api_key`, `grovs_use_test_environment`,
  `grovs_enabled`).
- iOS: `ios/Runner/Info.plist`, the `Grovs*` keys (`GrovsApiKey`,
  `GrovsUseTestEnvironment`, `GrovsEnabled`).

The link domains are set in different places. On Android they are the intent filter hosts in `android/app/src/main/AndroidManifest.xml`. On iOS they are the associated domains in `ios/Runner/Runner.entitlements`.

## Push notifications (optional)

The app builds and runs without any Firebase files. The push section then
shows "Push not configured".

To try push, add your own Firebase files. Both are git-ignored:

- Android: `android/app/google-services.json`
- iOS: `ios/Runner/GoogleService-Info.plist` (add it to the Runner target)

On iOS, also enable the Push Notifications capability and use a real device.

## Open a link from a terminal

Android:

```
adb shell am start -a android.intent.action.VIEW -d "<link>" io.grovs.example
```

iOS simulator:

```
xcrun simctl openurl booted "<link>"
```

The Links tab and the QR sheet show these commands with your link filled in.
