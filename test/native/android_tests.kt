import kotlinx.coroutines.*
import kotlinx.coroutines.test.*

private class Reply : MethodChannel.Result {
    val values = mutableListOf<Any?>()
    override fun success(value: Any?) { values.add(value) }
    override fun error(code: String, message: String?, details: Any?) { values.add(code) }
    override fun notImplemented() { error("Unexpected unimplemented method") }
}
private class Engine(val plugin: GrovsPlugin = GrovsPlugin(), host: Activity = Activity()) {
    val binding = FlutterPlugin.FlutterPluginBinding()
    val activity = ActivityPluginBinding(host)
    val received = mutableListOf<Any?>()
    val inAppReceived = mutableListOf<Map<*, *>>()
    init { plugin.onAttachedToEngine(binding); plugin.onAttachedToActivity(activity) }
    val stream get() = binding.binaryMessenger.events.getValue("grovs/deeplinks").handler!!
    fun listen() = stream.onListen(null, EventChannel.EventSink { received.add(it) })
    val inAppStream get() = binding.binaryMessenger.events.getValue("grovs/inapp").handler!!
    fun listenInApp() = inAppStream.onListen(null, EventChannel.EventSink { inAppReceived.add(it as Map<*, *>) })
    fun call(method: String, arguments: Map<String, Any?> = emptyMap()): List<Any?> {
        val reply = Reply()
        plugin.onMethodCall(MethodCall(method, arguments), reply)
        return reply.values
    }
    fun enabled(value: Boolean) {
        val reply = Reply()
        plugin.onMethodCall(MethodCall("setSDK", mapOf("enabled" to value)), reply)
        check(reply.values == listOf(null))
    }
    fun close() = plugin.onDetachedFromEngine(binding)
}

@OptIn(ExperimentalCoroutinesApi::class)
fun main() = runBlocking {
    val dispatcher = StandardTestDispatcher()
    Dispatchers.setMain(dispatcher)
    fun drain() = dispatcher.scheduler.runCurrent()
    fun emit(id: String) = Grovs.listener!!(LinkDetails(id))

    val first = Engine()
    repeat(25) { emit("$it") }
    drain()
    first.listen()
    check(first.received.map { (it as Map<*, *>)["link"] } == (5..24).map { "$it" })
    first.stream.onCancel(null)
    emit("after-cancel"); drain()
    first.listen()
    check(first.received.size == 21)
    first.stream.onCancel(null)
    first.listen()
    check(first.received.size == 21)
    println("PASS Android: bounded FIFO buffer and cancel/resubscribe without duplicates")

    first.stream.onCancel(null)
    emit("old-first-engine"); drain()
    val second = Engine()
    emit("old-second-engine"); drain()
    second.enabled(false)
    first.listen(); second.listen()
    check(first.received.size == 21 && second.received.isEmpty())
    second.enabled(true)
    second.stream.onCancel(null); second.listen()
    check(second.received.isEmpty())
    println("PASS Android: consent withdrawal clears buffers across engines")

    emit("queued-before-withdrawal")
    second.enabled(false); drain()
    check(second.received.isEmpty())
    second.enabled(true)
    emit("queued-before-regrant")
    second.enabled(false); second.enabled(true); drain()
    check(second.received.isEmpty())
    second.enabled(false)
    emit("while-disabled")
    second.enabled(true); drain()
    check(second.received.isEmpty())
    emit("fresh"); drain()
    check(second.received.size == 1)
    println("PASS Android: queued callbacks cannot cross consent changes")

    val oldCallback = Grovs.listener!!
    val captures = oldCallback.javaClass.declaredFields.map { it.isAccessible = true; it.get(oldCallback) }
    check(captures.none { it is GrovsPlugin || it is Activity || it is ActivityPluginBinding })
    emit("queued-before-detach")
    second.close(); drain()
    check(second.received.size == 1 && second.activity.listeners.isEmpty())
    check(second.binding.binaryMessenger.events.values.all { it.handler == null })
    check(second.binding.binaryMessenger.methods.values.all { it.handler == null })
    for (name in listOf("channel", "eventChannel", "errorChannel", "inAppChannel", "eventSink", "errorSink", "inAppSink", "activityBinding", "newIntentListener")) {
        check(GrovsPlugin::class.java.getDeclaredField(name).also { it.isAccessible = true }.get(second.plugin) == null)
    }
    val reused = Engine(second.plugin)
    reused.listen()
    oldCallback(LinkDetails("obsolete")); drain()
    check(reused.received.isEmpty())
    emit("current"); drain()
    check(reused.received.size == 1)
    println("PASS Android: weak native listener, detach cleanup, and reuse reject old callbacks")

    repeat(3) {
        reused.plugin.onDetachedFromActivityForConfigChanges()
        check(reused.activity.listeners.isEmpty())
        reused.plugin.onReattachedToActivityForConfigChanges(reused.activity)
        check(reused.activity.listeners.size == 1)
    }
    println("PASS Android: activity rotation removes and restores one intent listener")

    // A FlutterFragmentActivity attaches its engine, and so the plugin, during onStart, after the
    // application's activity-started callbacks have already fired. The plugin must take the start
    // from the host's own lifecycle, which replays it to a late observer.
    Grovs.started.clear()
    val lateHost = FlutterFragmentActivity()
    lateHost.lifecycle.start()
    val late = Engine(GrovsPlugin(), lateHost)
    check(Grovs.started == listOf<Activity>(lateHost)) { "late attach: ${Grovs.started}" }
    lateHost.lifecycle.stop(); lateHost.lifecycle.start()
    check(Grovs.started == listOf<Activity>(lateHost, lateHost)) { "restart: ${Grovs.started}" }
    late.plugin.onDetachedFromActivity()
    lateHost.lifecycle.stop(); lateHost.lifecycle.start()
    check(Grovs.started.size == 2 && lateHost.lifecycle.observers.isEmpty()) { "after detach: ${Grovs.started}" }
    late.close()

    Grovs.started.clear()
    val earlyHost = FlutterActivity()
    val early = Engine(GrovsPlugin(), earlyHost)
    check(Grovs.started.isEmpty()) { "before start: ${Grovs.started}" }
    earlyHost.lifecycle.start()
    check(Grovs.started == listOf<Activity>(earlyHost)) { "early attach: ${Grovs.started}" }
    early.close()
    println("PASS Android: the host lifecycle starts the SDK whether the plugin attaches before or after onStart")

    fun handleUrl(engine: Engine, url: Any?): List<Any?> {
        val reply = Reply()
        engine.plugin.onMethodCall(MethodCall("handleUrl", mapOf("url" to url)), reply)
        return reply.values
    }
    val link = "https://example.sqd.link/abc"
    Grovs.intents.clear()
    val linkEngine = Engine()
    for (invalid in listOf("", "not a url", "relative/path", "https://", "mailto:a@b.c", null, 42)) {
        check(handleUrl(linkEngine, invalid) == listOf("INVALID_ARGUMENT")) { "accepted $invalid" }
    }
    check(Grovs.intents.isEmpty())
    check(handleUrl(linkEngine, link) == listOf(true))
    check(handleUrl(linkEngine, "grovstest://example.sqd.link/abc") == listOf(true))
    val (intent, activity) = Grovs.intents.first()
    check(intent.action == Intent.ACTION_VIEW && intent.data?.value == link && activity === linkEngine.activity.activity)
    linkEngine.enabled(false)
    check(handleUrl(linkEngine, link) == listOf(false))
    linkEngine.enabled(true)
    linkEngine.plugin.onDetachedFromActivity()
    check(handleUrl(linkEngine, link) == listOf(false))
    check(Grovs.intents.size == 2)
    linkEngine.close()
    println("PASS Android: handleUrl validates input and hands a view intent to the SDK only when enabled and attached")

    Grovs.generated = CompletableDeferred()
    Grovs.generationStarted = CompletableDeferred()
    val cancelled = Reply()
    reused.plugin.onMethodCall(MethodCall("generateLink", mapOf("title" to "test")), cancelled)
    drain()
    withTimeout(5000) { Grovs.generationStarted.await() }
    reused.close()
    Grovs.generated.complete("too-late"); drain()
    check(cancelled.values.isEmpty())
    val finalEngine = Engine(reused.plugin)
    val success = Reply()
    Grovs.generated = CompletableDeferred("fresh-generated-link")
    finalEngine.plugin.onMethodCall(MethodCall("generateLink", mapOf("title" to "test")), success)
    withTimeout(5000) { while (success.values.isEmpty()) { drain(); delay(1) } }
    check(success.values == listOf("fresh-generated-link"))
    finalEngine.close(); first.close()
    Dispatchers.resetMain()
    println("PASS Android: generation cancels on detach and works after reuse")

    val inApp = Grovs.inAppListener!!
    val shownEngine = Engine()
    repeat(25) { inApp.onInAppMessageShown("$it") }
    shownEngine.listenInApp()
    check(shownEngine.inAppReceived.map { it["campaignId"] } == (5..24).map { "$it" })
    check(shownEngine.inAppReceived.all { it == mapOf("type" to "shown", "campaignId" to it["campaignId"]) })
    check(Grovs.inAppListener === inApp && Grovs.inAppListenerSets == 1)
    println("PASS Android: in-app events are buffered with a bounded FIFO and replayed on listen")

    val otherEngine = Engine()
    otherEngine.listenInApp()
    shownEngine.inAppReceived.clear()
    val payload = mapOf("big" to 9_000_000_000L, "nested" to mapOf("k" to listOf(1, "two")))
    inApp.onInAppMessageClicked("c", "b", payload)
    inApp.onInAppMessageClicked("c", null, null)
    inApp.onInAppMessageDismissed("c", "swipe")
    inApp.onInAppMessageAnswered("c", 4, "great")
    inApp.onInAppMessageAnswered("c", "opt", null)
    inApp.onInAppMessageFailed("c", "no view")
    val expected = listOf(
        mapOf("type" to "clicked", "campaignId" to "c", "buttonId" to "b", "payload" to payload),
        mapOf("type" to "clicked", "campaignId" to "c"),
        mapOf("type" to "dismissed", "campaignId" to "c", "reason" to "swipe"),
        mapOf("type" to "answered", "campaignId" to "c", "value" to 4, "comment" to "great"),
        mapOf("type" to "answered", "campaignId" to "c", "value" to "opt"),
        mapOf("type" to "failed", "campaignId" to "c", "message" to "no view"),
    )
    check(shownEngine.inAppReceived == expected) { "first engine: ${shownEngine.inAppReceived}" }
    check(otherEngine.inAppReceived == expected) { "second engine: ${otherEngine.inAppReceived}" }
    check(shownEngine.inAppReceived[0]["payload"] === payload)
    println("PASS Android: every attached engine gets each in-app event with its payload unchanged and absent keys omitted")

    shownEngine.inAppStream.onCancel(null); otherEngine.inAppStream.onCancel(null)
    shownEngine.inAppReceived.clear(); otherEngine.inAppReceived.clear()
    inApp.onInAppMessageShown("before-withdrawal")
    otherEngine.enabled(false)
    inApp.onInAppMessageShown("while-disabled")
    otherEngine.enabled(true)
    shownEngine.listenInApp(); otherEngine.listenInApp()
    check(shownEngine.inAppReceived.isEmpty() && otherEngine.inAppReceived.isEmpty())
    println("PASS Android: consent withdrawal clears in-app buffers across engines")

    shownEngine.close(); otherEngine.close()
    inApp.onInAppMessageShown("no-engine")
    val nextEngine = Engine()
    nextEngine.listenInApp()
    check(nextEngine.inAppReceived.isEmpty())
    println("PASS Android: an in-app event with no attached engine is dropped")

    Grovs.inAppCalls.clear()
    check(nextEngine.call("pauseInAppMessages") == listOf(null))
    check(nextEngine.call("resumeInAppMessages") == listOf(null))
    check(nextEngine.call("discardInAppMessages", mapOf("dismissCurrent" to true)) == listOf(null))
    check(nextEngine.call("discardInAppMessages", mapOf("dismissCurrent" to false)) == listOf(null))
    check(nextEngine.call("setInAppExcludedScreens", mapOf("screens" to listOf("Checkout", "Login"))) == listOf(null))
    check(nextEngine.call("setInAppDebugLogging", mapOf("enabled" to true)) == listOf(null))
    check(Grovs.inAppCalls == listOf("pause", "resume", "discard true", "discard false", "screens [Checkout, Login]", "debug true")) { "${Grovs.inAppCalls}" }
    check(nextEngine.call("setInAppExcludedScreens") == listOf("INVALID_ARGUMENT"))
    check(nextEngine.call("discardInAppMessages") == listOf("INVALID_ARGUMENT"))
    check(nextEngine.call("setInAppDebugLogging") == listOf("INVALID_ARGUMENT"))
    check(Grovs.inAppCalls.size == 6)
    nextEngine.close()
    println("PASS Android: in-app control methods pass their arguments to the SDK and reject missing ones")
}
