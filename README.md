# 🚀 Portable AI USB

A local AI system that runs 100% from a USB drive, works on any computer, offline after setup.

## 🎯 Core Features

- ✅ **100% Portable** - Everything runs from USB
- ✅ **Offline After Setup** - No internet needed after initial install
- ✅ **Multi-Platform** - Windows, macOS, Linux
- ✅ **Dynamic Model Selection** - Auto-selects models based on hardware
- ✅ **Multi-Agent Orchestration** - Spawn specialized agents per task
- ✅ **Tool Integration** - Web search, file access, PDF analysis, image vision
- ✅ **Message Routing** - Send outputs to BlueBubbles, Telegram, Discord
- ✅ **Automated Workflows** - Cron jobs for scheduled tasks
- ✅ **Memory System** - Daily notes + long-term curated memory
- ✅ **Voice Capabilities** - TTS for stories, summaries, notifications

## 📋 What's Different from Portable-AI-USB

| Feature | Portable-AI-USB | This Project |
|---------|------------------|---------------|
| Portability | USB drive | USB drive + Workspace sync |
| Models | 1 per session | Dynamic switching |
| Agents | Single chat | Multi-agent orchestration |
| Tools | None | Full tool integration |
| Memory | Local chats | Curated memory system |
| Automation | Manual | Cron jobs |
| Message Routing | None | Channel plugins |
| Hardware Access | Limited | Full device control |

## 🛠️ Architecture

```
PORTABLE-AI-USB/
├── scripts/
│   ├── detect/           # Hardware detection
│   ├── install/          # Setup scripts
│   └── launcher/         # Platform launchers
├── models/               # Model files (.gguf)
├── config/               # Generated configs
├── ollama/               # AI engine
├── anythingllm/         # Chat interface
├── anythingllm_data/    # User data (portable)
└── log/                  # Installation logs
```

## 🚀 Setup (One-Time)

1. Copy repo to USB drive
2. Run `scripts/install/setup.sh`
3. Download desired models
4. Configure AnythingLLM
5. Run `launcher/start-[platform].sh`

## 📁 Usage

After setup, use any platform:
- **macOS**: `launcher/start-mac.command`
- **Windows**: `launcher/start-windows.bat`
- **Linux**: `launcher/start-linux.sh`

## 🧠 Memory System

- `memory/YYYY-MM-DD.md` - Daily logs (written when needed)
- `memory/PROJECT.md` - Project context

## 🔄 Multi-Project Support

Create new project folders:
- `PORTABLE-AI-USB/`
- `ANOTHER-PROJECT/`
- Each gets its own cron job, session, workspace

## 📖 Documentation

- [ARCHITECTURE.md](ARCHITECTURE.md) - Design decisions
- [INSTALLATION.md](INSTALLATION.md) - Setup guide
- [TO-DO.md](TO-DO.md) - Current tasks

## 🔧 Development

Run from your local workspace:
```bash
# Continue project
openclaw status
# or spawn new session
sessions_spawn(task="Continue Portable AI USB")
```

## 📚 Credits

- Inspired by: techjarves/Portable-AI-USB  
Built with: Hermes Agent on macOS

## 📄 License

MIT License
