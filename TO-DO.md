# 📋 TO-DO: Portable AI USB

## Completed ✅

### Core Platform (v1.0)
- [x] Project skeleton + directory structure
- [x] Hardware detection scripts (macOS/Windows/Linux)
- [x] Model detection scripts
- [x] Main installation script (setup.sh)
- [x] Configuration generation (config.sh)
- [x] Cross-platform launchers (mac, Windows, Linux variants)
- [x] Model management script (models.sh)
- [x] Cleanup script (cleanup.sh)
- [x] Uninstall script (uninstall.sh)
- [x] Project README
- [x] Architecture documentation (ARCHITECTURE.md)
- [x] Installation guide (INSTALLATION.md)

### Model System
- [x] Model manifest (config/models.json) with 9 models
- [x] Model pull script with verification
- [x] Model recommendation engine (auto-detect + install)
- [x] HuggingFace download fallback for all models
- [x] Model checksum verification framework
- [x] Model cleanup and cache management
- [x] Cross-platform GPU detection (NVIDIA, Apple, OpenCL)
- [x] Python manifest helper (model_manifest_helper.py)
- [x] Detection rules for RAM tiers
- [x] Download sources config (Ollama primary, HuggingFace fallback)
- [x] Checksum population helper (populate_checksums.sh)

### Web Server & UI
- [x] Web server (server/web_server.py — stdlib HTTP, no Flask dep)
- [x] HTML chat interface (server/ui.html)
- [x] Web UI CSS (server/ui.css)
- [x] Server config (server/config.py)
- [x] Server launcher (server/start.sh)
- [x] Conversation history — JSON file-per-session, streaming, rename, delete
- [x] Markdown rendering in web server

### Installers & Launchers
- [x] Universal installer (scripts/install/install.sh)
- [x] Fedora installer (install-fedora.sh)
- [x] Arch Linux installer (install-arch.sh)
- [x] Ubuntu launcher (start-ubuntu.sh)
- [x] Fedora launcher (start-fedora.sh)
- [x] Arch Linux launcher (start-arch.sh)
- [x] macOS launcher (launcher-mac.command)
- [x] Windows launcher (launcher-windows.bat)

### Documentation
- [x] .gitignore present
- [x] Project memory (PORTABLE-AI-USB/memory/PROJECT.md)

## In Progress 🚧

- [ ] **P0** Run populate_checksums.sh to populate SHA256 checksums (needs fast internet)
- [ ] **P0** Initialize git repo and push to GitHub
- [ ] **P1** Real-hardware testing (Mac mini Apple Silicon)
- [ ] **P1** Real-hardware testing (Linux distros)
- [ ] **P1** Windows launcher verification
- [ ] AnythingLLM integration scripts (v1.5)
- [ ] Comprehensive usage documentation

## Next Steps 🔜

### 1. Model Download Integration

**Manual → Automatic:**
- [ ] Add direct model download links (HuggingFace, Ollama library)
- [ ] Implement checksum verification
- [ ] Create model manifest (JSON/YAML)
- [ ] Add fallback download sources
- [ ] Create model pull script
- [ ] Implement model cache management
- [ ] Create uninstall script

**Model Sources:**
- [ ] llama3.2:1b-instruct (4GB+ RAM)
- [ ] llama3.1:8b-instruct (8GB+ RAM)
- [ ] llama3:70b-instruct (16GB+ RAM)
- [ ] mistral:7b (8GB+ RAM)
- [ ] codegemma:7b (8GB+ RAM)
- [ ] tinyllama:1.1b (2GB+ RAM)
- [ ] Llama 3.1 405b (for high-end only)

### 2. AnythingLLM Setup

**Installation:**
- [ ] Generate AnythingLLM installation script
- [ ] Configure default settings
- [ ] Add custom theme support
- [ ] Setup model routing
- [ ] Create knowledge base structure
- [ ] Add plugin support

**Configuration:**
- [ ] Default chat theme
- [ ] Model routing rules
- [ ] Knowledge base defaults
- [ ] User preferences storage
- [ ] Sync settings to USB

### 3. Testing

**Platform Testing:**
- [ ] Test installation on macOS (Apple Silicon)
- [ ] Test installation on macOS (Intel)
- [ ] Test installation on Windows (WSL2)
- [ ] Test installation on Windows (native)
- [ ] Test installation on Ubuntu 20.04
- [ ] Test installation on Ubuntu 22.04
- [ ] Test installation on Fedora
- [ ] Test installation on Arch Linux
- [ ] Test with 4GB RAM
- [ ] Test with 8GB RAM
- [ ] Test with 16GB RAM

**Functional Testing:**
- [ ] Test model auto-detection
- [ ] Test model download flow
- [ ] Test web server startup
- [ ] Test chat functionality
- [ ] Test history persistence
- [ ] Test cleanup scripts
- [ ] Test cross-platform compatibility
- [ ] Test all installer scripts
- [ ] Test launcher scripts

### 4. Documentation

**User Documentation:**
- [ ] Create installation guide (INSTALLATION.md)
- [ ] Write troubleshooting section
- [ ] Add FAQ
- [ ] Document model limitations
- [ ] Create quick start guide
- [ ] Write API reference
- [ ] Add code examples

**Developer Documentation:**
- [ ] Architecture overview
- [ ] Development setup guide
- [ ] Contribution guidelines
- [ ] Code review checklist
- [ ] Testing guidelines

**User-Facing:**
- [ ] Create video tutorial (optional)
- [ ] Write blog post series
- [ ] Create demo videos
- [ ] Document known issues
- [ ] Add user forum links

### 5. Advanced Features

**Model Management:**
- [ ] Add model fine-tuning support
- [ ] Implement quantization management
- [ ] Add GPU offloading optimization
- [ ] Create backup/restore functionality
- [ ] Add sync across USB drives
- [ ] Implement model pruning
- [ ] Add quantization conversion tools

**Performance:**
- [ ] GPU auto-detection
- [ ] VRAM optimization
- [ ] Context window management
- [ ] Response caching
- [ ] Batch processing
- [ ] Multi-model routing

**Security:**
- [ ] Add model access controls
- [ ] Implement rate limiting
- [ ] Add authentication
- [ ] Encrypt model storage
- [ ] Secure configuration

### 6. GitHub Deployment

**Repository Setup:**
- [ ] Initialize git repository
- [ ] Configure .gitignore
- [ ] Add LICENSE file (MIT)
- [ ] Write contributing guidelines
- [ ] Create release notes
- [ ] Add CI/CD workflows
- [ ] Setup GitHub Pages

**Release Management:**
- [ ] Create release workflow
- [ ] Add changelog
- [ ] Tag releases
- [ ] Generate release notes
- [ ] Create download links

### 7. Maintenance

**Updates:**
- [ ] Set up automated model updates
- [ ] Monitor Ollama releases
- [ ] Update dependencies
- [ ] Fix reported bugs
- [ ] Add feature requests

**Monitoring:**
- [ ] Add usage statistics
- [ ] Create health check endpoints
- [ ] Implement logging
- [ ] Set up alerts
- [ ] Create status dashboard

## Project Structure

```
PORTABLE-AI-USB/
├── README.md              ✅
├── TO-DO.md               ✅
├── ARCHITECTURE.md        ✅
├── INSTALLATION.md        ✅
├── scripts/
│   ├── detect/
│   │   ├── hardware.sh    ✅
│   │   └── model.sh       ✅
│   ├── install/
│   │   ├── setup.sh       ✅
│   │   ├── config.sh      ✅
│   │   ├── models.sh      ✅
│   │   ├── cleanup.sh     ✅
│   │   ├── install.sh     ✅ NEW
│   │   ├── install-fedora.sh     ✅ NEW
│   │   ├── install-arch.sh       ✅ NEW
│   │   ├── web_server.sh  ✅
│   │   ├── launcher-linux.sh       ✅
│   │   ├── launcher-mac.command    ✅
│   │   ├── launcher-windows.bat    ✅
│   │   └── launcher-ubuntu.sh      ✅ NEW
│   └── launcher/
│       └── start.sh       ✅
├── server/                ✅
│   ├── web_server.py     ✅
│   ├── ui.html           ✅
│   ├── ui.css            ✅
│   └── config.py         ✅
├── models/                🚧
├── ollama/                🚧
├── anythingllm/          🚧
├── anythingllm_data/     🚧
├── config/                🚧
└── log/                   🚧
```

## Current Status

**Status (2026-04-28 17:53 AEST): Core v1.0 structurally complete. 32 files stable. No code changes needed. Awaiting Manu's P0 actions: populate checksums + git init/push + real-hardware testing.**

**What's Done:**
- ✅ All infrastructure (detect, install, launcher, server scripts)
- ✅ Model manifest with 9 models, dual download URLs, RAM-tier detection rules
- ✅ Model management engine (recommend, list, auto-install, verify)
- ✅ Web UI server (stdlib HTTP, no Flask dep) + history persistence, streaming, rename/delete
- ✅ Documentation (README, ARCHITECTURE, INSTALLATION)
- ✅ Cross-platform installers (universal, Fedora, Arch)
- ✅ Cross-platform launchers (Ubuntu, Fedora, Arch, macOS, Windows)
- ✅ .gitignore present + git repo initialized (main, uncommitted)
- ✅ Model checksum verification framework + populate_checksums.sh helper
- ✅ Download retry logic (in models.sh)
- ✅ Markdown rendering in web server
- ✅ Conversation history — JSON file-per-session, streaming, rename, delete
- ✅ Uninstall script — safe, prompt-driven

**Blocking items (need Manu's action):**
1. **P0** — Run `scripts/manage/populate_checksums.sh` (fast internet required, downloads full models)
2. **P0** — `git add` + commit + push to GitHub
3. **P1** — Real-hardware testing (Mac mini Apple Silicon, Linux, Windows)

**File Count:** 32 files (stable since last review)

**Git Status:** `main` branch, no commits, all files untracked.

## Notes

- **Conversation history** — JSON file-per-session, streaming support, rename, delete
- **Uninstall script** — safe, prompt-driven, preserves user config by default
- **All installer/launcher scripts** validated and executable
- **Model manifest** with 9 models, dual download sources, RAM-tier detection
- **populate_checksums.sh** requires fast internet (downloads full models)
- **No git repo yet** — needs `git init` on first deploy
