import Flutter
import UIKit
import Grovs

public class GrovsPlugin: NSObject, FlutterPlugin {
    enum IncomingLink {
        case userActivity(NSUserActivity)
        case url(URL)
    }

    private static let events = GrovsEventRelay()

    private var methodChannel: FlutterMethodChannel?
    private var eventChannel: FlutterEventChannel?
    private var errorChannel: FlutterEventChannel?
    private var inAppChannel: FlutterEventChannel?
    private let errorStream = BufferedStreamHandler(stream: GrovsPlugin.events.errors)
    private let deeplinkStream = BufferedStreamHandler(stream: GrovsPlugin.events.deeplinks)
    private let inAppStream = BufferedStreamHandler(stream: GrovsPlugin.events.inApp)

    // Configuration, consent state and the launch link received while disabled are
    // shared by every engine because the SDK is configured once per process.
    private static var configured = false
    static var sdkEnabled = true
    private static var pendingLaunchLink: IncomingLink?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "grovs", binaryMessenger: registrar.messenger())
        let eventChannel = FlutterEventChannel(name: "grovs/deeplinks", binaryMessenger: registrar.messenger())
        
        let instance = GrovsPlugin()
        Grovs.delegate = events
        Grovs.inAppDelegate = events
        instance.methodChannel = channel
        instance.eventChannel = eventChannel
        registrar.publish(instance)
        
        registrar.addMethodCallDelegate(instance, channel: channel)
        registrar.addApplicationDelegate(instance)
        registrar.addSceneDelegate(instance)
        eventChannel.setStreamHandler(instance.deeplinkStream)
        let errorChannel = FlutterEventChannel(name: "grovs/errors", binaryMessenger: registrar.messenger())
        instance.errorChannel = errorChannel
        errorChannel.setStreamHandler(instance.errorStream)
        let inAppChannel = FlutterEventChannel(name: "grovs/inapp", binaryMessenger: registrar.messenger())
        instance.inAppChannel = inAppChannel
        inAppChannel.setStreamHandler(instance.inAppStream)
    }

    public func detachFromEngine(for registrar: FlutterPluginRegistrar) {
        _ = deeplinkStream.onCancel(withArguments: nil)
        _ = errorStream.onCancel(withArguments: nil)
        _ = inAppStream.onCancel(withArguments: nil)
        eventChannel?.setStreamHandler(nil)
        errorChannel?.setStreamHandler(nil)
        inAppChannel?.setStreamHandler(nil)
        methodChannel?.setMethodCallHandler(nil)
        eventChannel = nil
        errorChannel = nil
        inAppChannel = nil
        methodChannel = nil
    }

    // Hook into didFinishLaunchingWithOptions
    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [AnyHashable : Any] = [:]) -> Bool {
        GrovsPlugin.configureFromInfoPlist()
        return true
    }

    // Links are handed to Grovs but never claimed, so other plugins still receive them.
    public func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]) -> Void) -> Bool {
        _ = GrovsPlugin.deliver(.userActivity(userActivity))
        return false
    }

    public func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        _ = GrovsPlugin.deliver(.url(url))
        return false
    }

    static func configureFromInfoPlist(_ info: [String: Any]? = Bundle.main.infoDictionary) {
        guard !configured, let info, let apiKey = info["GrovsApiKey"] as? String else { return }
        configured = true
        let enabled = info["GrovsEnabled"] as? Bool ?? true
        sdkEnabled = enabled
        events.deeplinks.enabled = enabled
        events.inApp.enabled = enabled
        Grovs.configure(
            APIKey: apiKey,
            useTestEnvironment: info["GrovsUseTestEnvironment"] as? Bool ?? false,
            baseURL: info["GrovsBaseURL"] as? String,
            autoTrackScreenViews: false,
            clipboardDomains: info["GrovsClipboardDomains"] as? [String],
            enabled: enabled,
            delegate: events
        )
    }

    static func deliver(_ link: IncomingLink) -> Bool {
        if !sdkEnabled {
            pendingLaunchLink = link
        }
        switch link {
        case .userActivity(let activity):
            return Grovs.handleAppDelegate(continue: activity, restorationHandler: { _ in })
        case .url(let url):
            return Grovs.handleAppDelegate(open: url, options: [:])
        }
    }

    static func handleUrl(arguments: Any?) -> Any {
        guard let args = arguments as? [String: Any],
              let urlString = args["url"] as? String,
              let url = URL(string: urlString),
              url.scheme != nil,
              url.host?.isEmpty == false else {
            return FlutterError(code: "INVALID_ARGUMENT", message: "url must be an absolute URL with a host", details: nil)
        }
        guard sdkEnabled else { return false }
        return deliver(.url(url))
    }

    static func linkDetails(arguments: Any?, result: @escaping FlutterResult) {
        guard let args = arguments as? [String: Any],
              let path = args["path"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "path is required", details: nil))
            return
        }
        // The native SDK queues requests until it is enabled, which would leave the call hanging.
        guard sdkEnabled else {
            result(FlutterError(code: "SDK_DISABLED", message: "Grovs SDK is disabled. Call setSDK(true) first.", details: nil))
            return
        }
        Grovs.linkDetails(path: path) { details in
            if let details {
                result(details)
            } else {
                result(FlutterError(code: "LINK_DETAILS_ERROR", message: "Failed to get link details.", details: nil))
            }
        }
    }

    static func isGrovsNotification(arguments: Any?) -> Any {
        guard let userInfo = notificationData(arguments) else { return missingNotificationData }
        return Grovs.isGrovsNotification(userInfo: userInfo)
    }

    static func handleNotificationOpen(arguments: Any?) -> Any {
        guard let userInfo = notificationData(arguments) else { return missingNotificationData }
        guard sdkEnabled else { return false }
        return Grovs.handleNotificationOpen(userInfo: userInfo)
    }

    private func setSDKEnabled(_ enabled: Bool) {
        guard enabled != GrovsPlugin.sdkEnabled else { return }
        GrovsPlugin.sdkEnabled = enabled
        GrovsPlugin.events.deeplinks.enabled = enabled
        GrovsPlugin.events.inApp.enabled = enabled
        Grovs.setSDK(enabled: enabled)

        guard enabled, let pending = GrovsPlugin.pendingLaunchLink else { return }
        GrovsPlugin.pendingLaunchLink = nil
        // The native SDK drops links received while disabled; hand it the launch
        // link again now that it may process it. Must run on the main thread.
        _ = GrovsPlugin.deliver(pending)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion)
            
        case "configure":
            break
            
        case "generateLink":
            guard let args = call.arguments as? [String: Any],
                  let title = args["title"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "title is required", details: nil))
                return
            }
            
            let subtitle = args["subtitle"] as? String
            let imageURL = args["imageURL"] as? String
            let data = args["data"] as? [String: Any]
            let tags = args["tags"] as? [String]
            let customRedirectsMap = args["customRedirects"] as? [String: [String: Any]]
            let showPreviewIos = args["showPreviewIos"] as? Bool
            let showPreviewAndroid = args["showPreviewAndroid"] as? Bool
            let copyToClipboardIos = args["copyToClipboardIos"] as? Bool
            let copyToClipboardAndroid = args["copyToClipboardAndroid"] as? Bool
            let trackingMap = args["tracking"] as? [String: String]
            
            // Parse custom redirects
            var customRedirects: CustomRedirects?
            if let redirectsMap = customRedirectsMap {
                var ios: CustomLinkRedirect?
                var android: CustomLinkRedirect?
                var desktop: CustomLinkRedirect?
                
                if let iosMap = redirectsMap["ios"] {
                    ios = CustomLinkRedirect(
                        link: iosMap["url"] as? String ?? "",
                        openAppIfInstalled: iosMap["openAppIfInstalled"] as? Bool ?? true
                    )
                }
                if let androidMap = redirectsMap["android"] {
                    android = CustomLinkRedirect(
                        link: androidMap["url"] as? String ?? "",
                        openAppIfInstalled: androidMap["openAppIfInstalled"] as? Bool ?? true
                    )
                }
                if let desktopMap = redirectsMap["desktop"] {
                    desktop = CustomLinkRedirect(
                        link: desktopMap["url"] as? String ?? "",
                        openAppIfInstalled: desktopMap["openAppIfInstalled"] as? Bool ?? true
                    )
                }
                
                customRedirects = CustomRedirects(ios: ios, android: android, desktop: desktop)
            }
            
            // Extract tracking parameters
            let trackingCampaign = trackingMap?["utm_campaign"]
            let trackingSource = trackingMap?["utm_source"]
            let trackingMedium = trackingMap?["utm_medium"]
            
            Grovs.generateLink(
                title: title,
                subtitle: subtitle,
                imageURL: imageURL,
                data: data,
                tags: tags,
                customRedirects: customRedirects,
                showPreviewiOS: showPreviewIos,
                showPreviewAndroid: showPreviewAndroid,
                copyToClipboardiOS: copyToClipboardIos,
                copyToClipboardAndroid: copyToClipboardAndroid,
                trackingCampaign: trackingCampaign,
                trackingSource: trackingSource,
                trackingMedium: trackingMedium
            ) { url in
                if let url = url {
                    result(url.absoluteString)
                } else {
                    result(FlutterError(code: "GENERATION_ERROR", message: "Failed to generate link", details: nil))
                }
            }
            
        case "setPushToken":
            guard let args = call.arguments as? [String: Any],
                  let token = args["token"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "token is required", details: nil))
                return
            }
            
            Grovs.pushToken = token
            result(nil)
            
        case "setUserIdentifier":
            guard let args = call.arguments as? [String: Any],
                  let identifier = args["identifier"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "identifier is required", details: nil))
                return
            }
            
            Grovs.userIdentifier = identifier
            result(nil)
            
        case "setUserAttributes":
            guard let args = call.arguments as? [String: Any],
                  let attributes = args["attributes"] as? [String: Any] else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "attributes are required", details: nil))
                return
            }
            
            Grovs.userAttributes = attributes
            result(nil)
            
        case "setDebugLevel":
            guard let args = call.arguments as? [String: Any],
                  let level = args["level"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "level is required", details: nil))
                return
            }
            
            let debugLevel: LogLevel
            switch level.lowercased() {
            case "info":
                debugLevel = .info
            case "error":
                debugLevel = .error
            default:
                debugLevel = .error
            }
            
            Grovs.setDebug(level: debugLevel)
            result(nil)
            
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

            let startDate = (args["startDate"] as? NSNumber).map {
                Date(timeIntervalSince1970: $0.doubleValue / 1000)
            }

            Grovs.logCustomPurchase(type: type, priceInCents: priceInCents, currency: currency, productID: productId, startDate: startDate) { success in
                if success {
                    result(nil)
                } else {
                    result(FlutterError(code: "PAYMENT_ERROR", message: "Failed to log custom purchase", details: nil))
                }
            }

        // Native analytics calls are fire-and-forget (void, non-throwing); nothing to surface to Flutter.
        case "track":
            guard let args = call.arguments as? [String: Any],
                  let name = args["name"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "name is required", details: nil))
                return
            }

            let properties = args["properties"] as? [String: Any]
            let tags = args["tags"] as? [String]
            Grovs.track(name, properties: properties, tags: tags)
            result(nil)

        case "setGlobalTags":
            let args = call.arguments as? [String: Any]
            let tags = args?["tags"] as? [String]
            Grovs.setGlobalTags(tags)
            result(nil)

        case "trackScreenView":
            guard let args = call.arguments as? [String: Any],
                  let screenName = args["screenName"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "screenName is required", details: nil))
                return
            }

            let properties = args["properties"] as? [String: Any]
            Grovs.trackScreenView(screenName, properties: properties)
            result(nil)

        case "setScreenAliases":
            guard let args = call.arguments as? [String: Any],
                  let aliases = args["aliases"] as? [String: String] else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "aliases is required", details: nil))
                return
            }

            Grovs.setScreenAliases(aliases)
            result(nil)

        case "setSDK":
            guard let args = call.arguments as? [String: Any],
                  let enabled = args["enabled"] as? Bool else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "enabled is required", details: nil))
                return
            }

            setSDKEnabled(enabled)
            result(nil)

        case "linkDetails":
            GrovsPlugin.linkDetails(arguments: call.arguments, result: result)

        case "handleUrl":
            result(GrovsPlugin.handleUrl(arguments: call.arguments))

        case "isGrovsNotification":
            result(GrovsPlugin.isGrovsNotification(arguments: call.arguments))

        case "handleNotificationOpen":
            result(GrovsPlugin.handleNotificationOpen(arguments: call.arguments))

        case "pauseInAppMessages":
            Grovs.pauseInAppMessages()
            result(nil)

        case "resumeInAppMessages":
            Grovs.resumeInAppMessages()
            result(nil)

        case "discardInAppMessages":
            guard let args = call.arguments as? [String: Any],
                  let dismissCurrent = args["dismissCurrent"] as? Bool else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "dismissCurrent is required", details: nil))
                return
            }

            Grovs.discardInAppMessages(dismissCurrent: dismissCurrent)
            result(nil)

        case "setInAppExcludedScreens":
            guard let args = call.arguments as? [String: Any],
                  let screens = args["screens"] as? [String] else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "screens is required", details: nil))
                return
            }

            Grovs.setInAppExcludedScreens(screens)
            result(nil)

        case "setInAppDebugLogging":
            guard let args = call.arguments as? [String: Any],
                  let enabled = args["enabled"] as? Bool else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "enabled is required", details: nil))
                return
            }

            Grovs.setInAppDebugLogging(enabled)
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
