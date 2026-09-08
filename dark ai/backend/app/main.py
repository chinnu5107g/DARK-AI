import logging
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from app.models.schemas import ChatRequest, ChatResponse, VoiceCommandRequest, AssistantStatus
from app.assistant.engine import engine
from app.assistant.intents import REMINDERS_DB, NOTES_DB

# Configure logging
logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(name)s: %(message)s")
logger = logging.getLogger("dark.main")

app = FastAPI(
    title="DARK AI Assistant Backend",
    description="Intelligent Voice-Activated Assistant API powering screen-off and hands-free DARK AI",
    version="2.5.0"
)

# Enable CORS for Flutter mobile/web/desktop
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/", tags=["Status"])
async def root():
    return {
        "app": "DARK AI",
        "tagline": "Advanced Android Voice Activation & Autonomous Assistant",
        "wake_word": "Hey Dark",
        "status": "online"
    }

@app.get("/api/health", response_model=AssistantStatus, tags=["Status"])
async def health():
    return AssistantStatus()

@app.post("/api/chat", response_model=ChatResponse, tags=["Assistant"])
async def chat(request: ChatRequest):
    """
    Main conversational endpoint: processes transcribed voice commands or chat text,
    routes through intent engine, and returns visual reply + TTS spoken text.
    """
    if not request.message or not request.message.strip():
        raise HTTPException(status_code=400, detail="Message cannot be empty")
    
    logger.info(f"Received query [source={request.source}, screen_off={request.screen_off}]: {request.message}")
    response = engine.process_message(request)
    return response

@app.post("/api/voice/process", response_model=ChatResponse, tags=["Voice"])
async def process_voice(command_req: VoiceCommandRequest):
    """
    Dedicated endpoint called after wake word ('Hey Dark') and speech recognition.
    """
    chat_req = ChatRequest(
        message=command_req.command,
        source="voice",
        screen_off=command_req.screen_off or False,
        context={"wake_phrase": command_req.wake_phrase, "confidence": command_req.confidence}
    )
    return engine.process_message(chat_req)

@app.get("/api/reminders", tags=["Tools"])
async def list_reminders():
    return {"reminders": [r.dict() for r in REMINDERS_DB]}

@app.get("/api/notes", tags=["Tools"])
async def list_notes():
    return {"notes": [n.dict() for n in NOTES_DB]}

@app.delete("/api/session/{session_id}", tags=["Assistant"])
async def clear_session(session_id: str):
    cleared = engine.clear_session(session_id)
    return {"session_id": session_id, "cleared": cleared}
