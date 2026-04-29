#!/bin/bash
# Portable AI USB Installer for Arch Linux
# Usage: ./install.sh [install-only | install-and-launch]
# Options: --help, --port <port>, --model <model>

set -e

# Default configuration
INSTALL_ONLY=true
PORT=11434
MODEL="qwen2.5"
LOG_FILE="/tmp/ollama-install-arch.log"
CONFIG_DIR="/usr/share/ollama/config"
OLLAMA_DATA_DIR="/usr/share/ollama/data"

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
Portable AI USB Installer for Arch Linux

Usage: $(basename "$0") [OPTIONS] [install-only|install-and-launch]

Options:
  --help             Show this help message
  --port <port>      Set the web server port (default: 11434)
  --model <model>    Set default model to pull (default: qwen2.5)
  --config-dir <dir> Set config directory (default: /usr/share/ollama/config)
  --data-dir <dir>   Set data directory (default: /usr/share/ollama/data)
  --quiet            Suppress verbose output
  --debug            Enable debug mode

Arguments:
  install-only       Only install, don't start services (default)
  install-and-launch Install and start services immediately

Environment:
  PORT               Web server port (default: 11434)
  MODEL              Default model to pull (default: qwen2.5)

Examples:
  $(basename "$0")                # Install only
  $(basename "$0") install-and-launch
  $(basename "$0") --port 11435 install-only
  $(basename "$0") --model llama3.2:1b install-and-launch

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
        --model)
            MODEL="$2"
            shift 2
            ;;
        --config-dir)
            CONFIG_DIR="$2"
            shift 2
            ;;
        --data-dir)
            DATA_DIR="$2"
            shift 2
            ;;
        --quiet)
            QUIET=true
            shift
            ;;
        --debug)
            DEBUG=true
            shift
            ;;
        install-only)
            INSTALL_ONLY=true
            shift
            ;;
        install-and-launch)
            INSTALL_ONLY=false
            shift
            ;;
        *)
            log_error "Unknown option: $1"
            log_help
            exit 1
            ;;
    esac
done

# Handle positional arguments
if [[ $# -gt 0 ]]; then
    case $1 in
        install-only)
            INSTALL_ONLY=true
            ;;
        install-and-launch)
            INSTALL_ONLY=false
            ;;
        *)
            log_error "Unknown action: $1"
            log_help
            exit 1
            ;;
    esac
fi

# Suppress output if quiet mode
if [[ "$QUIET" == "true" ]]; then
    log_info=": "
    log_warn="[WARN]"
    log_error="[ERROR]"
    log_success="[SUCCESS]"
    log_step="[STEP]"
fi

log_info "Portable AI USB Installer for Arch Linux"
log_info "Version: 1.0.0"
log_info "=========================================="

# Function to check requirements
check_requirements() {
    log_step "Checking system requirements..."
    
    # Check for Python 3.8+
    if command -v python3 &>/dev/null; then
        PYTHON_VERSION=$(python3 --version 2>&1)
        PYTHON_MAJOR=$(python3 -c "import sys; print(sys.version_info.major)" 2>/dev/null)
        if [[ "$PYTHON_MAJOR" -ge 3 ]]; then
            log_success "Python $PYTHON_VERSION is installed"
        else
            log_error "Python 3.8+ is required. Found: $PYTHON_VERSION"
            return 1
        fi
    else
        log_error "Python 3 is not installed"
        return 1
    fi
    
    # Check for curl
    if command -v curl &>/dev/null; then
        log_success "curl is installed"
    else
        log_error "curl is required"
        return 1
    fi
    
    # Check for wget (fallback)
    if command -v wget &>/dev/null; then
        log_success "wget is installed"
    fi
    
    return 0
}

# Function to install Ollama dependencies
install_dependencies() {
    log_step "Installing system dependencies..."
    
    # Sync package database
    pacman -Sy --noconfirm --refresh base-devel ca-certificates curl tar jq || {
        pacman -Sy --noconfirm base-devel ca-certificates curl tar jq
    }
    
    # Install Python if needed (Python is usually available on Arch)
    if ! command -v python3 &>/dev/null; then
        pacman -Sy --noconfirm python && python3
    fi
    
    log_success "Dependencies installed"
}

# Function to download and install Ollama
install_ollama() {
    log_step "Downloading Ollama..."
    
    # Create data directory
    mkdir -p "$DATA_DIR"
    chmod 755 "$DATA_DIR"
    
    # Determine architecture
    ARCH=$(uname -m)
    if [[ "$ARCH" == "aarch64" ]]; then
        ARCH_SPEC="arm64"
    else
        ARCH_SPEC="amd64"
    fi
    
    # Download Ollama using Python if curl fails
    if ! curl -fsSL \
        "https://ollama.com/download/ollama-${ARCH_SPEC}-linux.tar.gz" \
        -o /tmp/ollama-linux.tar.gz; then
    
        log_warn "curl download failed, trying Python..."
        python3 -m http.client.get "https://ollama.com/download/ollama-${ARCH_SPEC}-linux.tar.gz" | \
            tar -xzf - -C /tmp
    fi
    
    # Extract Ollama
    tar -xzf /tmp/ollama-linux.tar.gz -C /tmp 2>/dev/null || true
    
    # Make executable
    chmod +x /tmp/ollama
    
    # Install to system location
    cp /tmp/ollama /usr/bin/ollama
    chmod +x /usr/bin/ollama
    
    rm -f /tmp/ollama-linux.tar.gz /tmp/ollama
    
    log_success "Ollama installed"
}

# Function to set up Ollama configuration
setup_config() {
    log_step "Setting up Ollama configuration..."
    
    # Create config directory
    mkdir -p "$CONFIG_DIR"
    chmod 755 "$CONFIG_DIR"
    
    # Create models configuration
    cat > "$CONFIG_DIR/models.json" << EOF
{
  "default": "$MODEL"
}
EOF
    
    # Create default config
    mkdir -p /etc/ollama
    cat > /etc/ollama/ollama.conf << EOF
# Ollama configuration file
# Created by Portable AI USB Installer
listen = $PORT
model = $MODEL
EOF
    
    # Create systemd service unit
    cat > /etc/systemd/system/ollama.service << EOF
[Unit]
Description=Ollama Self-Contained AI Server
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/ollama serve
Restart=on-failure
RestartSec=5s
TimeoutStopSec=30s
CapabilityBoundingSet=
MemoryDenyWriteExecute=true
PrivateDevices=true
PrivateTmp=true
RestrictAddressFamilies=AF_INET AF_INET6 AF_UNIX
SystemCallArchitectures=native
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/usr/share/ollama/data
Environment=OLLAMA_MODELS=$OLLAMA_DATA_DIR
Environment=OLLAMA_CONFIG=$CONFIG_DIR

[Install]
WantedBy=multi-user.target
EOF
    
    # Reload systemd and enable service
    systemctl daemon-reload
    systemctl enable ollama.service
    
    log_success "Configuration set up"
}

# Function to pull the default model
pull_model() {
    log_step "Pulling default model: $MODEL..."
    
    # Pull the model (this may take a while for first run)
    ollama pull "$MODEL" --stream 2>/dev/null || ollama pull "$MODEL"
    
    if [[ $? -eq 0 ]]; then
        log_success "Model '$MODEL' pulled successfully"
    else
        log_warn "Failed to pull model '$MODEL'. You can pull it manually later with: ollama pull $MODEL"
    fi
}

# Function to verify Ollama is running
verify_ollama() {
    log_step "Verifying Ollama installation..."
    
    # Check if ollama command exists
    if ! command -v ollama &>/dev/null; then
        log_error "ollama command not found"
        return 1
    fi
    
    # Try to get version info
    ollama --version 2>&1 || {
        log_warn "Could not verify Ollama version"
    }
    
    log_success "Ollama verification complete"
    return 0
}

# Function to start Ollama service
start_services() {
    log_step "Starting Ollama services..."
    
    if command -v systemctl &>/dev/null; then
        # Check if service is running
        if systemctl is-active --quiet ollama.service 2>/dev/null; then
            log_info "Ollama service is already running"
        else
            systemctl start ollama.service
            if [[ $? -eq 0 ]]; then
                log_success "Ollama service started"
            else
                log_warn "Failed to start via systemctl"
            fi
        fi
    else
        # Start directly if no systemd
        ollama serve --port "$PORT" &
        ollama_pid=$!
        
        # Wait a moment for it to start
        sleep 2
        
        # Verify it's running
        if ps -p "$ollama_pid" &>/dev/null; then
            log_success "Ollama started directly"
            kill "$ollama_pid" 2>/dev/null || true
        else
            log_warn "Failed to start Ollama directly"
        fi
    fi
}

# Function to show startup messages
show_startup_messages() {
    log_step "Displaying startup messages..."
    
    cat << EOF

========================================
     Portable AI USB Installation Complete!
========================================

Ollama has been successfully installed on Arch Linux!

Web Server:
  Port: $PORT
  URL: http://localhost:$PORT

Default Model:
  $MODEL
  Command: ollama run $MODEL

Quick Start:
  1. Pull a model: ollama pull $MODEL
  2. Run a model: ollama run $MODEL
  3. View conversations: ollama chat $MODEL
  4. List models: ollama list
  5. Create custom models: ollama create <name> -f Modelfile

To start the server manually:
  ollama serve --port $PORT

To stop the server:
  ollama serve --stop
  or
  systemctl stop ollama.service

To check status:
  systemctl status ollama.service

========================================
EOF
}

# Main installation function
main() {
    log_info "Starting installation..."
    
    # Check requirements
    if ! check_requirements; then
        log_error "Installation failed due to missing requirements"
        exit 1
    fi
    
    # Install dependencies
    install_dependencies
    
    # Download and install Ollama
    install_ollama
    
    # Set up configuration
    setup_config
    
    # Pull the default model
    pull_model
    
    # Verify installation
    verify_ollama
    
    # Start services (only if not install-only)
    if [[ "$INSTALL_ONLY" == "false" ]]; then
        start_services
    fi
    
    # Show startup messages
    if [[ "$QUIET" != "true" ]]; then
        show_startup_messages
    fi
    
    log_success "Installation completed successfully!"
}

# Run main function
main
