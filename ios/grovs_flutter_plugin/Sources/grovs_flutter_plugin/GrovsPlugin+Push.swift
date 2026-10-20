import Flutter
import UIKit
import UserNotifications
import Grovs

// Every plugin receives the same notification center callbacks and completion
// handler, so only Grovs pushes are handled here and the handler is called once.
extension GrovsPlugin {
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
        if GrovsPlugin.sdkEnabled {
            Grovs.handleNotificationResponse(response)
        }
        completionHandler()
    }

    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        guard Grovs.isGrovsNotification(userInfo: notification.request.content.userInfo) else { return }
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .list, .sound])
        } else {
            completionHandler([.alert, .sound])
        }
    }
}
