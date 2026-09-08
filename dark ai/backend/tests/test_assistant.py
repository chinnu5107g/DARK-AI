from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_health():
    response = client.get("/api/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "online"
    assert "wake_word_activation" in data["capabilities"]

def test_root():
    response = client.get("/")
    assert response.status_code == 200
    assert response.json()["app"] == "DARK AI"

def test_chat_time_query():
    response = client.post("/api/chat", json={"message": "what time is it", "source": "voice"})
    assert response.status_code == 200
    data = response.json()
    assert data["intent"] == "time_query"
    assert "time is" in data["spoken_text"].lower()

def test_chat_weather():
    response = client.post("/api/chat", json={"message": "how is the weather in Tokyo", "source": "voice"})
    assert response.status_code == 200
    data = response.json()
    assert data["intent"] == "weather_query"
    assert "Tokyo" in data["reply"]
    assert "degrees" in data["spoken_text"].lower()

def test_create_reminder():
    response = client.post("/api/chat", json={"message": "remind me to review voice activation code at 4pm", "source": "voice"})
    assert response.status_code == 200
    data = response.json()
    assert data["intent"] == "reminder_create"
    assert "reminder" in data["spoken_text"].lower()

def test_voice_process_endpoint():
    response = client.post("/api/voice/process", json={
        "command": "who are you",
        "wake_phrase": "Hey Dark",
        "screen_off": True
    })
    assert response.status_code == 200
    data = response.json()
    assert data["intent"] == "assistant_info"
    assert "DARK" in data["spoken_text"]
