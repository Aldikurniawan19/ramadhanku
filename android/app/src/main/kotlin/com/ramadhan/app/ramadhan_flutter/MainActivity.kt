package com.ramadhan.app.ramadhan_flutter

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.ramadhan.app/adhan"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Register the adhan MethodChannel via the Application class
        // so it's available in both foreground and background engines.
        val app = application
        if (app is AdhanApplication) {
            app.registerAdhanChannel(flutterEngine)
        } else {
            // Fallback: register directly on this activity's engine
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
                when (call.method) {
                    "playAdhan" -> {
                        AdhanPlayerService.start(this)
                        result.success(true)
                    }
                    "stopAdhan" -> {
                        AdhanPlayerService.stop(this)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }
}
