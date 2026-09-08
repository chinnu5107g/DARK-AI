import re
import uuid
from datetime import datetime
from typing import Tuple, Dict, Any, List
from app.models.schemas import ReminderItem, NoteItem

# In-memory stores for reminders and notes
REMINDERS_DB: List[ReminderItem] = [
    ReminderItem(id="rem-1", title="System diagnostic & voice calibration", due_time="14:00", completed=False),
]

NOTES_DB: List[NoteItem] = [
    NoteItem(id="note-1", title="DARK AI Initialization", content="Background voice activation engine loaded with 'Hey Dark' wake phrase."),
]

class IntentHandler:
    @staticmethod
    def classify_and_execute(text: str, screen_off: bool = False) -> Tuple[str, str, str, Dict[str, Any]]:
        """
        Classifies user query and executes relevant assistant intent.
        Returns: (intent_name, visual_reply, spoken_text, action_data)
        """
        clean = text.lower().strip()
        now = datetime.now()

        # 1. TIME & DATE INTENT
        if any(p in clean for p in ["time is it", "current time", "what time", "what's the time", "tell me the time"]):
            time_str = now.strftime("%I:%M %p")
            reply = f"🕒 The current time is **{time_str}**."
            spoken = f"The time is {now.strftime('%I:%M %p')}."
            return "time_query", reply, spoken, {"time": time_str, "timestamp": now.isoformat()}

        if any(p in clean for p in ["what date", "today's date", "what is today's date", "which day is today", "day is it", "what day"]):
            date_str = now.strftime("%A, %B %d, %Y")
            reply = f"📅 Today is **{date_str}**."
            spoken = f"Today is {now.strftime('%A, %B %d, %Y')}."
            return "date_query", reply, spoken, {"date": date_str}

        # 2. WEATHER INTENT
        if any(p in clean for p in ["weather", "temperature", "forecast", "is it raining", "how hot", "how cold"]):
            # Extract possible city
            city = "your location"
            city_match = re.search(r"in ([a-zA-Z\s]+)", clean)
            if city_match:
                city = city_match.group(1).title().strip()
            
            # Simulated realistic weather response with dynamic values
            temp_c = 24
            condition = "Partly Cloudy"
            humidity = "58%"
            reply = f"⛅ Weather for **{city}**:\n- **Condition**: {condition}\n- **Temperature**: {temp_c}°C / {int(temp_c * 9/5 + 32)}°F\n- **Humidity**: {humidity}\n- **Forecast**: Pleasant conditions continuing throughout the day."
            spoken = f"It's currently {temp_c} degrees Celsius and {condition.lower()} in {city} with pleasant conditions."
            return "weather_query", reply, spoken, {"city": city, "temperature_c": temp_c, "condition": condition}

        # 3. REMINDERS INTENT
        # Add reminder
        if any(clean.startswith(prefix) for prefix in ["remind me to", "remind me", "set a reminder", "create reminder", "add reminder"]):
            title = re.sub(r"^(remind me to|remind me|set a reminder to|create reminder to|add reminder to|set a reminder|create reminder|add reminder)\s*", "", clean, flags=re.IGNORECASE).strip()
            if not title:
                title = "voice command reminder"
            
            # Simple time extraction if present
            due_time = "Later today"
            time_match = re.search(r"(at|by|in)\s+(\d{1,2}(?::\d{2})?\s*(?:am|pm)?)", title, re.IGNORECASE)
            if time_match:
                due_time = time_match.group(2)
                title = title.replace(time_match.group(0), "").strip()

            new_rem = ReminderItem(
                id=f"rem-{uuid.uuid4().hex[:6]}",
                title=title.capitalize(),
                due_time=due_time,
                completed=False
            )
            REMINDERS_DB.append(new_rem)

            reply = f"✅ Reminder saved: **{new_rem.title}**\n- ⏰ Due: {new_rem.due_time}"
            spoken = f"I've created a reminder for {new_rem.title}."
            return "reminder_create", reply, spoken, {"reminder": new_rem.dict()}

        # List reminders
        if any(p in clean for p in ["my reminders", "show reminders", "list reminders", "what are my reminders", "any reminders"]):
            pending = [r for r in REMINDERS_DB if not r.completed]
            if not pending:
                reply = "📋 You have no active reminders."
                spoken = "You have no active reminders scheduled."
                return "reminder_list", reply, spoken, {"reminders": []}
            
            lines = [f"{i+1}. **{r.title}** ({r.due_time or 'No due time'})" for i, r in enumerate(pending)]
            reply = "📋 **Your Reminders:**\n" + "\n".join(lines)
            spoken = f"You have {len(pending)} pending reminder{'s' if len(pending) > 1 else ''}: " + ", ".join([r.title for r in pending[:3]])
            return "reminder_list", reply, spoken, {"reminders": [r.dict() for r in pending]}

        # 4. NOTES INTENT
        if any(clean.startswith(prefix) for prefix in ["take a note", "note down", "write down", "create a note", "new note"]):
            content = re.sub(r"^(take a note that|take a note|note down that|note down|write down that|write down|create a note|new note)\s*", "", clean, flags=re.IGNORECASE).strip()
            if not content:
                content = "Quick voice note captured by DARK AI."
            
            new_note = NoteItem(
                id=f"note-{uuid.uuid4().hex[:6]}",
                title=content[:24].capitalize() + ("..." if len(content) > 24 else ""),
                content=content
            )
            NOTES_DB.append(new_note)

            reply = f"📝 Note created:\n> *\"{new_note.content}\"*"
            spoken = f"Noted: {new_note.content}"
            return "note_create", reply, spoken, {"note": new_note.dict()}

        if any(p in clean for p in ["my notes", "show notes", "list notes", "what are my notes", "read my notes"]):
            if not NOTES_DB:
                reply = "📝 You haven't stored any notes yet."
                spoken = "You don't have any saved notes."
                return "note_list", reply, spoken, {"notes": []}
            
            lines = [f"- **{n.title}**: {n.content}" for n in NOTES_DB[-5:]]
            reply = "📝 **Recent Notes:**\n" + "\n".join(lines)
            spoken = f"You have {len(NOTES_DB)} notes. The latest is: {NOTES_DB[-1].title}."
            return "note_list", reply, spoken, {"notes": [n.dict() for n in NOTES_DB]}

        # 5. DEVICE & ASSISTANT CAPABILITIES
        if any(p in clean for p in ["who are you", "what are you", "what can you do", "introduce yourself"]):
            reply = (
                "🤖 **DARK AI Personal Assistant**\n\n"
                "I am DARK, your advanced voice-activated AI companion. Key features:\n"
                "• **Screen-Off Voice Activation**: Say *\"Hey Dark\"* even when your device is locked or the screen is dark.\n"
                "• **On-Device Keyword Spotting**: Local acoustic processing preserving full privacy.\n"
                "• **Hands-free Tasks**: Manage reminders, capture notes, check time and weather, and answer complex questions.\n"
                "• **High-speed Vocal Output**: Instant native Text-to-Speech playback."
            )
            spoken = "I am DARK, your voice-activated personal assistant. You can wake me anytime by saying Hey Dark, even when your screen is locked. How can I help you right now?"
            return "assistant_info", reply, spoken, {"status": "online"}

        if any(p in clean for p in ["battery", "battery status", "battery optimization"]):
            reply = (
                "🔋 **Battery & Background Optimization**\n\n"
                "DARK AI runs an energy-efficient Foreground Service with an on-device wake-word buffer.\n"
                "To ensure Android's Doze mode does not terminate listening while your screen is off, "
                "verify that **Battery Optimization Exemption** is enabled in DARK Settings."
            )
            spoken = "DARK is operating efficiently. Make sure battery optimization is exempted in settings for reliable screen-off wake word detection."
            return "battery_info", reply, spoken, {"service_status": "optimized"}

        # 6. GREETINGS & CASUAL
        if any(clean == g or clean.startswith(g + " ") for g in ["hello", "hi", "hey", "good morning", "good evening", "good afternoon"]):
            greeting = "Hello"
            if now.hour < 12:
                greeting = "Good morning"
            elif now.hour < 18:
                greeting = "Good afternoon"
            else:
                greeting = "Good evening"
            
            reply = f"👋 **{greeting}!** I am DARK, standing by. How can I assist you?"
            spoken = f"{greeting}. DARK is online and listening. How can I help?"
            return "greeting", reply, spoken, {}

        if any(p in clean for p in ["thank you", "thanks", "appreciate it"]):
            reply = "You're welcome! Let me know whenever you need anything else."
            spoken = "You are welcome. Standing by."
            return "gratitude", reply, spoken, {}

        # 7. GENERAL KNOWLEDGE & FALLBACK REASONING
        # Generates clear, concise spoken answer and visually rich markdown reply
        reply = (
            f"🧠 **DARK AI Analysis**\n\n"
            f"You asked: *\"{text}\"*\n\n"
            f"I have processed your request. DARK is ready to automate your tasks, answer queries, or manage your schedule. "
            f"If you'd like to set a reminder, take a note, or check the weather, just say the word."
        )
        spoken = f"I received your request: {text}. Standing by for your next command."
        return "general_reasoning", reply, spoken, {"query": text}
