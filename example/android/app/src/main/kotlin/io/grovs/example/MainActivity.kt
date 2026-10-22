package io.grovs.example

import android.content.pm.PackageManager
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "grovs_example/config")
            .setMethodCallHandler { call, result ->
                if (call.method == "read") result.success(readGrovsConfig()) else result.notImplemented()
            }
    }

    /** Reads the manifest values the same way the Grovs plugin does. */
    private fun readGrovsConfig(): Map<String, Any?> {
        val meta = packageManager
            .getApplicationInfo(packageName, PackageManager.GET_META_DATA)
            .metaData ?: Bundle()
        return mapOf(
            "apiKey" to (meta.getString("grovs_api_key") ?: ""),
            "useTestEnvironment" to meta.getBoolean("grovs_use_test_environment", false),
            "baseUrl" to meta.getString("grovs_base_url"),
            "clipboardDomains" to (meta.getString("grovs_clipboard_domains")
                ?.split(',')
                ?.map { it.trim() }
                ?.filter { it.isNotEmpty() }
                ?: emptyList()),
            "startEnabled" to meta.getBoolean("grovs_enabled", true),
        )
    }
}
