package com.ramadhan.app.ramadhan_flutter

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

/**
 * AdhanBroadcastReceiver — receives broadcast intents from background isolates
 * (android_alarm_manager_plus callbacks) and starts the AdhanPlayerService
 * as a Foreground Service.
 *
 * Why do we need this?
 *   - Background isolates (Dart) cannot use MethodChannel to reach MainActivity
 *     because the main FlutterEngine may not be running.
 *   - Instead, the background isolate sends an explicit broadcast intent
 *     which this receiver catches and forwards to AdhanPlayerService.
 *   - BroadcastReceivers can start Foreground Services from alarm callbacks
 *     (this is an exemption in Android 12+ restrictions).
 *
 * Usage from Dart background isolate:
 *   MethodChannel('com.ramadhan.app/adhan_bg').invokeMethod('playAdhanViaBroadcast')
 *   — or directly via the AdhanApplication background method channel handler.
 */
class AdhanBroadcastReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "AdhanBroadcastReceiver"
        const val ACTION_PLAY_ADHAN = "com.ramadhan.app.PLAY_ADHAN"
        const val ACTION_STOP_ADHAN = "com.ramadhan.app.STOP_ADHAN"
    }

    override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "onReceive: action=${intent.action}")

        when (intent.action) {
            ACTION_PLAY_ADHAN -> {
                Log.d(TAG, "Starting AdhanPlayerService as foreground service")
                AdhanPlayerService.start(context)
            }
            ACTION_STOP_ADHAN -> {
                Log.d(TAG, "Stopping AdhanPlayerService")
                AdhanPlayerService.stop(context)
            }
            else -> {
                Log.w(TAG, "Unknown action: ${intent.action}")
            }
        }
    }
}
