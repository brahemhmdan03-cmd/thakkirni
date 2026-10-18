package com.thakkirni.thakkirni

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var channel: MethodChannel? = null
    private var listenRequested = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (savedInstanceState == null && isListenIntent(intent)) listenRequested = true
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "thakkirni/launch").apply {
            setMethodCallHandler { call, result ->
                if (call.method == "consumeListenRequest") {
                    result.success(listenRequested)
                    listenRequested = false
                } else {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (isListenIntent(intent)) {
            listenRequested = true
            channel?.invokeMethod("listen", null)
        }
    }

    private fun isListenIntent(intent: Intent?): Boolean =
        intent?.action == "com.thakkirni.LISTEN" ||
            (intent?.action == Intent.ACTION_VIEW && intent.data?.host == "listen")
}
