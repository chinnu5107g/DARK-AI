# DARK AI — Assistant Backend

FastAPI intelligent backend powering DARK AI's hands-free and screen-off personal assistant functionality.

## Features
- **Voice Command Processing**: Direct endpoint `/api/voice/process` designed for ASR output after wake-word detection.
- **Intent Engine**: Fast rule-based + generative tools for Time, Date, Weather, Reminders, Notes, and Device Status.
- **Dual Output**: Formats rich markdown for screen view (`reply`) and natural, concise phrasing for native Android Text-to-Speech (`spoken_text`).
- **Session Memory**: Tracks conversation turns across interactions.

## Run
```bash
pip install -r requirements.txt
python run.py
```
Default server starts on `http://0.0.0.0:8000`.
