#!/bin/bash
# Portable AI USB - Standalone Uninstall Script
# Safely removes Portable AI USB components while preserving user data.

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
USB_ROOT="${USB_ROOT:-$(cd "$SCRIPT_DIR/../../" 2>/dev/null && pwd || echo "$HOME/PORTABLE-AI-USB")}"
LOG_DIR="$USB_ROOT/log"
LOG_FILE="$LOG_DIR/uninstall.log"
DRY_RUN=false

mkdir -p "$LOG_DIR" 2>/dev/null || true

log() { echo "[$(date +%H:%M:%S)] $*"; }
log_info()  { echo "[INFO]  $1"; }
log_warn()  { echo "[WARN]  $1" >&2; }
log_error() { echo "[ERROR] $1" >&2; }
log_step()  { echo "[STEP]  $1"; }
log_success() { echo "[OK]    $1"; }

# --- Argument parsing ---
for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        --force)   FORCE=true ;;
        *)         ;;
    esac
done

# --- Safety checks ---
if [ ! -f "$USB_ROOT/README.md" ]; then
    log_error "Portable AI USB root not found at: $USB_ROOT"
    log_info "Set USB_ROOT env var or run from the project directory."
    exit 1
fi

log_info "Portable AI USB Uninstaller"
log_info "USB_ROOT=$USB_ROOT"
[ "$DRY_RUN" = true ] && log_warn "DRY RUN — no files will be deleted"
echo

# --- What will be removed ---
should_remove() {
    local item="$1"
    if [ "$FORCE" = true ]; then
        return 0
    fi
    printf "  Remove %s? [y/N] " "$item"
    read -r ans
    case "$ans" in
        [yY]|[yY][eE][sS]) return 0 ;;
        *) return 1 ;;
    esac
}

# --- Step 1: Stop running services ---
log_step "1. Stopping any running services..."
if command -v pkill >/dev/null 2>&1; then
    pkill -f "web_server.py" 2>/dev/null || true
fi
if command -v taskkill >/dev/null 2>&1; then
    taskkill //IM python.exe //F 2>/dev/null || true
fi
log_success "Services stopped (or none were running)"
echo

# --- Step 2: Remove Ollama models (optional) ---
log_step "2. Removing installed models..."
if command -v ollama >/dev/null 2>&1; then
    if should_remove "Ollama-pulled models"; then
        log_info "Listing Ollama models..."
        ollama list 2>/dev/null || true
        echo
        log_info "Removing all Ollama models..."
        ollama list --json 2>/dev/null | python3 -c "
import json,sys
try:
    data=json.load(sys.stdin)
    for m in data.get('models',[]):
        name=m.get('name','unknown')
        print(f'  {name}')
" 2>/dev/null || true
        ollama rm -a 2>/dev/null || true
        log_success "Ollama models removed"
    else
        log_info "Keeping Ollama models"
    fi
else
    log_info "Ollama not found on this system — skipping"
fi
echo

# --- Step 3: Remove Portable AI USB data directories ---
REMOVE_DIRS=()
for d in "$USB_ROOT/ollama" "$USB_ROOT/anythingllm" "$USB_ROOT/anythingllm_data" "$USB_ROOT/models"; do
    if [ -d "$d" ]; then
        REMOVE_DIRS+=("$d")
    fi
done

for dir in "${REMOVE_DIRS[@]}"; do
    if should_remove "$(basename "$dir")/"; then
        if [ "$DRY_RUN" = true ]; then
            log_info "[DRY RUN] Would remove $dir"
        else
            rm -rf "$dir"
            log_success "Removed $dir"
        fi
    else
        log_info "Keeping $(basename "$dir")"
    fi
done
echo

# --- Step 4: Remove config (optional — preserves user edits) ---
if should_remove "config/ (your settings will be preserved unless you say yes)"; then
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would remove $USB_ROOT/config/"
    else
        rm -rf "$USB_ROOT/config/generated"
        log_success "Removed config/generated/"
        log_warn "Config files preserved — you can delete config/ manually if desired"
    fi
else
    log_info "Preserving all config files"
fi
echo

# --- Step 5: Cleanup logs ---
if should_remove "log/"; then
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would remove $USB_ROOT/log/"
    else
        rm -rf "$USB_ROOT/log"
        log_success "Removed log/"
    fi
else
    log_info "Preserving log/"
fi
echo

# --- Step 6: Remove launcher symlinks/aliases (optional) ---
log_step "3. Cleaning up launcher shortcuts..."
if should_remove "Quick-launch aliases (~/.local/bin/portable-ai*)"; then
    for alias_file in "$HOME/.local/bin/portable-ai-"*; do
        [ -f "$alias_file" ] || continue
        if [ "$DRY_RUN" = true ]; then
            log_info "[DRY RUN] Would remove $alias_file"
        else
            rm -f "$alias_file"
            log_success "Removed $alias_file"
        fi
    done
else
    log_info "Keeping launcher aliases"
fi
echo

# --- Step 7: Cleanup Ollama library cache (optional, aggressive) ---
if should_remove "Ollama library cache (~/.ollama/models)"; then
    if [ "$DRY_RUN" = true ]; then
        log_info "[DRY RUN] Would remove ~/.ollama/models/"
    else
        rm -rf "$HOME/.ollama/models" 2>/dev/null || true
        log_success "Removed ~/.ollama/models/"
        log_warn "This removes ALL Ollama models system-wide, not just Portable AI USB ones"
    fi
else
    log_info "Keeping Ollama library cache"
fi
echo

# --- Done ---
log_success "Uninstall complete"
echo
log_info "The following directories remain in $USB_ROOT:"
ls -1 "$USB_ROOT" 2>/dev/null | while read -r item; do
    [ -d "$USB_ROOT/$item" ] && echo "  $item/"
done
echo
log_info "You can safely delete the remaining files (scripts/, README.md, etc.)"
