import Flutter
import Grovs

// The SDK and its pending events outlive individual Flutter engines.
final class GrovsEventRelay: NSObject, GrovsDelegate, GrovsInAppDelegate {
    let errors = BufferedEventStream()
    let deeplinks = BufferedEventStream()
    let inApp = BufferedEventStream()

    func grovsDidEncounterError(_ error: GrovsError, message: String) {
        if error == .inAppDisplayFailed {
            inApp.send(["type": "failed", "message": message])
            return
        }
        errors.send(["code": error.description, "message": message])
    }

    func grovsReceivedPayloadFromDeeplink(link: String?, payload: [String: Any]?, tracking: [String: Any]?) {
        var event: [String: Any] = [:]
        if let link = link { event["link"] = link }
        if let payload = payload { event["data"] = payload }
        if let tracking = tracking { event["tracking"] = tracking }
        deeplinks.send(event)
    }

    func grovsDidShowInAppMessage(campaignID: String) {
        inApp.send(["type": "shown", "campaignId": campaignID])
    }

    func grovsDidTapInAppMessage(campaignID: String, buttonID: String?, payload: [String: Any]?) {
        var event: [String: Any] = ["type": "clicked", "campaignId": campaignID]
        if let buttonID = buttonID { event["buttonId"] = buttonID }
        if let payload = payload { event["payload"] = payload }
        inApp.send(event)
    }

    func grovsDidDismissInAppMessage(campaignID: String, reason: String) {
        inApp.send(["type": "dismissed", "campaignId": campaignID, "reason": reason])
    }

    func grovsDidAnswerInAppMessage(campaignID: String, value: Any, comment: String?) {
        var event: [String: Any] = ["type": "answered", "campaignId": campaignID, "value": value]
        if let comment = comment { event["comment"] = comment }
        inApp.send(event)
    }
}

// Accessed only on the platform's main thread.
final class BufferedEventStream {
    private weak var listener: BufferedStreamHandler?
    private var pending: [[String: Any]] = []
    private let maxPending = 20
    private var generation = 0

    var enabled = true {
        didSet {
            if !enabled {
                generation += 1
                pending.removeAll()
            }
        }
    }

    func send(_ event: [String: Any]) {
        guard enabled else { return }
        if let sink = listener?.sink {
            sink(event)
            return
        }
        pending.append(event)
        if pending.count > maxPending {
            pending.removeFirst()
        }
    }

    func listen(_ handler: BufferedStreamHandler) {
        listener = handler
        let events = pending
        let currentGeneration = generation
        pending.removeAll()
        for event in events {
            guard currentGeneration == generation else { return }
            send(event)
        }
    }

    func cancel(_ handler: BufferedStreamHandler) {
        if listener === handler {
            listener = nil
        }
    }
}

final class BufferedStreamHandler: NSObject, FlutterStreamHandler {
    private let stream: BufferedEventStream
    fileprivate var sink: FlutterEventSink?

    init(stream: BufferedEventStream) {
        self.stream = stream
        super.init()
    }

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        sink = events
        stream.listen(self)
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        sink = nil
        stream.cancel(self)
        return nil
    }
}
