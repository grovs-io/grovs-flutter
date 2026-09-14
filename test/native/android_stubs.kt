import kotlinx.coroutines.CompletableDeferred
import java.io.Serializable

typealias Result = MethodChannel.Result
typealias MethodCallHandler = MethodChannel.MethodCallHandler
class Intent
open class Activity { var intent: Intent? = null }
class FlutterActivity : Activity()
class Bundle {
    fun getString(key: String): String? = null
    fun getBoolean(key: String, fallback: Boolean) = fallback
}
class PackageManager {
    companion object { const val GET_META_DATA = 128 }
    class ApplicationInfo { val metaData: Bundle? = null }
    fun getApplicationInfo(name: String, flags: Int) = ApplicationInfo()
}
class Application {
    val packageManager = PackageManager()
    val packageName = "test"
    val callbacks = mutableListOf<ActivityLifecycleCallbacks>()
    fun registerActivityLifecycleCallbacks(callback: ActivityLifecycleCallbacks) { callbacks.add(callback) }
    interface ActivityLifecycleCallbacks {
        fun onActivityCreated(activity: Activity, state: Bundle?)
        fun onActivityStarted(activity: Activity)
        fun onActivityResumed(activity: Activity)
        fun onActivityPaused(activity: Activity)
        fun onActivityStopped(activity: Activity)
        fun onActivitySaveInstanceState(activity: Activity, state: Bundle)
        fun onActivityDestroyed(activity: Activity)
    }
}
class Messenger {
    val methods = mutableMapOf<String, MethodChannel>()
    val events = mutableMapOf<String, EventChannel>()
}
interface FlutterPlugin {
    class FlutterPluginBinding(val applicationContext: Application = Application(), val binaryMessenger: Messenger = Messenger())
    fun onAttachedToEngine(binding: FlutterPluginBinding)
    fun onDetachedFromEngine(binding: FlutterPluginBinding)
}
interface ActivityAware {
    fun onAttachedToActivity(binding: ActivityPluginBinding)
    fun onDetachedFromActivityForConfigChanges()
    fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding)
    fun onDetachedFromActivity()
}
object PluginRegistry { fun interface NewIntentListener { fun onNewIntent(intent: Intent): Boolean } }
class ActivityPluginBinding(val activity: Activity = Activity()) {
    val listeners = mutableSetOf<PluginRegistry.NewIntentListener>()
    fun addOnNewIntentListener(listener: PluginRegistry.NewIntentListener) { listeners.add(listener) }
    fun removeOnNewIntentListener(listener: PluginRegistry.NewIntentListener) { listeners.remove(listener) }
}
class MethodCall(val method: String, private val arguments: Map<String, Any?> = emptyMap()) {
    @Suppress("UNCHECKED_CAST") fun <T> argument(key: String): T? = arguments[key] as T?
}
class MethodChannel(messenger: Messenger, name: String) {
    init { messenger.methods[name] = this }
    var handler: MethodCallHandler? = null
    fun setMethodCallHandler(value: MethodCallHandler?) { handler = value }
    interface MethodCallHandler { fun onMethodCall(call: MethodCall, result: Result) }
    interface Result {
        fun success(value: Any?)
        fun error(code: String, message: String?, details: Any?)
        fun notImplemented()
    }
}
class EventChannel(messenger: Messenger, name: String) {
    init { messenger.events[name] = this }
    var handler: StreamHandler? = null
    fun setStreamHandler(value: StreamHandler?) { handler = value }
    interface StreamHandler {
        fun onListen(arguments: Any?, events: EventSink?)
        fun onCancel(arguments: Any?)
    }
    fun interface EventSink { fun success(event: Any?) }
}
data class CustomLinkRedirect(val link: String, val openAppIfInstalled: Boolean)
data class CustomRedirects(val ios: CustomLinkRedirect?, val android: CustomLinkRedirect?, val desktop: CustomLinkRedirect?)
data class TrackingParams(val utmCampaign: String?, val utmSource: String?, val utmMedium: String?)
enum class LogLevel { INFO, ERROR }
enum class PaymentEventType { BUY, CANCEL, REFUND }
data class InstantCompat(val epochMillis: Long) {
    companion object { fun ofEpochMilli(millis: Long) = InstantCompat(millis) }
}
class GrovsException(message: String) : Exception(message)
data class LinkDetails(val link: String?, val data: Any? = null, val tracking: Any? = null)
object Grovs {
    var listener: ((LinkDetails) -> Unit)? = null
    var generated = CompletableDeferred("generated-link")
    var generationStarted = CompletableDeferred<Unit>()
    var pushToken: String? = null
    var identifier: String? = null
    var attributes: Map<String, Any>? = null
    fun configure(application: Application, key: String, test: Boolean, url: String?, auto: Boolean, domains: List<String>?, enabled: Boolean) {}
    fun setSDK(enabled: Boolean) {}
    fun onStart(activity: Activity) {}
    fun onNewIntent(intent: Intent, activity: Activity) {}
    fun setOnDeeplinkReceivedListener(activity: Activity, callback: (LinkDetails) -> Unit) { listener = callback }
    suspend fun generateLink(title: String, subtitle: String?, imageURL: String?, data: Map<String, Serializable>?, tags: List<String>?, customRedirects: CustomRedirects?, showPreviewIos: Boolean?, showPreviewAndroid: Boolean?, copyToClipboardIos: Boolean?, copyToClipboardAndroid: Boolean?, tracking: TrackingParams?): String {
        generationStarted.complete(Unit)
        return generated.await()
    }
    fun setDebug(level: LogLevel) {}
    fun logInAppPurchase(id: String) {}
    fun logCustomPurchase(type: PaymentEventType, price: Int, currency: String, product: String, startDate: InstantCompat? = null) {}
    fun track(name: String, properties: Map<String, Any>?, tags: List<String>?) {}
    fun setGlobalTags(tags: List<String>?) {}
    fun trackScreenView(name: String, properties: Map<String, Any>?) {}
    fun setScreenAliases(aliases: Map<String, String>) {}
}
