import 'package:flutter/foundation.dart';

import 'controls/info.dart';

/// What each less obvious control does, in plain words, for people new to Grovs.
class Help {
  const Help._();

  static const sdkEnabled = Info(
    'SDK enabled',
    'The Grovs SDK is the library this app uses to talk to Grovs. This switch is the user\'s consent (Grovs.setSDK). When off, the SDK stays installed but sends nothing to Grovs: no links, events or push data.',
  );
  static const pushToken = Info(
    'Push token',
    'Firebase gives every install a token that push notifications are sent to. The SDK passes it to Grovs so you can reach this phone from a dashboard campaign. Copy it to send a test push to just this phone.',
  );
  static const openedFrom = Info(
    'Opened from',
    'Grovs links open your app when it is installed, and the SDK hands the link and its data to the app through onDeeplinkReceived. This shows the last link that opened the app.',
  );
  static const identity = Info(
    'Identity',
    'Grovs groups links opened, events and purchases by user. The identifier is your own user id, for example from your login (Grovs.identifier). Attributes are facts about the user, like plan or country, shown on their profile in the dashboard.',
  );
  static const quickActions = Info(
    'Quick actions',
    'Shortcuts to the most common tests. One tap runs the test with the values you last used on its tab. Hold a button to change the values first.',
  );
  static const inspect = Info(
    'Inspect a link',
    'Every Grovs link is stored on the Grovs backend with its title, data and settings. Paste a link to load what is stored for it (Grovs.linkDetails). Useful for checking a link made here or in the dashboard.',
  );
  static const linkData = Info(
    'Data',
    'Custom values saved inside the link, like a promo code or the id of a product. When someone opens the link, your app gets this data back and can show the right screen. Tap the type badge to send a value as text, number, true/false or date.',
  );
  static const linkTags = Info(
    'Tags',
    'Labels for organizing links in the Grovs dashboard, for example by campaign or channel. They do not change how the link behaves.',
  );
  static const utm = Info(
    'UTM tracking',
    'UTM parameters are the standard way to name where traffic comes from: source (like newsletter), medium (like email) and campaign. Grovs uses them to show which campaign brought each open and install.',
  );
  static const customRedirects = Info(
    'Custom redirects',
    'When someone opens a link without the app installed, Grovs sends them somewhere: by default the store or website set in your project. Turn this on to choose a different place per platform for this one link.',
  );
  static const openAppIfInstalled = Info(
    'Open app if installed',
    'On: if the app is installed, the link opens it, and the URL above is only used when it is not. Off: the link always opens the URL above.',
  );
  static const platformOverrides = Info(
    'Platform overrides',
    'Per-link versions of two project settings. Preview shows a page with the link\'s title and image before redirecting. Clipboard copies the link on that page, so after installing, the app can still find which link brought the user. "Default" keeps the project\'s setting.',
  );
  static const customEvent = Info(
    'Custom event',
    'Events are actions you report from your app, like signup or level_complete (Grovs.track). They appear in the dashboard and can trigger in-app messages. Some names are used by Grovs itself and rejected; "Send anyway" checks that.',
  );
  static const eventPropertiesAndTags = Info(
    'Properties and tags',
    'Properties are details sent with this one event, like level = 3. Tags are labels for filtering events in the dashboard, up to 20 per event.',
  );
  static const screenView = Info(
    'Screen view',
    'Grovs records which screens people visit, for analytics and for in-app message rules. Most screens are reported on their own (see Auto track screens in Settings). This reports one by hand (Grovs.trackScreenView). Hold Track to add properties.',
  );
  static const globalTags = Info(
    'Global tags',
    'Tags added to every event this app sends from now on, like beta or region_eu (Grovs.setGlobalTags). Handy for splitting all events by a group of users.',
  );
  static const screenAliases = Info(
    'Screen aliases',
    'Automatically tracked screens are named after their route, like /. An alias gives a screen a readable name in the dashboard. The key is the route name, the value is the name to show.',
  );
  static const purchase = Info(
    'Purchase',
    'Grovs ties purchases to the link or campaign that brought the user, so you can see revenue per link. Use this for payments you handle yourself (Grovs.logCustomPurchase). Buy, cancel and refund are the types; the amount is sent in cents.',
  );
  static const startDate = Info(
    'Start date',
    'When the purchase happened. Choose an earlier date to test a purchase that is reported late.',
  );
  static const showMessage = Info(
    'Show a message',
    'In-app messages are pop-ups you design in the Grovs dashboard. Each campaign has a trigger: an event name. This sends that event, and a message shows if a live campaign uses it as its trigger.',
  );
  static const queue = Info(
    'Queue',
    'Messages wait in a queue until a good moment to show. Discard waiting drops queued messages. Close current also closes the one on screen. Both pause messages; switch to Running to resume.',
  );
  static const inAppDebug = Info(
    'Debug logging',
    'Makes the SDK explain its in-app message decisions in the device log (Logcat on Android, the Xcode console on iOS): why a message was or was not shown.',
  );
  static const excludedScreens = Info(
    'Excluded screens',
    'Screens where in-app messages never appear, like checkout. Use the route name, like ExcludedScreen. Messages wait until the user leaves that screen.',
  );
  static const apiKey = Info(
    'API key',
    'Identifies your Grovs project, so the SDK sends data to the right place. Copy it from your project in the Grovs dashboard. Changes apply after a restart.',
  );
  static const environment = Info(
    'Environment',
    'Each Grovs project has a test environment and a live (Prod) one, with separate data. Use Test while building so you don\'t mix test data with real users. Use the API key that matches.',
  );
  static const baseUrl = Info(
    'Base URL',
    'The server the SDK talks to. Leave it empty for Grovs\' own servers. Set it only to test against another backend, like a staging server; it must start with http:// or https://.',
  );
  static const clipboardDomains = Info(
    'Clipboard domains',
    'Deferred deep linking means the app finds the link that brought a user even after a fresh install. One way is through the clipboard. If your links use your own domain, list it here so the SDK trusts it. grovs.link and sqd.link always work.',
  );
  static const autoTrackScreens = Info(
    'Auto track screens',
    'Set natively. In Flutter, screens are tracked by GrovsNavigatorObserver, which this app adds to MaterialApp.',
  );
  static const startEnabled = Info(
    'Start with SDK enabled',
    'Whether the user\'s consent starts as given on each launch. Off starts the SDK without sending anything until you turn it on from Home, like an app waiting for a consent popup.',
  );
  static const debugLevel = Info(
    'Debug level',
    'How much the SDK writes to the device log (Logcat on Android, the Xcode console on iOS). Info shows every step, Error only failures.',
  );

  static const _playPurchase = Info(
    'Google Play purchase JSON',
    'For purchases made with Google Play Billing. Paste the purchase\'s originalJson and the SDK sends it to Grovs to log the purchase (Grovs.logInAppPurchase).',
  );
  static const _storeKitPurchase = Info(
    'StoreKit transaction',
    'For purchases made with StoreKit. Paste the transaction id and the SDK sends it to Grovs to log the purchase (logInAppPurchase).',
  );

  static Info get storePurchase => defaultTargetPlatform == TargetPlatform.iOS
      ? _storeKitPurchase
      : _playPurchase;
}
