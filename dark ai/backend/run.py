import uvicorn
import os
import sys

# Ensure backend root is on sys.path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

if __name__ == "__main__":
    port = int(os.environ.get("DARK_PORT", 8000))
    host = os.environ.get("DARK_HOST", "0.0.0.0")
    print(f"🚀 Starting DARK AI Assistant Backend on http://{host}:{port}...")
    uvicorn.run("app.main:app", host=host, port=port, reload=True)
