#!/usr/bin/env python3
"""
Web Server Configuration for Portable AI USB
Simple HTTP server for AI chat interface
"""

import os

# Server Settings
HOST = "localhost"
PORT = int(os.getenv("WEB_PORT", "8080"))
OLLAMA_HOST = os.getenv("OLLAMA_HOST", "http://localhost:11434")

# Model Settings
DEFAULT_MODEL = os.getenv("DEFAULT_MODEL", "qwen2.5:7b")

# UI Settings
UI_THEME = os.getenv("UI_THEME", "dark")
UI_LANGUAGE = os.getenv("UI_LANGUAGE", "en")

# Storage
CONVERSATION_HISTORY_DIR = os.getenv("HISTORY_FILE", os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "data", "history"))

# API Limits
MAX_TOKENS = int(os.getenv("MAX_TOKENS", "4096"))
MAX_HISTORY_SIZE = int(os.getenv("MAX_HISTORY_SIZE", "20"))

# System Prompt
SYSTEM_PROMPT = os.getenv("SYSTEM_PROMPT", "")

# Deepthinking mode (longer context, more thinking tokens)
DEEP_THINKING_ENABLED = os.getenv("DEEP_THINKING_ENABLED", "false").lower() in ("true", "1", "yes")

# Rate limiting (requests per minute per IP)
RATE_LIMIT_RPM = int(os.getenv("RATE_LIMIT_RPM", "30"))

# Ollama timeout (seconds)
OLLAMA_TIMEOUT = int(os.getenv("OLLAMA_TIMEOUT", "120"))

print(f"Server config loaded: host={HOST}, port={PORT}, model={DEFAULT_MODEL}")
