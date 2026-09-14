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
var links: [[String: Any]] = []
_ = stream(first).onListen(withArguments: nil) { links.append($0 as! [String: Any]) }
precondition(links.map { $0["link"] as! String } == (5..<25).map(String.init))
precondition((links.last!["data"] as! [String: String])["id"] == "24")
precondition((links.last!["tracking"] as! [String: String])["source"] == "test")
_ = stream(first).onCancel(withArguments: nil)
emit("cancelled")
_ = stream(first).onListen(withArguments: nil) { links.append($0 as! [String: Any]) }
precondition(links.count == 21)
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
