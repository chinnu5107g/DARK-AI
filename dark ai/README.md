# DARK AI — Advanced Screen-Off / Locked Phone Voice Activation System

DARK AI is an autonomous, privacy-preserving personal assistant featuring an advanced native Android voice activation system that wakes on the phrase **"Hey Dark"** even when the device's screen is turned off or locked (while powered on).

## Architecture

```
Flutter Application (UI, State & Settings)
      │
      │ Platform Channel (MethodChannel + EventChannel)
      ▼
Native Android Kotlin Layer
      │
      ▼
DARK Foreground Service (with Partial WakeLock & Ongoing Notification)
      │
      ▼
Wake Word Engine (On-Device 16kHz PCM Gated Pattern Spotter: "Hey Dark")
      │
      ▼ [Wake Word Detected + Haptic Chime]
Voice Command Listener (Android SpeechRecognizer with Silence Detection)
      │
      ▼ [Transcribed Command]
FastAPI DARK AI Backend
  ├── Intent Classifier (Time, Weather, Reminders, Notes, System Guidance)
  ├── Personal Assistant Memory & Reasoning
  └── Formats Spoken Text & Visual Markdown
      │
      ▼ [AI Spoken Text]
Android Native Text-to-Speech (DarkTextToSpeech)
      │
      ▼ [Audio Output]
DARK Resumes Listening for "Hey Dark"
```

## Repository Structure

```
dark ai/
├── backend/                  # FastAPI Assistant Intelligence Service
│   ├── app/
│   │   ├── main.py           # FastAPI app & endpoints (/api/chat, /api/voice/process)
│   │   ├── models/schemas.py # Pydantic request/response schemas
│   │   ├── assistant/
│   │   │   ├── engine.py     # Conversation memory & session engine
│   │   │   └── intents.py    # Intent classifier & tools (reminders, weather, time)
│   ├── tests/
│   │   └── test_assistant.py # Pytest test suite
│   ├── run.py                # Server runner script
│   └── requirements.txt
│
└── mobile/                   # Flutter Application + Android Native Layer
    ├── lib/
    │   ├── main.dart         # Flutter entrypoint & tab navigation
    │   ├── core/             # Theme, constants, API client
    │   └── features/
    │       ├── chat/         # Chat screen, bubbles, message model, suggestions
    │       ├── voice/        # Wake word HUD, controller, voice service, PTT
    │       └── settings/     # Permissions, battery optimization, wake word toggles
    └── android/app/src/main/
        ├── AndroidManifest.xml # Permissions, Foreground Service & Lockscreen flags
        └── kotlin/com/dark/ai/
            ├── MainActivity.kt
            ├── services/DarkForegroundService.kt
            ├── wakeword/WakeWordManager.kt
            ├── wakeword/WakeWordEngine.kt
            ├── speech/SpeechRecognitionManager.kt
            ├── tts/DarkTextToSpeech.kt
            └── channels/DarkPlatformChannel.kt
```

## Voice Activation State Machine

```
   ┌────────┐
   │  IDLE  │ (User enables Assistant)
   └───┬────┘
       ▼
   ┌─────────────────────┐
   │ WAKE_WORD_LISTENING │◄─────────────────────┐
   └─────────┬───────────┘                      │
             │ "Hey Dark" detected              │
             ▼                                  │
   ┌─────────────────────┐                      │
   │      ACTIVATED      │                      │
   └─────────┬───────────┘                      │
             │ Handoff microphone               │
             ▼                                  │
   ┌─────────────────────┐                      │
   │  LISTENING_COMMAND  │                      │
   └─────────┬───────────┘                      │
             │ Command transcribed              │
             ▼                                  │
   ┌─────────────────────┐                      │
   │     PROCESSING      │ (FastAPI Backend)    │
   └─────────┬───────────┘                      │
             │ AI Response ready                │
             ▼                                  │
   ┌─────────────────────┐                      │
   │      SPEAKING       │ (Native TTS)         │
   └─────────┬───────────┘                      │
             │ TTS finished                     │
             └──────────────────────────────────┘
```

## Getting Started

### 1. Start the Backend
```bash
cd backend
pip install -r requirements.txt
python run.py
```

### 2. Launch the Flutter App
```bash
cd mobile
flutter pub get
flutter run
```

### 3. Activate Hands-Free Assistant
1. Open the Settings tab in DARK AI.
2. Grant **Microphone** and **Notification** permissions.
3. Tap **Allow Unrestricted Background** to exempt DARK from Android Doze battery optimizations.
4. Toggle **Wake Word Assistant** to ON.
5. Lock the phone or turn the screen off, then say: **"Hey Dark"**!
