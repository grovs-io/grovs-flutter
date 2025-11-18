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

public class GrovsPlugin: NSObject, FlutterPlugin {
    private var eventSink: FlutterEventSink?
    private var methodChannel: FlutterMethodChannel?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "grovs", binaryMessenger: registrar.messenger())
        let eventChannel = FlutterEventChannel(name: "grovs/deeplinks", binaryMessenger: registrar.messenger())
        
        let instance = GrovsPlugin()
        instance.methodChannel = channel
        
        registrar.addMethodCallDelegate(instance, channel: channel)
        registrar.addApplicationDelegate(instance)
        eventChannel.setStreamHandler(instance)
    }

    // Hook into didFinishLaunchingWithOptions
    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [AnyHashable : Any] = [:]) -> Bool {
        // Read API key and test environment flag from Info.plist
        if let infoDictionary = Bundle.main.infoDictionary, let apiKey = infoDictionary["GrovsApiKey"] as? String {
            let useTestEnvironment = infoDictionary["GrovsUseTestEnvironment"] as? Bool ?? false
            Grovs.configure(APIKey: apiKey, useTestEnvironment: useTestEnvironment, delegate: self)
        }
        
        return true
    }
    
    // Handle universal link continuation
    public func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]) -> Void) -> Bool {
        return Grovs.handleAppDelegate(continue: userActivity, restorationHandler: Array.convertClosure(restorationHandler, toOptionalArrayOf: UIUserActivityRestoring.self))
    }

    // Handle URI opening
    public func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return Grovs.handleAppDelegate(open: url, options: options)
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
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}

// MARK: - GrovsDelegate
extension GrovsPlugin: GrovsDelegate {
    public func grovsReceivedPayloadFromDeeplink(link: String?, payload: [String : Any]?, tracking: [String : Any]?) {
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
