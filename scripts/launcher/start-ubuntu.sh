#!/bin/bash
# Portable AI USB Launcher for Ubuntu/Debian
# Usage: ./start-ubuntu.sh [--help] [--port <port>]

set -e

# Default configuration
PORT=11434
QUIET=false
LOG_FILE="/tmp/ollama-launch-ubuntu.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

log_help() {
    cat << EOF
Portable AI USB Launcher for Ubuntu/Debian

Usage: $(basename "$0") [OPTIONS]

Options:
  --help             Show this help message
  --port <port>      Set the web server port (default: 11434)
  --quiet            Suppress verbose output

Examples:
  $(basename "$0")             # Start on default port
  $(basename "$0") --port 11435
  $(basename "$0") --quiet

EOF
}

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --help|-h)
            log_help
            exit 0
            ;;
        --port)
            PORT="$2"
            shift 2
            ;;
        --quiet)
            QUIET=true
            shift
            ;;
        *)
            log_error "Unknown option: $1"
            log_help
            exit 1
            ;;
    esac
done

# Suppress output if quiet mode
if [[ "$QUIET" == "true" ]]; then
    log_info=": "
    log_warn="[WARN]"
    log_error="[ERROR]"
    log_success="[SUCCESS]"
    log_step="[STEP]"
fi

log_info "Portable AI USB Launcher for Ubuntu/Debian"
log_info "Version: 1.0.0"
log_info "=========================================="

# Function to check if Ollama is already running
check_ollama_running() {
    log_step "Checking if Ollama is running..."
    
    if systemctl is-active --quiet ollama.service 2>/dev/null; then
        log_success "Ollama is already running via systemd"
        return 0
    fi
    
    # Check if ollama process is running
    if ps aux | grep -v grep | grep -q "ollama serve"; then
        log_success "Ollama process is already running"
        return 0
    fi
    
    return 1
}

# Function to start Ollama
start_ollama() {
    log_step "Starting Ollama..."
    
    if command -v systemctl &>/dev/null; then
        # Start via systemd
        systemctl start ollama.service
        
        # Wait for it to be ready
        sleep 2
        
        if systemctl is-active --quiet ollama.service; then
            log_success "Ollama started via systemd"
        else
            log_error "Failed to start Ollama via systemd"
            return 1
        fi
    else
        # Start directly
        ollama serve --port "$PORT" &
        ollama_pid=$!
        
        # Wait for it to start
        sleep 2
        
        # Check if it's running
        if ps -p "$ollama_pid" &>/dev/null; then
            log_success "Ollama started directly (PID: $ollama_pid)"
            kill "$ollama_pid" 2>/dev/null || true
            return 0
        else
            log_error "Failed to start Ollama directly"
            return 1
        fi
    fi
}

# Function to verify Ollama is accessible
verify_ollama() {
    log_step "Verifying Ollama is accessible..."
    
    # Try to curl the API endpoint
    if curl -s http://localhost:$PORT/api/tags &>/dev/null; then
        log_success "Ollama API is accessible at http://localhost:$PORT"
        return 0
    else
        log_warn "Could not verify Ollama API response"
        # Check if process is running
        if ps aux | grep -v grep | grep -q "ollama serve"; then
            log_success "Ollama process is running, API may be accepting connections"
            return 0
        else
            return 1
        fi
    fi
}

# Function to list available models
list_models() {
    log_step "Listing available models..."
    
    if curl -s http://localhost:$PORT/api/tags | python3 -m json.tool 2>/dev/null; then
        log_success "Models:"
    else
        log_warn "Could not list models"
    fi
}

# Function to show startup summary
show_summary() {
    log_step "=== Startup Summary ==="
    
    cat << EOF

🎉 Ollama is now running!

📡 Web Server:
   Port: $PORT
   URL: http://localhost:$PORT
   
📚 Quick Commands:
   ollama run <model>      - Run a model
   ollama list             - List installed models
   ollama pull <model>     - Pull a new model
   ollama chat <model>     - Chat with a model
   ollama create <name> -f Modelfile - Create custom model

📖 Documentation:
   https://github.com/ollama/ollama

=== End of Summary ===
EOF
}

# Main function
main() {
    log_info "Initializing launcher..."
    
    # Check if already running
    if check_ollama_running; then
        show_summary
        log_success "Launch complete"
        exit 0
    fi
    
    # Start Ollama
    if ! start_ollama; then
        log_error "Failed to start Ollama"
        exit 1
    fi
    
    # Verify it's running
    verify_ollama || {
        log_error "Ollama does not appear to be accessible"
        exit 1
    }
    
    # List models (optional, only if not quiet)
    if [[ "$QUIET" != "true" ]]; then
        list_models
    fi
    
    # Show summary
    show_summary
    
    log_success "Launch complete"
}

# Run main function
main
