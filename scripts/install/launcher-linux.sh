#!/bin/bash
# Linux Launcher for Portable AI USB

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USB_ROOT="$(dirname "$SCRIPT_DIR")"
MODELS_DIR="$USB_ROOT/models"
OLLAMA_DIR="$USB_ROOT/ollama"
ANYTHINGLLM_DIR="$USB_ROOT/anythingllm"
CONFIG_DIR="$USB_ROOT/config"
LOG_FILE="$USB_ROOT/log/launcher.log"

mkdir -p "$USB_ROOT/log"

echo "Portable AI USB - Linux Launcher" | tee -a "$LOG_FILE"
echo "=================================" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Check if already running
if curl -s http://localhost:11434/api/tags &> /dev/null; then
    echo "✅ Ollama is already running" | tee -a "$LOG_FILE"
    echo "Opening AnythingLLM..." | tee -a "$LOG_FILE"
    
    # Try to open AnythingLLm
    if [[ -f "$ANYTHINGLLM_DIR/anythingllm.AppImage" ]]; then
        echo "Opening AnythingLLM..." | tee -a "$LOG_FILE"
        "$ANYTHINGLLM_DIR/anythingllm.AppImage" &
        disown
    elif [[ -f "$ANYTHINGLLM_DIR/anythingllm.AppRun" ]]; then
        echo "Opening AnythingLLM (.AppRun)..." | tee -a "$LOG_FILE"
        "$ANYTHINGLLM_DIR/anythingllm.AppRun" &
        disown
    elif [[ -d "$ANYTHINGLLM_DIR" ]]; then
        xdg-open "$ANYTHINGLLM_DIR"
    else
        # Fallback: open browser
        echo "Opening Ollama UI in browser..." | tee -a "$LOG_FILE"
        xdg-open "http://localhost:11434" 2>/dev/null || echo "No X11 display found"
    fi
else
    echo "📥 Starting Ollama..." | tee -a "$LOG_FILE"
    
    # Check for Ollama binary
    if [[ -f "$OLLAMA_DIR/ollama" ]]; then
        "$OLLAMA_DIR/ollama" serve &
        OLLAMA_PID=$!
        echo "Started with PID: $OLLAMA_PID" | tee -a "$LOG_FILE"
        
        # Wait for startup
        sleep 3
        
        # Check if ready
        if curl -s http://localhost:11434/api/tags &> /dev/null; then
            echo "✅ Ollama started successfully" | tee -a "$LOG_FILE"
            
            # Try to open AnythingLLM
            if [[ -f "$ANYTHINGLLM_DIR/anythingllm.AppImage" ]]; then
                echo "Opening AnythingLLM..." | tee -a "$LOG_FILE"
                "$ANYTHINGLLM_DIR/anythingllm.AppImage" &
                disown
            elif command -v ollama &> /dev/null; then
                xdg-open "http://localhost:11434"
            else
                echo "⚠️  AnythingLLM not found. Use: ollama chat <model>" | tee -a "$LOG_FILE"
            fi
        else
            echo "⚠️  Ollama started but not ready yet" | tee -a "$LOG_FILE"
            xdg-open "http://localhost:11434" 2>/dev/null || true
        fi
    else
        echo "❌ Ollama not found at $OLLAMA_DIR/ollama" | tee -a "$LOG_FILE"
        echo "Install ollama with: curl -fsSL https://ollama.com/install.sh | sh" | tee -a "$LOG_FILE"
    fi
fi

echo "" | tee -a "$LOG_FILE"
echo "Portable AI USB is running..." | tee -a "$LOG_FILE"
echo "Press Ctrl+C to shut down" | tee -a "$LOG_FILE"

# Trap Ctrl+C for clean shutdown
trap 'echo ""; echo "Shutting down..."; kill $OLLAMA_PID 2>/dev/null; exit 1' SIGINT SIGTERM
