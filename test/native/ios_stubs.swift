import Foundation

typealias FlutterEventSink = (Any?) -> Void
typealias FlutterResult = (Any?) -> Void
class FlutterError: NSObject {
    var code = ""
    var message: String?
    override init() {}
    init(code: String, message: String?, details: Any?) { self.code = code; self.message = message }
}
protocol FlutterStreamHandler {
    func onListen(withArguments: Any?, eventSink: @escaping FlutterEventSink) -> FlutterError?
    func onCancel(withArguments: Any?) -> FlutterError?
}
protocol FlutterPlugin {}
protocol GrovsDelegate: AnyObject {
    func grovsDidEncounterError(_ error: GrovsError, message: String)
    func grovsReceivedPayloadFromDeeplink(link: String?, payload: [String: Any]?, tracking: [String: Any]?)
}
enum GrovsError: CustomStringConvertible {
    case authenticationFailed, inAppDisplayFailed
    var description: String { self == .inAppDisplayFailed ? "in_app_display_failed" : "authentication_failed" }
}
protocol GrovsInAppDelegate: AnyObject {
    func grovsDidShowInAppMessage(campaignID: String)
    func grovsDidTapInAppMessage(campaignID: String, buttonID: String?, payload: [String: Any]?)
    func grovsDidDismissInAppMessage(campaignID: String, reason: String)
    func grovsDidAnswerInAppMessage(campaignID: String, value: Any, comment: String?)
}
class Messenger: NSObject {
    var methods: [String: FlutterMethodChannel] = [:]
    var events: [String: FlutterEventChannel] = [:]
}
class FlutterMethodChannel {
    init(name: String, binaryMessenger: Messenger) { binaryMessenger.methods[name] = self }
    func setMethodCallHandler(_ handler: Any?) {}
}
class FlutterEventChannel {
    var handler: FlutterStreamHandler?
    init(name: String, binaryMessenger: Messenger) { binaryMessenger.events[name] = self }
    func setStreamHandler(_ handler: FlutterStreamHandler?) { self.handler = handler }
}
class FlutterPluginRegistrar {
    var instance: GrovsPlugin?
    let messages = Messenger()
    func messenger() -> Messenger { messages }
    func publish(_ instance: GrovsPlugin) { self.instance = instance }
    func addMethodCallDelegate(_ instance: GrovsPlugin, channel: FlutterMethodChannel) {}
    func addApplicationDelegate(_ instance: GrovsPlugin) {}
    weak var sceneDelegate: GrovsPlugin?
    func addSceneDelegate(_ instance: GrovsPlugin) { sceneDelegate = instance }
}
class UIApplication {}
var testInfoDictionary: [String: Any]? = nil
class Grovs {
    static weak var delegate: GrovsDelegate?
    static weak var inAppDelegate: GrovsInAppDelegate?
    static var log: [String] = []
    static func configure(APIKey: String, useTestEnvironment: Bool, baseURL: String?, autoTrackScreenViews: Bool, clipboardDomains: [String]?, enabled: Bool, delegate: GrovsDelegate?) {
        log.append("configure enabled=\(enabled)")
    }
    static func setSDK(enabled: Bool) { log.append("setSDK \(enabled)") }
    static var linkDetailsPaths: [String] = []
    static var linkDetailsReply: [String: Any]? = nil
    static func linkDetails(path: String, completion: @escaping ([String: Any]?) -> Void) {
        linkDetailsPaths.append(path)
        completion(linkDetailsReply)
    }
    static func handleAppDelegate(continue activity: NSUserActivity, restorationHandler: ([Any]) -> Void) -> Bool {
        log.append("link \(activity.webpageURL?.absoluteString ?? activity.activityType)")
        return activity.webpageURL != nil
    }
    static func handleAppDelegate(open url: URL, options: [String: Any]) -> Bool {
        log.append("link \(url.absoluteString)")
        return true
    }
    static func setPushToken(deviceToken: Data) {
        log.append("setPushToken \(deviceToken.map { String(format: "%02x", $0) }.joined())")
    }
    static func isGrovsNotification(userInfo: [AnyHashable: Any]) -> Bool {
        log.append("isGrovsNotification")
        return (userInfo["grovs_campaign_id"] as? String)?.isEmpty == false
    }
    @discardableResult
    static func handleNotificationResponse(_ response: UNNotificationResponse) -> Bool {
        log.append("handleNotificationResponse \(response.actionIdentifier)")
        return (response.notification.request.content.userInfo["grovs_campaign_id"] as? String)?.isEmpty == false
    }
    @discardableResult
    static func handleNotificationOpen(userInfo: [AnyHashable: Any]) -> Bool {
        log.append("handleNotificationOpen")
        return (userInfo["grovs_campaign_id"] as? String)?.isEmpty == false
    }
}
func links() -> [String] {
    Grovs.log.filter { $0.hasPrefix("link ") }.map { String($0.dropFirst("link ".count)) }
}
func webActivity(_ link: String) -> NSUserActivity {
    let activity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
    activity.webpageURL = URL(string: link)!
    return activity
}

protocol FlutterSceneLifeCycleDelegate {}
class UISceneSession {}
class UIOpenURLContext: NSObject {
    let url: URL
    init(url: URL) { self.url = url }
}
class UIScene {
    class ConnectionOptions {
        let userActivities: Set<NSUserActivity>
        let urlContexts: Set<UIOpenURLContext>
        let notificationResponse: UNNotificationResponse?
        init(userActivities: Set<NSUserActivity> = [], urlContexts: Set<UIOpenURLContext> = [], notificationResponse: UNNotificationResponse? = nil) {
            self.userActivities = userActivities
            self.urlContexts = urlContexts
            self.notificationResponse = notificationResponse
        }
    }
}

let UNNotificationDefaultActionIdentifier = "com.apple.UNNotificationDefaultActionIdentifier"
class UNUserNotificationCenter {}
class UNNotificationContent {
    let userInfo: [AnyHashable: Any]
    init(userInfo: [AnyHashable: Any]) { self.userInfo = userInfo }
}
class UNNotificationRequest {
    let identifier: String
    let content: UNNotificationContent
    init(identifier: String, content: UNNotificationContent) {
        self.identifier = identifier
        self.content = content
    }
}
class UNNotification {
    let request: UNNotificationRequest
    let date: Date
    init(userInfo: [AnyHashable: Any], identifier: String = UUID().uuidString, date: Date = Date()) {
        request = UNNotificationRequest(identifier: identifier, content: UNNotificationContent(userInfo: userInfo))
        self.date = date
    }
}
class UNNotificationResponse {
    let notification: UNNotification
    let actionIdentifier: String
    init(userInfo: [AnyHashable: Any], actionIdentifier: String = UNNotificationDefaultActionIdentifier, identifier: String = UUID().uuidString, date: Date = Date()) {
        notification = UNNotification(userInfo: userInfo, identifier: identifier, date: date)
        self.actionIdentifier = actionIdentifier
    }
}
struct UNNotificationPresentationOptions: OptionSet {
    let rawValue: Int
    static let alert = UNNotificationPresentationOptions(rawValue: 1 << 0)
    static let sound = UNNotificationPresentationOptions(rawValue: 1 << 1)
    static let list = UNNotificationPresentationOptions(rawValue: 1 << 2)
    static let banner = UNNotificationPresentationOptions(rawValue: 1 << 3)
}
