import logging
from typing import Dict, List, Optional
from datetime import datetime
from app.models.schemas import ChatRequest, ChatResponse
from app.assistant.intents import IntentHandler

logger = logging.getLogger("dark.engine")

class DarkAssistantEngine:
    def __init__(self):
        # Store session conversation turns: session_id -> list of turn dicts
        self.sessions: Dict[str, List[Dict[str, str]]] = {}
        logger.info("DARK Assistant Engine initialized.")

    def process_message(self, request: ChatRequest) -> ChatResponse:
        session_id = request.session_id or "default"
        if session_id not in self.sessions:
            self.sessions[session_id] = []

        # Record user message in session
        self.sessions[session_id].append({
            "role": "user",
            "text": request.message,
            "timestamp": datetime.now().isoformat(),
            "source": request.source or "voice"
        })

        # Classify and execute intent
        intent, reply, spoken_text, action_data = IntentHandler.classify_and_execute(
            text=request.message,
            screen_off=request.screen_off or False
        )

        # Record assistant reply in session
        self.sessions[session_id].append({
            "role": "assistant",
            "text": reply,
            "spoken_text": spoken_text,
            "intent": intent,
            "timestamp": datetime.now().isoformat()
        })

        # Keep session history bounded
        if len(self.sessions[session_id]) > 50:
            self.sessions[session_id] = self.sessions[session_id][-50:]

        return ChatResponse(
            reply=reply,
            spoken_text=spoken_text,
            intent=intent,
            action_data=action_data,
            session_id=session_id,
            timestamp=datetime.now().isoformat()
        )

    def get_session_history(self, session_id: str) -> List[Dict[str, str]]:
        return self.sessions.get(session_id, [])

    def clear_session(self, session_id: str) -> bool:
        if session_id in self.sessions:
            del self.sessions[session_id]
            return True
        return False

# Global instance
engine = DarkAssistantEngine()
