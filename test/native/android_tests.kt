import kotlinx.coroutines.*
import kotlinx.coroutines.test.*

private class Reply : MethodChannel.Result {
    val values = mutableListOf<Any?>()
    override fun success(value: Any?) { values.add(value) }
    override fun error(code: String, message: String?, details: Any?) { values.add(code) }
    override fun notImplemented() { error("Unexpected unimplemented method") }
}
private class Engine(val plugin: GrovsPlugin = GrovsPlugin()) {
    val binding = FlutterPlugin.FlutterPluginBinding()
    val activity = ActivityPluginBinding()
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
