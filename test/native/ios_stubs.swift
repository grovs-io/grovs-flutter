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
}
class Grovs {
    static weak var delegate: GrovsDelegate?
    static func setSDK(enabled: Bool) {}
    static func handleAppDelegate(continue activity: NSUserActivity, restorationHandler: ([Any]) -> Void) -> Bool { true }
    static func handleAppDelegate(open url: URL, options: [String: Any]) -> Bool { true }
}
