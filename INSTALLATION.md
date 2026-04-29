# 📚 Installation Guide: Portable AI USB

## Prerequisites

- USB drive (16GB minimum, 32GB recommended)
- Host computer with:
  - **macOS**: Apple Silicon (M1/M2) or Intel
  - **Windows**: Windows 10/11, WSL2 support recommended
  - **Linux**: Ubuntu 20.04+, Fedora 38+
  - **RAM**: Minimum 4GB (8GB+ recommended)
  - **Storage**: 10GB+ available on USB

## Setup Steps

### 1. Prepare USB Drive

```bash
# Format USB (do this on any platform)
# macOS
diskutil eraseDisk ExFAT "PORTABLE-AI" /dev/disk2

# Windows (PowerShell as Admin)
New-Volume -FileSystem exFAT -FileSystemLabel "PORTABLE-AI" -DriveLetter P

# Linux
sudo mkfs.exfat /dev/sdX
```

### 2. Copy Project Files

Copy entire `PORTABLE-AI-USB/` folder to USB root.

### 3. Run Installer

```bash
# From USB drive
./scripts/install/setup.sh

# Follow prompts
# - Select models to download
# - Configure AnythingLLM
# - Choose output directories
```

### 4. Verify Installation

```bash
# Check components
./scripts/detect/hardware.sh
./scripts/detect/model.sh
```

### 5. Start Using AI

```bash
# macOS
./launcher/start-mac.command

# Windows
.\launcher\start-windows.bat

# Linux
./launcher/start-linux.sh

# Or use web UI
./scripts/install/web_server.sh
```

### 6. Access Web Interface

Open browser to `http://localhost:8080`

## Post-Installation

1. **Download Models**: Run installer prompts
2. **Configure AnythingLLM**: Set preferences
3. **Set Up Automations**: Configure cron jobs
4. **Customize UI**: Edit web server files as needed

## Troubleshooting

### Model Won't Load
```bash
# Check available RAM
./scripts/detect/hardware.sh

# Verify model integrity
./scripts/install/verify.sh
```

### Web Server Fails
```bash
# Check Ollama running
ollama list

# Restart Ollama
sudo launchctl kickstart -k com.ollama

# Windows
ollama serve

# Linux
sudo systemctl status ollama
```

### Insufficient RAM
- Use smaller models
- Close other applications
- Reduce GPU offloading

### Ollama Not Found
- Download from https://ollama.com
- Follow platform-specific installer
- Restart computer

## Uninstallation

```bash
./scripts/install/cleanup.sh
# or
sudo rm -rf PORTABLE-AI-USB/*
```

## Maintenance

- **Update Models**: `ollama pull <model>`
- **Update Ollama**: Download latest from website
- **Clear Cache**: `ollama clean`
- **Backup Models**: Copy `models/` folder

## Quick Start (5 Minutes)

```bash
# On USB drive
./scripts/install/setup.sh --quick \
  --model llama3.2:1b-instruct \
  --port 8080 \
  --install anythingllm

# Start web server
./scripts/install/web_server.sh

# Open browser
open http://localhost:8080
```

## Supported Models

- **llama3.2:1b** - 4GB+ RAM, fast
- **llama3.1:8b** - 8GB+ RAM, balanced
- **llama3:70b** - 16GB+ RAM, powerful
- **mistral:7b** - 8GB+ RAM, efficient
- **codegemma:7b** - 8GB+ RAM, code focused

## Advanced Configuration

Edit `config.py` for web server:

```python
SERVER_PORT = 8080
DEFAULT_MODEL = "llama3.2:1b-instruct"
MAX_CONTEXT = 4096
STREAM_RESPONSES = True
```

## Credits

- **Base Project**: techjarves/Portable-AI-USB
- **AI Engine**: Ollama
- **Chat Interface**: AnythingLLM
- **Built with**: OpenClaw

## License

MIT License
