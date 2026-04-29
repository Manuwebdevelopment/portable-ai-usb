#!/bin/bash
# Configuration generation script
# Creates platform-specific configs and .env files

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USB_ROOT="$(dirname "$SCRIPT_DIR")"
CONFIG_DIR="$USB_ROOT/config"
LOG_FILE="$USB_ROOT/log/config.log"

mkdir -p "$CONFIG_DIR" "$USB_ROOT/log"

echo "=== Generating Configuration ===" | tee -a "$LOG_FILE"

# Generate .env file
cat > "$CONFIG_DIR/.env" <<'ENV'
# Portable AI USB Configuration
# Edit this file to customize settings

# Model token limit (default 4096, increase for better context)
OLLAMA_MODEL_TOKEN_LIMIT=4096

# Model context size (8192 for better long-context handling)
OLLAMA_CONTEXT_SIZE=8192

# Default model to load on startup (change to your preference)
DEFAULT_MODEL=qwen2.5:7b

# Enable GPU acceleration (true/false)
OLLAMA_GPU_ENABLED=true

# Temperature (0.0 = deterministic, 1.0 = creative)
OLLAMA_TEMPERATURE=0.7

# Top P (nucleus sampling)
OLLAMA_TOP_P=0.9

# Number of threads for CPU inference
OLLAMA_NUM_THREADS=0

# GPU layers for Metal/NVIDIA
OLLAMA_NUM_GPU=-1

# AnythingLLM config
ANYTHINGLLM_PORT=3000
ANYTHINGLLM_DEBUG=false

# Log level (debug|info|warn|error)
LOG_LEVEL=info

# Auto-download missing models
AUTO_DOWNLOAD=true

# Check for updates
CHECK_UPDATES=false

ENV

echo "Generated: $CONFIG_DIR/.env" | tee -a "$LOG_FILE"

# Generate platform-specific launcher config
if [[ "$OSTYPE" == "darwin"* ]]; then
    cat > "$CONFIG_DIR/launcher-mac.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>org.ollama.portable-ai-usb</string>
    <key>ProgramArguments</key>
    <array>
        <string>[WORKING_DIR]/ollama/ollama</string>
        <string>serve</string>
    </array>
    <key>WorkingDirectory</key>
    <string>[WORKING_DIR]</string>
</dict>
</plist>
PLIST
    echo "Generated: launcher-mac.plist" | tee -a "$LOG_FILE"
fi

# Generate Windows config
cat > "$CONFIG_DIR/launcher-windows.bat" <<'BAT'
@echo off
REM Windows Launcher for Portable AI USB
REM Run this from the USB drive

set USB_ROOT=%~dp0
set MODELS_DIR=%USB_ROOT%models
set OLLAMA_EXE=%USB_ROOT%ollama\ollama.exe
set ANYTHINGLLM=%USB_ROOT%anythingllm\app.exe

echo Starting Portable AI USB...
echo.

REM Start Ollama in background
start "" "%OLLAMA_EXE%" serve

echo Ollama started. Waiting for startup...
timeout /t 5

REM Open AnythingLLM
start "" "%ANYTHINGLLM%"

REM Keep terminal open
echo.
echo Press any key to shut down...
pause
BAT

echo "Generated: launcher-windows.bat" | tee -a "$LOG_FILE"

# Generate Linux launcher
cat > "$USB_ROOT/scripts/install/launcher-linux.sh" <<'LINUX'
#!/bin/bash
# Linux Launcher for Portable AI USB

USB_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODELS_DIR="$USB_ROOT/models"
OLLAMA_DIR="$USB_ROOT/ollama"
ANYTHINGLLM_DIR="$USB_ROOT/anythingllm"

echo "Starting Portable AI USB on Linux..."
echo "======================================"

# Start Ollama
OLLAMA="$OLLAMA_DIR/ollama"
if [[ -f "$OLLAMA" ]]; then
    $OLLAMA serve || ollama serve
else
    echo "⚠️  Ollama not found in $OLLAMA_DIR"
    echo "   Please install ollama globally first"
    echo "   curl -fsSL https://ollama.com/install.sh | sh"
    exit 1
fi

# Wait for Ollama to start
sleep 2

# Open AnythingLLM
if [[ -f "$ANYTHINGLLM_DIR/anythingllm.AppImage" ]]; then
    echo "Opening AnythingLLM..."
    xdg-open "$ANYTHINGLLM_DIR/anythingllm.AppImage" || \
    xdg-open "$ANYTHINGLLM_DIR/anythingllm.AppRun" || \
    xdg-open "$ANYTHINGLLM_DIR"
elif command -v ollama &> /dev/null; then
    # Fallback: open browser to ollama UI
    echo "Opening Ollama UI in browser..."
    xdg-open "http://localhost:11434"
fi

# Keep terminal open
echo ""
echo "Portable AI USB is running..."
echo "Press Ctrl+C to shut down"
LINUX

chmod +x "$USB_ROOT/scripts/install/launcher-linux.sh"
echo "Generated: scripts/install/launcher-linux.sh" | tee -a "$LOG_FILE"

echo ""
echo "=== Configuration Complete ===" | tee -a "$LOG_FILE"

cat "$CONFIG_DIR/.env"
