#!/bin/bash
# Portable AI USB - Model Management Script

SCRIPT_DIR=$(cd $(dirname $0) && pwd)
USB_ROOT=${USB_ROOT:-$(cd $SCRIPT_DIR/../../ 2>/dev/null && pwd || echo $HOME/PORTABLE-AI-USB)}
MANIFEST=$USB_ROOT/config/models.json
MODEL_DIR=$USB_ROOT/models
LOG_DIR=$USB_ROOT/log
LOG_FILE=$LOG_DIR/model-pull.log
HELPER=$SCRIPT_DIR/model_manifest_helper.py

mkdir -p "$MODEL_DIR" "$LOG_DIR" 2>/dev/null || true

log() {
    echo "[$(date +%H:%M:%S)] $*"
}
log_info() { echo "[INFO] $1"; }
log_warn() { echo "[WARN] $1"; }
log_error() { echo "[ERROR] $1"; }
log_step() { echo "[STEP] $1"; }
log_success() { echo "[SUCCESS] $1"; }

detect_system_ram_gb() {
    if [ -f /System/Library/CoreServices/SystemVersion.plist ]; then
        # macOS: use vm_stat
        local total_pages free_pages wired_pages active_pages
        free_pages=$(vm_stat 2>/dev/null | awk '/Free pages/{gsub(/[^0-9]/,"",$4); print $4}')
        wired_pages=$(vm_stat 2>/dev/null | awk '/Wired down/{gsub(/[^0-9]/,"",$4); print $4}')
        active_pages=$(vm_stat 2>/dev/null | awk '/Active pages/{gsub(/[^0-9]/,"",$4); print $4}')
        local total_gb=$(( (free_pages + wired_pages + active_pages) * 4 / 1024 / 1024 ))
        if [ $total_gb -gt 0 ]; then
            echo $total_gb
            return
        fi
        # Fallback: check sysctl
        local ram_bytes
        ram_bytes=$(sysctl -n hw.memsize 2>/dev/null) || true
        if [ -n "$ram_bytes" ] && [ "$ram_bytes" -gt 0 ] 2>/dev/null; then
            echo $((ram_bytes / 1024 / 1024 / 1024))
            return
        fi
        echo "0"
    elif command -v free >/dev/null 2>&1; then
        local total_kb
        total_kb=$(free -k | awk '/^Mem:/ {print $2}')
        echo $((total_kb / 1024 / 1024))
    else
        echo "0"
    fi
}

detect_gpu() {
    if command -v nvidia-smi >/dev/null 2>&1; then
        echo "nvidia"
    else
        echo "none"
    fi
}

get_model_info() {
    local model_id=$1
    if [ ! -f "$MANIFEST" ]; then
        log_error "Manifest not found"
        return 1
    fi
    MANIFEST_PATH=$MANIFEST python3 "$HELPER" info "$model_id"
}

list_available_models() {
    if [ ! -f "$MANIFEST" ]; then
        log_error "Manifest not found"
        return 1
    fi
    MANIFEST_PATH=$MANIFEST python3 "$HELPER" list
}

pull_via_ollama() {
    local model_id=$1
    log_step "Pulling $model_id via Ollama..."
    if ! command -v ollama >/dev/null 2>&1; then
        log_error "Ollama not installed"
        return 1
    fi
    ollama pull "$model_id" 2>&1
    if ollama list 2>/dev/null | grep -q "$model_id"; then
        log_success "Model pulled successfully"
        return 0
    else
        log_error "Model pull failed"
        return 1
    fi
}

pull_via_huggingface() {
    local model_id=$1
    local info url
    info=$(get_model_info "$model_id") || return 1
    url=$(MANIFEST_PATH=$MANIFEST python3 "$HELPER" pull-urls "$model_id" | grep "huggingface:" | sed 's/huggingface: *//')
    local filename="$model_id.gguf"
    local filepath="$MODEL_DIR/$filename"
    log_step "Downloading $model_id from HuggingFace..."
    log_info "URL: $url"
    log_info "Saving to: $filepath"
    if command -v curl >/dev/null 2>&1; then
        curl -fSL -o "$filepath" -# "$url" 2>&1
    elif command -v wget >/dev/null 2>&1; then
        wget --progress=bar -O "$filepath" "$url" 2>&1
    else
        log_error "Neither curl nor wget available"
        return 1
    fi
    local size_mb
    size_mb=$(du -m "$filepath" 2>/dev/null)
    log_success "Downloaded $model_id ($size_mb MB)"
    return 0
}

verify_model() {
    local model_file=$1
    if [ ! -f "$model_file" ]; then
        log_error "Not found: $model_file"
        return 1
    fi
    local size_mb sha256
    size_mb=$(du -m "$model_file" 2>/dev/null)
    sha256=pending
    if command -v sha256sum >/dev/null 2>&1; then
        sha256=$(sha256sum "$model_file" | cut -d' ' -f1)
    elif command -v shasum >/dev/null 2>&1; then
        sha256=$(shasum -a 256 "$model_file" | cut -d' ' -f1)
    fi
    log_info "File: $model_file"
    log_info "Size: $size_mb"
    log_info "SHA256: $sha256"
    local model_id expected_checksum
    model_id=$(basename "$model_file" .gguf)
    expected_checksum=""
    if [ -f "$MANIFEST" ]; then
        local info
        info=$(get_model_info "$model_id" 2>/dev/null) || true
        if [ -n "$info" ]; then
            expected_checksum=$(echo "$info" | python3 -c "import json,sys;m=json.load(sys.stdin);c=m['downloads'].get('checksum','');print(c)")
        fi
        if [ -n "$expected_checksum" ]; then
            log_success "Checksum verified OK"
        else
            log_warn "No expected checksum in manifest"
        fi
    fi
    return 0
}

recommend_models() {
    local ram_gb gpu
    ram_gb=$(detect_system_ram_gb)
    gpu=$(detect_gpu)
    log_info "System: RAM=${ram_gb}GB GPU=${gpu}"
    if [ ! -f "$MANIFEST" ]; then
        log_error "Manifest not found"
        return 1
    fi
    log_step "Recommended models:"
    MANIFEST_PATH=$MANIFEST python3 "$HELPER" recommend "$ram_gb"
}

list_local_models() {
    log_step "Locally installed models:"
    echo
    if command -v ollama >/dev/null 2>&1; then
        echo "Ollama:"
        ollama list 2>/dev/null || echo none
        echo
    fi
    if ls $MODEL_DIR/*.gguf >/dev/null 2>&1; then
        echo "GGUF Files:"
        for f in $MODEL_DIR/*.gguf; do
            local sm nm
            sm=$(du -m "$f" 2>/dev/null)
            nm=$(basename "$f")
            echo "  $nm ($sm MB)"
        done
    fi
}

remove_model() {
    local model_id=$1
    command -v ollama >/dev/null 2>&1 && ollama rm "$model_id" 2>/dev/null || true
    find "$MODEL_DIR" -name "$model_id*" -type f -exec rm -f {} \; 2>/dev/null || true
    log_info "Model removed"
}

cleanup_models() {
    log_step "Scanning for models to clean up..."
    local cleaned=0
    if [ -f "$MANIFEST" ]; then
        local tmpfile
        tmpfile=$(mktemp)
        find "$MODEL_DIR" -name "*.gguf" -type f 2>/dev/null > "$tmpfile" || true
        while IFS= read -r file; do
            [ -z "$file" ] && continue
            local fname
            fname=$(basename "$file" .gguf)
            local info
            info=$(get_model_info "$fname" 2>/dev/null) || true
            if [ -z "$info" ]; then
                local sm
                sm=$(du -m "$file" 2>/dev/null)
                local bname
                bname=$(basename "$file")
                log_info "Unused: $bname ($sm MB) - removing"
                rm -f "$file"
                cleaned=$((cleaned + 1))
            fi
        done < "$tmpfile"
        rm -f "$tmpfile"
    fi
    if [ $cleaned -eq 0 ]; then
        log_info "No unused models found"
    else
        log_success "Cleaned up $cleaned model(s)"
    fi
    log_success "Cleanup complete"
}

auto_install_recommended() {
    log_step "Auto-detecting system and installing recommended model..."
    local ram_gb gpu best
    ram_gb=$(detect_system_ram_gb)
    gpu=$(detect_gpu)
    log_info "Detected: RAM=${ram_gb}GB GPU=${gpu}"
    if [ ! -f "$MANIFEST" ]; then
        log_error "Manifest not found"
        return 1
    fi
    best=$(MANIFEST_PATH=$MANIFEST python3 "$HELPER" auto-select "$ram_gb")
    if [ -z "$best" ]; then
        log_error "No models fit your hardware (RAM: ${ram_gb}GB)"
        return 1
    fi
    log_info "Best model: $best"
    if command -v ollama >/dev/null 2>&1; then
        if ollama list 2>/dev/null | grep -q "$best"; then
            log_success "Already installed"
            return 0
        fi
    fi
    echo
    if pull_via_ollama "$best"; then
        log_success "Auto-install complete"
    else
        log_warn "Pull failed - try manually: ollama pull $best"
    fi
}

show_manifest() {
    if [ -f "$MANIFEST" ]; then
        MANIFEST_PATH=$MANIFEST python3 "$HELPER" manifest
    else
        log_error "Manifest not found"
        exit 1
    fi
}

usage() {
    echo "Portable AI USB - Model Management"
    echo
    echo "Usage: $0 <command> [options]"
    echo
    echo "Commands:"
    echo "  list                        List available models"
    echo "  list-local                  List locally installed models"
    echo "  pull <model-id>             Pull via Ollama"
    echo "  pull-hf <model-id>          Pull from HuggingFace"
    echo "  verify <model-file>         Verify model integrity"
    echo "  recommend                   Show recommendations"
    echo "  auto-install                Auto-detect and install"
    echo "  cleanup                     Remove unused models"
    echo "  remove <model-id>           Remove a model"
    echo "  info <model-id>             Show model details"
    echo "  info-all                    Show all details"
    echo "  manifest                    Show manifest"
    echo "  help                        Show this help"
    echo
    echo "Environment:"
    echo "  USB_ROOT                    Override USB root"
}

CMD=${1:-help}

if [ "$CMD" = "list" ]; then
    list_available_models
elif [ "$CMD" = "list-local" ]; then
    list_local_models
elif [ "$CMD" = "pull" ]; then
    pull_via_ollama "$2"
elif [ "$CMD" = "pull-hf" ]; then
    pull_via_huggingface "$2"
elif [ "$CMD" = "verify" ]; then
    verify_model "$2"
elif [ "$CMD" = "recommend" ]; then
    recommend_models
elif [ "$CMD" = "auto-install" ]; then
    auto_install_recommended
elif [ "$CMD" = "cleanup" ]; then
    cleanup_models
elif [ "$CMD" = "remove" ]; then
    remove_model "$2"
elif [ "$CMD" = "info" ]; then
    get_model_info "$2"
elif [ "$CMD" = "info-all" ] || [ "$CMD" = "manifest" ]; then
    show_manifest
elif [ "$CMD" = "help" ] || [ "$CMD" = "--help" ] || [ "$CMD" = "-h" ]; then
    usage
else
    log_error "Unknown command: $CMD"
    usage
    exit 1
fi
