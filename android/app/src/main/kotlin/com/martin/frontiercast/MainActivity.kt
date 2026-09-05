package com.martin.frontiercast

import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Extends [AudioServiceActivity] rather than FlutterActivity — audio_service
 * requires its own activity to bind playback — and adds the channel Dart uses
 * to hold a foreground service open while transcriptions run.
 */
class MainActivity : AudioServiceActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "start" -> {
                        TranscriptionService.start(
                            this,
                            call.argument<String>("text") ?: "Transcribing…",
                        )
                        result.success(null)
                    }
                    "stop" -> {
                        TranscriptionService.stop(this)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    companion object {
        private const val CHANNEL = "com.martin.frontiercast/transcription"
    }
}
