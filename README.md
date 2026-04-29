# 🚀 Portable AI USB

A local AI system that runs from any USB stick or portable drive. Download models once, carry them anywhere, and run on any computer — no cloud required.

## What It Does

- **Ollama** — local LLM engine that runs entirely from your USB drive
- **Model library** — `config/models.json` with 9 pre-configured models (2GB to 40GB)
- **Flask web server** — browser-based chat interface with live streaming, conversation history, and multimodal input
- **Cross-platform launchers** — one-click on macOS, Windows, and Linux
- **Hardware detection** — automatically detects your CPU, RAM, and GPU to recommend the right model
- **Fully offline** — works completely offline after the initial model download

## Getting Started: USB Setup

This section walks you through preparing a physical USB drive, installing the project onto it, and running from any computer.

### 1. Preparing the USB Drive

**Recommended USB size:** 32GB+ minimum (project + models can easily exceed 50GB). For 70B models, plan on 128GB+ drives.

**Filesystem: ExFAT, not FAT32.**

| Filesystem | Max single file | Cross-platform | Suitable? |
|---|---|---|---|
| FAT32 | 4 GB | ✅ macOS / Windows / Linux | ❌ Models larger than 4 GB won't fit |
| **ExFAT** | 16 EB | ✅ macOS / Windows / Linux | ✅ **Recommended** |
| NTFS | 16 TB | ⚠️ Windows native, macOS read-only | ❌ macOS can't write |
| APFS | — | ✅ macOS only | ❌ Not usable on Windows/Linux |
| ext4 | 16 EB | ✅ Linux native | ❌ Not usable on macOS/Windows native |

**Format the drive (back up any existing data first):**

```bash
# macOS
diskutil eraseDisk ExFAT "PORTABLE-AI" /dev/disk2

# Windows (PowerShell as Administrator)
New-Volume -FileSystem ExFAT -FileSystemLabel "PORTABLE-AI" -Force

# Linux (replace /dev/sdX with your USB device — double check with `lsblk`!)
sudo mkfs.exfat -n "PORTABLE-AI" /dev/sdX
```

> ⚠️  **Never format the wrong disk.** Always verify the device name with `lsblk` (Linux), `diskutil list` (macOS), or Disk Management (Windows) before running a format command.

### 2. Copying the Project Files

**Option A: Copy the entire repo folder (recommended)**

Copy the **entire** `PORTABLE-AI-USB/` folder to the root of your USB drive. Keep the directory structure intact — launchers and scripts rely on relative paths.

```
PORTABLE-AI/   ← USB root
├── server/     ← Web server code
├── config/     ← Model manifest & configs
├── scripts/    ← Installers, launchers, helpers
├── models/     ← Created by setup.sh (model files go here)
├── ollama/     ← Created by setup.sh (portable Ollama binary)
└── requirements.txt
```

Don't extract or flatten the contents — the launchers detect the USB root by walking up from their own location, so the project must sit as a coherent folder.

**Option B: Git clone directly onto the USB**

If you're comfortable with Git:

```bash
# Clone directly into the USB mount point (macOS or Linux)
git clone https://github.com/Manuwebdevelopment/portable-ai-usb /Volumes/PORTABLE-AI/portable-ai-usb
cd /Volumes/PORTABLE-AI/portable-ai-usb
chmod +x scripts/install/*.sh
chmod +x scripts/install/launcher-mac.command
```

This is useful for keeping in sync with upstream changes. For a one-shot copy, use Option A.

> ⚠️  **Ignore the `git clone` step in the Quick Start** below if you're running from USB — that section assumes you're developing on the host. See the setup below instead.

### 3. First-Time Setup on a New Computer

What runs from the USB vs. what lives on the host depends on your approach:

| Component | From USB | Installed on Host |
|---|---|---|
| **Ollama binary** | ✅ (via setup.sh) — or use host-installed version | ❌ Not needed if USB binary is used |
| **Model files** | ✅ Stored in `models/` on USB | ❌ Nothing persistent on host |
| **Python + Flask** | ✅ Python is the portable part; Flask via `requirements.txt` | ✅ Python 3.8+ must exist on the host (usually does) |
| **Web server code** | ✅ `server/` on USB | ❌ Runs from USB |
| **Launchers** | ✅ One-click scripts on USB | ❌ Nothing persistent |

**The setup flow:**

1. **Plug in the USB** to your target computer.

2. **Run the setup script** from the USB:

   ```bash
   # macOS
   /Volumes/PORTABLE-AI/portable-ai-usb/scripts/install/setup.sh

   # Linux (from USB mount)
   /media/$USER/PORTABLE-AI/portable-ai-usb/scripts/install/setup.sh
   ```

   This script:
   - Creates USB-side `models/`, `ollama/`, `config/`, `log/` directories
   - Downloads a portable Ollama binary onto the USB (on macOS); on Linux it asks you to install Ollama on the host
   - Generates configuration files (`.env`, launchers)
   - Detects your RAM and recommends suitable models

3. **Pull your models** — the models themselves download into the USB's `models/` folder:

   ```bash
   # After setup.sh, pull a model (will be stored on USB)
   ollama pull llama3.2:1b
   # or for larger machines
   ollama pull qwen2.5
   ```

   > The `setup.sh` script attempts to pull a default model automatically. If you have internet, it'll download into the USB's model directory. If not, pull models manually at your next connected session and add more later.

4. **If you don't run setup.sh**, you can still use the project manually:
   - Install Ollama on the host (one-time)
   - Pull models manually via `ollama pull <name>`
   - The web server will still read models from Ollama's default store (which lives on the host, not USB)

### 4. Plugging In and Running on Any Machine

After the one-time setup, using the USB is plug-and-play:

**On macOS:**
```bash
# 1. Plug in the USB
# 2. Double-click the launcher (or run from terminal)
/Volumes/PORTABLE-AI/portable-ai-usb/scripts/install/launcher-mac.command
```

**On Windows:**
1. Plug in the USB
2. Open File Explorer → USB drive → navigate to `portable-ai-usb`
3. Double-click `scripts\install\launcher-windows.bat`

**On Linux:**
```bash
# 1. Plug in the USB (usually mounts to /media/$USER/PORTABLE-AI)
# 2. Run the Linux launcher
./scripts/install/launcher-linux.sh
```

The launcher:
1. Detects the USB's mount point automatically (using `$0` relative path resolution)
2. Starts Ollama from the USB's portable binary (if present) or falls back to host Ollama
3. Starts the Flask web server from USB's `server/` directory
4. Opens the browser to `http://localhost:8080`

You can now chat through the web interface. Everything — models, configs, conversation data — lives on or is served from the USB.

### 5. Limitations & Gotchas

| Limitation | Workaround |
|---|---|
| **USB write speed** | Use USB 3.0+ drives (USB-A or USB-C depending on your ports). USB 2.0 will be painfully slow for model loading. |
| **USB capacity** | 7B models ≈ 5–8 GB each (quantized). The 70B model is ~40 GB. Pick your drive size accordingly — 64GB or 128GB is practical for most use cases. |
| **Ollama on host** | The installer tries to put a portable Ollama binary on the USB, but on Linux and Windows the host still needs Ollama installed. macOS gets a fully self-contained experience. |
| **One computer at a time** | Ollama binds to `localhost` — you can't run the same USB on multiple computers simultaneously (the web server would conflict on port binding). |
| **Port conflicts** | If another service uses port 8080, edit `server/.env` (or `config/.env`) and change `WEB_PORT=8080` to an available port. |
| **Host Python version** | The USB's Python code needs Python 3.8+. If the host doesn't have it, install Python before running. Python is almost universally present on modern macOS and Linux systems. |
| **Not a boot drive** | This project is not designed to boot a computer from USB. It is a portable runtime — the host OS must already be running. |
| **Antivirus false positives** | Some AV tools flag the launcher scripts and Python executables as suspicious. If this happens, add the USB folder to your AV exclusion list. |

> 💡 **Pro tip:** Keep a small text file on the USB named `README-portable.txt` with notes like "last pulled models: [list]" so next time you plug it in on a different machine you remember what's already there.

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
