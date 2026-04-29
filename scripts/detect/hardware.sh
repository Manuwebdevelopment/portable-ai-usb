#!/bin/bash
# Hardware Detection Script

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USB_ROOT="${USB_ROOT:-$HOME/PORTABLE-AI-USB}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Hardware Detection ===${NC}"

# Detect OS
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS="$NAME"
        VERSION="$VERSION_ID"
    elif command -v sw_vers > /dev/null; then
        OS="macOS $(sw_vers -productVersion)"
    elif command -v wsl > /dev/null; then
        OS="WSL2 on $(uname -r)"
    else
        OS="Unknown ($(uname -s))"
    fi
    
    echo -e "${GREEN}[OS]${NC}: $OS"
}

detect_os

# Detect platform
detect_platform() {
    if [ "$(uname -m)" = "arm64" ]; then
        PLATFORM="ARM64"
        echo -e "${GREEN}[Platform]${NC}: $PLATFORM"
    elif [ "$(uname -m)" = "x86_64" ]; then
        PLATFORM="x86_64"
        echo -e "${GREEN}[Platform]${NC}: $PLATFORM"
    else
        PLATFORM="Unknown"
        echo -e "${RED}[Platform]${NC}: $PLATFORM"
    fi
    
    # Check for Apple Silicon
    if [ -f /System/Library/CoreServices/SystemVersion.plist ]; then
        if grep -q "M1\|M2\|M3" /System/Library/CoreServices/SystemVersion.plist 2>/dev/null; then
            echo -e "${GREEN}[CPU]${NC}: Apple Silicon (M1/M2/M3)"
            return
        fi
    fi
    
    # Check for NVIDIA GPU
    if command -v nvidia-smi > /dev/null; then
        GPU_NAME=$(nvidia-smi --query-gpu=name --format=csv | head -n1)
        echo -e "${GREEN}[GPU]${NC}: $GPU_NAME (NVIDIA)"
    elif command -v clover > /dev/null; then
        GPU_NAME=$(clover --gpu)
        echo -e "${GREEN}[GPU]${NC}: $GPU_NAME (AMD)"
    else
        echo -e "${YELLOW}[GPU]${NC}: None detected (CPU inference only)"
    fi
}

detect_platform

# Detect RAM
detect_ram() {
    if command -v free > /dev/null; then
        RAM_TOTAL=$(free -m | grep Mem | awk '{print $2}')
        RAM_FREE=$(free -m | grep Mem | awk '{print $4}')
        echo -e "${GREEN}[RAM]${NC}: ${RAM_TOTAL}MB total, ${RAM_FREE}MB free"
        
        if [ "$RAM_TOTAL" -ge 16384 ]; then
            RAM_CLASS="high"
            echo -e "${GREEN}  -> Suitable for large models (16GB+)"
        elif [ "$RAM_TOTAL" -ge 8192 ]; then
            RAM_CLASS="medium"
            echo -e "${GREEN}  -> Suitable for medium models (8GB+)"
        elif [ "$RAM_TOTAL" -ge 4096 ]; then
            RAM_CLASS="low"
            echo -e "${GREEN}  -> Suitable for small models (4GB+)"
        else
            RAM_CLASS="critial"
            echo -e "${RED}  -> Insufficient RAM (<4GB)"
        fi
    fi
}

detect_ram

# Detect GPU VRAM
detect_vram() {
    if command -v nvidia-smi > /dev/null; then
        VRAM_TOTAL=$(nvidia-smi --query-gpu=memory.total --format=csv | tr -d ' ')
        echo -e "${GREEN}[VRAM]${NC}: ${VRAM_TOTAL}MB"
    elif [ -f /System/Library/Extensions/IOGPU.kext/Contents/Info.plist ]; then
        VRAM_TOTAL="Unknown (Apple GPU)"
        echo -e "${GREEN}[VRAM]${NC}: $VRAM_TOTAL"
    else
        echo -e "${YELLOW}[VRAM]${NC}: N/A (Intel/AMD integrated graphics)"
    fi
}

detect_vram

# Detect storage
detect_storage() {
    echo -e "${GREEN}[Storage]${NC}: Checking USB drive..."
    
    if [ -d "$USB_ROOT" ]; then
        USB_FREE=$(df -B1 "$USB_ROOT" | tail -1 | awk '{print $4}')
        USB_TOTAL=$(df -B1 "$USB_ROOT" | tail -1 | awk '{print $2}')
        USB_PERCENT=$(df -B1 "$USB_ROOT" | tail -1 | awk '{print $5}' | tr -d '%')
        echo -e "${GREEN}  [Total]${NC}: $USB_TOTAL bytes ($((USB_TOTAL / 1024 / 1024)) MB)"
        echo -e "${GREEN}  [Free]${NC}: $USB_FREE bytes ($((USB_FREE / 1024 / 1024)) MB)"
        echo -e "${GREEN}  [Used]${NC}: $USB_PERCENT%"
    else
        echo -e "${RED}  [USB]${NC}: $USB_ROOT not found"
    fi
}

detect_storage

# Generate model recommendation
recommend_model() {
    echo -e "${BLUE}=== Model Recommendations ===${NC}"
    
    if command -v nvidia-smi > /dev/null; then
        echo -e "${GREEN}  Option 1 (GPU Available):${NC}"
        echo -e "    llama3.1:8b-instruct-q8_0.gguf  (Best for GPU)"
        echo -e "    llama3:70b-instruct-q4_0.gguf   (Maximum model size)"
    fi
    
    echo -e "${GREEN}  Option 2 (RAM 16GB+):${NC}"
    echo -e "    llama3.1:8b-instruct-q8_0.gguf"
    echo -e "    llama3:70b-instruct-q4_0.gguf"
    
    echo -e "${GREEN}  Option 3 (RAM 8-15GB):${NC}"
    echo -e "    llama3.1:8b-instruct-q4_0.gguf"
    echo -e "    llama3:70b-instruct-q3_0.gguf"
    
    echo -e "${GREEN}  Option 4 (RAM 4-7GB):${NC}"
    echo -e "    llama3.2:1b-instruct-q4_0.gguf"
    echo -e "    llama3.2:3b-instruct-q4_0.gguf"
    
    echo -e "${GREEN}  Option 5 (RAM <4GB):${NC}"
    echo -e "    tinyllama:1.1b-v1.0-q4_0.gguf"
}

recommend_model

echo -e "${GREEN}=== Detection Complete ===${NC}"
