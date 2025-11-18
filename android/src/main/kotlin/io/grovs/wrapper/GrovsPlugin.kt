package io.grovs.wrapper

import android.app.Activity
import android.app.Application
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.grovs.Grovs
import io.grovs.model.CustomLinkRedirect
import io.grovs.model.DebugLogger
import io.grovs.model.LogLevel
import io.grovs.model.exceptions.GrovsException
import io.grovs.service.CustomRedirects
import io.grovs.service.TrackingParams
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.Serializable
import java.lang.ref.WeakReference

/** GrovsPlugin */
class GrovsPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null
    private lateinit var context: Context
    private var activityBinding: ActivityPluginBinding? = null
    private val coroutineScope = CoroutineScope(Dispatchers.Main)

    private val applicationLifecycleObserver: Application.ActivityLifecycleCallbacks = object : Application.ActivityLifecycleCallbacks {
        override fun onActivityCreated(p0: Activity, p1: Bundle?) { }
        override fun onActivityStarted(activity: Activity) {
            if (activity is FlutterActivity) {
                Grovs.onStart(activity)
            }
        }
        override fun onActivityResumed(activity: Activity) { }
        override fun onActivityPaused(activity: Activity) { }
        override fun onActivityStopped(activity: Activity) { }
        override fun onActivitySaveInstanceState(activity: Activity, p1: Bundle) {}
        override fun onActivityDestroyed(activity: Activity) { }
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "grovs")
        channel.setMethodCallHandler(this)
        
        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "grovs/deeplinks")
        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
                setupDeeplinkListener()
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })

        val application = context as? Application ?: (context.applicationContext as Application)
        application.registerActivityLifecycleCallbacks(applicationLifecycleObserver)

        val app = flutterPluginBinding.applicationContext as Application
        val meta = app.packageManager.getApplicationInfo(app.packageName, PackageManager.GET_META_DATA).metaData
        val apiKey = meta.getString("grovs_api_key")
        val useTestEnvironment = meta.getBoolean("grovs_use_test_environment", false)
        Grovs.configure(application, apiKey ?: "", useTestEnvironment)
    }

    private fun setupDeeplinkListener() {
        activityBinding?.activity?.let { activity ->
            Grovs.setOnDeeplinkReceivedListener(activity) { linkDetails ->
                coroutineScope.launch {
                    eventSink?.success(mapOf("link" to linkDetails.link, "data" to linkDetails.data, "tracking" to linkDetails.tracking))
                }
            }
        }
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
                                tracking = tracking
                            )
                        }
                        result.success(link)
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
            
            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
        // Set up deeplink listener when activity is available
        if (eventSink != null) {
            setupDeeplinkListener()
        }

        // Add listener for new intents
        binding.addOnNewIntentListener { intent ->
            Grovs.onNewIntent(intent, binding.activity)
            false
        }
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activityBinding = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activityBinding = binding
        // Re-setup deeplink listener when activity is reattached
        if (eventSink != null) {
            setupDeeplinkListener()
        }
        // Add listener for new intents
        binding.addOnNewIntentListener { intent ->
            Grovs.onNewIntent(intent, binding.activity)
            false
        }
    }

    override fun onDetachedFromActivity() {
        activityBinding = null
    }
}
