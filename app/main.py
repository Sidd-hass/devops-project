from flask import Flask, jsonify, request
import os
import sys
import time

app = Flask(__name__)

CRASH_FLAG = os.environ.get("CRASH_ME", "0")

@app.route("/")
def hello():
    return jsonify({"message": "Hello from DevOps"})

@app.route("/health")
def health():
    # readiness/liveness endpoint
    return jsonify({"status": "ok"})

@app.route("/crash")
def crash():
    # Endpoint to intentionally crash the process for failure simulation
    # Kubernetes liveness probe will detect and restart the pod
    print("Crashing now...", file=sys.stderr)
    sys.stderr.flush()
    os._exit(1)

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    # Optional crash-on-start for simulation: set CRASH_ON_START=1 in env
    if os.environ.get("CRASH_ON_START") == "1":
        print("Crashing on start as requested", file=sys.stderr)
        os._exit(1)
    app.run(host="0.0.0.0", port=port)
