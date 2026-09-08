from typing import Optional, List, Dict, Any
from pydantic import BaseModel, Field
from datetime import datetime

class ChatRequest(BaseModel):
    message: str = Field(..., description="The user message or transcribed voice command")
    session_id: Optional[str] = Field("default", description="Conversation session ID")
    source: Optional[str] = Field("voice", description="Source of message: voice or text")
    screen_off: Optional[bool] = Field(False, description="Whether phone screen was off during trigger")
    context: Optional[Dict[str, Any]] = Field(default_factory=dict, description="Additional client context")

class ChatResponse(BaseModel):
    reply: str = Field(..., description="Visual text reply formatted for chat screen")
    spoken_text: str = Field(..., description="Speech-optimized response for native Text-to-Speech")
    intent: str = Field("general", description="Identified assistant intent")
    action_data: Optional[Dict[str, Any]] = Field(default_factory=dict, description="Structured tool/action payload")
    session_id: str = Field("default")
    timestamp: str = Field(default_factory=lambda: datetime.now().isoformat())

class VoiceCommandRequest(BaseModel):
    command: str = Field(..., description="Raw speech-to-text transcript")
    wake_phrase: Optional[str] = Field("Hey Dark", description="Wake phrase used")
    confidence: Optional[float] = Field(1.0, description="ASR confidence score")
    screen_off: Optional[bool] = Field(False)

class ReminderItem(BaseModel):
    id: str
    title: str
    due_time: Optional[str] = None
    completed: bool = False
    created_at: str = Field(default_factory=lambda: datetime.now().isoformat())

class NoteItem(BaseModel):
    id: str
    title: str
    content: str
    created_at: str = Field(default_factory=lambda: datetime.now().isoformat())

class AssistantStatus(BaseModel):
    status: str = "online"
    name: str = "DARK AI"
    version: str = "2.5.0"
    capabilities: List[str] = [
        "wake_word_activation",
        "screen_off_operation",
        "reminders",
        "notes",
        "weather",
        "time_query",
        "device_guidance",
        "conversational_reasoning"
    ]
