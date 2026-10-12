import Flutter
import UIKit

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
            return GrovsPlugin.deliver(.userActivity(activity))
        }
        if let url = connectionOptions.urlContexts.first?.url {
            return GrovsPlugin.deliver(.url(url))
        }
        return false
    }

    public func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) -> Bool {
        guard let context = URLContexts.first else { return false }
        guard GrovsPlugin.isNewSceneEvent(context) else { return true }
        return GrovsPlugin.deliver(.url(context.url))
    }

    public func scene(_ scene: UIScene, continue userActivity: NSUserActivity) -> Bool {
        guard GrovsPlugin.isNewSceneEvent(userActivity) else { return true }
        return GrovsPlugin.deliver(.userActivity(userActivity))
    }
}
