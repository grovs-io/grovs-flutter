package io.grovs.wrapper

import android.app.Activity
import android.app.Application
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import io.grovs.Grovs
import io.grovs.model.CustomLinkRedirect
import io.grovs.model.LogLevel
import io.grovs.model.exceptions.GrovsException
import io.grovs.service.CustomRedirects
import io.grovs.service.TrackingParams
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import io.grovs.model.events.PaymentEventType
import java.io.Serializable
import java.lang.ref.WeakReference
import java.util.Collections
import java.util.WeakHashMap

/** GrovsPlugin */
class GrovsPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    private var channel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    private var errorChannel: EventChannel? = null
    private var eventSink: EventChannel.EventSink? = null
    private var errorSink: EventChannel.EventSink? = null
    private var activityBinding: ActivityPluginBinding? = null
    private lateinit var coroutineScope: CoroutineScope
    private var newIntentListener: PluginRegistry.NewIntentListener? = null
    private val pendingDeeplinks = mutableListOf<Map<String, Any?>>()
    private val maxPendingDeeplinks = 20

    companion object {
        // Native configure and lifecycle registration must run once per process,
        // even when several Flutter engines attach.
        private var configured = false

        // Last consent value handed to the native SDK, shared by all engines.
        private var sdkEnabled = true
        private var consentGeneration = 0L
        private val attachedPlugins = Collections.newSetFromMap(WeakHashMap<GrovsPlugin, Boolean>())
        private var pendingIntent: Intent? = null

        private fun handleActivityStart(activity: Activity) {
            if (sdkEnabled) {
                pendingIntent?.let { activity.intent = it }
                pendingIntent = null
            }
            Grovs.onStart(activity)
        }
    }

    private val applicationLifecycleObserver: Application.ActivityLifecycleCallbacks = object : Application.ActivityLifecycleCallbacks {
        override fun onActivityCreated(p0: Activity, p1: Bundle?) { }
        override fun onActivityStarted(activity: Activity) {
            if (activity is FlutterActivity) {
                handleActivityStart(activity)
            }
        }
        override fun onActivityResumed(activity: Activity) { }
        override fun onActivityPaused(activity: Activity) { }
        override fun onActivityStopped(activity: Activity) { }
        override fun onActivitySaveInstanceState(activity: Activity, p1: Bundle) {}
        override fun onActivityDestroyed(activity: Activity) { }
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        coroutineScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
        attachedPlugins.add(this)
        
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "grovs")
        channel?.setMethodCallHandler(this)
        
        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "grovs/deeplinks")
        eventChannel?.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
                if (events == null) return
                val pending = pendingDeeplinks.toList()
                pendingDeeplinks.clear()
                val generation = consentGeneration
                pending.forEach { deliverDeeplink(it, generation) }
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })

        errorChannel = EventChannel(flutterPluginBinding.binaryMessenger, "grovs/errors")
        errorChannel?.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                errorSink = events
            }

            override fun onCancel(arguments: Any?) {
                errorSink = null
            }
        })

        configureOnce(flutterPluginBinding.applicationContext as Application)
    }

    private fun configureOnce(application: Application) {
        if (configured) return
        val meta = application.packageManager
            .getApplicationInfo(application.packageName, PackageManager.GET_META_DATA)
            .metaData ?: Bundle()
        val apiKey = meta.getString("grovs_api_key") ?: ""
        val useTestEnvironment = meta.getBoolean("grovs_use_test_environment", false)
        val baseURL = meta.getString("grovs_base_url")
        val clipboardDomains = meta.getString("grovs_clipboard_domains")
            ?.split(',')
            ?.map { it.trim() }
            ?.filter { it.isNotEmpty() }
        sdkEnabled = meta.getBoolean("grovs_enabled", true)

        Grovs.configure(
            application,
            apiKey,
            useTestEnvironment,
            baseURL,
            false,
            clipboardDomains,
            sdkEnabled
        )
        application.registerActivityLifecycleCallbacks(applicationLifecycleObserver)
        configured = true
    }

    private fun setSDKEnabled(enabled: Boolean) {
        if (enabled == sdkEnabled) return
        Grovs.setSDK(enabled)
        sdkEnabled = enabled
        if (!enabled) {
            consentGeneration++
            attachedPlugins.forEach { it.pendingDeeplinks.clear() }
        }
        if (enabled) {
            // Re-run intent handling so a launch link and first-open attribution
            // that were skipped while disabled are processed now.
            activityBinding?.activity?.let { handleActivityStart(it) }
        }
    }

    private fun registerNativeDeeplinkListener(activity: Activity) {
        val plugin = WeakReference(this)
        val scope = coroutineScope
        Grovs.setOnDeeplinkReceivedListener(activity) { linkDetails ->
            if (!sdkEnabled) return@setOnDeeplinkReceivedListener
            val generation = consentGeneration
            scope.launch {
                plugin.get()?.deliverDeeplink(
                    mapOf(
                        "link" to linkDetails.link,
                        "data" to linkDetails.data,
                        "tracking" to linkDetails.tracking
                    ),
                    generation
                )
            }
        }
    }

    private fun deliverDeeplink(event: Map<String, Any?>, generation: Long) {
        if (!sdkEnabled || generation != consentGeneration) return
        val sink = eventSink
        if (sink != null) {
            sink.success(event)
            return
        }
        pendingDeeplinks.add(event)
        if (pendingDeeplinks.size > maxPendingDeeplinks) {
            pendingDeeplinks.removeAt(0)
        }
    }

    private fun attachActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
        registerNativeDeeplinkListener(binding.activity)

        val listener = PluginRegistry.NewIntentListener { intent ->
            if (!sdkEnabled) pendingIntent = intent
            Grovs.onNewIntent(intent, binding.activity)
            false
        }
        newIntentListener = listener
        binding.addOnNewIntentListener(listener)
    }

    private fun detachActivity() {
        newIntentListener?.let { activityBinding?.removeOnNewIntentListener(it) }
        newIntentListener = null
        activityBinding = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getPlatformVersion" -> {
                result.success("Android ${android.os.Build.VERSION.RELEASE}")
            }
            
            "generateLink" -> {
                val title = call.argument<String>("title")
                val subtitle = call.argument<String>("subtitle")
                val imageURL = call.argument<String>("imageURL")
                val data = call.argument<Map<String, Any>>("data")
                val tags = call.argument<List<String>>("tags")
                val customRedirectsMap = call.argument<Map<String, Any>>("customRedirects")
                val showPreviewIos = call.argument<Boolean>("showPreviewIos")
                val showPreviewAndroid = call.argument<Boolean>("showPreviewAndroid")
                val copyToClipboardIos = call.argument<Boolean>("copyToClipboardIos")
                val copyToClipboardAndroid = call.argument<Boolean>("copyToClipboardAndroid")
                val trackingMap = call.argument<Map<String, Any>>("tracking")
                
                if (title == null) {
                    result.error("INVALID_ARGUMENT", "title is required", null)
                    return
                }
                
                // Parse customRedirects
                val customRedirects = customRedirectsMap?.let { redirectsMap ->
                    val ios = (redirectsMap["ios"] as? Map<*, *>)?.let { iosMap ->
                        CustomLinkRedirect(
                            link = iosMap["url"] as? String ?: "",
                            openAppIfInstalled = iosMap["openAppIfInstalled"] as? Boolean ?: true
                        )
                    }
                    val android = (redirectsMap["android"] as? Map<*, *>)?.let { androidMap ->
                        CustomLinkRedirect(
                            link = androidMap["url"] as? String ?: "",
                            openAppIfInstalled = androidMap["openAppIfInstalled"] as? Boolean ?: true
                        )
                    }
                    val desktop = (redirectsMap["desktop"] as? Map<*, *>)?.let { desktopMap ->
                        CustomLinkRedirect(
                            link = desktopMap["url"] as? String ?: "",
                            openAppIfInstalled = desktopMap["openAppIfInstalled"] as? Boolean ?: true
                        )
                    }
                    CustomRedirects(ios = ios, android = android, desktop = desktop)
                }
                
                // Parse tracking params
                val tracking = trackingMap?.let { trackingParams ->
                    TrackingParams(
                        utmCampaign = trackingParams["utm_campaign"] as? String,
                        utmSource = trackingParams["utm_source"] as? String,
                        utmMedium = trackingParams["utm_medium"] as? String
                    )
                }
                
                // Convert data map to Serializable map
                val serializableData = data?.mapValues { entry ->
                    when (val value = entry.value) {
                        is Serializable -> value
                        is Number -> value
                        is String -> value
                        is Boolean -> value
                        else -> value.toString()
                    }
                }
                
                coroutineScope.launch {
                    try {
                        val link = withContext(Dispatchers.IO) {
                            Grovs.generateLink(
                                title = title,
                                subtitle = subtitle,
                                imageURL = imageURL,
                                data = serializableData,
                                tags = tags,
                                customRedirects = customRedirects,
                                showPreviewIos = showPreviewIos,
                                showPreviewAndroid = showPreviewAndroid,
                                copyToClipboardIos = copyToClipboardIos,
                                copyToClipboardAndroid = copyToClipboardAndroid,
                                tracking = tracking
                            )
                        }
                        result.success(link)
                    } catch (e: CancellationException) {
                        throw e
                    } catch (e: GrovsException) {
                        result.error("GENERATION_ERROR", e.message, null)
                    } catch (e: Exception) {
                        result.error("GENERATION_ERROR", e.message, null)
                    }
                }
            }
            
            "setPushToken" -> {
                val token = call.argument<String>("token")
                
                if (token == null) {
                    result.error("INVALID_ARGUMENT", "token is required", null)
                    return
                }
                
                try {
                    Grovs.pushToken = token
                    result.success(null)
                } catch (e: Exception) {
                    result.error("TOKEN_ERROR", e.message, null)
                }
            }
            
            "setUserIdentifier" -> {
                val identifier = call.argument<String>("identifier")
                
                if (identifier == null) {
                    result.error("INVALID_ARGUMENT", "identifier is required", null)
                    return
                }
                
                try {
                    Grovs.identifier = identifier
                    result.success(null)
                } catch (e: Exception) {
                    result.error("USER_ERROR", e.message, null)
                }
            }
            
            "setUserAttributes" -> {
                val attributes = call.argument<Map<String, Any>>("attributes")
                
                if (attributes == null) {
                    result.error("INVALID_ARGUMENT", "attributes are required", null)
                    return
                }
                
                try {
                    Grovs.attributes = attributes
                    result.success(null)
                } catch (e: Exception) {
                    result.error("USER_ERROR", e.message, null)
                }
            }
            
            "setDebugLevel" -> {
                val level = call.argument<String>("level")
                
                if (level == null) {
                    result.error("INVALID_ARGUMENT", "level is required", null)
                    return
                }
                
                try {
                    // Convert string to Grovs debug level
                    // Note: You may need to adjust this based on the actual Grovs SDK API
                    when (level.lowercase()) {
                        "info" -> Grovs.setDebug(LogLevel.INFO)
                        "error" -> Grovs.setDebug(LogLevel.ERROR)
                        else -> Grovs.setDebug(LogLevel.ERROR)
                    }
                    result.success(null)
                } catch (e: Exception) {
                    result.error("DEBUG_ERROR", e.message, null)
                }
            }
            
            "logInAppPurchase" -> {
                val transactionId = call.argument<String>("transactionId")

                if (transactionId == null) {
                    result.error("INVALID_ARGUMENT", "transactionId is required", null)
                    return
                }

                try {
                    Grovs.logInAppPurchase(transactionId)
                    result.success(null)
                } catch (e: Exception) {
                    result.error("PAYMENT_ERROR", e.message, null)
                }
            }

            "logCustomPurchase" -> {
                val typeString = call.argument<String>("type")
                val priceInCents = call.argument<Int>("priceInCents")
                val currency = call.argument<String>("currency")
                val productId = call.argument<String>("productId")
                val startDateString = call.argument<String>("startDate")

                if (typeString == null || priceInCents == null || currency == null || productId == null) {
                    result.error("INVALID_ARGUMENT", "type, priceInCents, currency, and productId are required", null)
                    return
                }

                val type = when (typeString) {
                    "buy" -> PaymentEventType.BUY
                    "cancel" -> PaymentEventType.CANCEL
                    "refund" -> PaymentEventType.REFUND
                    else -> {
                        result.error("INVALID_ARGUMENT", "Invalid transaction type: $typeString", null)
                        return
                    }
                }

                try {
                    Grovs.logCustomPurchase(type, priceInCents, currency, productId)
                    result.success(null)
                } catch (e: Exception) {
                    result.error("PAYMENT_ERROR", e.message, null)
                }
            }

            "track" -> {
                val name = call.argument<String>("name")
                val properties = call.argument<Map<String, Any>>("properties")
                val tags = call.argument<List<String>>("tags")

                if (name == null) {
                    result.error("INVALID_ARGUMENT", "name is required", null)
                    return
                }

                try {
                    Grovs.track(name, properties, tags)
                    result.success(null)
                } catch (e: Exception) {
                    result.error("EVENT_ERROR", e.message, null)
                }
            }

            "setGlobalTags" -> {
                val tags = call.argument<List<String>>("tags")
                try {
                    Grovs.setGlobalTags(tags)
                    result.success(null)
                } catch (e: Exception) {
                    result.error("EVENT_ERROR", e.message, null)
                }
            }

            "trackScreenView" -> {
                val screenName = call.argument<String>("screenName")
                val properties = call.argument<Map<String, Any>>("properties")

                if (screenName == null) {
                    result.error("INVALID_ARGUMENT", "screenName is required", null)
                    return
                }

                try {
                    Grovs.trackScreenView(screenName, properties)
                    result.success(null)
                } catch (e: Exception) {
                    result.error("EVENT_ERROR", e.message, null)
                }
            }

            "setScreenAliases" -> {
                val aliases = call.argument<Map<String, String>>("aliases")

                if (aliases == null) {
                    result.error("INVALID_ARGUMENT", "aliases is required", null)
                    return
                }

                try {
                    Grovs.setScreenAliases(aliases)
                    result.success(null)
                } catch (e: Exception) {
                    result.error("EVENT_ERROR", e.message, null)
                }
            }

            "setSDK" -> {
                val enabled = call.argument<Boolean>("enabled")

                if (enabled == null) {
                    result.error("INVALID_ARGUMENT", "enabled is required", null)
                    return
                }

                try {
                    setSDKEnabled(enabled)
                    result.success(null)
                } catch (e: Exception) {
                    result.error("CONSENT_ERROR", e.message, null)
                }
            }

            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        eventChannel?.setStreamHandler(null)
        errorChannel?.setStreamHandler(null)
        // Removing stream handlers does not call onCancel.
        eventSink = null
        errorSink = null
        pendingDeeplinks.clear()
        detachActivity()
        coroutineScope.cancel()
        attachedPlugins.remove(this)
        channel = null
        eventChannel = null
        errorChannel = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        attachActivity(binding)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        detachActivity()
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        attachActivity(binding)
    }

    override fun onDetachedFromActivity() {
        detachActivity()
    }
}
