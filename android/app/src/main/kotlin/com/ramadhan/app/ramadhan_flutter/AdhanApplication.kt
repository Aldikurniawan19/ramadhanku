package com.ramadhan.app.ramadhan_flutter

import android.content.Intent
import android.util.Log
import io.flutter.app.FlutterApplication
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * AdhanApplication — Custom Application class that provides the adhan
 * MethodChannel handler for both foreground (MainActivity) and background
 * (android_alarm_manager_plus) FlutterEngines.
 *
 * Purpose:
 *   When android_alarm_manager_plus fires an alarm, it creates a NEW background
 *   FlutterEngine in a separate isolate. The default MainActivity's MethodChannel
 *   handler is NOT available in that isolate.
 *
 *   This class provides a `registerAdhanChannel()` method that can be called by:
 *   1. MainActivity.configureFlutterEngine() — for foreground usage
 *   2. android_alarm_manager_plus's AlarmService — via FlutterApplication lifecycle
 *
 *   When the background Dart isolate calls playAdhan, this handler receives it
 *   and starts the AdhanPlayerService as a foreground service.
 */
class AdhanApplication : FlutterApplication() {

    companion object {
        private const val TAG = "AdhanApplication"
        const val CHANNEL = "com.ramadhan.app/adhan"
    }

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "AdhanApplication created")
    }

    /**
     * Register the adhan MethodChannel on a FlutterEngine.
     * Called from both MainActivity (foreground) and can be called from
     * background engine creation callbacks.
     */
    fun registerAdhanChannel(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                Log.d(TAG, "MethodChannel call: ${call.method}")
                when (call.method) {
                    "playAdhan" -> {
                        // Start the foreground service to play adzan
                        AdhanPlayerService.start(this@AdhanApplication)
                        result.success(true)
                    }
                    "stopAdhan" -> {
                        AdhanPlayerService.stop(this@AdhanApplication)
                        result.success(true)
                    }
                    "playAdhanViaBroadcast" -> {
                        // Alternative: send broadcast to AdhanBroadcastReceiver
                        val intent = Intent(AdhanBroadcastReceiver.ACTION_PLAY_ADHAN)
                        intent.setPackage(packageName)
                        sendBroadcast(intent)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
        Log.d(TAG, "Adhan MethodChannel registered on engine")
    }
}
