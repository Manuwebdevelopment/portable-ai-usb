# 🚀 Portable AI USB

A local AI system that runs from a USB stick or portable drive. Download models once, carry them anywhere, run on any computer.

## What It Does

- **Ollama** — local LLM engine (runs from USB, no cloud)
- **Model library** — `config/models.json` with 9 pre-configured models (4B to 70B+)
- **Flask web server** — browser-based chat UI with conversation history, multimodal input, and streaming
- **Cross-platform** — macOS, Linux, Windows launchers
- **Hardware detection** — auto-detects CPU/RAM/gpu and suggests the right model size
- **Offline** — works fully offline after models are downloaded

## Project Structure

```
PORTABLE-AI-USB/
├── server/
│   ├── web_server.py    Flask chat server (port 8080)
│   ├── config.py        Server configuration
│   └── ui.html          Chat interface
├── config/
│   └── models.json      Model manifest (names, URLs, sizes)
├── scripts/
│   ├── detect/
│   │   ├── hardware.sh  CPU / RAM / GPU detection
│   │   └── model.sh     Hardware-aware model selection
│   ├── install/
│   │   ├── install.sh   Ubuntu/Debian installer
│   │   ├── install-arch.sh   Arch Linux installer
│   │   ├── install-fedora.sh Fedora installer
│   │   ├── launcher-mac.command   macOS launcher (double-click)
│   │   ├── launcher-windows.bat   Windows launcher (double-click)
│   │   └── config.sh    Creates service/unit configs
│   └── manage/
│       ├── models.sh    Model management utilities
│       └── populate_checksums.sh  Fills SHA256 checksums
├── requirements.txt     Python dependencies (Flask)
├── .gitignore
└── TO-DO.md
```

## Quick Start

### 1. Install Ollama (one-time, per computer)

**macOS:**
```bash
brew install ollama
ollama serve
```

**Ubuntu/Debian:**
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

### 2. Pull a Model

```bash
ollama pull qwen2.5
# or
ollama pull llama3.2:1b   # for low-end PCs
```

Models are listed in `config/models.json`. See below for all options.

### 3. Launch

**macOS:** Double-click `scripts/install/launcher-mac.command`  
**Windows:** Double-click `scripts/install/launcher-windows.bat`  
**Linux:** 
```bash
ollama serve          # terminal 1
python3 -m server.web_server   # terminal 2
```

Then open `http://localhost:8080` in your browser.

## Models

| Model | Size | Min RAM | When to use |
|-------|------|---------|-------------|
| `qwen2.5` | ~8GB | 8GB | General purpose |
| `llama3.2:1b` | ~2GB | 4GB | Low-end PC |
| `llama3.2:3b` | ~4GB | 6GB | Balanced |
| `llama3.1:8b` | ~8GB | 8GB | Strongest small |
| `qwen3:8b` | ~8GB | 8GB | Good multilingual |
| `mistral:7b` | ~7GB | 8GB | Code + text |
| `llama3:70b` | ~40GB | 32GB | High-end |
| `codegemma:7b` | ~7GB | 8GB | Code-only |
| `tinyllama:1.1b` | ~2GB | 4GB | Ultra-low-end |

Full list and download URLs: `config/models.json`

## Configuration

Edit `server/.env.example` and rename to `server/.env` to customize:

```
WEB_PORT=8080         # Web server port
OLLAMA_HOST=http://localhost:11434   # Ollama endpoint
DEFAULT_MODEL=qwen2.5         # Initial model
MAX_TOKENS=4096       # Max response length
```

## Troubleshooting

**"Ollama not running"** — Start it first: `ollama serve`  
**Port already in use** — Change port in `.env` or kill the other process  
**"Out of memory"** — Pick a smaller model from the table above  
**Models not downloading** — Check `config/models.json` for available models  

## License

MIT
