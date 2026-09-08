package com.dark.ai.services

import android.annotation.SuppressLint
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ServiceInfo
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.util.Log
import androidx.core.app.NotificationCompat
import com.dark.ai.MainActivity
import com.dark.ai.channels.DarkPlatformChannel
import com.dark.ai.speech.SpeechRecognitionCallback
import com.dark.ai.speech.SpeechRecognitionManager
import com.dark.ai.tts.DarkTextToSpeech
import com.dark.ai.tts.TextToSpeechCallback
import com.dark.ai.wakeword.VoiceState
import com.dark.ai.wakeword.WakeWordListener
import com.dark.ai.wakeword.WakeWordManager

class DarkForegroundService : Service(), WakeWordListener, SpeechRecognitionCallback, TextToSpeechCallback {

    companion object {
        private const val TAG = "DARK_ForegroundService"
        const val CHANNEL_ID = "dark_voice_assistant_channel"
        const val NOTIFICATION_ID = 9901

        const val ACTION_START = "com.dark.ai.action.START_SERVICE"
        const val ACTION_STOP = "com.dark.ai.action.STOP_SERVICE"
        const val ACTION_SPEAK = "com.dark.ai.action.SPEAK"
        const val EXTRA_SPEAK_TEXT = "extra_speak_text"
        const val EXTRA_WAKE_PHRASE = "extra_wake_phrase"

        var isServiceRunning = false
            private set
    }

    private var wakeLock: PowerManager.WakeLock? = null
    private lateinit var wakeWordManager: WakeWordManager
    private lateinit var speechManager: SpeechRecognitionManager
    private lateinit var textToSpeech: DarkTextToSpeech
    private lateinit var audioManager: AudioManager

    private var currentWakePhrase = "Hey Dark"
    private var isScreenOff = false

    private val screenReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            when (intent?.action) {
                Intent.ACTION_SCREEN_OFF -> {
                    isScreenOff = true
                    Log.d(TAG, "Screen went OFF. WakeLock ensuring continuous wake-word detection.")
                }
                Intent.ACTION_SCREEN_ON -> {
                    isScreenOff = false
                    Log.d(TAG, "Screen turned ON.")
                }
                Intent.ACTION_USER_PRESENT -> {
                    Log.d(TAG, "Device unlocked by user.")
                }
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        Log.i(TAG, "Initializing DarkForegroundService...")

        audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager

        // Acquire partial wake lock to keep CPU awake during screen-off
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "DARK:VoiceWakeLock"
        ).apply {
            setReferenceCounted(false)
            acquire(24 * 60 * 60 * 1000L) // Safe max duration
        }

        // Initialize modules
        wakeWordManager = WakeWordManager(currentWakePhrase).apply {
            setListener(this@DarkForegroundService)
        }

        speechManager = SpeechRecognitionManager(this).apply {
            setCallback(this@DarkForegroundService)
        }

        textToSpeech = DarkTextToSpeech(this).apply {
            setCallback(this@DarkForegroundService)
        }

        // Register screen state receiver
        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_OFF)
            addAction(Intent.ACTION_SCREEN_ON)
            addAction(Intent.ACTION_USER_PRESENT)
        }
        registerReceiver(screenReceiver, filter)

        createNotificationChannel()
    }

    @SuppressLint("InlinedApi")
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action

        if (action == ACTION_STOP) {
            Log.i(TAG, "Received ACTION_STOP. Shutting down foreground service.")
            stopSelf()
            return START_NOT_STICKY
        }

        if (action == ACTION_SPEAK) {
            val textToSpeak = intent.getStringExtra(EXTRA_SPEAK_TEXT) ?: ""
            if (textToSpeak.isNotEmpty()) {
                handleSpeakCommand(textToSpeak)
            }
            return START_STICKY
        }

        // Start Foreground Notification
        val phrase = intent?.getStringExtra(EXTRA_WAKE_PHRASE) ?: currentWakePhrase
        currentWakePhrase = phrase
        wakeWordManager.setWakePhrase(phrase)

        val notification = buildNotification("Listening for \"$currentWakePhrase\"")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }

        isServiceRunning = true
        DarkPlatformChannel.notifyStateChanged(VoiceState.WAKE_WORD_LISTENING)

        // Begin wake-word detection
        wakeWordManager.startListening()

        return START_STICKY
    }

    override fun onDestroy() {
        Log.i(TAG, "Destroying DarkForegroundService...")
        isServiceRunning = false

        try {
            unregisterReceiver(screenReceiver)
        } catch (e: Exception) {
            Log.w(TAG, "Screen receiver already unregistered")
        }

        wakeWordManager.stopListening()
        speechManager.destroyRecognizer()
        textToSpeech.shutdown()

        wakeLock?.let {
            if (it.isHeld) {
                it.release()
            }
        }
        wakeLock = null

        DarkPlatformChannel.notifyStateChanged(VoiceState.IDLE)
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    // --- WAKE WORD LISTENER ---

    override fun onWakeWordDetected(phrase: String) {
        Log.i(TAG, "✨ Wake word detected: $phrase! Screen off: $isScreenOff")
        triggerHapticFeedback()

        updateNotification("Activated! Listening for command...")
        DarkPlatformChannel.notifyWakeWordDetected(phrase)
        DarkPlatformChannel.notifyStateChanged(VoiceState.ACTIVATED)

        // Request audio focus
        requestAudioFocus()

        // Switch to Command Listening
        wakeWordManager.setState(VoiceState.LISTENING_COMMAND)
        DarkPlatformChannel.notifyStateChanged(VoiceState.LISTENING_COMMAND)
        DarkPlatformChannel.notifyListeningStarted()

        speechManager.startListening()
    }

    override fun onStateChanged(newState: VoiceState) {
        DarkPlatformChannel.notifyStateChanged(newState)
    }

    override fun onError(errorMessage: String) {
        Log.e(TAG, "WakeWordManager error: $errorMessage")
        DarkPlatformChannel.notifyServiceError(errorMessage)
        safeRecover()
    }

    // --- SPEECH RECOGNITION CALLBACK ---

    override fun onReadyForSpeech() {
        Log.d(TAG, "SpeechRecognizer is ready for input.")
    }

    override fun onBeginningOfSpeech() {
        Log.d(TAG, "User started speaking command.")
    }

    override fun onRmsChanged(rmsdB: Float) {
        // Voice waveform updates can be bridged here if active UI is showing
    }

    override fun onPartialResults(partialText: String) {
        DarkPlatformChannel.notifyCommandPartial(partialText)
    }

    override fun onFinalResult(commandText: String) {
        Log.i(TAG, "Command transcribed: '$commandText'")
        if (commandText.isBlank()) {
            Log.w(TAG, "Blank command received. Returning to wake word listening.")
            safeRecover()
            return
        }

        wakeWordManager.setState(VoiceState.PROCESSING)
        DarkPlatformChannel.notifyStateChanged(VoiceState.PROCESSING)
        DarkPlatformChannel.notifyCommandReceived(commandText, isScreenOff)
        updateNotification("Processing: \"$commandText\"")
    }

    override fun onError(errorCode: Int, errorMessage: String) {
        Log.w(TAG, "SpeechRecognizer error ($errorCode): $errorMessage")
        DarkPlatformChannel.notifyServiceError(errorMessage)
        safeRecover()
    }

    // --- TEXT TO SPEECH CALLBACK ---

    fun handleSpeakCommand(text: String) {
        wakeWordManager.setState(VoiceState.SPEAKING)
        DarkPlatformChannel.notifyStateChanged(VoiceState.SPEAKING)
        updateNotification("Speaking response...")
        textToSpeech.speak(text)
    }

    override fun onSpeakingStarted(utteranceId: String) {
        Log.d(TAG, "TTS speaking started.")
        DarkPlatformChannel.notifySpeakingStarted()
    }

    override fun onSpeakingFinished(utteranceId: String) {
        Log.d(TAG, "TTS speaking finished. Resuming wake word listening.")
        DarkPlatformChannel.notifySpeakingFinished()
        abandonAudioFocus()
        safeRecover()
    }

    override fun onSpeakingError(utteranceId: String, errorMessage: String) {
        Log.e(TAG, "TTS speaking error: $errorMessage")
        abandonAudioFocus()
        safeRecover()
    }

    // --- RECOVERY & AUDIO FOCUS ---

    private fun safeRecover() {
        Log.d(TAG, "Safe recovery initiated. Resuming wake word listening.")
        speechManager.stopListening()
        updateNotification("Listening for \"$currentWakePhrase\"")
        wakeWordManager.resumeListening()
    }

    private fun requestAudioFocus() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val audioAttributes = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_ASSISTANCE_NAVIGATION_GUIDANCE)
                .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                .build()
            val focusRequest = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_EXCLUSIVE)
                .setAudioAttributes(audioAttributes)
                .build()
            audioManager.requestAudioFocus(focusRequest)
        } else {
            @Suppress("DEPRECATION")
            audioManager.requestAudioFocus(null, AudioManager.STREAM_MUSIC, AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_EXCLUSIVE)
        }
    }

    private fun abandonAudioFocus() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val focusRequest = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_EXCLUSIVE).build()
            audioManager.abandonAudioFocusRequest(focusRequest)
        } else {
            @Suppress("DEPRECATION")
            audioManager.abandonAudioFocus(null)
        }
    }

    private fun triggerHapticFeedback() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val vibratorManager = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
                val vibrator = vibratorManager.defaultVibrator
                val effect = VibrationEffect.createWaveform(longArrayOf(0, 100, 80, 150), -1)
                vibrator.vibrate(effect)
            } else {
                @Suppress("DEPRECATION")
                val vibrator = getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    vibrator.vibrate(VibrationEffect.createWaveform(longArrayOf(0, 100, 80, 150), -1))
                } else {
                    vibrator.vibrate(200)
                }
            }
        } catch (e: Exception) {
            Log.w(TAG, "Vibration feedback failed", e)
        }
    }

    // --- NOTIFICATION MANAGEMENT ---

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "DARK Voice Assistant",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Ongoing foreground service for hands-free and screen-off wake-word detection"
                setShowBadge(false)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(statusText: String): Notification {
        val openAppIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val openAppPendingIntent = PendingIntent.getActivity(
            this, 0, openAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val stopIntent = Intent(this, DarkForegroundService::class.java).apply {
            action = ACTION_STOP
        }
        val stopPendingIntent = PendingIntent.getService(
            this, 1, stopIntent,
            PendingIntent.FLAG_CANCEL_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("DARK AI Assistant Active")
            .setContentText(statusText)
            .setSmallIcon(android.R.drawable.ic_btn_speak_now)
            .setContentIntent(openAppPendingIntent)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .addAction(android.R.drawable.ic_menu_close_clear_cancel, "Stop", stopPendingIntent)
            .build()
    }

    private fun updateNotification(statusText: String) {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(NOTIFICATION_ID, buildNotification(statusText))
    }
}
