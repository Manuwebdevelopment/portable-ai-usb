#!/bin/bash
# Main installation script for Portable AI USB
# One-time setup - downloads models, configures Ollama, sets up AnythingLLM

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USB_ROOT="$(dirname "$SCRIPT_DIR")"
MODELS_DIR="$USB_ROOT/models"
OLLAMA_DIR="$USB_ROOT/ollama"
ANYTHINGLLM_DIR="$USB_ROOT/anythingllm"
LOG_FILE="$USB_ROOT/log/setup.log"
STATE_FILE="$USB_ROOT/.installation_state"

mkdir -p "$MODELS_DIR" "$OLLAMA_DIR" "$USB_ROOT/log"

echo "=========================================" > "$LOG_FILE"
echo "Portable AI USB - Setup Script" >> "$LOG_FILE"
echo "Started: $(date)" >> "$LOG_FILE"
echo "=========================================" >> "$LOG_FILE"
echo ""

# Check if already installed
if [[ -f "$STATE_FILE" ]]; then
    echo "⚠️  Already installed. Run cleanup.sh to reset or use start-[platform].sh"
    cat "$STATE_FILE"
    exit 0
fi

echo "🚀 Initializing Portable AI USB..."
echo "========================================="

# Create required directories
echo "Creating directories..."
mkdir -p "$MODELS_DIR" "$OLLAMA_DIR" "$ANYTHINGLLM_DIR" "$USB_ROOT/config" "$USB_ROOT/log"

# Generate configuration
echo "Generating configuration..."
"$SCRIPT_DIR/install/config.sh"

# Check and install Ollama engine
echo "Checking Ollama engine..."
if ! command -v ollama &> /dev/null; then
    echo "📥 Downloading Ollama engine..."
    
    # Detect platform
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        OLLAMA_URL="https://github.com/ollama/ollama/releases/download/v0.3.20/ollama-darwin-aarch64"
        if [[ "$(uname -m)" == "x86_64" ]]; then
            OLLAMA_URL="https://github.com/ollama/ollama/releases/download/v0.3.20/ollama-darwin-amd64"
        fi
        curl -L -o "$OLLAMA_DIR/ollama" "$OLLAMA_URL"
        chmod +x "$OLLAMA_DIR/ollama"
        mv "$OLLAMA_DIR/ollama" /usr/local/bin/ollama 2>/dev/null || \
            mv "$OLLAMA_DIR/ollama" "$OLLAMA_DIR/ollama-run"
    elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
        # Windows
        OLLAMA_URL="https://github.com/ollama/ollama/releases/download/v0.3.20/OllamaSetup.exe"
        curl -L -o "$OLLAMA_DIR/ollama.exe" "$OLLAMA_URL"
        echo "⚠️  Please run ollama.exe manually and install on the USB"
    else
        # Linux
        # Use existing ollama or download appropriate version
        if ! command -v ollama &> /dev/null; then
            echo "⚠️  Install ollama on this system first:"
            echo "   curl -fsSL https://ollama.com/install.sh | sh"
        fi
    fi
else
    echo "✅ Ollama engine already installed"
fi

# Download model based on RAM detection
echo ""
echo "📊 System detected:"
if [[ "$OSTYPE" == "darwin"* ]]; then
    if [[ "$(uname -m)" == "arm64" ]]; then
        RAM=$(sysctl hw.memsize | awk '{print int($2/1024/1024/1024)}')
        echo "  Apple Silicon with ${RAM}GB RAM"
        
        if ((RAM >= 16)); then
            echo "📥 Downloading NemoMix Unleashed 12B (recommended)..."
            # TODO: Add NemoMix download
            echo "⏳ After manual download: cp NemoMix.gguf $MODELS_DIR/"
        elif ((RAM >= 8)); then
            echo "📥 Downloading Qwen 2.5 7B..."
            ollama pull qwen2.5:7b
            ollama pull qwen2:7b-instruct
            ollama create qwen7b-instruct -f /dev/stdin <<'EOF'
FROM qwen2:7b-instruct
SYSTEM "You are a helpful AI assistant."
EOF
        else
            echo "📥 Downloading Llama 3.2 3B (lightweight)..."
            ollama pull llama3.2:3b
            ollama pull phi3.5:mini
        fi
    fi
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    # Windows
    echo "📥 Available models for Windows:"
    echo "   ollama pull nemo-mix-unleashed:12b"
    echo "   ollama pull dolphin:2.9llama3:8b"
    echo "   ollama pull mistral:instruct"
    echo "   ollama pull qwen2.5:7b"
    echo "   ollama pull llama3.2:3b"
    echo "   ollama pull phi3.5:mini"
else
    echo "📥 Linux - models can be pulled with ollama pull"
fi

echo ""
echo "========================================="
echo "Setup complete!"
echo "========================================="
echo "Next steps:"
echo "1. Download desired models (if not done above)"
echo "2. Configure AnythingLLM in $ANYTHINGLLM_DIR"
echo "3. Run start-[platform].sh to use your AI"
echo ""
echo "For manual model installation:"
echo "   cp [model].gguf $MODELS_DIR/"
echo "   ollama pull [model-name]"
echo ""

# Set installation state
echo "Installed: $(date)" > "$STATE_FILE"
echo "Platform: $OSTYPE" >> "$STATE_FILE"
echo "=========================================" >> "$STATE_FILE"

cat "$LOG_FILE"
