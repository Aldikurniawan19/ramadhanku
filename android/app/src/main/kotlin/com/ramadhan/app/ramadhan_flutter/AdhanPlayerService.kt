package com.ramadhan.app.ramadhan_flutter

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.MediaPlayer
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import android.util.Log
import androidx.core.app.NotificationCompat

/**
 * AdhanPlayerService — **Foreground Service** that plays the adzan sound
 * using Android's native MediaPlayer with USAGE_ALARM audio attributes.
 *
 * Why Foreground Service?
 *   - Android 8+ (Oreo): plain startService() from background is KILLED immediately.
 *   - Android 12+: background service starts are outright prohibited.
 *   - A Foreground Service with startForeground() keeps the process alive
 *     even when the screen is off, app is in background, or swiped from recents.
 *
 * Audio strategy:
 *   - Uses USAGE_ALARM to bypass DND and silent mode
 *   - Sets alarm stream volume to at least 70% of max
 *   - Acquires a partial WakeLock to keep CPU alive during playback
 *   - Auto-stops after playback completes or after MAX_DURATION_MS
 *
 * Sound file: res/raw/adzan.mp3 (copied from assets/audio/adzan.mp3)
 */
class AdhanPlayerService : Service() {

    companion object {
        private const val TAG = "AdhanPlayerService"
        private const val MAX_DURATION_MS = 60_000L // 60 seconds max (adzan can be ~45s)
        private const val FOREGROUND_NOTIF_ID = 9999
        private const val CHANNEL_ID = "adhan_playback_fg"

        fun start(context: Context) {
            try {
                val intent = Intent(context, AdhanPlayerService::class.java)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(intent)
                } else {
                    context.startService(intent)
                }
                Log.d(TAG, "Service start requested (foreground)")
            } catch (e: Exception) {
                Log.e(TAG, "Failed to start foreground service: ${e.message}")
                // Fallback: try regular startService (may work on older Android)
                try {
                    val intent = Intent(context, AdhanPlayerService::class.java)
                    context.startService(intent)
                    Log.d(TAG, "Fallback: regular startService")
                } catch (e2: Exception) {
                    Log.e(TAG, "Fallback startService also failed: ${e2.message}")
                }
            }
        }

        fun stop(context: Context) {
            try {
                val intent = Intent(context, AdhanPlayerService::class.java)
                context.stopService(intent)
                Log.d(TAG, "Service stop requested")
            } catch (e: Exception) {
                Log.e(TAG, "Failed to stop service: ${e.message}")
            }
        }
    }

    private var mediaPlayer: MediaPlayer? = null
    private var wakeLock: PowerManager.WakeLock? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "onStartCommand — promoting to foreground and starting adzan playback")

        // MUST call startForeground() within 5 seconds of startForegroundService()
        val notification = buildForegroundNotification()
        try {
            startForeground(FOREGROUND_NOTIF_ID, notification)
            Log.d(TAG, "startForeground() success")
        } catch (e: Exception) {
            Log.e(TAG, "startForeground() failed: ${e.message}")
        }

        playAdzan()
        return START_NOT_STICKY
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Adzan Playback",
                NotificationManager.IMPORTANCE_LOW // Low importance = no sound from channel itself
            ).apply {
                description = "Notifikasi saat adzan sedang diputar"
                setSound(null, null) // No channel sound — audio comes from MediaPlayer
                enableVibration(false)
            }
            val nm = getSystemService(NotificationManager::class.java)
            nm?.createNotificationChannel(channel)
        }
    }

    private fun buildForegroundNotification(): Notification {
        // PendingIntent to open the app when the notification is tapped
        val openAppIntent = packageManager.getLaunchIntentForPackage(packageName)
        val pendingIntent = if (openAppIntent != null) {
            PendingIntent.getActivity(
                this, 0, openAppIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        } else null

        // Stop action button
        val stopIntent = Intent(this, AdhanPlayerService::class.java).apply {
            action = "STOP_ADHAN"
        }
        val stopPendingIntent = PendingIntent.getService(
            this, 1, stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("🕌 Adzan Berkumandang")
            .setContentText("Telah memasuki waktu sholat")
            .setSmallIcon(R.mipmap.ic_launcher_round)
            .setOngoing(true)
            .setSilent(true) // No notification sound — audio from MediaPlayer
            .setContentIntent(pendingIntent)
            .addAction(
                android.R.drawable.ic_media_pause,
                "Berhenti",
                stopPendingIntent
            )
            .build()
    }

    private fun playAdzan() {
        // Handle STOP action
        // (checked in onStartCommand flow — if intent has STOP_ADHAN action)

        // Acquire a partial wake lock to keep CPU alive during playback
        try {
            val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
            wakeLock = pm.newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK,
                "ramadhan::AdzanWakeLock"
            ).apply {
                acquire(MAX_DURATION_MS + 5_000) // slightly longer than max duration
            }
            Log.d(TAG, "WakeLock acquired")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to acquire WakeLock: ${e.message}")
        }

        // Ensure previous player is released
        releasePlayer()

        try {
            // Find the adzan resource (new file: res/raw/adzan.mp3)
            var resId = resources.getIdentifier("adzan", "raw", packageName)
            // Fallback to old file name if new one not found
            if (resId == 0) {
                resId = resources.getIdentifier("adhan", "raw", packageName)
            }
            if (resId == 0) {
                Log.e(TAG, "adzan.mp3 not found in res/raw!")
                stopSelf()
                return
            }

            mediaPlayer = MediaPlayer().apply {
                // Use USAGE_ALARM to bypass DND/silent mode and play at alarm volume
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                        .build()
                )

                // Set volume to at least 70% of max alarm volume
                val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                val maxVolume = audioManager.getStreamMaxVolume(AudioManager.STREAM_ALARM)
                val currentVolume = audioManager.getStreamVolume(AudioManager.STREAM_ALARM)
                val targetVolume = maxOf(currentVolume, (maxVolume * 0.7).toInt())
                audioManager.setStreamVolume(AudioManager.STREAM_ALARM, targetVolume, 0)

                val afd = resources.openRawResourceFd(resId)
                setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
                afd.close()

                setOnCompletionListener {
                    Log.d(TAG, "Adzan playback completed")
                    stopSelf()
                }

                setOnErrorListener { _, what, extra ->
                    Log.e(TAG, "MediaPlayer error: what=$what, extra=$extra")
                    stopSelf()
                    true
                }

                prepare()

                // Safety timeout: stop after MAX_DURATION_MS
                val duration = duration // in ms
                val timeout = minOf(duration.toLong() + 2_000, MAX_DURATION_MS)
                android.os.Handler(mainLooper).postDelayed({
                    Log.d(TAG, "Safety timeout reached, stopping playback")
                    stopSelf()
                }, timeout)

                start()
                Log.d(TAG, "Adzan playback started (duration=${duration}ms, file=adzan.mp3)")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to play adzan: ${e.message}")
            stopSelf()
        }
    }

    private fun releasePlayer() {
        try {
            mediaPlayer?.let {
                if (it.isPlaying) it.stop()
                it.release()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error releasing MediaPlayer: ${e.message}")
        }
        mediaPlayer = null
    }

    private fun releaseWakeLock() {
        try {
            wakeLock?.let {
                if (it.isHeld) it.release()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error releasing WakeLock: ${e.message}")
        }
        wakeLock = null
    }

    override fun onDestroy() {
        Log.d(TAG, "Service destroying — releasing resources")
        releasePlayer()
        releaseWakeLock()
        super.onDestroy()
    }
}
