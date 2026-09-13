import Flutter
import UIKit
import Grovs

extension Array where Element == Any {
    func toArray<T>(of type: T.Type) -> [T] {
        return self.compactMap { $0 as? T }
    }
}

extension Array where Element == Any {
    static func convertClosure<T>(
        _ closure: @escaping ([Any]) -> Void,
        to type: T.Type
    ) -> ([T]) -> Void {
        return { typedArray in
            let anyArray = typedArray.map { $0 as Any }
            closure(anyArray)
        }
    }
    
    /// Wraps a `([Any]) -> Void` closure as a `([T]?) -> Void` closure.
    static func convertClosure<T>(
        _ closure: @escaping ([Any]) -> Void,
        toOptionalArrayOf type: T.Type
    ) -> ([T]?) -> Void {
        return { typedArray in
            let anyArray: [Any] = typedArray?.map { $0 } ?? []
            closure(anyArray)
        }
    }
}

/// Forwards native SDK errors to Dart, buffering the ones raised before Dart subscribes.
private final class ErrorStreamHandler: NSObject, FlutterStreamHandler {
    private var sink: FlutterEventSink?
    private var pending: [[String: Any]] = []
    private let maxPending = 20

    func send(_ event: [String: Any]) {
        if let sink = sink {
            sink(event)
            return
        }
        pending.append(event)
        if pending.count > maxPending {
            pending.removeFirst()
        }
    }

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        sink = events
        pending.forEach { events($0) }
        pending.removeAll()
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        sink = nil
        return nil
    }
}

public class GrovsPlugin: NSObject, FlutterPlugin {
    private enum PendingLaunchLink {
        case userActivity(NSUserActivity)
        case url(URL)
    }

    private var eventSink: FlutterEventSink?
    private var methodChannel: FlutterMethodChannel?
    private let errorStream = ErrorStreamHandler()

    // Consent state and the launch link received while disabled are shared by
    // every engine because the SDK is configured once per process.
    private static var sdkEnabled = true
    private static var pendingLaunchLink: PendingLaunchLink?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "grovs", binaryMessenger: registrar.messenger())
        let eventChannel = FlutterEventChannel(name: "grovs/deeplinks", binaryMessenger: registrar.messenger())
        
        let instance = GrovsPlugin()
        instance.methodChannel = channel
        
        registrar.addMethodCallDelegate(instance, channel: channel)
        registrar.addApplicationDelegate(instance)
        eventChannel.setStreamHandler(instance)
        let errorChannel = FlutterEventChannel(name: "grovs/errors", binaryMessenger: registrar.messenger())
        errorChannel.setStreamHandler(instance.errorStream)
    }

    // Hook into didFinishLaunchingWithOptions
    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [AnyHashable : Any] = [:]) -> Bool {
        // Read API key and test environment flag from Info.plist
        if let infoDictionary = Bundle.main.infoDictionary, let apiKey = infoDictionary["GrovsApiKey"] as? String {
            let useTestEnvironment = infoDictionary["GrovsUseTestEnvironment"] as? Bool ?? false
            let baseURL = infoDictionary["GrovsBaseURL"] as? String
            let clipboardDomains = infoDictionary["GrovsClipboardDomains"] as? [String]
            let enabled = infoDictionary["GrovsEnabled"] as? Bool ?? true
            GrovsPlugin.sdkEnabled = enabled
            Grovs.configure(
                APIKey: apiKey,
                useTestEnvironment: useTestEnvironment,
                baseURL: baseURL,
                autoTrackScreenViews: false,
                clipboardDomains: clipboardDomains,
                enabled: enabled,
                delegate: self
            )
        }
        
        return true
    }
    
    // Handle universal link continuation
    public func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]) -> Void) -> Bool {
        if !GrovsPlugin.sdkEnabled {
            GrovsPlugin.pendingLaunchLink = .userActivity(userActivity)
        }
        return Grovs.handleAppDelegate(continue: userActivity, restorationHandler: Array.convertClosure(restorationHandler, toOptionalArrayOf: UIUserActivityRestoring.self))
    }

    // Handle URI opening
    public func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        if !GrovsPlugin.sdkEnabled {
            GrovsPlugin.pendingLaunchLink = .url(url)
        }
        return Grovs.handleAppDelegate(open: url, options: options)
    }

    private func setSDKEnabled(_ enabled: Bool) {
        guard enabled != GrovsPlugin.sdkEnabled else { return }
        Grovs.setSDK(enabled: enabled)
        GrovsPlugin.sdkEnabled = enabled

        guard enabled, let pending = GrovsPlugin.pendingLaunchLink else { return }
        GrovsPlugin.pendingLaunchLink = nil
        // The native SDK drops links received while disabled; hand it the launch
        // link again now that it may process it. Must run on the main thread.
        switch pending {
        case .userActivity(let activity):
            _ = Grovs.handleAppDelegate(continue: activity, restorationHandler: { _ in })
        case .url(let url):
            _ = Grovs.handleAppDelegate(open: url, options: [:])
        }
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
            
        case "numberOfUnreadMessages":
            Grovs.numberOfUnreadMessages { count in
                result(count)
            }
            
        case "displayMessages":
            Grovs.displayMessagesViewController() {
                result(nil)
            }
            
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

        default:
            result(FlutterMethodNotImplemented)
        }
    }
}

// MARK: - GrovsDelegate
extension GrovsPlugin: GrovsDelegate {
    public func grovsDidEncounterError(_ error: GrovsError, message: String) {
        errorStream.send(["code": error.description, "message": message])
    }

    public func grovsReceivedPayloadFromDeeplink(link: String?, payload: [String : Any]?, tracking: [String : Any]?) {
        // Drop lookups that complete after consent is withdrawn.
        guard GrovsPlugin.sdkEnabled else { return }
        guard let eventSink = eventSink else { return }
        
        var eventData: [String: Any] = [:]
        if let link = link {
            eventData["link"] = link
        }
        if let payload = payload {
            eventData["data"] = payload
        }
        if let tracking = tracking {
            eventData["tracking"] = tracking
        }
        
        eventSink(eventData)
    }
}

// MARK: - FlutterStreamHandler
extension GrovsPlugin: FlutterStreamHandler {
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
}
