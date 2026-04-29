#!/bin/bash
# macOS Launcher for Portable AI USB

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USB_ROOT="$(dirname "$SCRIPT_DIR")"
MODELS_DIR="$USB_ROOT/models"
OLLAMA_DIR="$USB_ROOT/ollama"
ANYTHINGLLM_DIR="$USB_ROOT/anythingllm"
CONFIG_DIR="$USB_ROOT/config"
LOG_FILE="$USB_ROOT/log/launcher.log"

mkdir -p "$USB_ROOT/log"

echo "Portable AI USB - macOS Launcher"
echo "=========================="
echo ""

# Check if already running
if ollama list &> /dev/null; then
    echo "✅ Ollama is already running"
    
    # Open AnythingLLM if installed
    if [[ -d "$ANYTHINGLLM_DIR" ]]; then
        open "$ANYTHINGLLM_DIR"
    elif command -v open &> /dev/null; then
        open "http://localhost:3000"
    fi
else
    echo "📥 Starting Ollama..."
    
    # Check for Ollama binary
    if [[ -f "$OLLAMA_DIR/ollama" ]]; then
        # Kill any existing ollama process
        pkill ollama 2>/dev/null
        
        # Start Ollama
        "$OLLAMA_DIR/ollama" serve &
        OLLAMA_PID=$!
        echo "Started with PID: $OLLAMA_PID"
        
        # Wait for startup
        sleep 3
        
        # Check if ready
        if ollama list &> /dev/null; then
            echo "✅ Ollama started successfully"
            
            # Try to open AnythingLLM
            if [[ -d "$ANYTHINGLLM_DIR" ]]; then
                open "$ANYTHINGLLM_DIR"
            else
                open "http://localhost:11434"
            fi
        else
            echo "⚠️  Ollama started but not ready yet"
            open "http://localhost:11434"
        fi
    else
        echo "❌ Ollama not found at $OLLAMA_DIR/ollama"
        echo "Install ollama with:"
        echo "   brew install ollama"
        echo "   or download from: https://ollama.com/download"
    fi
fi

echo ""
echo "Portable AI USB is running..."
echo "Press Ctrl+C to shut down"

# Trap Ctrl+C for clean shutdown
trap 'echo ""; echo "Shutting down..."; kill $OLLAMA_PID 2>/dev/null; exit 1' SIGINT SIGTERM
