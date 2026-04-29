#!/bin/bash
# Web Server Installation Script

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USB_ROOT="${USB_ROOT:-$HOME/PORTABLE-AI-USB}"
SERVER_DIR="$USB_ROOT/server"
MODELS_DIR="$USB_ROOT/models"
OLLAMA_SOCKET="/var/run/ollama/ollama.sock"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Portable AI USB: Web Server Setup ===${NC}"

# Create server directory
mkdir -p "$SERVER_DIR"
echo -e "${GREEN}[OK]${NC} Created server directory: $SERVER_DIR"

# Copy web server files
if [ -f "$SERVER_DIR/web_server.py" ]; then
    echo -e "${GREEN}[OK]${NC} Web server files found"
else
    echo -e "${YELLOW}[WARN]${NC} Creating minimal web server..."
    python3 -c "
import sys
sys.path.insert(0, '$SERVER_DIR')
from web_server import app, run_server
run_server()
"
fi

# Check if server already exists
if [ -d "$SERVER_DIR/ollama" ]; then
    echo -e "${GREEN}[OK]${NC} Ollama data directory found"
else
    echo -e "${YELLOW}[INFO]${NC} Models not yet downloaded"
fi

# Create start script
cat > "$SERVER_DIR/start.sh" << 'EOF'
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Kill existing server
pkill -f "python.*web_server.py" 2>/dev/null || true

# Start Ollama if running
if command -v ollama &> /dev/null; then
    ollama serve &
    sleep 2
fi

# Start web server
cd "$SCRIPT_DIR"
python3 web_server.py

# Keep script alive
trap 'echo "Server running..."; sleep 1' EXIT INT TERM
EOF

chmod +x "$SERVER_DIR/start.sh"
echo -e "${GREEN}[OK]${NC} Created start script: $SERVER_DIR/start.sh"

echo -e "${GREEN}=== Setup Complete ===${NC}"
echo "To start web server:"
echo "  $SCRIPT_DIR/start.sh"
echo ""
echo "Then open: http://localhost:8080"
