# Portable Agent USB

Run Claude Code and OpenAI Codex from a USB drive on any Windows or Linux PC. No installation needed on the host machine.

Plug in. Click launcher. Work. Unplug. No traces left.

## What's Inside

- **Portable Node.js** for Windows and Linux (no install)
- **Claude Code** and **Codex CLI** pre-installed
- **Your skills, CLAUDE.md, and config** — all on the drive
- **All temp/cache** redirected to the USB — nothing written to host

## Quick Start

### 1. Build the USB

Format a USB drive as **exFAT** (works on both Windows and Linux).

Then run the setup script from your Linux machine:

```bash
git clone https://github.com/bnovik0v/portable-agent-usb.git
cd portable-agent-usb
bash setup.sh /mnt/your-usb-drive
```

### 2. Authenticate

You have two options:

**Option A: OAuth login (recommended for Pro/Max/Plus subscribers)**

No API keys needed. Just launch the agent on first use — it opens a browser to log in. Your auth token is saved on the USB drive, so you only do this once.

```bash
# After running setup.sh, launch from the USB:
bash /mnt/your-usb-drive/start.sh
# Then type 'claude' — it will prompt you to log in via browser
```

**Option B: API keys**

Edit the key files on the USB:

```bash
nano /mnt/your-usb-drive/config/env.sh       # Linux
# Or edit config\env.bat with Notepad          # Windows
```

Set your keys:
```
ANTHROPIC_API_KEY=sk-ant-...
OPENAI_API_KEY=sk-...
```

OAuth and API keys can coexist — if both are present, the API key takes priority.

### 3. Add Your Skills (optional)

Copy your skill files into `config/.claude/skills/` on the USB drive.
Edit `config/.claude/CLAUDE.md` with your global instructions.

### 4. Use It

**Windows:** Plug in the USB. When AutoPlay pops up, choose "Open folder". Double-click `start.bat`.

**Linux:** Plug in the USB. Open a terminal and run:
```bash
bash /media/$USER/PORTABLE-AGENT/start.sh
```

You'll get a terminal with `claude` and `codex` commands ready to use.

## Requirements

- **USB drive:** 1GB+ (USB 3.0 recommended for speed)
- **Host PC:** Windows 10/11 or Linux, x64 architecture
- **Setup machine:** Linux with `curl`, `unzip`, and internet access
- **Auth:** Anthropic/OpenAI API keys, OR a Claude Pro/Max or ChatGPT Plus subscription (OAuth)

## How "No Traces" Works

| Clean | How |
|---|---|
| No programs installed | Portable Node.js runs from USB |
| No files in user profile | APPDATA/HOME/TEMP redirected to USB |
| No npm cache on host | NPM_CONFIG_CACHE on USB |
| No config on host | CLAUDE_CONFIG_DIR on USB |
| OAuth tokens on USB | Auth persists across machines, not on host |

OS-level artifacts we can't prevent (and don't need to):
- Windows USB device history in registry/Event Viewer
- Linux mount logs in syslog

This is fine — the goal is not to install anything, not to evade forensics.

## USB Size

| Component | ~Size |
|---|---|
| Node.js (2 platforms) | 100 MB |
| Claude Code + Codex (2 platforms) | 400 MB |
| Config and scripts | 1 MB |
| **Total** | **~500 MB** |

## Customization

- Edit `config/.claude/CLAUDE.md` for Claude Code instructions
- Add skills to `config/.claude/skills/`
- Modify `start.bat` / `start.sh` to change startup behavior

## Limitations

- **x64 only** — won't work on ARM devices
- **No auto-run** — modern OSes block auto-execution from USB for security. You click the launcher once.
- **USB 2.0 is slow** — Node.js startup may take a few seconds. Use USB 3.0.
- **Cross-platform npm install** — the setup script uses `--os=win32` flag. If a package doesn't support this, run `setup-windows.bat` on a Windows machine once.

## License

MIT
