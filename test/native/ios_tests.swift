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
    Grovs.delegate!.grovsDidEncounterError(.authenticationFailed, message: message)
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
precondition(!linkPlugin.application(UIApplication(), continue: webActivity("https://app.sqd.link/a"), restorationHandler: { _ in }))
precondition(!linkPlugin.application(UIApplication(), open: URL(string: "grovstest://b")!, options: [:]))
precondition(links() == ["https://app.sqd.link/a", "grovstest://b"])
linkPlugin.setSDKEnabled(false)
_ = GrovsPlugin.deliver(.userActivity(webActivity("https://app.sqd.link/launch")))
linkPlugin.setSDKEnabled(true)
precondition(links().suffix(2) == ["https://app.sqd.link/launch", "https://app.sqd.link/launch"])
linkPlugin.setSDKEnabled(false); linkPlugin.setSDKEnabled(true)
precondition(links().count == 4)
linkPlugin.detachFromEngine(for: linkEngine)
print("PASS iOS: app delegate links reach the SDK without being claimed, and a link received while disabled is replayed once")

let sceneEngine = engine()
let scenePlugin = sceneEngine.instance!
precondition(sceneEngine.sceneDelegate === scenePlugin)
let universal = "https://app.sqd.link/cold"
let scheme = "grovstest://cold"
Grovs.log.removeAll()
precondition(!scenePlugin.scene(UIScene(), willConnectTo: UISceneSession(), options: UIScene.ConnectionOptions(
    userActivities: [webActivity(universal)], urlContexts: [UIOpenURLContext(url: URL(string: scheme)!)])))
precondition(links() == [universal])
precondition(!scenePlugin.scene(UIScene(), willConnectTo: UISceneSession(), options: UIScene.ConnectionOptions(
    urlContexts: [UIOpenURLContext(url: URL(string: scheme)!)])))
precondition(links() == [universal, scheme])
precondition(!scenePlugin.scene(UIScene(), willConnectTo: UISceneSession(), options: nil))
precondition(!scenePlugin.scene(UIScene(), willConnectTo: UISceneSession(), options: UIScene.ConnectionOptions()))
precondition(!scenePlugin.scene(UIScene(), openURLContexts: []))
precondition(!scenePlugin.scene(UIScene(), continue: webActivity("https://app.sqd.link/warm")))
precondition(!scenePlugin.scene(UIScene(), openURLContexts: [UIOpenURLContext(url: URL(string: "grovstest://warm")!)]))
precondition(links() == [universal, scheme, "https://app.sqd.link/warm", "grovstest://warm"])
scenePlugin.detachFromEngine(for: sceneEngine)
print("PASS iOS: scene launch, URL and user activity events each reach the SDK once and are never claimed")

let sharedEngineA = engine()
let sharedEngineB = engine()
let sharedA = sharedEngineA.instance!
let sharedB = sharedEngineB.instance!
Grovs.log.removeAll()
let sharedContext = UIOpenURLContext(url: URL(string: "grovstest://shared")!)
precondition(!sharedA.scene(UIScene(), openURLContexts: [sharedContext]))
precondition(!sharedB.scene(UIScene(), openURLContexts: [sharedContext]))
precondition(links() == ["grovstest://shared"])
precondition(!sharedB.scene(UIScene(), openURLContexts: [UIOpenURLContext(url: URL(string: "grovstest://shared")!)]))
precondition(links() == ["grovstest://shared", "grovstest://shared"])
let sharedActivity = webActivity("https://app.sqd.link/shared")
precondition(!sharedA.scene(UIScene(), continue: sharedActivity))
precondition(!sharedB.scene(UIScene(), continue: sharedActivity))
precondition(links().count == 3)
precondition(!sharedB.scene(UIScene(), continue: webActivity("https://app.sqd.link/shared")))
precondition(links().count == 4)
let handoff = NSUserActivity(activityType: "com.example.handoff")
precondition(!sharedA.scene(UIScene(), continue: handoff))
precondition(!sharedB.scene(UIScene(), continue: handoff))
precondition(links().count == 5)
sharedA.detachFromEngine(for: sharedEngineA)
sharedB.detachFromEngine(for: sharedEngineB)
print("PASS iOS: a scene event seen by several engines reaches the SDK once and no engine claims it")

func handleUrl(_ url: Any?) -> Any { GrovsPlugin.handleUrl(arguments: ["url": url as Any]) }
func isInvalid(_ value: Any) -> Bool { (value as? FlutterError)?.code == "INVALID_ARGUMENT" }

let manualEngine = engine()
let manualPlugin = manualEngine.instance!
Grovs.log.removeAll()
for invalid in ["", "not a url", "relative/path", "https://", "mailto:a@b.c"] {
    precondition(isInvalid(handleUrl(invalid)), "accepted \(invalid)")
}
precondition(isInvalid(handleUrl(nil)) && isInvalid(handleUrl(42)) && isInvalid(GrovsPlugin.handleUrl(arguments: nil)))
precondition(links().isEmpty)
precondition(handleUrl("https://app.sqd.link/manual") as? Bool == true)
precondition(handleUrl("grovstest://app.sqd.link/manual") as? Bool == true)
manualPlugin.setSDKEnabled(false)
precondition(handleUrl("https://app.sqd.link/manual") as? Bool == false)
manualPlugin.setSDKEnabled(true)
precondition(links() == ["https://app.sqd.link/manual", "grovstest://app.sqd.link/manual"])
manualPlugin.detachFromEngine(for: manualEngine)
print("PASS iOS: handleUrl validates input, reaches the SDK only while enabled, and never queues")

let inAppDelegate = Grovs.inAppDelegate!
func inAppEngine() -> FlutterPluginRegistrar {
    let registrar = engine()
    precondition(Grovs.inAppDelegate === inAppDelegate)
    return registrar
}
func inAppStream(_ engine: FlutterPluginRegistrar) -> FlutterStreamHandler { stream(engine, "grovs/inapp") }
func listenInApp(_ engine: FlutterPluginRegistrar, _ sink: @escaping ([String: Any]) -> Void) {
    _ = inAppStream(engine).onListen(withArguments: nil) { sink($0 as! [String: Any]) }
}

let inAppFirst = inAppEngine()
for id in 0..<25 { inAppDelegate.grovsDidShowInAppMessage(campaignID: String(id)) }
var inAppEvents: [[String: Any]] = []
listenInApp(inAppFirst) { inAppEvents.append($0) }
precondition(inAppEvents.map { $0["campaignId"] as! String } == (5..<25).map(String.init))
precondition(inAppEvents.allSatisfy { $0["type"] as? String == "shown" && $0.count == 2 })
_ = inAppStream(inAppFirst).onCancel(withArguments: nil)
print("PASS iOS: in-app events are buffered with a bounded FIFO and replayed on listen")

inAppEvents.removeAll()
listenInApp(inAppFirst) { inAppEvents.append($0) }
inAppDelegate.grovsDidTapInAppMessage(campaignID: "c", buttonID: "b", payload: ["nested": ["k": 1]])
inAppDelegate.grovsDidTapInAppMessage(campaignID: "c", buttonID: nil, payload: nil)
inAppDelegate.grovsDidDismissInAppMessage(campaignID: "c", reason: "swipe")
inAppDelegate.grovsDidAnswerInAppMessage(campaignID: "c", value: 4, comment: "great")
inAppDelegate.grovsDidAnswerInAppMessage(campaignID: "c", value: "opt", comment: nil)
precondition(inAppEvents[0]["type"] as? String == "clicked" && inAppEvents[0]["buttonId"] as? String == "b")
precondition((inAppEvents[0]["payload"] as! [String: [String: Int]])["nested"]!["k"] == 1)
precondition(Set(inAppEvents[1].keys) == ["type", "campaignId"])
precondition(inAppEvents[2]["type"] as? String == "dismissed" && inAppEvents[2]["reason"] as? String == "swipe")
precondition(inAppEvents[3]["type"] as? String == "answered" && inAppEvents[3]["value"] as? Int == 4)
precondition(inAppEvents[3]["comment"] as? String == "great")
precondition(inAppEvents[4]["value"] as? String == "opt" && inAppEvents[4]["comment"] == nil)
print("PASS iOS: in-app events keep nested payloads, Int and String answers, and omit absent keys")

var inAppErrors = 0
_ = stream(inAppFirst, "grovs/errors").onListen(withArguments: nil) { _ in inAppErrors += 1 }
inAppEvents.removeAll()
Grovs.delegate!.grovsDidEncounterError(.inAppDisplayFailed, message: "no view")
precondition(inAppErrors == 0)
precondition(inAppEvents.count == 1 && inAppEvents[0]["type"] as? String == "failed" && inAppEvents[0]["message"] as? String == "no view")
Grovs.delegate!.grovsDidEncounterError(.authenticationFailed, message: "auth")
precondition(inAppErrors == 1 && inAppEvents.count == 1)
_ = stream(inAppFirst, "grovs/errors").onCancel(withArguments: nil)
print("PASS iOS: a display failure reaches the in-app stream and not the error stream")

_ = inAppStream(inAppFirst).onCancel(withArguments: nil)
inAppDelegate.grovsDidShowInAppMessage(campaignID: "before-withdrawal")
inAppFirst.instance!.setSDKEnabled(false)
inAppDelegate.grovsDidShowInAppMessage(campaignID: "while-disabled")
listenInApp(inAppFirst) { _ in preconditionFailure("Consent violation") }
inAppFirst.instance!.setSDKEnabled(true)
_ = inAppStream(inAppFirst).onCancel(withArguments: nil)
listenInApp(inAppFirst) { _ in preconditionFailure("Stale in-app event revived") }
_ = inAppStream(inAppFirst).onCancel(withArguments: nil)
print("PASS iOS: disable clears pending in-app events and re-enabling does not revive them")

inAppFirst.instance!.detachFromEngine(for: inAppFirst)
weak var oldInAppInstance = inAppFirst.instance
inAppFirst.instance = nil
precondition(oldInAppInstance == nil)
precondition(Grovs.inAppDelegate === inAppDelegate)
inAppDelegate.grovsDidShowInAppMessage(campaignID: "between-engines")
let inAppSecond = inAppEngine()
var secondInApp: [String] = []
listenInApp(inAppSecond) { secondInApp.append($0["campaignId"] as! String) }
inAppDelegate.grovsDidShowInAppMessage(campaignID: "after-subscription")
precondition(secondInApp == ["between-engines", "after-subscription"])
inAppSecond.instance!.detachFromEngine(for: inAppSecond)
print("PASS iOS: the in-app delegate and pending events survive engine destruction")

func linkDetails(_ arguments: Any?) -> Any? {
    var reply: Any?
    GrovsPlugin.linkDetails(arguments: arguments) { reply = $0 }
    return reply
}
func errorCode(_ value: Any?) -> String? { (value as? FlutterError)?.code }

let detailsEngine = engine()
let detailsPlugin = detailsEngine.instance!
for invalid in [nil, [String: Any](), ["path": 5]] as [Any?] {
    precondition(errorCode(linkDetails(invalid)) == "INVALID_ARGUMENT", "accepted \(String(describing: invalid))")
}
precondition(Grovs.linkDetailsPaths.isEmpty)
Grovs.linkDetailsReply = ["id": 3, "path": "abc"]
precondition((linkDetails(["path": "abc"]) as? [String: Any])?["path"] as? String == "abc")
Grovs.linkDetailsReply = nil
let failed = linkDetails(["path": "missing"]) as? FlutterError
precondition(failed?.code == "LINK_DETAILS_ERROR" && failed?.message == "Failed to get link details.")
precondition(Grovs.linkDetailsPaths == ["abc", "missing"])
detailsPlugin.setSDKEnabled(false)
let disabled = linkDetails(["path": "abc"]) as? FlutterError
precondition(disabled?.code == "SDK_DISABLED" && disabled?.message == "Grovs SDK is disabled. Call setSDK(true) first.")
precondition(Grovs.linkDetailsPaths == ["abc", "missing"])
detailsPlugin.setSDKEnabled(true)
Grovs.linkDetailsReply = ["path": "abc"]
precondition(linkDetails(["path": "abc"]) is [String: Any])
detailsPlugin.detachFromEngine(for: detailsEngine)
print("PASS iOS: linkDetails validates input, guards consent and maps the reply")
