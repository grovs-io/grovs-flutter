import Flutter
import UIKit
import UserNotifications
import Grovs

// Flutter repeats each notification callback, with the same completion handler,
// for every engine's plugin, and a launch tap can also arrive with the scene.
// Only Grovs pushes are handled here, each one once.
extension GrovsPlugin {
    private static var lastOpenedNotification: String?
    private static var lastCompletedNotification: String?
    private static var lastPresentedNotification: String?

    private static func isNew(_ notification: UNNotification, since last: inout String?) -> Bool {
        let key = "\(notification.request.identifier) \(notification.date.timeIntervalSince1970)"
        if last == key { return false }
        last = key
        return true
    }

    static func openNotification(_ response: UNNotificationResponse) {
        guard sdkEnabled,
              Grovs.isGrovsNotification(userInfo: response.notification.request.content.userInfo),
              isNew(response.notification, since: &lastOpenedNotification) else { return }
        Grovs.handleNotificationResponse(response)
    }

    static var missingNotificationData: FlutterError {
        FlutterError(code: "INVALID_ARGUMENT", message: "data is required", details: nil)
    }

    static func notificationData(_ arguments: Any?) -> [AnyHashable: Any]? {
        (arguments as? [String: Any])?["data"] as? [AnyHashable: Any]
    }

    public func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Grovs.setPushToken(deviceToken: deviceToken)
    }

    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        guard Grovs.isGrovsNotification(userInfo: response.notification.request.content.userInfo) else { return }
        GrovsPlugin.openNotification(response)
        if GrovsPlugin.isNew(response.notification, since: &GrovsPlugin.lastCompletedNotification) {
            completionHandler()
        }
    }

    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        guard Grovs.isGrovsNotification(userInfo: notification.request.content.userInfo),
              GrovsPlugin.isNew(notification, since: &GrovsPlugin.lastPresentedNotification) else { return }
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .list, .sound])
        } else {
            completionHandler([.alert, .sound])
        }
    }
}
