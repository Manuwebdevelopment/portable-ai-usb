#!/usr/bin/env python3
"""
Portable AI USB Web Server
Flask-based server with session management, streaming, multimodal support,
rate limiting, and comprehensive API.
"""

import os
import sys
import json
import uuid
import glob
import time
import logging
import signal
import re
import hashlib
import base64
from datetime import datetime
from functools import wraps
from http import HTTPStatus
from io import BytesIO

import requests
from flask import (
    Flask, jsonify, request, send_from_directory, Response, 
    stream_with_context
)
from flask_cors import CORS

# Add server dir to path for config import
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import config

# ============================================================
# Logging Setup
# ============================================================
LOG_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "log")
os.makedirs(LOG_DIR, exist_ok=True)
LOG_FILE = os.path.join(LOG_DIR, "server.log")

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[
        logging.StreamHandler(sys.stdout),
        logging.FileHandler(LOG_FILE, encoding="utf-8"),
    ],
)
logger = logging.getLogger("portable-ai-usb")

# ============================================================
# Flask App Setup
# ============================================================
app = Flask(__name__, static_folder=None)
CORS(app)  # Enable CORS for cross-origin requests

# Rate limiting: in-memory bucket per IP
rate_limit_store = {}  # ip -> list of timestamps

def rate_limiter(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        if config.RATE_LIMIT_RPM <= 0:
            return f(*args, **kwargs)
        ip = request.remote_addr or "unknown"
        now = time.time()
        window = 60  # 1 minute
        if ip not in rate_limit_store:
            rate_limit_store[ip] = []
        # Clean old entries
        rate_limit_store[ip] = [t for t in rate_limit_store[ip] if now - t < window]
        if len(rate_limit_store[ip]) >= config.RATE_LIMIT_RPM:
            logger.warning(f"Rate limit exceeded for {ip}")
            return jsonify({"error": "Rate limit exceeded. Try again later."}), 429
        rate_limit_store[ip].append(now)
        return f(*args, **kwargs)
    return decorated

# ============================================================
# Conversation History Storage
# ============================================================
HISTORY_DIR = config.CONVERSATION_HISTORY_DIR
os.makedirs(HISTORY_DIR, exist_ok=True)

def _history_file(session_id):
    """Get the path to a session's history file."""
    return os.path.join(HISTORY_DIR, f"{session_id}.json")

def load_session(session_id):
    """Load conversation history for a session. Creates if new."""
    path = _history_file(session_id)
    if os.path.exists(path):
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    
    # Check if session exists but file was deleted
    return {
        "id": session_id,
        "name": f"Conversation {datetime.utcnow().strftime('%H:%M')}",
        "created": datetime.utcnow().isoformat() + "Z",
        "updated": datetime.utcnow().isoformat() + "Z",
        "messages": []
    }

def save_session(session):
    """Save conversation history."""
    session["updated"] = datetime.utcnow().isoformat() + "Z"
    path = _history_file(session["id"])
    with open(path, "w", encoding="utf-8") as f:
        json.dump(session, f, indent=2, ensure_ascii=False)

def list_sessions():
    """List all conversation sessions."""
    sessions = []
    for filepath in glob.glob(os.path.join(HISTORY_DIR, "*.json")):
        try:
            with open(filepath, "r", encoding="utf-8") as f:
                s = json.load(f)
            sessions.append({
                "id": s["id"],
                "name": s.get("name", "Unnamed"),
                "created": s.get("created", ""),
                "updated": s.get("updated", ""),
                "message_count": len(s.get("messages", []))
            })
        except (json.JSONDecodeError, IOError):
            logger.warning(f"Skipping corrupted history file: {filepath}")
            continue
    
    sessions.sort(key=lambda x: x["updated"], reverse=True)
    return sessions

def delete_session(session_id):
    """Delete a conversation session."""
    path = _history_file(session_id)
    if os.path.exists(path):
        os.remove(path)
        return True
    return False

def merge_sessions(from_id, to_id):
    """Merge messages from one session into another."""
    from_session = load_session(from_id)
    to_session = load_session(to_id)
    
    # Get messages from 'from' session that don't exist in 'to'
    to_message_ids = {id(m) for m in to_session.get("messages", [])}
    new_msgs = [m for m in from_session.get("messages", []) if id(m) not in to_message_ids]
    
    # Add timestamps if missing
    for msg in new_msgs:
        if "timestamp" not in msg:
            msg["timestamp"] = datetime.utcnow().isoformat() + "Z"
    
    to_session["messages"].extend(new_msgs)
    save_session(to_session)
    
    return {"merged_from": from_id, "merged_to": to_id, "messages_added": len(new_msgs)}

# ============================================================
# Ollama API Helper
# ============================================================
def ollama_request(method, path, **kwargs):
    """Make request to Ollama API with error handling."""
    url = f"{config.OLLAMA_HOST}{path}"
    try:
        kwargs.setdefault("timeout", config.OLLAMA_TIMEOUT)
        resp = requests.request(method, url, **kwargs)
        resp.raise_for_status()
        return resp
    except requests.exceptions.ConnectionError:
        logger.error(f"Ollama connection error: {url}")
        return None
    except requests.exceptions.Timeout:
        logger.error(f"Ollama timeout: {url}")
        return None
    except Exception as e:
        logger.error(f"Ollama API error: {e}")
        return None

# ============================================================
# Health Check
# ============================================================
@app.route("/api/health", methods=["GET"])
def health_check():
    """Health check endpoint."""
    ollama_ok = False
    try:
        resp = requests.get(f"{config.OLLAMA_HOST}/api/version", timeout=5)
        ollama_ok = resp.status_code == 200
    except Exception:
        pass
    
    return jsonify({
        "status": "running" if ollama_ok else "degraded",
        "ollama_connected": ollama_ok,
        "ollama_host": config.OLLAMA_HOST,
        "server_port": config.PORT,
        "history_dir": HISTORY_DIR,
        "sessions_count": len(list_sessions()),
        "timestamp": datetime.utcnow().isoformat() + "Z"
    })

# ============================================================
# Session Management Endpoints
# ============================================================
@app.route("/api/sessions", methods=["GET"])
def get_sessions():
    """List all conversation sessions."""
    return jsonify(list_sessions())

@app.route("/api/new-conversation", methods=["POST"])
def new_conversation():
    """Create a new conversation session."""
    session_id = str(uuid.uuid4())[:12]
    data = request.get_json() or {}
    
    session = {
        "id": session_id,
        "name": data.get("name", f"Conversation {datetime.utcnow().strftime('%H:%M')}"),
        "created": datetime.utcnow().isoformat() + "Z",
        "updated": datetime.utcnow().isoformat() + "Z",
        "messages": [],
        "settings": {
            "model": data.get("model", config.DEFAULT_MODEL),
            "system_prompt": data.get("system_prompt", config.SYSTEM_PROMPT),
            "temperature": data.get("temperature", 0.7),
            "max_tokens": data.get("max_tokens", config.MAX_TOKENS),
            "context_window": data.get("context_window", 10),
            "deep_thinking": data.get("deep_thinking", config.DEEP_THINKING_ENABLED)
        }
    }
    
    save_session(session)
    return jsonify(session)

@app.route("/api/session", methods=["GET"])
def get_session():
    """Load a single session."""
    sid = request.args.get("id")
    if not sid:
        return jsonify({"error": "Session ID required"}), 400
    
    session = load_session(sid)
    return jsonify(session)

@app.route("/api/session/history", methods=["GET"])
def get_session_history():
    """Get messages for a session."""
    sid = request.args.get("id")
    if not sid:
        return jsonify({"error": "Session ID required"}), 400
    
    session = load_session(sid)
    messages = session.get("messages", [])
    
    # Support limit parameter
    limit = request.args.get("limit")
    if limit and limit.isdigit():
        messages = messages[-int(limit):]
    
    return jsonify(messages)

@app.route("/api/session/rename", methods=["POST"])
def rename_session():
    """Rename a session."""
    data = request.get_json()
    sid = data.get("session_id") or data.get("id")
    name = data.get("name")
    
    if not sid or not name:
        return jsonify({"error": "session_id and name required"}), 400
    
    session = load_session(sid)
    session["name"] = name
    save_session(session)
    return jsonify(session)

@app.route("/api/session/merge", methods=["POST"])
def merge_session():
    """Merge two sessions."""
    data = request.get_json()
    from_id = data.get("from_id") or data.get("from")
    to_id = data.get("to_id") or data.get("to")
    
    if not from_id or not to_id:
        return jsonify({"error": "from_id and to_id required"}), 400
    
    result = merge_sessions(from_id, to_id)
    return jsonify(result)

@app.route("/api/session", methods=["DELETE"])
def remove_session():
    """Delete a session."""
    sid = request.args.get("id")
    if not sid:
        return jsonify({"error": "Session ID required"}), 400
    
    if delete_session(sid):
        return jsonify({"ok": True, "deleted": sid})
    return jsonify({"error": "Session not found"}), 404

@app.route("/api/session/export", methods=["GET"])
def export_session():
    """Export session as JSON for download/export."""
    sid = request.args.get("id")
    if not sid:
        return jsonify({"error": "Session ID required"}), 400
    
    session = load_session(sid)
    return jsonify({
        "session": session,
        "exported_at": datetime.utcnow().isoformat() + "Z",
        "format": "portable-ai-usb"
    })

@app.route("/api/history/import", methods=["POST"])
def import_history():
    """Import conversation history from JSON."""
    data = request.get_json()
    
    if "session" in data:
        session = data["session"]
        session_id = session.get("id", str(uuid.uuid4())[:12])
        
        # Ensure all messages have timestamps
        for msg in session.get("messages", []):
            if "timestamp" not in msg:
                msg["timestamp"] = datetime.utcnow().isoformat() + "Z"
        
        save_session(session)
        return jsonify({"ok": True, "session_id": session_id})
    
    # Import individual messages into current session
    sid = request.get_json().get("session_id") or request.get_json().get("session-id")
    messages = request.get_json().get("messages", [])
    
    if not sid:
        return jsonify({"error": "session_id required"}), 400
    
    session = load_session(sid)
    session["messages"].extend([{
        "role": m.get("role", "user"),
        "content": m.get("content", ""),
        "timestamp": m.get("timestamp", datetime.utcnow().isoformat() + "Z")
    } for m in messages])
    
    save_session(session)
    return jsonify({"ok": True, "added": len(messages)})

# ============================================================
# Model Management
# ============================================================
@app.route("/api/model/tags", methods=["GET"])
def get_model_tags():
    """Get list of available models from Ollama."""
    resp = ollama_request("GET", "/api/tags")
    if not resp:
        return jsonify({"error": "Cannot reach Ollama", "models": []}), 503
    return jsonify(resp.json())

@app.route("/api/model/show", methods=["GET"])
def show_model():
    """Show model details."""
    name = request.args.get("name")
    if not name:
        return jsonify({"error": "name required"}), 400
    
    resp = ollama_request("POST", "/api/show", json={"name": name})
    if not resp:
        return jsonify({"error": "Cannot reach Ollama"}), 503
    return jsonify(resp.json())

@app.route("/api/models/pull", methods=["POST"])
@rate_limiter
def pull_model():
    """Pull a model. Ollama supports async pull, so we start it."""
    data = request.get_json()
    model_id = data.get("model")
    
    if not model_id:
        return jsonify({"error": "model parameter required"}), 400
    
    resp = ollama_request("POST", "/api/pull", json={"model": model_id, "stream": False})
    if not resp:
        return jsonify({"error": "Failed to pull model"}), 503
    
    return jsonify({"status": "success", "model": model_id, "status_code": resp.status_code})

# ============================================================
# Settings
# ============================================================
@app.route("/api/settings", methods=["GET"])
def get_settings():
    """Get current settings."""
    return jsonify({
        "host": config.HOST,
        "port": config.PORT,
        "ollama_host": config.OLLAMA_HOST,
        "default_model": config.DEFAULT_MODEL,
        "system_prompt": config.SYSTEM_PROMPT,
        "deep_thinking": config.DEEP_THINKING_ENABLED,
        "max_tokens": config.MAX_TOKENS,
        "max_history_size": config.MAX_HISTORY_SIZE,
        "ui_theme": config.UI_THEME,
        "ui_language": config.UI_LANGUAGE,
        "rate_limit_rpm": config.RATE_LIMIT_RPM,
        "ollama_timeout": config.OLLAMA_TIMEOUT
    })

@app.route("/api/settings", methods=["POST"])
@rate_limiter
def update_settings():
    """Update server settings (only for this session)."""
    data = request.get_json()
    
    # Only allow updating runtime settings (not persistent config)
    updates = {}
    if "system_prompt" in data:
        config.SYSTEM_PROMPT = data["system_prompt"]
        updates["system_prompt"] = config.SYSTEM_PROMPT
    if "deep_thinking" in data:
        config.DEEP_THINKING_ENABLED = str(data["deep_thinking"]).lower() in ("true", "1", "yes")
        updates["deep_thinking"] = config.DEEP_THINKING_ENABLED
    if "max_tokens" in data:
        config.MAX_TOKENS = int(data["max_tokens"])
        updates["max_tokens"] = config.MAX_TOKENS
    if "ollama_host" in data:
        config.OLLAMA_HOST = data["ollama_host"]
        updates["ollama_host"] = config.OLLAMA_HOST
    if "default_model" in data:
        config.DEFAULT_MODEL = data["default_model"]
        updates["default_model"] = config.DEFAULT_MODEL
    
    logger.info(f"Settings updated: {updates}")
    return jsonify({"status": "ok", "settings": updates})

# ============================================================
# Chat Endpoint (with streaming, multimodal, etc.)
# ============================================================
@app.route("/api/chat", methods=["POST"])
@rate_limiter
def handle_chat():
    """Main chat endpoint with full support for streaming, multimodal, etc."""
    data = request.get_json()
    if not data:
        return jsonify({"error": "Invalid JSON"}), 400
    
    session_id = data.get("session_id", str(uuid.uuid4())[:12])
    user_message = data.get("message", "")
    
    if not user_message:
        return jsonify({"error": "message is required"}), 400
    
    # Load or create session
    session = load_session(session_id)
    session["name"] = data.get("name", session.get("name", "Conversation"))
    
    # Add user message
    user_msg = {
        "role": "user", 
        "content": user_message,
        "timestamp": datetime.utcnow().isoformat() + "Z"
    }
    
    # Handle image upload if present
    images = []
    if data.get("image"):
        image_data = data["image"]
        if isinstance(image_data, str) and image_data.startswith("data:"):
            # base64 data URL
            image_data = image_data.split(",")[1]
        images.append(base64.b64decode(image_data))
        user_msg["images"] = True  # Flag that this message has an image
    
    session["messages"].append(user_msg)
    
    # Determine model and settings
    model = data.get("model", config.DEFAULT_MODEL)
    temperature = data.get("temperature", 0.7)
    max_tokens = data.get("max_tokens", config.MAX_TOKENS)
    context_window = data.get("context_window", min(10, config.MAX_HISTORY_SIZE))
    deep_thinking = data.get("deep_thinking", config.DEEP_THINKING_ENABLED)
    system_prompt = data.get("system_prompt", config.SYSTEM_PROMPT)
    
    # Add deep thinking system prompt addition
    if deep_thinking:
        thinking_prompt = ("You are a helpful AI assistant with enhanced reasoning capabilities. "
                          "Before answering, please think through the problem step by step. "
                          "Provide clear, detailed explanations for your reasoning.")
        if system_prompt:
            system_prompt = system_prompt + "\n\n" + thinking_prompt
        else:
            system_prompt = thinking_prompt
    
    # Build context from recent messages
    all_messages = session["messages"]
    recent_msgs = all_messages[-context_window:] if len(all_messages) > 1 else [user_msg]
    
    # Filter out image data from messages for Ollama
    context_for_ollama = []
    for msg in recent_msgs:
        cleaned = {k: v for k, v in msg.items() if k != "images"}
        context_for_ollama.append(cleaned)
    
    # If system prompt exists, prepend
    if system_prompt:
        context_for_ollama = [{"role": "system", "content": system_prompt}] + context_for_ollama
    
    # Build request payload
    stream = data.get("stream", False)
    payload = {
        "model": model,
        "messages": context_for_ollama,
        "stream": stream,
        "options": {
            "temperature": temperature,
            "num_predict": max_tokens
        }
    }
    
    # Add images for multimodal support
    if images:
        payload["images"] = [base64.b64encode(img).decode("utf-8") for img in images]
    
    try:
        if stream:
            # Streaming response with SSE
            def generate():
                assistant_content = ""
                try:
                    resp = requests.post(
                        f"{config.OLLAMA_HOST}/api/chat",
                        json=payload,
                        timeout=config.OLLAMA_TIMEOUT,
                        stream=True
                    )
                    resp.raise_for_status()
                    
                    for line in resp.iter_lines():
                        if line:
                            chunk = json.loads(line.decode("utf-8"))
                            delta = chunk.get("message", {}).get("content", "")
                            if delta:
                                assistant_content += delta
                                yield f"data: {json.dumps(delta)}\n\n"
                    
                    # Final delta with [DONE] marker
                    yield f"data: {json.dumps(assistant_content)}\n\n"
                    yield "data: [DONE]\n\n"
                    
                    # Save assistant response
                    session["messages"].append({
                        "role": "assistant",
                        "content": assistant_content,
                        "timestamp": datetime.utcnow().isoformat() + "Z"
                    })
                    save_session(session)
                except Exception as e:
                    error_data = {"error": str(e)}
                    yield f"data: {json.dumps(error_data)}\n\n"
                    yield "data: [DONE]\n\n"
            
            return Response(
                stream_with_context(generate()),
                content_type="text/event-stream",
                headers={
                    "Cache-Control": "no-cache",
                    "X-Accel-Buffering": "no"  # Disable nginx buffering
                }
            )
        else:
            # Non-streaming response
            resp = requests.post(
                f"{config.OLLAMA_HOST}/api/chat",
                json=payload,
                timeout=config.OLLAMA_TIMEOUT
            )
            resp.raise_for_status()
            
            result = resp.json()
            assistant_content = result.get("message", {}).get("content", "")
            
            session["messages"].append({
                "role": "assistant",
                "content": assistant_content,
                "timestamp": datetime.utcnow().isoformat() + "Z"
            })
            save_session(session)
            
            return jsonify({
                "session_id": session_id,
                "message": assistant_content,
                "model": model,
                "context_window": context_window,
                "total_messages": len(session["messages"])
            })
    
    except requests.exceptions.ConnectionError:
        return jsonify({"error": "Ollama not connected. Is Ollama running?"}), 502
    except requests.exceptions.Timeout:
        return jsonify({"error": "Ollama request timed out"}), 504
    except Exception as e:
        logger.error(f"Chat error: {e}")
        return jsonify({"error": f"Chat error: {str(e)}"}), 500

# ============================================================
# Image Upload for Multimodal Support
# ============================================================
@app.route("/api/upload", methods=["POST"])
@rate_limiter
def upload_image():
    """Handle image upload for multimodal conversations."""
    if "file" in request.files:
        file = request.files["file"]
        if file.filename == "":
            return jsonify({"error": "No file selected"}), 400
        
        # Read and base64 encode
        img_data = file.read()
        b64_data = base64.b64encode(img_data).decode("utf-8")
        mime_type = file.content_type or "image/png"
        
        return jsonify({
            "success": True,
            "filename": file.filename,
            "size": len(img_data),
            "mime_type": mime_type,
            "base64": f"data:{mime_type};base64,{b64_data}"
        })
    
    return jsonify({"error": "No file in request"}), 400

# ============================================================
# Static File Serving (HTML + CSS)
# ============================================================
SERVER_DIR = os.path.dirname(os.path.abspath(__file__))

@app.route("/")
def serve_index():
    """Serve the main UI."""
    return send_from_directory(SERVER_DIR, "ui.html")

@app.route("/ui.html")
def serve_ui_html():
    """Serve the UI HTML."""
    return send_from_directory(SERVER_DIR, "ui.html")

@app.route("/static/uikit.css")
def serve_ui_css():
    """Serve the CSS."""
    return send_from_directory(SERVER_DIR, "ui.css")

@app.route("/ui.css")
def serve_css():
    """Serve the CSS."""
    return send_from_directory(SERVER_DIR, "ui.css")

# ============================================================
# Proxy Ollama API Endpoints
# ============================================================
@app.route("/api/<path:path>", methods=["GET", "POST", "PUT", "DELETE"])
def proxy_ollama(path):
    """Proxy Ollama API endpoints."""
    url = f"{config.OLLAMA_HOST}/api/{path}"
    
    if request.method == "GET":
        resp = requests.get(url, params=request.args, timeout=config.OLLAMA_TIMEOUT)
    elif request.method == "POST":
        resp = requests.post(url, json=request.get_json() if request.is_json else {}, timeout=config.OLLAMA_TIMEOUT)
    elif request.method == "PUT":
        resp = requests.put(url, json=request.get_json() if request.is_json else {}, timeout=config.OLLAMA_TIMEOUT)
    elif request.method == "DELETE":
        resp = requests.delete(url, json=request.get_json() if request.is_json else {}, timeout=config.OLLAMA_TIMEOUT)
    else:
        return jsonify({"error": "Method not allowed"}), 405
    
    resp.raise_for_status()
    return jsonify(resp.json())

# ============================================================
# Graceful Shutdown
# ============================================================
def shutdown_gracefully(signum, frame):
    """Handle graceful shutdown on SIGINT/SIGTERM."""
    logger.info("Received shutdown signal, stopping server...")
    sys.exit(0)

signal.signal(signal.SIGINT, shutdown_gracefully)
signal.signal(signal.SIGTERM, shutdown_gracefully)

# ============================================================
# Main Entry Point
# ============================================================
if __name__ == "__main__":
    logger.info("=" * 60)
    logger.info("Starting Portable AI USB Web Server")
    logger.info(f"  Host: {config.HOST}")
    logger.info(f"  Port: {config.PORT}")
    logger.info(f"  Ollama: {config.OLLAMA_HOST}")
    logger.info(f"  Default Model: {config.DEFAULT_MODEL}")
    logger.info(f"  Deep Thinking: {config.DEEP_THINKING_ENABLED}")
    logger.info(f"  Rate Limit: {config.RATE_LIMIT_RPM} RPM")
    logger.info(f"  Max Tokens: {config.MAX_TOKENS}")
    logger.info(f"  History Dir: {HISTORY_DIR}")
    logger.info("-" * 60)
    
    app.run(
        host=config.HOST,
        port=config.PORT,
        debug=False,
        threaded=True,
        use_reloader=False
    )
