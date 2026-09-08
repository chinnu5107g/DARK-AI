package com.dark.ai.wakeword

import android.annotation.SuppressLint
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.os.Handler
import android.os.Looper
import android.util.Log
import java.util.concurrent.atomic.AtomicBoolean

enum class VoiceState {
    IDLE,
    WAKE_WORD_LISTENING,
    ACTIVATED,
    LISTENING_COMMAND,
    PROCESSING,
    SPEAKING,
    ERROR
}

interface WakeWordListener {
    fun onStateChanged(newState: VoiceState)
    fun onWakeWordDetected(phrase: String)
    fun onError(errorMessage: String)
}

class WakeWordManager(
    private var wakePhrase: String = "Hey Dark",
    private val engine: WakeWordEngine = AcousticKeywordSpotter()
) {
    companion object {
        private const val TAG = "DARK_WakeWord"
        private const val SAMPLE_RATE = 16000
        private const val CHANNEL_CONFIG = AudioFormat.CHANNEL_IN_MONO
        private const val AUDIO_FORMAT = AudioFormat.ENCODING_PCM_16BIT
    }

    private var audioRecord: AudioRecord? = null
    private var recordingThread: Thread? = null
    private val isRunning = AtomicBoolean(false)
    private val mainHandler = Handler(Looper.getMainLooper())

    @Volatile
    var currentState: VoiceState = VoiceState.IDLE
        private set

    private var listener: WakeWordListener? = null

    fun setListener(listener: WakeWordListener) {
        this.listener = listener
    }

    fun setWakePhrase(phrase: String) {
        this.wakePhrase = phrase
    }

    fun setState(newState: VoiceState) {
        if (currentState == newState) return
        Log.i(TAG, "State transition: $currentState -> $newState")
        currentState = newState
        mainHandler.post {
            listener?.onStateChanged(newState)
        }
    }

    /**
     * Starts continuous low-power wake word listening.
     */
    @SuppressLint("MissingPermission")
    @Synchronized
    fun startListening(): Boolean {
        if (isRunning.get()) {
            Log.d(TAG, "WakeWordManager is already running.")
            return true
        }

        val minBufferSize = AudioRecord.getMinBufferSize(SAMPLE_RATE, CHANNEL_CONFIG, AUDIO_FORMAT)
        if (minBufferSize == AudioRecord.ERROR || minBufferSize == AudioRecord.ERROR_BAD_VALUE) {
            val err = "AudioRecord minBufferSize error: $minBufferSize"
            Log.e(TAG, err)
            setState(VoiceState.ERROR)
            mainHandler.post { listener?.onError(err) }
            return false
        }

        val bufferSize = (minBufferSize * 2).coerceAtLeast(3200)

        try {
            audioRecord = AudioRecord(
                MediaRecorder.AudioSource.VOICE_RECOGNITION,
                SAMPLE_RATE,
                CHANNEL_CONFIG,
                AUDIO_FORMAT,
                bufferSize
            )

            if (audioRecord?.state != AudioRecord.STATE_INITIALIZED) {
                // Fallback to MIC if VOICE_RECOGNITION fails
                audioRecord?.release()
                audioRecord = AudioRecord(
                    MediaRecorder.AudioSource.MIC,
                    SAMPLE_RATE,
                    CHANNEL_CONFIG,
                    AUDIO_FORMAT,
                    bufferSize
                )
            }

            if (audioRecord?.state != AudioRecord.STATE_INITIALIZED) {
                val err = "Failed to initialize AudioRecord for wake word detection"
                Log.e(TAG, err)
                setState(VoiceState.ERROR)
                mainHandler.post { listener?.onError(err) }
                return false
            }

            audioRecord?.startRecording()
            isRunning.set(true)
            engine.reset()
            setState(VoiceState.WAKE_WORD_LISTENING)

            recordingThread = Thread({
                processAudioLoop(bufferSize)
            }, "DARK-WakeWord-Thread").apply {
                priority = Thread.NORM_PRIORITY + 1
                start()
            }

            Log.i(TAG, "WakeWordManager started listening for: $wakePhrase")
            return true

        } catch (e: Exception) {
            Log.e(TAG, "Exception starting WakeWordManager", e)
            setState(VoiceState.ERROR)
            mainHandler.post { listener?.onError("Failed to start audio recording: ${e.message}") }
            cleanupAudioRecord()
            return false
        }
    }

    /**
     * Processing loop running on background thread.
     */
    private fun processAudioLoop(bufferSize: Int) {
        val audioBuffer = ShortArray(640) // 40ms frame at 16kHz

        while (isRunning.get() && !Thread.currentThread().isInterrupted) {
            val record = audioRecord ?: break
            val readCount = record.read(audioBuffer, 0, audioBuffer.size)

            if (readCount > 0 && currentState == VoiceState.WAKE_WORD_LISTENING) {
                val detected = engine.process(audioBuffer, readCount)
                if (detected) {
                    Log.i(TAG, "⚡ Wake phrase '$wakePhrase' DETECTED!")
                    // Immediately transition to ACTIVATED
                    setState(VoiceState.ACTIVATED)

                    // Notify listener on main thread
                    mainHandler.post {
                        listener?.onWakeWordDetected(wakePhrase)
                    }

                    // Release microphone temporarily so SpeechRecognizer can take over cleanly
                    pauseListeningForCommand()
                    break
                }
            } else if (readCount < 0) {
                Log.w(TAG, "AudioRecord read error: $readCount")
                try {
                    Thread.sleep(50)
                } catch (ie: InterruptedException) {
                    break
                }
            }
        }
    }

    /**
     * Pauses the wake word AudioRecord to release microphone hardware to SpeechRecognizer.
     */
    @Synchronized
    fun pauseListeningForCommand() {
        isRunning.set(false)
        recordingThread?.interrupt()
        recordingThread = null
        cleanupAudioRecord()
        Log.d(TAG, "WakeWordManager paused & mic released for command listener.")
    }

    /**
     * Resumes wake word listening after TTS or command completion.
     */
    @Synchronized
    fun resumeListening(): Boolean {
        Log.d(TAG, "Resuming wake word listening...")
        return startListening()
    }

    /**
     * Fully stops wake-word detection and releases all resources.
     */
    @Synchronized
    fun stopListening() {
        isRunning.set(false)
        recordingThread?.interrupt()
        recordingThread = null
        cleanupAudioRecord()
        engine.reset()
        setState(VoiceState.IDLE)
        Log.i(TAG, "WakeWordManager stopped.")
    }

    private fun cleanupAudioRecord() {
        try {
            if (audioRecord?.recordingState == AudioRecord.RECORDSTATE_RECORDING) {
                audioRecord?.stop()
            }
            audioRecord?.release()
        } catch (e: Exception) {
            Log.w(TAG, "Error cleaning up AudioRecord", e)
        } finally {
            audioRecord = null
        }
    }

    fun isListening(): Boolean = isRunning.get() && currentState == VoiceState.WAKE_WORD_LISTENING
}
