import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    FlutterMethodChannel(
      name: "grovs_example/config",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    ).setMethodCallHandler { call, result in
      call.method == "read" ? result(Self.grovsConfig()) : result(FlutterMethodNotImplemented)
    }
  }

  /// Reads the Info.plist values the same way the Grovs plugin does.
  private static func grovsConfig() -> [String: Any] {
    let info = Bundle.main.infoDictionary ?? [:]
    var config: [String: Any] = [
      "apiKey": info["GrovsApiKey"] as? String ?? "",
      "useTestEnvironment": info["GrovsUseTestEnvironment"] as? Bool ?? false,
      "clipboardDomains": info["GrovsClipboardDomains"] as? [String] ?? [],
      "startEnabled": info["GrovsEnabled"] as? Bool ?? true,
    ]
    config["baseUrl"] = info["GrovsBaseURL"] as? String
    return config
  }
}
