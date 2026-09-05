package com.martin.frontiercast

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.IBinder

/**
 * Keeps the process alive while a transcription is running.
 *
 * Transcribing an episode takes minutes to hours on the Mac, and the phone has
 * to hold an HTTP stream open the whole time. Backgrounded, that doesn't
 * survive: Samsung's Freecess freezes the app within seconds of losing focus,
 * and Android then kills it outright — three times in one day, in the exit log
 * that led to this class. A foreground service is the only thing that reliably
 * holds the process, so the queue runs inside one.
 */
class TranscriptionService : Service() {
    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val text = intent?.getStringExtra(EXTRA_TEXT) ?: DEFAULT_TEXT
        startForeground(NOTIFICATION_ID, buildNotification(text))
        // The Dart side owns the queue and restarts it on launch, so there is
        // nothing useful to redeliver if we're killed anyway.
        return START_NOT_STICKY
    }

    private fun buildNotification(text: String): Notification {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.createNotificationChannel(
            NotificationChannel(
                CHANNEL_ID,
                "Transcription",
                // Silent and collapsed: this is a progress indicator, not news.
                NotificationManager.IMPORTANCE_LOW,
            ).apply { description = "Shown while an episode is being transcribed" }
        )

        val tapToOpen = packageManager.getLaunchIntentForPackage(packageName)?.let {
            PendingIntent.getActivity(this, 0, it, PendingIntent.FLAG_IMMUTABLE)
        }

        return Notification.Builder(this, CHANNEL_ID)
            .setContentTitle("FrontierCast")
            .setContentText(text)
            .setSmallIcon(android.R.drawable.stat_sys_download)
            .setOngoing(true)
            .setContentIntent(tapToOpen)
            .build()
    }

    companion object {
        private const val CHANNEL_ID = "com.martin.frontiercast.transcription"
        private const val NOTIFICATION_ID = 1837
        private const val DEFAULT_TEXT = "Transcribing…"
        const val EXTRA_TEXT = "text"

        fun start(context: Context, text: String) {
            context.startForegroundService(
                Intent(context, TranscriptionService::class.java).putExtra(EXTRA_TEXT, text)
            )
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, TranscriptionService::class.java))
        }
    }
}
