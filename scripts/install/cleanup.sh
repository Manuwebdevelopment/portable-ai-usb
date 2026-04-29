#!/bin/bash
# Cleanup script for Portable AI USB
# Removes Ollama processes, clears cache, removes old models

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USB_ROOT="$(dirname "$SCRIPT_DIR")"
MODELS_DIR="$USB_ROOT/models"
OLLAMA_DIR="$USB_ROOT/ollama"
LOG_FILE="$USB_ROOT/log/cleanup.log"

mkdir -p "$USB_ROOT/log"

echo "Portable AI USB - Cleanup" | tee -a "$LOG_FILE"
echo "==========================" | tee -a "$LOG_FILE"
echo ""

# Kill Ollama processes
echo "Stopping Ollama processes..." | tee -a "$LOG_FILE"
pkill ollama 2>/dev/null || true
ollama stop --all 2>/dev/null || true
echo "✅ Processes stopped" | tee -a "$LOG_FILE"
echo ""

# Clear Ollama cache
echo "Clearing Ollama cache..." | tee -a "$LOG_FILE"
ollama cache clear 2>/dev/null || echo "⚠️  Cache clear not supported on this system" | tee -a "$LOG_FILE"
echo "✅ Cache cleared" | tee -a "$LOG_FILE"
echo ""

# Remove old models (not in catalog)
if [[ -d "$MODELS_DIR" ]]; then
    echo "Checking for old models..." | tee -a "$LOG_FILE"
    
    declare -A MODELS
    MODELS["qwen2.5:7b"]=1
    MODELS["qwen2:7b-instruct"]=1
    MODELS["llama3.2:3b"]=1
    MODELS["llama3.1:8b"]=1
    MODELS["mistral:7b"]=1
    MODELS["dolphin-mixtral:8x7b"]=1
    MODELS["phi3.5:mini"]=1
    
    old_count=0
    for model in "$MODELS_DIR"/*.gguf; do
        if [[ -f "$model" ]]; then
            name=$(basename "$model" .gguf)
            if [[ -z "${MODELS[$name]}" ]]; then
                size=$(du -h "$model" | cut -f1)
                read -p "Remove $name (${size})? [y/N] " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    rm "$model"
                    echo "✅ Removed: $name" | tee -a "$LOG_FILE"
                    ((old_count++))
                fi
            fi
        fi
    done
    
    echo ""
    echo "Removed $old_count old models" | tee -a "$LOG_FILE"
else
    echo "No models directory" | tee -a "$LOG_FILE"
fi

# Clear log files
echo "Clearing old logs..." | tee -a "$LOG_FILE"
find "$USB_ROOT/log" -name "*.log" -mtime +7 -delete 2>/dev/null || true
echo "✅ Old logs cleared" | tee -a "$LOG_FILE"
echo ""

# Show disk usage before and after
echo "Disk usage:" | tee -a "$LOG_FILE"
if [[ -d "$MODELS_DIR" ]]; then
    du -sh "$MODELS_DIR" | tee -a "$LOG_FILE"
fi
echo ""

echo "=== Cleanup Complete ===" | tee -a "$LOG_FILE"
