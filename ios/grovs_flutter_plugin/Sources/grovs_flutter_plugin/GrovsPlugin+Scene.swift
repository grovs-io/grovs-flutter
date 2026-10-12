import Flutter
import UIKit

extension GrovsPlugin: FlutterSceneLifeCycleDelegate {
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
        guard let url = URLContexts.first?.url else { return false }
        return GrovsPlugin.deliver(.url(url))
    }

    public func scene(_ scene: UIScene, continue userActivity: NSUserActivity) -> Bool {
        GrovsPlugin.deliver(.userActivity(userActivity))
    }
}
