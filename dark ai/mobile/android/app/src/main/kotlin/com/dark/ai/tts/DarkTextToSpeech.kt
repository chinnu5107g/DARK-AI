package com.dark.ai.tts

import android.content.Context
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import android.util.Log
import java.util.Locale

interface TextToSpeechCallback {
    fun onSpeakingStarted(utteranceId: String)
    fun onSpeakingFinished(utteranceId: String)
    fun onSpeakingError(utteranceId: String, errorMessage: String)
}

class DarkTextToSpeech(private val context: Context) : TextToSpeech.OnInitListener {

    companion object {
        private const val TAG = "DARK_TTS"
    }

    private var tts: TextToSpeech? = null
    private var isInitialized = false
    private var callback: TextToSpeechCallback? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    private val pendingSpeechQueue = mutableListOf<Pair<String, String>>() // (text, utteranceId)

    init {
        tts = TextToSpeech(context.applicationContext, this)
    }

    fun setCallback(callback: TextToSpeechCallback) {
        this.callback = callback
    }

    override fun onInit(status: Int) {
        if (status == TextToSpeech.SUCCESS) {
            val result = tts?.setLanguage(Locale.US)
            if (result == TextToSpeech.LANG_MISSING_DATA || result == TextToSpeech.LANG_NOT_SUPPORTED) {
                Log.w(TAG, "Default language US is not supported or missing data")
            }
            tts?.setPitch(0.95f) // Slightly deeper, sharp assistant tone
            tts?.setSpeechRate(1.05f) // Crisp, efficient pace

            tts?.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
                override fun onStart(utteranceId: String?) {
                    Log.d(TAG, "TTS onStart: $utteranceId")
                    mainHandler.post {
                        callback?.onSpeakingStarted(utteranceId ?: "")
                    }
                }

                override fun onDone(utteranceId: String?) {
                    Log.d(TAG, "TTS onDone: $utteranceId")
                    mainHandler.post {
                        callback?.onSpeakingFinished(utteranceId ?: "")
                    }
                }

                @Deprecated("Deprecated in Java")
                override fun onError(utteranceId: String?) {
                    Log.e(TAG, "TTS onError: $utteranceId")
                    mainHandler.post {
                        callback?.onSpeakingError(utteranceId ?: "", "TTS synthesis error")
                    }
                }

                override fun onError(utteranceId: String?, errorCode: Int) {
                    Log.e(TAG, "TTS onError code $errorCode: $utteranceId")
                    mainHandler.post {
                        callback?.onSpeakingError(utteranceId ?: "", "TTS synthesis error code $errorCode")
                    }
                }
            })

            isInitialized = true
            Log.i(TAG, "TextToSpeech successfully initialized.")

            // Flush any pending speeches
            for ((text, id) in pendingSpeechQueue) {
                speak(text, id)
            }
            pendingSpeechQueue.clear()

        } else {
            Log.e(TAG, "Failed to initialize TextToSpeech: status $status")
            isInitialized = false
        }
    }

    /**
     * Synthesize and speak the given text.
     */
    fun speak(text: String, utteranceId: String = "dark_speech_${System.currentTimeMillis()}") {
        if (!isInitialized) {
            Log.w(TAG, "TTS not ready yet, queuing utterance: $text")
            pendingSpeechQueue.add(Pair(text, utteranceId))
            return
        }

        val params = Bundle().apply {
            putString(TextToSpeech.Engine.KEY_PARAM_UTTERANCE_ID, utteranceId)
        }

        val result = tts?.speak(text, TextToSpeech.QUEUE_FLUSH, params, utteranceId)
        if (result == TextToSpeech.ERROR) {
            Log.e(TAG, "Error executing speak()")
            callback?.onSpeakingError(utteranceId, "Failed to invoke TTS speak")
        }
    }

    fun stop() {
        try {
            if (tts?.isSpeaking == true) {
                tts?.stop()
            }
        } catch (e: Exception) {
            Log.w(TAG, "Error stopping TTS", e)
        }
    }

    fun shutdown() {
        try {
            stop()
            tts?.shutdown()
            tts = null
            isInitialized = false
        } catch (e: Exception) {
            Log.w(TAG, "Error shutting down TTS", e)
        }
    }
}
