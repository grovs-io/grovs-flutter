import Foundation

testInfoDictionary = ["GrovsApiKey": "key", "GrovsEnabled": false]
let registrar = FlutterPluginRegistrar()
GrovsPlugin.register(with: registrar)
let plugin = registrar.instance!
let cold = "https://app.sqd.link/cold"

precondition(!plugin.scene(UIScene(), willConnectTo: UISceneSession(), options: UIScene.ConnectionOptions(
    userActivities: [webActivity(cold)])))
precondition(Grovs.log == ["configure enabled=false", "link \(cold)"])
print("PASS iOS launch: a scene connection configures the SDK from Info.plist before delivering the link")

plugin.setSDKEnabled(true)
precondition(Grovs.log == ["configure enabled=false", "link \(cold)", "setSDK true", "link \(cold)"])
print("PASS iOS launch: the launch link received while disabled is replayed once consent is given")

let second = "https://app.sqd.link/second"
_ = plugin.scene(UIScene(), willConnectTo: UISceneSession(), options: UIScene.ConnectionOptions(
    userActivities: [webActivity(second)]))
_ = plugin.application(UIApplication(), didFinishLaunchingWithOptions: [:])
plugin.setSDKEnabled(false); plugin.setSDKEnabled(true)
precondition(Grovs.log.filter { $0.hasPrefix("configure") }.count == 1)
precondition(Grovs.log.suffix(3) == ["link \(second)", "setSDK false", "setSDK true"])
print("PASS iOS launch: later scene connections and launch events keep runtime consent and configure nothing")
