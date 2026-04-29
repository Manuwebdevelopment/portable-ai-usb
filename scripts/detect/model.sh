#!/bin/bash
# Model detection script
# Checks what models are already installed

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USB_ROOT="$(dirname "$SCRIPT_DIR")"
MODELS_DIR="$USB_ROOT/models"
LOG_FILE="$USB_ROOT/log/model.log"

mkdir -p "$USB_ROOT/log"

echo "=== Installed Models Detection ===" | tee -a "$LOG_FILE"

if [[ -d "$MODELS_DIR" ]]; then
    echo "Scanning: $MODELS_DIR" | tee -a "$LOG_FILE"
    
    # List all .gguf files
    echo "" | tee -a "$LOG_FILE"
    echo "Installed models:" | tee -a "$LOG_FILE"
    
    for model in "$MODELS_DIR"/*.gguf; do
        if [[ -f "$model" ]]; then
            name=$(basename "$model")
            size=$(du -h "$model" | cut -f1)
            echo "  - $name (${size})" | tee -a "$LOG_FILE"
        fi
    done
    
    # Check Ollama installed models
    echo "" | tee -a "$LOG_FILE"
    echo "Checking Ollama models..." | tee -a "$LOG_FILE"
    
    if command -v ollama &> /dev/null; then
        ollama list 2>/dev/null | tee -a "$LOG_FILE"
    else
        echo "Ollama not found - models detected only from filesystem" | tee -a "$LOG_FILE"
    fi
else
    echo "No models directory found - run setup.sh first" | tee -a "$LOG_FILE"
fi

# Detect available models based on hardware
echo "" | tee -a "$LOG_FILE"
echo "Available models for your system:" | tee -a "$LOG_FILE"

# Check RAM again
if [[ "$OSTYPE" == "darwin"* ]]; then
    if [[ "$(uname -m)" == "arm64" ]]; then
        RAM=$(sysctl hw.memsize | awk '{print int($2/1024/1024/1024)}')
        echo "Apple Silicon with ${RAM}GB RAM" | tee -a "$LOG_FILE"
        
        if ((RAM >= 16)); then
            echo "  Available: NemoMix 12B, Qwen 7B, Llama 3.2 3B" | tee -a "$LOG_FILE"
        elif ((RAM >= 8)); then
            echo "  Available: Qwen 7B, Llama 3.2 3B, Phi-3.5" | tee -a "$LOG_FILE"
        else
            echo "  Available: Llama 3.2 3B, Phi-3.5 (lightweight only)" | tee -a "$LOG_FILE"
        fi
    fi
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    echo "  Windows: All models available via ollama pull" | tee -a "$LOG_FILE"
else
    echo "  Linux: All models available via ollama pull" | tee -a "$LOG_FILE"
fi

echo "" | tee -a "$LOG_FILE"
echo "=== Detection Complete ===" | tee -a "$LOG_FILE"
