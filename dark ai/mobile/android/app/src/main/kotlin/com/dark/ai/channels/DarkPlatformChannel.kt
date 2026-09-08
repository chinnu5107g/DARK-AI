package com.dark.ai.channels

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.provider.Settings
import android.util.Log
import androidx.core.content.ContextCompat
import com.dark.ai.services.DarkForegroundService
import com.dark.ai.wakeword.VoiceState
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class DarkPlatformChannel private constructor() : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    companion object {
        private const val TAG = "DARK_PlatformChannel"
        const val METHOD_CHANNEL_NAME = "com.dark.ai/assistant"
        const val EVENT_CHANNEL_NAME = "com.dark.ai/assistant_events"

        val instance: DarkPlatformChannel by lazy { DarkPlatformChannel() }

        private val mainHandler = Handler(Looper.getMainLooper())
        private var eventSink: EventChannel.EventSink? = null

        fun notifyEvent(eventData: Map<String, Any>) {
            mainHandler.post {
                try {
                    eventSink?.success(eventData)
                } catch (e: Exception) {
                    Log.w(TAG, "Error emitting event to Flutter sink", e)
                }
            }
        }

        fun notifyStateChanged(state: VoiceState) {
            notifyEvent(mapOf("event" to "state_changed", "state" to state.name))
        }

        fun notifyWakeWordDetected(phrase: String) {
            notifyEvent(mapOf("event" to "wake_word_detected", "phrase" to phrase))
        }

        fun notifyListeningStarted() {
            notifyEvent(mapOf("event" to "listening_started"))
        }

        fun notifyCommandPartial(partialText: String) {
            notifyEvent(mapOf("event" to "command_partial", "text" to partialText))
        }

        fun notifyCommandReceived(commandText: String, screenOff: Boolean) {
            notifyEvent(mapOf(
                "event" to "command_received",
                "text" to commandText,
                "screen_off" to screenOff
            ))
        }

        fun notifyProcessingStarted() {
            notifyEvent(mapOf("event" to "processing_started"))
        }

        fun notifySpeakingStarted() {
            notifyEvent(mapOf("event" to "speaking_started"))
        }

        fun notifySpeakingFinished() {
            notifyEvent(mapOf("event" to "speaking_finished"))
        }

        fun notifyServiceError(message: String) {
            notifyEvent(mapOf("event" to "service_error", "message" to message))
        }
    }

    private var context: Context? = null
    private var activity: Activity? = null
    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null

    fun register(messenger: BinaryMessenger, context: Context, activity: Activity) {
        this.context = context.applicationContext
        this.activity = activity

        methodChannel = MethodChannel(messenger, METHOD_CHANNEL_NAME).apply {
            setMethodCallHandler(this@DarkPlatformChannel)
        }

        eventChannel = EventChannel(messenger, EVENT_CHANNEL_NAME).apply {
            setStreamHandler(this@DarkPlatformChannel)
        }

        Log.i(TAG, "DarkPlatformChannel registered with Flutter BinaryMessenger.")
    }

    fun unregister() {
        methodChannel?.setMethodCallHandler(null)
        eventChannel?.setStreamHandler(null)
        methodChannel = null
        eventChannel = null
        activity = null
        context = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val ctx = context ?: run {
            result.error("NO_CONTEXT", "Context is null", null)
            return
        }

        when (call.method) {
            "startWakeWordService" -> {
                val phrase = call.argument<String>("wakePhrase") ?: "Hey Dark"
                val intent = Intent(ctx, DarkForegroundService::class.java).apply {
                    action = DarkForegroundService.ACTION_START
                    putExtra(DarkForegroundService.EXTRA_WAKE_PHRASE, phrase)
                }
                ContextCompat.startForegroundService(ctx, intent)
                result.success(true)
            }

            "stopWakeWordService" -> {
                val intent = Intent(ctx, DarkForegroundService::class.java).apply {
                    action = DarkForegroundService.ACTION_STOP
                }
                ctx.stopService(intent)
                result.success(true)
            }

            "getWakeWordStatus" -> {
                result.success(mapOf(
                    "isRunning" to DarkForegroundService.isServiceRunning
                ))
            }

            "speak" -> {
                val text = call.argument<String>("text") ?: ""
                val intent = Intent(ctx, DarkForegroundService::class.java).apply {
                    action = DarkForegroundService.ACTION_SPEAK
                    putExtra(DarkForegroundService.EXTRA_SPEAK_TEXT, text)
                }
                ContextCompat.startForegroundService(ctx, intent)
                result.success(true)
            }

            "isBatteryOptimizationIgnored" -> {
                val powerManager = ctx.getSystemService(Context.POWER_SERVICE) as PowerManager
                val isIgnored = powerManager.isIgnoringBatteryOptimizations(ctx.packageName)
                result.success(isIgnored)
            }

            "requestBatteryOptimizationExemption" -> {
                val act = activity
                if (act != null) {
                    try {
                        val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                            data = Uri.parse("package:${ctx.packageName}")
                        }
                        act.startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        Log.w(TAG, "Failed to launch direct battery exemption intent, falling back to settings", e)
                        val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                        act.startActivity(intent)
                        result.success(true)
                    }
                } else {
                    result.error("NO_ACTIVITY", "Activity is null", null)
                }
            }

            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        Log.d(TAG, "Flutter attached to event stream.")
        eventSink = events
        // Emit current status immediately upon connection
        val initialStatus = if (DarkForegroundService.isServiceRunning) VoiceState.WAKE_WORD_LISTENING else VoiceState.IDLE
        notifyStateChanged(initialStatus)
    }

    override fun onCancel(arguments: Any?) {
        Log.d(TAG, "Flutter detached from event stream.")
        eventSink = null
    }
}
