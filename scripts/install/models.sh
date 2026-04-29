#!/bin/bash
# Model download and management script
# Handles model installation, updates, and cleanup

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USB_ROOT="$(dirname "$SCRIPT_DIR")"
MODELS_DIR="$USB_ROOT/models"
CONFIG_DIR="$USB_ROOT/config"
LOG_FILE="$USB_ROOT/log/models.log"

mkdir -p "$MODELS_DIR" "$USB_ROOT/log"

echo "=== Model Management ===" | tee -a "$LOG_FILE"

# Source config
if [[ -f "$CONFIG_DIR/.env" ]]; then
    source "$CONFIG_DIR/.env"
fi

# Model catalog
declare -A MODELS
MODELS["qwen2.5:7b"]="qwen2.5:7b"
MODELS["qwen2:7b-instruct"]="qwen2:7b-instruct"
MODELS["llama3.2:3b"]="llama3.2:3b"
MODELS["llama3.1:8b"]="llama3.1:8b"
MODELS["mistral:7b"]="mistral:7b"
MODELS["dolphin-mixtral:8x7b"]="dolphin-mixtral:8x7b"
MODELS["phi3.5:mini"]="phi3.5:mini"

echo "" | tee -a "$LOG_FILE"
echo "Available models:" | tee -a "$LOG_FILE"
echo "  qwen2.5:7b       - Qwen 2.5 7B (recommended)" | tee -a "$LOG_FILE"
echo "  qwen2:7b-instruct- - Qwen 2 7B Instruct" | tee -a "$LOG_FILE"
echo "  llama3.2:3b      - Llama 3.2 3B (lightweight)" | tee -a "$LOG_FILE"
echo "  llama3.1:8b      - Llama 3.1 8B" | tee -a "$LOG_FILE"
echo "  mistral:7b       - Mistral 7B" | tee -a "$LOG_FILE"
echo "  dolphin-mixtral:8x7b - Dolphin Mixtral 8x7B" | tee -a "$LOG_FILE"
echo "  phi3.5:mini      - Phi-3.5 Mini" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# List installed models
echo "Installed models:" | tee -a "$LOG_FILE"
if [[ -d "$MODELS_DIR" ]]; then
    for model in "$MODELS_DIR"/*.gguf; do
        if [[ -f "$model" ]]; then
            name=$(basename "$model")
            size=$(du -h "$model" | cut -f1)
            echo "  - $name (${size})" | tee -a "$LOG_FILE"
        fi
    done
    echo "" | tee -a "$LOG_FILE"
fi

if command -v ollama &> /dev/null; then
    ollama list 2>/dev/null | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
fi

# Download function
download_model() {
    local model_name="$1"
    
    echo "📥 Downloading: $model_name..." | tee -a "$LOG_FILE"
    
    # Check if model already downloaded
    if command -v ollama &> /dev/null; then
        ollama pull "$model_name" 2>&1 | tee -a "$LOG_FILE"
    else
        echo "⚠️  ollama not found. Please install first:" | tee -a "$LOG_FILE"
        echo "   curl -fsSL https://ollama.com/install.sh | sh" | tee -a "$LOG_FILE"
        return 1
    fi
    
    echo "✅ Downloaded: $model_name" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
}

# Download all models
download_all_models() {
    echo "📥 Downloading all models..." | tee -a "$LOG_FILE"
    
    for model_key in "${!MODELS[@]}"; do
        model_name="${MODELS[$model_key]}"
        download_model "$model_name"
    done
    
    echo "📥 All models downloaded!" | tee -a "$LOG_FILE"
}

# Download custom model from URL
download_custom_model() {
    local url="$1"
    local filename=$(basename "$url" .gguf)
    local filepath="$MODELS_DIR/${filename}.gguf"
    
    if [[ -f "$filepath" ]]; then
        echo "✅ Model already exists: $filename" | tee -a "$LOG_FILE"
    else
        echo "📥 Downloading custom model..." | tee -a "$LOG_FILE"
        curl -L -o "$filepath" "$url" 2>&1 | tail -20 | tee -a "$LOG_FILE"
        
        if [[ -f "$filepath" ]]; then
            echo "✅ Downloaded to: $filepath" | tee -a "$LOG_FILE"
        else
            echo "❌ Download failed" | tee -a "$LOG_FILE"
        fi
    fi
}

# Cleanup old models
cleanup_models() {
    if [[ ! -d "$MODELS_DIR" ]]; then
        echo "No models directory" | tee -a "$LOG_FILE"
        return
    fi
    
    echo "Available models to remove:" | tee -a "$LOG_FILE"
    
    # Remove a model
    remove_model() {
        local model_name="$1"
        local filepath="$MODELS_DIR/${model_name}.gguf"
        
        if [[ -f "$filepath" ]]; then
            local size=$(du -h "$filepath" | cut -f1)
            rm "$filepath"
            echo "✅ Removed: $model_name (${size})" | tee -a "$LOG_FILE"
        else
            echo "⚠️  Model not found: $model_name" | tee -a "$LOG_FILE"
        fi
    }
    
    remove_model "$1"
}

# Show help
show_help() {
    echo "Usage: $0 {list|download|remove|cleanup}" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
    echo "Commands:" | tee -a "$LOG_FILE"
    echo "  list           - List installed models" | tee -a "$LOG_FILE"
    echo "  download [name] - Download a model" | tee -a "$LOG_FILE"
    echo "  remove [name]  - Remove a model" | tee -a "$LOG_FILE"
    echo "  cleanup         - Remove models not in catalog" | tee -a "$LOG_FILE"
    echo "  help            - Show this help" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
    echo "Examples:" | tee -a "$LOG_FILE"
    echo "  $0 download qwen2.5:7b" | tee -a "$LOG_FILE"
    echo "  $0 remove llama3.2:3b" | tee -a "$LOG_FILE"
}

# Main command
case "$1" in
    list)
        list_installed
        ;;
    download)
        download_model "$2"
        ;;
    remove)
        remove_model "$2"
        ;;
    cleanup)
        cleanup_models
        ;;
    help|*)
        show_help
        ;;
esac

echo ""
echo "=== Complete ===" | tee -a "$LOG_FILE"
