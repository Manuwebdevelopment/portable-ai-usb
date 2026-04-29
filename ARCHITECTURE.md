# 🏗️ Architecture: Portable AI USB

## Core Design Principles

1. **Zero Dependencies on Host** - Everything runs from USB
2. **Automatic Detection** - Identifies hardware, OS, available models
3. **Offline-First** - Works without internet after initial setup
4. **Self-Contained** - Includes all necessary binaries and configs
5. **Cross-Platform** - Works on macOS, Windows, Linux

## Component Overview

```
PORTABLE-AI-USB/
├── scripts/
│   ├── detect/
│   │   ├── hardware.sh    # Detects CPU, GPU, RAM, OS
│   │   └── model.sh       # Detects existing models
│   ├── install/
│   │   ├── setup.sh       # Main installer
│   │   ├── config.sh      # Config generation
│   │   ├── models.sh      # Model management
│   │   ├── cleanup.sh     # Cleanup utilities
│   │   ├── web_server.sh  # Web UI setup (NEW)
│   │   ├── launcher-mac.command
│   │   ├── launcher-windows.bat
│   │   └── launcher-linux.sh
│   └── launcher/
│       └── start.sh       # Platform-agnostic launcher
├── server/                 # Web server components (NEW)
│   ├── web_server.py      # Flask/FastAPI or Python http.server
│   ├── ui.html            # Chat interface
│   ├── ui.css             # Styling
│   └── config.py          # Server configuration
├── models/                 # Model storage (.gguf files)
├── ollama/                 # Ollama binary + data
├── anythingllm/           # AnythingLLM installation
├── anythingllm_data/      # User data (portable)
├── config/                 # Generated configs
└── log/                    # Installation logs
```

## Model Selection Logic

### Hardware-Based Selection

```python
def select_model(ram_gb, gpu_available):
    if gpu_available and ram_gb >= 16:
        return "llama3.1:8b-instruct-q8_0.gguf"  # GPU + 16GB RAM
    elif ram_gb >= 8:
        return "llama3.1:8b-instruct-q4_0.gguf"   # 8GB RAM
    elif ram_gb >= 4:
        return "llama3.2:1b-instruct-q4_0.gguf"   # 4GB RAM (minimal)
    else:
        return None  # Insufficient RAM
```

### Priority Order

1. **Large Models** (≥16GB RAM): Full-featured models
2. **Medium Models** (8-15GB RAM): Optimized quantizations
3. **Small Models** (4-7GB RAM): Compact models for limited RAM
4. **None** (<4GB RAM): Insufficient resources

## Web Server Options

### Option A: Python http.server (Simple)
- Zero dependencies
- Minimal code
- Basic chat interface only
- No model management

### Option B: Flask/FastAPI (Recommended)
- Model management endpoints
- Customizable UI
- Better error handling
- Streaming responses

### Option C: Go Binary (Lightweight)
- Single binary
- No dependencies
- Slower development
- Good for final product

**Current Decision:** Flask for development, potential Go rewrite for final release.

## Web UI Features

- **Model Selection**: Dropdown to choose loaded models
- **Chat Interface**: Clean, minimal design
- **API Proxy**: Forward to Ollama /api/chat, /api/generate
- **Markdown Support**: Render responses with markdown
- **Conversation History**: Store locally
- **Theme Customization**: Configurable colors

## Memory System

- `memory/YYYY-MM-DD.md` - Daily operation logs
- `memory/PROJECT.md` - Project context
- `MEMORY.md` - Personal wisdom (curated)

## Message Routing

Outputs can be sent to:
- **Telegram**
- **Discord**
- **BlueBubbles (WhatsApp)**
- **Email**

## Automation

- **Cron Jobs**: Scheduled tasks (daily, weekly)
- **Auto-start**: Launch on USB detection
- **Model Updates**: Automatic pull/checks

## Security

- No external dependencies
- Offline operation
- Local model storage
- No cloud API calls

## Limitations

- Requires host Ollama installed
- USB drive speed affects performance
- Model sizes limited by USB capacity
- No internet required after setup
