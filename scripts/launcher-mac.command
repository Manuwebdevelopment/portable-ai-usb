#!/bin/bash
# macOS Launcher for Portable AI USB (v0.3.20 compatible)
# Usage: ./launcher-mac.command [--port PORT] [--model MODEL] [--verbose]

set -euo pipefail

# ─── Defaults ───────────────────────────────────────────
PORT=11434
MODEL="qwen2.5"
LOG_DIR="$HOME/.portable-ai-usb/logs"
LOG_FILE="$LOG_DIR/launcher_$(date +%Y%m%d_%H%M%S).log"
MODELS_DIR="$HOME/.portable-ai-usb/models"
OLLAMA_HOME="$HOME/.portable-ai-usb/ollama"
export OLLAMA_MODELS="$MODELS_DIR"
export OLLAMA_HOST="127.0.0.1:$PORT"

mkdir -p "$LOG_DIR" "$MODELS_DIR" "$OLLAMA_HOME"

# ─── Argument parsing ───────────────────────────────────
while [[ $# -gt 0 ]]; do
    case "$1" in
        --port)  PORT="$2"; shift 2 ;;
        --model) MODEL="$2"; shift 2 ;;
        --verbose)
            set -x
            OLLAMA_DEBUG=1
            export OLLAMA_DEBUG
            shift ;;
        -h|--help)
            cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Options:
  --port PORT       Port for Ollama to listen on (default: $PORT)
  --model MODEL     Model to use (default: $(basename $MODEL))
  --verbose         Show debug output
  -h, --help        Show this help message
EOF
            exit 0 ;;
        *)
            echo "❌ Unknown option: $1"
            exit 1 ;;
    esac
done

# ─── Check for Ollama ───────────────────────────────────
if ! command -v ollama &>/dev/null; then
    echo "⚠️  Ollama not found. Installing..."
    brew install ollama 2>/dev/null || {
        echo "⚠️  brew not found. Trying curl install..."
        curl -fsSL https://ollama.com/install.sh | sh
    }
fi

# ─── Check if Ollama is already running ─────────────────
if ollama list &>/dev/null 2>&1; then
    echo "✅ Ollama is already running on port $PORT"
    # Just open the UI
    open "http://localhost:$PORT" 2>/dev/null &
    exit 0
fi

# ─── Start Ollama ─────────────────────────────────────━━
echo "🚀 Starting Portable AI USB..."
ollama serve --port $PORT &
OLLAMA_PID=$!

# Wait for Ollama to become ready
echo "⏳ Waiting for Ollama to start..."
for i in {1..30}; do
    if ollama list &>/dev/null 2>&1; then
        echo "✅ Ollama is running (PID: $OLLAMA_PID)"
        break
    fi
    sleep 1
done

# ─── Open UI ────────────────────────────────────────────
open "http://localhost:$PORT" 2>/dev/null &

echo "✅ Portable AI USB is now running!"
echo "   - Ollama on http://localhost:$PORT"
echo "   - Models in: $MODELS_DIR"
echo "   - Logs in: $LOG_DIR"
echo ""
echo "   Type 'exit' or press Ctrl+C to stop."

# Keep the script running
wait $OLLAMA_PID 2>/dev/null || true
