#!/bin/bash
# Start Portable AI USB Web Server
# Runs on host PC, serves models from USB

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USB_ROOT="$(dirname "$SCRIPT_DIR")"
LOG_FILE="$USB_ROOT/log/server.log"

mkdir -p "$USB_ROOT/log"

# Configuration
export WEB_PORT="${WEB_PORT:-8080}"
export OLLAMA_HOST="${OLLAMA_HOST:-http://localhost:11434}"
export DEFAULT_MODEL="${DEFAULT_MODEL:-qwen2.5:7b}"

# Check Ollama
echo "Checking Ollama..."
if ! command -v ollama &> /dev/null; then
    echo "❌ Ollama not found. Run ollama install first!"
    exit 1
fi

# Check Ollama is running
if ! curl -s http://localhost:11434/api/version &> /dev/null; then
    echo "❌ Ollama not running. Start Ollama first!"
    echo "   Run: ollama serve"
    exit 1
fi

# Start web server
echo "✅ Starting Portable AI USB Web Server"
echo "   Port: $WEB_PORT"
echo "   Model: $DEFAULT_MODEL"
echo "   Logs: $LOG_FILE"
echo "   Open browser: http://localhost:$WEB_PORT"

python3 "$USB_ROOT/server/web_server.py" >> "$LOG_FILE" 2>&1 &

SERVER_PID=$!
echo "Server PID: $SERVER_PID"

# Cleanup on exit
cleanup() {
    echo "Stopping server..."
    kill "$SERVER_PID" 2>/dev/null || true
    wait "$SERVER_PID" 2>/dev/null || true
    echo "Server stopped."
}
trap cleanup EXIT

# Wait for server to start
sleep 2

echo "Server started successfully!"
echo "Open: http://localhost:$WEB_PORT"
