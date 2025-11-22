from flask import Flask, jsonify
import os
import sys

app = Flask(__name__)

CRASH_FLAG = False

@app.route("/")
def hello():
    return jsonify({"message": "Hello from DevOps"})

@app.route("/crash")
def crash():
    """
    Endpoint to trigger a crash.
    - With Gunicorn + --preload: force exit master with os._exit(1)
    - With Flask dev server: mark pod unhealthy
    """
    if os.environ.get("USE_GUNICORN_CRASH") == "1":
        print("Crashing master (Gunicorn) now...", file=sys.stderr)
        sys.stderr.flush()
        os._exit(1)
    else:
        global CRASH_FLAG
        CRASH_FLAG = True
        return "Pod will be marked unhealthy soon", 200

@app.route("/health")
def health():
    if CRASH_FLAG:
        return "unhealthy", 500
    return jsonify({"status": "ok"})

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    
    # Optional crash on start for testing
    if os.environ.get("CRASH_ON_START") == "1":
        print("Crashing on start as requested", file=sys.stderr)
        sys.stderr.flush()
        os._exit(1)
    
    app.run(host="0.0.0.0", port=port)
