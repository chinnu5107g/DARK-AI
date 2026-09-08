# DARK AI — Android Voice Activation & Mobile Assistant

This Flutter application houses the native Android voice activation system that enables wake-word detection ("Hey Dark") even when the device is locked or the screen is turned off.

## Architectural Flow

```
[Screen OFF / Phone Locked (Powered ON)]
                 │
                 ▼
[DarkForegroundService] ─── (Kept alive via Partial WakeLock)
                 │
                 ▼
        [WakeWordManager]
  - Continuous 16kHz PCM AudioRecord stream
  - On-Device Acoustic Keyword Spotter ("Hey Dark")
  - Zero cloud audio streaming (100% private)
                 │
                 ▼ ("Hey Dark" detected)
          [Haptic Chime] ─── (Vibration alert)
                 │
                 ▼
   [SpeechRecognitionManager]
  - Hands-off microphone from wake-word to ASR
  - Listens for user command with silence timeouts
                 │
                 ▼
     [DarkPlatformChannel]
  - Dispatches transcribed command to Flutter / Backend
                 │
                 ▼
     [FastAPI DARK Backend]
  - Processes query, executes intent tools (weather, reminders, time)
                 │
                 ▼
       [DarkTextToSpeech]
  - Speaks response aloud using native Android TTS
                 │
                 ▼
     (Resumes "Hey Dark" listening)
```

## Android Native Structure
Located in `android/app/src/main/kotlin/com/dark/ai/`:
- **`services/DarkForegroundService.kt`**: Persistent foreground service with notification channel, microphone type, wake lock, screen-off broadcast receiver, and audio focus management.
- **`wakeword/WakeWordEngine.kt`**: On-device acoustic keyword spotting interface and sliding-window spectral/energy pattern matcher.
- **`wakeword/WakeWordManager.kt`**: Manages `AudioRecord` thread, buffer reading, and voice state machine transitions.
- **`speech/SpeechRecognitionManager.kt`**: Android `SpeechRecognizer` integration for post-wake-word voice commands.
- **`tts/DarkTextToSpeech.kt`**: Android `TextToSpeech` engine with `UtteranceProgressListener`.
- **`channels/DarkPlatformChannel.kt`**: Bi-directional `MethodChannel` and `EventChannel` communicating with Flutter.
- **`MainActivity.kt`**: Configured with `setShowWhenLocked(true)` and `setTurnScreenOn(true)` to display UI on wake.

## Essential Android Permissions
- `RECORD_AUDIO`: Required for microphone access.
- `FOREGROUND_SERVICE` & `FOREGROUND_SERVICE_MICROPHONE`: Required on modern Android (API 29+/34+) to maintain microphone access in the background.
- `POST_NOTIFICATIONS`: Android 13+ requirement for foreground notification display.
- `WAKE_LOCK`: `PARTIAL_WAKE_LOCK` to ensure CPU does not sleep when screen is dark.
- `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`: Protects the service from aggressive OEM task killers (MIUI, Samsung OneUI, etc.).

## How to Run
1. Connect an Android phone or launch an Android Emulator (API 26+).
2. Start the FastAPI backend:
   ```bash
   cd ../backend
   python run.py
   ```
3. Run the Flutter app:
   ```bash
   flutter run
   ```
4. In DARK AI Settings:
   - Grant Microphone and Notification permissions.
   - Tap **"Allow Unrestricted Background"** to exempt from battery optimization.
   - Switch on **Wake Word Assistant**.
5. Turn off the phone screen or lock the phone, and speak:
   > *"Hey Dark"*
   > *(feel the haptic buzz)*
   > *"What time is it?"*
   DARK will wake up and respond immediately.
