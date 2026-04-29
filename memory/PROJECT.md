# Portable AI USB - Project Context

## Current State (2026-04-28 09:53 AEST)

**Status:** Core platform complete (v1.0). All infrastructure built and validated. Git repo initialized on `main` (no commits yet). Awaiting Manu's P0 actions to populate checksums and push to GitHub.

**File count:** 31 files (stable)

### Recent Changes (2026-04-27)
- Git repo initialized on `main` branch (was untracked before)
- TO-DO.md updated with latest status
- Project memory refreshed

### Git Status
- Branch: `main`
- Commits: 0 (all files untracked)
- Needs: `git add` + commit + push to GitHub

## Completed Infrastructure

### Scripts
- **Detection**: `scripts/detect/hardware.sh`, `scripts/detect/model.sh`
- **Installation**: Universal, Fedora, Arch Linux installers
- **Launchers**: macOS, Windows, Linux, Ubuntu, Fedora, Arch
- **Management**: `cleanup.sh`, `models.sh`
- **Web Server**: `scripts/install/web_server.sh`

### Server Components
- `server/web_server.py` - stdlib HTTP server (no Flask dep) with Ollama proxy
- `server/ui.html` - Chat interface
- `server/ui.css` - Styling
- `server/config.py` - Configuration
- `server/start.sh` - Launcher

### Documentation
- `README.md` - Project overview
- `TO-DO.md` - Task tracking
- `ARCHITECTURE.md` - Design decisions
- `INSTALLATION.md` - Setup guide

## In Progress

### Model System (Next)
1. Create model manifest (JSON/YAML)
2. Add download URLs (HuggingFace, Ollama library)
3. Implement checksum verification
4. Create model pull script
5. Add model cache management

### AnythingLLM Integration
1. Generate installation script
2. Configure default settings
3. Setup model routing
4. Create knowledge base structure
5. Add plugin support

### Testing
1. macOS (Apple Silicon)
2. macOS (Intel)
3. Windows (WSL2)
4. Windows (native)
5. Ubuntu 20.04/22.04
6. Fedora
7. Arch Linux
8. 4GB/8GB/16GB RAM variants

## Model Sources

- llama3.2:1b-instruct (4GB+ RAM)
- llama3.1:8b-instruct (8GB+ RAM)
- llama3:70b-instruct (16GB+ RAM)
- mistral:7b (8GB+ RAM)
- codegemma:7b (8GB+ RAM)
- tinyllama:1.1b (2GB+ RAM)
- Llama 3.1 405b (high-end only)

## Project Structure

```
PORTABLE-AI-USB/
├── README.md ✅
├── TO-DO.md ✅
├── ARCHITECTURE.md ✅
├── INSTALLATION.md ✅
├── scripts/
│   ├── detect/
│   │   ├── hardware.sh ✅
│   │   └── model.sh ✅
│   ├── install/
│   │   ├── setup.sh ✅
│   │   ├── config.sh ✅
│   │   ├── models.sh ✅
│   │   ├── cleanup.sh ✅
│   │   ├── install.sh ✅
│   │   ├── install-fedora.sh ✅
│   │   ├── install-arch.sh ✅
│   │   ├── web_server.sh ✅
│   │   └── launcher-ubuntu.sh ✅
│   └── launcher/
│       └── start.sh ✅
├── server/ ✅
│   ├── web_server.py ✅
│   ├── ui.html ✅
│   ├── ui.css ✅
│   └── config.py ✅
├── models/ 🚧
├── ollama/ 🚧
├── anythingllm/ 🚧
├── anythingllm_data/ 🚧
├── config/ 🚧
└── log/ 🚧
```

## Next Steps

1. **Model System**: Manifest, URLs, checksums, pull script
2. **AnythingLLM**: Installation script, configuration
3. **Testing**: Platform compatibility validation
4. **Documentation**: Usage guide, troubleshooting, FAQ

---

**Date**: 2026-04-17  
**Session**: Cron progress check
