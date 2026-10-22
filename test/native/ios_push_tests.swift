import Foundation

let registrar = FlutterPluginRegistrar()
GrovsPlugin.register(with: registrar)
let plugin = registrar.instance!
let grovsPush: [AnyHashable: Any] = ["grovs_campaign_id": "42", "link": "https://app.sqd.link/push"]
let otherPush: [AnyHashable: Any] = ["gcm.message_id": "1"]

func sdkCalls(_ name: String) -> [String] {
    Grovs.log.filter { $0.hasPrefix(name) }
}

func tap(_ userInfo: [AnyHashable: Any]) -> Int {
    var completions = 0
    plugin.userNotificationCenter(UNUserNotificationCenter(), didReceive: UNNotificationResponse(userInfo: userInfo)) {
        completions += 1
    }
    return completions
}

func present(_ userInfo: [AnyHashable: Any]) -> [UNNotificationPresentationOptions] {
    var options: [UNNotificationPresentationOptions] = []
    plugin.userNotificationCenter(UNUserNotificationCenter(), willPresent: UNNotification(userInfo: userInfo)) {
        options.append($0)
    }
    return options
}

plugin.application(UIApplication(), didRegisterForRemoteNotificationsWithDeviceToken: Data([0x0a, 0xff, 0x01]))
precondition(sdkCalls("setPushToken") == ["setPushToken 0aff01"])
print("PASS iOS push: the APNs device token reaches the SDK")

precondition(tap(grovsPush) == 1)
precondition(sdkCalls("handleNotificationResponse") == ["handleNotificationResponse \(UNNotificationDefaultActionIdentifier)"])
print("PASS iOS push: a Grovs tap is reported once and completes once")

Grovs.log = []
precondition(tap(otherPush) == 0)
precondition(sdkCalls("handleNotificationResponse").isEmpty)
print("PASS iOS push: a tap on another push is left to its owner")

precondition(present(grovsPush) == [[.banner, .list, .sound]])
precondition(present(otherPush).isEmpty)
print("PASS iOS push: a Grovs push shows in the foreground, other pushes are left to their owner")

func isGrovs(_ arguments: Any?) -> Any { GrovsPlugin.isGrovsNotification(arguments: arguments) }
func open(_ arguments: Any?) -> Any { GrovsPlugin.handleNotificationOpen(arguments: arguments) }
func isInvalid(_ result: Any) -> Bool { (result as? FlutterError)?.code == "INVALID_ARGUMENT" }

precondition(isGrovs(["data": grovsPush]) as? Bool == true)
precondition(isGrovs(["data": otherPush]) as? Bool == false)
precondition(isInvalid(isGrovs(nil)) && isInvalid(isGrovs(["data": 42])))
Grovs.log = []
precondition(open(["data": grovsPush]) as? Bool == true)
precondition(open(["data": otherPush]) as? Bool == false)
precondition(isInvalid(open(nil)) && isInvalid(open(["data": "x"])))
precondition(sdkCalls("handleNotificationOpen").count == 2)
print("PASS iOS push: the push helpers validate input and pass the payload to the SDK")

plugin.setSDKEnabled(false)
Grovs.log = []
precondition(tap(grovsPush) == 1)
precondition(open(["data": grovsPush]) as? Bool == false)
precondition(sdkCalls("handleNotification").isEmpty)
plugin.setSDKEnabled(true)
precondition(sdkCalls("handleNotification").isEmpty)
print("PASS iOS push: taps while disabled complete without reaching the SDK and are not replayed")

let secondRegistrar = FlutterPluginRegistrar()
GrovsPlugin.register(with: secondRegistrar)
let secondPlugin = secondRegistrar.instance!
Grovs.log = []
let sharedTap = UNNotificationResponse(userInfo: grovsPush)
var sharedCompletions = 0
plugin.userNotificationCenter(UNUserNotificationCenter(), didReceive: sharedTap) { sharedCompletions += 1 }
secondPlugin.userNotificationCenter(UNUserNotificationCenter(), didReceive: sharedTap) { sharedCompletions += 1 }
precondition(sdkCalls("handleNotificationResponse").count == 1 && sharedCompletions == 1)
let sharedPush = UNNotification(userInfo: grovsPush)
var sharedOptions = 0
plugin.userNotificationCenter(UNUserNotificationCenter(), willPresent: sharedPush) { _ in sharedOptions += 1 }
secondPlugin.userNotificationCenter(UNUserNotificationCenter(), willPresent: sharedPush) { _ in sharedOptions += 1 }
precondition(sharedOptions == 1)
print("PASS iOS push: a callback repeated for every engine is handled and completed once")

Grovs.log = []
let launchDate = Date()
let launchTap = UNNotificationResponse(userInfo: grovsPush, identifier: "launch", date: launchDate)
_ = plugin.scene(UIScene(), willConnectTo: UISceneSession(), options: UIScene.ConnectionOptions(notificationResponse: launchTap))
_ = secondPlugin.scene(UIScene(), willConnectTo: UISceneSession(), options: UIScene.ConnectionOptions(notificationResponse: launchTap))
precondition(sdkCalls("handleNotificationResponse").count == 1)
var launchCompletions = 0
plugin.userNotificationCenter(UNUserNotificationCenter(), didReceive: UNNotificationResponse(userInfo: grovsPush, identifier: "launch", date: launchDate)) {
    launchCompletions += 1
}
precondition(sdkCalls("handleNotificationResponse").count == 1 && launchCompletions == 1)
_ = plugin.scene(UIScene(), willConnectTo: UISceneSession(), options: UIScene.ConnectionOptions(notificationResponse: UNNotificationResponse(userInfo: otherPush)))
precondition(sdkCalls("handleNotificationResponse").count == 1)
print("PASS iOS push: a launch tap from the scene is reported once, and a later didReceive for it only completes")

Grovs.log = []
precondition(tap(grovsPush) == 1 && tap(grovsPush) == 1)
let resent = UNNotificationResponse(userInfo: grovsPush, identifier: "launch", date: launchDate.addingTimeInterval(60))
plugin.userNotificationCenter(UNUserNotificationCenter(), didReceive: resent) {}
precondition(sdkCalls("handleNotificationResponse").count == 3)
print("PASS iOS push: separate deliveries are each reported, even with the same identifier")
