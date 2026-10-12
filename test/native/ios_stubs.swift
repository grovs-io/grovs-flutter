import Foundation

typealias FlutterEventSink = (Any?) -> Void
class FlutterError: NSObject {}
protocol FlutterStreamHandler {
    func onListen(withArguments: Any?, eventSink: @escaping FlutterEventSink) -> FlutterError?
    func onCancel(withArguments: Any?) -> FlutterError?
}
protocol FlutterPlugin {}
protocol GrovsDelegate: AnyObject {
    func grovsDidEncounterError(_ error: GrovsError, message: String)
    func grovsReceivedPayloadFromDeeplink(link: String?, payload: [String: Any]?, tracking: [String: Any]?)
}
struct GrovsError { let description: String }
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
    static var log: [String] = []
    static func configure(APIKey: String, useTestEnvironment: Bool, baseURL: String?, autoTrackScreenViews: Bool, clipboardDomains: [String]?, enabled: Bool, delegate: GrovsDelegate?) {
        log.append("configure enabled=\(enabled)")
    }
    static func setSDK(enabled: Bool) { log.append("setSDK \(enabled)") }
    static func handleAppDelegate(continue activity: NSUserActivity, restorationHandler: ([Any]) -> Void) -> Bool {
        log.append("link \(activity.webpageURL!.absoluteString)")
        return true
    }
    static func handleAppDelegate(open url: URL, options: [String: Any]) -> Bool {
        log.append("link \(url.absoluteString)")
        return true
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
        init(userActivities: Set<NSUserActivity> = [], urlContexts: Set<UIOpenURLContext> = []) {
            self.userActivities = userActivities
            self.urlContexts = urlContexts
        }
    }
}
