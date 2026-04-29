# 🚀 Portable AI USB

A local AI system that runs from any USB stick or portable drive. Download models once, carry them anywhere, and run on any computer — no cloud required.

## What It Does

- **Ollama** — local LLM engine that runs entirely from your USB drive
- **Model library** — `config/models.json` with 9 pre-configured models (2GB to 40GB)
- **Flask web server** — browser-based chat interface with live streaming, conversation history, and multimodal input
- **Cross-platform launchers** — one-click on macOS, Windows, and Linux
- **Hardware detection** — automatically detects your CPU, RAM, and GPU to recommend the right model
- **Fully offline** — works completely offline after the initial model download

## Quick Start

### 1. Install Ollama *(one-time per computer)*

**macOS:**
```bash
brew install ollama
ollama serve
```

**Ubuntu / Debian:**
```bash
./scripts/install/install.sh
```

**Arch Linux:**
```bash
./scripts/install/install-arch.sh
```

**Fedora:**
```bash
./scripts/install/install-fedora.sh
```

### 2. Clone the Project

```bash
git clone https://github.com/Manuwebdevelopment/portable-ai-usb.git
cd portable-ai-usb
```

### 3. Pull a Model

```bash
ollama pull qwen2.5
# or for low-end PCs:
ollama pull llama3.2:1b
```

### 4. Launch

**macOS:** Double-click `scripts/install/launcher-mac.command`  
**Windows:** Double-click `scripts/install/launcher-windows.bat`  
**Linux:**
```bash
ollama serve          # Terminal 1
python3 -m server.web_server   # Terminal 2
```

Then open **http://localhost:8080** in your browser.

## Available Models

| Model | Size | Min RAM | When to use |
|-------|------|---------|-------------|
| `qwen2.5` | ~8GB | 8GB | General purpose |
| `llama3.2:1b` | ~2GB | 4GB | Low-end PC |
| `llama3.2:3b` | ~4GB | 6GB | Balanced quality / size |
| `llama3.1:8b` | ~8GB | 8GB | Strongest small model |
| `qwen3:8b` | ~8GB | 8GB | Good multilingual |
| `mistral:7b` | ~7GB | 8GB | Code + text |
| `llama3:70b` | ~40GB | 32GB | High-end desktop |
| `codegemma:7b` | ~7GB | 8GB | Code-only tasks |
| `tinyllama:1.1b` | ~2GB | 4GB | Ultra-low-end |

Full list with download URLs in `config/models.json`.

## Project Structure

```
PORTABLE-AI-USB/
├── server/
│   ├── web_server.py   Flask chat server (port 8080)
│   ├── config.py       Server configuration
│   ├── ui.html         Chat web interface
│   ├── ui.css          Interface styles
│   └── start.sh        Quick start script
├── config/
│   └── models.json     Model manifest (all 9 configs)
├── scripts/
│   ├── detect/        Hardware & model detection
│   │   ├── hardware.sh
│   │   └── model.sh
│   ├── install/       Installers & launchers
│   │   ├── install.sh         Ubuntu/Debian
│   │   ├── install-arch.sh    Arch Linux
│   │   ├── install-fedora.sh  Fedora
│   │   ├── launcher-mac.command
│   │   ├── launcher-windows.bat
│   │   └── launcher-linux.sh
│   └── manage/        Model & checksum management
│       ├── models.sh
│       └── populate_checksums.sh
├── .gitignore
├── requirements.txt   Python dependencies (Flask)
├── TO-DO.md           Current development tasks
└── ARCHITECTURE.md    Full system design
```

## Configuration

Edit `server/.env.example` and rename to `server/.env` to customize:

```bash
WEB_PORT=8080           # Web server port
OLLAMA_HOST=http://localhost:11434    # Ollama endpoint
DEFAULT_MODEL=qwen2.5              # Initial model
MAX_TOKENS=4096               # Max response length
```

## Troubleshooting

| Problem | Solution |
|---------|----------|
| "Ollama not running" | Start it first: `ollama serve` |
| Port already in use | Change port in `.env` or kill the other process |
| "Out of memory" | Pick a smaller model from the table above |
| Models not downloading | Check `config/models.json` for available URLs |
| Launcher does nothing | Check `scripts/install/` — one-click launchers are ready to go |

## License

MIT
