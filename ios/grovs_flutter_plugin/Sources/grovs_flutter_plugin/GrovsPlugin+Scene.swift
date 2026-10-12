import Flutter
import UIKit

// Links are handed to Grovs but never claimed, so other plugins (for example
// login callbacks) still receive them.
extension GrovsPlugin: FlutterSceneLifeCycleDelegate {
    // Flutter forwards each warm scene event to every engine's plugin, so the
    // same event object arrives once per engine. Deliver it only once.
    private static weak var lastSceneEvent: AnyObject?

    private static func isNewSceneEvent(_ event: AnyObject) -> Bool {
        if lastSceneEvent === event { return false }
        lastSceneEvent = event
        return true
    }

    public func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions?) -> Bool {
        // Some hosts never forward the app launch event to plugins in scene apps.
        GrovsPlugin.configureFromInfoPlist()
        guard let connectionOptions else { return false }
        if let activity = connectionOptions.userActivities.first(where: { $0.webpageURL != nil }) {
            _ = GrovsPlugin.deliver(.userActivity(activity))
        } else if let url = connectionOptions.urlContexts.first?.url {
            _ = GrovsPlugin.deliver(.url(url))
        }
        return false
    }

    public func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) -> Bool {
        if let context = URLContexts.first, GrovsPlugin.isNewSceneEvent(context) {
            _ = GrovsPlugin.deliver(.url(context.url))
        }
        return false
    }

    public func scene(_ scene: UIScene, continue userActivity: NSUserActivity) -> Bool {
        if GrovsPlugin.isNewSceneEvent(userActivity) {
            _ = GrovsPlugin.deliver(.userActivity(userActivity))
        }
        return false
    }
}
