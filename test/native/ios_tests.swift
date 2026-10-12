import Foundation

func engine() -> FlutterPluginRegistrar {
    let registrar = FlutterPluginRegistrar()
    GrovsPlugin.register(with: registrar)
    return registrar
}
func stream(_ engine: FlutterPluginRegistrar, _ name: String = "grovs/deeplinks") -> FlutterStreamHandler {
    engine.messages.events[name]!.handler!
}
func emit(_ id: String) {
    Grovs.delegate!.grovsReceivedPayloadFromDeeplink(link: id, payload: ["id": id], tracking: ["source": "test"])
}
func error(_ message: String) {
    Grovs.delegate!.grovsDidEncounterError(GrovsError(description: "authentication_failed"), message: message)
}

let first = engine()
let delegate = Grovs.delegate!
for id in 0..<25 { emit(String(id)) }
var received: [[String: Any]] = []
_ = stream(first).onListen(withArguments: nil) { received.append($0 as! [String: Any]) }
precondition(received.map { $0["link"] as! String } == (5..<25).map(String.init))
precondition((received.last!["data"] as! [String: String])["id"] == "24")
precondition((received.last!["tracking"] as! [String: String])["source"] == "test")
_ = stream(first).onCancel(withArguments: nil)
emit("cancelled")
_ = stream(first).onListen(withArguments: nil) { received.append($0 as! [String: Any]) }
precondition(received.count == 21)
_ = stream(first).onCancel(withArguments: nil)
_ = stream(first).onListen(withArguments: nil) { _ in preconditionFailure("Duplicate replay") }
print("PASS iOS: bounded FIFO buffer, payload preservation, cancel/resubscribe")

_ = stream(first).onCancel(withArguments: nil)
emit("before-withdrawal")
first.instance!.setSDKEnabled(false)
emit("while-disabled")
_ = stream(first).onListen(withArguments: nil) { _ in preconditionFailure("Consent violation") }
first.instance!.setSDKEnabled(true)
_ = stream(first).onCancel(withArguments: nil)
_ = stream(first).onListen(withArguments: nil) { _ in preconditionFailure("Stale event revived") }
print("PASS iOS: disable clears pending links and re-enabling does not revive them")

first.instance!.detachFromEngine(for: first)
precondition(first.messages.events.values.allSatisfy { $0.handler == nil })
weak var oldInstance = first.instance
first.instance = nil
precondition(oldInstance == nil)
emit("between-engines")
error("before-error-subscription")
let second = engine()
precondition(Grovs.delegate === delegate)
var errors: [String] = []
_ = stream(second, "grovs/errors").onListen(withArguments: nil) {
    errors.append(($0 as! [String: String])["message"]!)
}
error("after-error-subscription")
precondition(errors == ["before-error-subscription", "after-error-subscription"])
var replacementLinks: [String] = []
_ = stream(second).onListen(withArguments: nil) {
    replacementLinks.append(($0 as! [String: Any])["link"] as! String)
}
precondition(replacementLinks == ["between-engines"])
print("PASS iOS: delegate and pending events survive engine destruction, including error-only listening")

let third = engine()
var newestLinks: [String] = []
_ = stream(third).onListen(withArguments: nil) {
    newestLinks.append(($0 as! [String: Any])["link"] as! String)
}
second.instance!.detachFromEngine(for: second)
emit("new-owner")
precondition(newestLinks == ["new-owner"])
precondition(replacementLinks == ["between-engines"])
print("PASS iOS: old engine detach cannot cancel the new engine subscription")

third.instance!.setSDKEnabled(false)
error("errors-still-enabled")
var disabledErrors = 0
_ = stream(third, "grovs/errors").onListen(withArguments: nil) { _ in disabledErrors += 1 }
precondition(disabledErrors == 1)
third.instance!.setSDKEnabled(true)
third.instance!.detachFromEngine(for: third)
print("PASS iOS: error delivery is independent of deep link consent")

let relay = GrovsEventRelay()
weak var weakHandler: BufferedStreamHandler?
do {
    let handler = BufferedStreamHandler(stream: relay.deeplinks)
    weakHandler = handler
    _ = handler.onListen(withArguments: nil) { _ in }
}
precondition(weakHandler == nil)
relay.deeplinks.send(["id": 1])
relay.deeplinks.send(["id": 2])
let handler = BufferedStreamHandler(stream: relay.deeplinks)
var flushed = 0
_ = handler.onListen(withArguments: nil) { _ in
    flushed += 1
    relay.deeplinks.enabled = false
    relay.deeplinks.enabled = true
}
precondition(flushed == 1)
print("PASS iOS: stream owners are weak and consent changes stop an in-progress flush")

GrovsPlugin.configureFromInfoPlist(nil)
GrovsPlugin.configureFromInfoPlist(["GrovsUseTestEnvironment": true])
precondition(!Grovs.log.contains { $0.hasPrefix("configure") })
GrovsPlugin.configureFromInfoPlist(["GrovsApiKey": "key"])
GrovsPlugin.configureFromInfoPlist(["GrovsApiKey": "key", "GrovsEnabled": false])
precondition(Grovs.log.filter { $0.hasPrefix("configure") } == ["configure enabled=true"])
print("PASS iOS: the SDK is configured once, and only when an API key is present")

let linkEngine = engine()
let linkPlugin = linkEngine.instance!
Grovs.log.removeAll()
precondition(linkPlugin.application(UIApplication(), continue: webActivity("https://app.sqd.link/a"), restorationHandler: { _ in }))
precondition(linkPlugin.application(UIApplication(), open: URL(string: "grovstest://b")!, options: [:]))
precondition(links() == ["https://app.sqd.link/a", "grovstest://b"])
linkPlugin.setSDKEnabled(false)
_ = GrovsPlugin.deliver(.userActivity(webActivity("https://app.sqd.link/launch")))
linkPlugin.setSDKEnabled(true)
precondition(links().suffix(2) == ["https://app.sqd.link/launch", "https://app.sqd.link/launch"])
linkPlugin.setSDKEnabled(false); linkPlugin.setSDKEnabled(true)
precondition(links().count == 4)
linkPlugin.detachFromEngine(for: linkEngine)
print("PASS iOS: app delegate links reach the SDK, and a link received while disabled is replayed once")

let sceneEngine = engine()
let scenePlugin = sceneEngine.instance!
precondition(sceneEngine.sceneDelegate === scenePlugin)
let universal = "https://app.sqd.link/cold"
let scheme = "grovstest://cold"
Grovs.log.removeAll()
precondition(scenePlugin.scene(UIScene(), willConnectTo: UISceneSession(), options: UIScene.ConnectionOptions(
    userActivities: [webActivity(universal)], urlContexts: [UIOpenURLContext(url: URL(string: scheme)!)])))
precondition(links() == [universal])
precondition(scenePlugin.scene(UIScene(), willConnectTo: UISceneSession(), options: UIScene.ConnectionOptions(
    urlContexts: [UIOpenURLContext(url: URL(string: scheme)!)])))
precondition(links() == [universal, scheme])
precondition(!scenePlugin.scene(UIScene(), willConnectTo: UISceneSession(), options: nil))
precondition(!scenePlugin.scene(UIScene(), willConnectTo: UISceneSession(), options: UIScene.ConnectionOptions()))
precondition(!scenePlugin.scene(UIScene(), openURLContexts: []))
precondition(scenePlugin.scene(UIScene(), continue: webActivity("https://app.sqd.link/warm")))
precondition(scenePlugin.scene(UIScene(), openURLContexts: [UIOpenURLContext(url: URL(string: "grovstest://warm")!)]))
precondition(links() == [universal, scheme, "https://app.sqd.link/warm", "grovstest://warm"])
scenePlugin.detachFromEngine(for: sceneEngine)
print("PASS iOS: scene launch, URL and user activity events each reach the SDK once")
