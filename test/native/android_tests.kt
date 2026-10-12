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
    init { plugin.onAttachedToEngine(binding); plugin.onAttachedToActivity(activity) }
    val stream get() = binding.binaryMessenger.events.getValue("grovs/deeplinks").handler!!
    fun listen() = stream.onListen(null, EventChannel.EventSink { received.add(it) })
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
    for (name in listOf("channel", "eventChannel", "errorChannel", "eventSink", "errorSink", "activityBinding", "newIntentListener")) {
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
}
