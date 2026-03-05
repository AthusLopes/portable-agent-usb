# Portable Agent USB Drive — Design

## Goal

A USB flash drive you plug into any Windows or Linux PC to get a ready-to-use Claude Code + Codex CLI terminal. No installation on the host. Unplug and go.

## How It Works

1. Plug USB into friend's PC
2. Open file manager (auto-opens on most OSes)
3. Double-click `start.bat` (Windows) or run `bash start.sh` (Linux)
4. Terminal opens with `claude` and `codex` commands available
5. Work on their PC, unplug when done — nothing installed

## Architecture

### Filesystem Format

**exFAT** — native read/write on both Windows and modern Linux. No partition tricks needed. Only limitation: no Unix file permissions, which we work around in the launcher scripts.

### Directory Layout

```
USB_ROOT/
├── start.bat                    # Windows launcher (double-click)
├── start.sh                     # Linux launcher (bash start.sh)
│
├── bin/
│   ├── win/
│   │   └── node-v22.x-win-x64/       # Portable Node.js for Windows
│   │       ├── node.exe
│   │       ├── npm.cmd
│   │       └── npx.cmd
│   └── linux/
│       └── node-v22.x-linux-x64/     # Portable Node.js for Linux
│           └── bin/
│               ├── node
│               ├── npm
│               └── npx
│
├── tools/
│   ├── win/                           # npm packages installed for Windows
│   │   ├── claude-code/
│   │   │   └── node_modules/
│   │   └── codex/
│   │       └── node_modules/
│   └── linux/                         # npm packages installed for Linux
│       ├── claude-code/
│       │   └── node_modules/
│       └── codex/
│           └── node_modules/
│
├── config/
│   ├── env.bat                        # API keys (Windows)
│   ├── env.sh                         # API keys (Linux)
│   ├── .claude/                       # Claude Code config
│   │   ├── CLAUDE.md                  # Your global instructions
│   │   └── skills/                    # Your skill files
│   └── .codex/                        # Codex config (if applicable)
│
└── temp/                              # All temp/cache data stays on USB
    ├── npm-cache/
    ├── appdata/                       # Windows APPDATA redirect
    └── node-cache/                    # Node compile cache
```

### Why Separate `tools/win/` and `tools/linux/`

npm packages can contain **platform-specific native binaries** (e.g., esbuild, @rollup/rollup). A single `node_modules` built on Linux won't work on Windows and vice versa. We install twice — once per platform — during USB setup.

## Launcher Scripts

### start.bat (Windows)

```batch
@echo off
setlocal

REM Detect USB drive root
set "USB=%~dp0"

REM Portable Node.js
set "PATH=%USB%bin\win\node-v22-win-x64;%PATH%"

REM Claude Code + Codex on PATH
set "PATH=%USB%tools\win\claude-code\node_modules\.bin;%PATH%"
set "PATH=%USB%tools\win\codex\node_modules\.bin;%PATH%"

REM API keys
call "%USB%config\env.bat"

REM Claude Code config directory
set "CLAUDE_CONFIG_DIR=%USB%config\.claude"

REM Redirect temp/cache to USB (no traces on host)
set "APPDATA=%USB%temp\appdata"
set "LOCALAPPDATA=%USB%temp\localappdata"
set "TEMP=%USB%temp"
set "TMP=%USB%temp"
set "NPM_CONFIG_CACHE=%USB%temp\npm-cache"
set "NODE_COMPILE_CACHE=%USB%temp\node-cache"
set "XDG_CONFIG_HOME=%USB%config"

REM Create temp dirs if missing
if not exist "%USB%temp\appdata" mkdir "%USB%temp\appdata"
if not exist "%USB%temp\localappdata" mkdir "%USB%temp\localappdata"
if not exist "%USB%temp\npm-cache" mkdir "%USB%temp\npm-cache"
if not exist "%USB%temp\node-cache" mkdir "%USB%temp\node-cache"

echo.
echo ==============================
echo   Portable Agent Ready
echo ==============================
echo   claude  - Claude Code
echo   codex   - OpenAI Codex
echo ==============================
echo.

cmd /k
```

### start.sh (Linux)

```bash
#!/usr/bin/env bash
set -euo pipefail

USB="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Portable Node.js
export PATH="$USB/bin/linux/node-v22-linux-x64/bin:$PATH"

# Claude Code + Codex on PATH
export PATH="$USB/tools/linux/claude-code/node_modules/.bin:$PATH"
export PATH="$USB/tools/linux/codex/node_modules/.bin:$PATH"

# API keys
source "$USB/config/env.sh"

# Claude Code config
export CLAUDE_CONFIG_DIR="$USB/config/.claude"

# Redirect temp/cache to USB
export TMPDIR="$USB/temp"
export NPM_CONFIG_CACHE="$USB/temp/npm-cache"
export NODE_COMPILE_CACHE="$USB/temp/node-cache"
export XDG_CONFIG_HOME="$USB/config"

mkdir -p "$USB/temp/npm-cache" "$USB/temp/node-cache"

echo ""
echo "=============================="
echo "  Portable Agent Ready"
echo "=============================="
echo "  claude  - Claude Code"
echo "  codex   - OpenAI Codex"
echo "=============================="
echo ""

exec bash --norc --noprofile
```

## API Keys

Stored in plain text on the USB:

**config/env.bat:**
```batch
set "ANTHROPIC_API_KEY=sk-ant-xxx..."
set "OPENAI_API_KEY=sk-xxx..."
```

**config/env.sh:**
```bash
export ANTHROPIC_API_KEY="sk-ant-xxx..."
export OPENAI_API_KEY="sk-xxx..."
```

Risk: if you lose the USB, someone has your keys. Mitigation options:
- Use keys with spending limits / low balance
- Rotate keys after use if concerned
- Optional: encrypt with a password (adds friction)

## Setup Script (runs once on your Linux machine)

A `setup.sh` script to build the USB from scratch:

```bash
#!/usr/bin/env bash
# Usage: bash setup.sh /mnt/usb
set -euo pipefail

USB="${1:?Usage: bash setup.sh /path/to/usb/mount}"
NODE_VERSION="22.14.0"

echo "==> Setting up portable agent USB at: $USB"

# Create directory structure
mkdir -p "$USB"/{bin/{win,linux},tools/{win/{claude-code,codex},linux/{claude-code,codex}},config/.claude/skills,temp}

# Download Node.js for Linux
echo "==> Downloading Node.js $NODE_VERSION for Linux..."
curl -fSL "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz" \
  | tar -xJ -C "$USB/bin/linux/"

# Download Node.js for Windows
echo "==> Downloading Node.js $NODE_VERSION for Windows..."
curl -fSL "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-win-x64.zip" \
  -o /tmp/node-win.zip
unzip -q /tmp/node-win.zip -d "$USB/bin/win/"
rm /tmp/node-win.zip

# Install Claude Code for Linux (using Linux Node)
echo "==> Installing Claude Code (Linux)..."
LINUX_NPM="$USB/bin/linux/node-v${NODE_VERSION}-linux-x64/bin/npm"
(cd "$USB/tools/linux/claude-code" && "$LINUX_NPM" init -y && "$LINUX_NPM" install @anthropic-ai/claude-code)

# Install Codex for Linux
echo "==> Installing Codex CLI (Linux)..."
(cd "$USB/tools/linux/codex" && "$LINUX_NPM" init -y && "$LINUX_NPM" install @openai/codex)

# Install Claude Code for Windows (cross-platform)
echo "==> Installing Claude Code (Windows)..."
(cd "$USB/tools/win/claude-code" && "$LINUX_NPM" init -y && "$LINUX_NPM" install --os=win32 --cpu=x64 @anthropic-ai/claude-code)

# Install Codex for Windows (cross-platform)
echo "==> Installing Codex CLI (Windows)..."
(cd "$USB/tools/win/codex" && "$LINUX_NPM" init -y && "$LINUX_NPM" install --os=win32 --cpu=x64 @openai/codex)

# Create env templates
cat > "$USB/config/env.sh" << 'EOF'
export ANTHROPIC_API_KEY="YOUR_KEY_HERE"
export OPENAI_API_KEY="YOUR_KEY_HERE"
EOF

cat > "$USB/config/env.bat" << 'EOF'
set "ANTHROPIC_API_KEY=YOUR_KEY_HERE"
set "OPENAI_API_KEY=YOUR_KEY_HERE"
EOF

# Create default CLAUDE.md
cat > "$USB/config/.claude/CLAUDE.md" << 'EOF'
# Portable Agent

You are running from a portable USB drive.
Working directory is on the host machine.
EOF

# Copy launcher scripts
# (These should already exist from the repo, but create them if building from scratch)

echo ""
echo "==> Done! Next steps:"
echo "  1. Edit $USB/config/env.sh and $USB/config/env.bat with your API keys"
echo "  2. Add any skill files to $USB/config/.claude/skills/"
echo "  3. Safely eject the USB"
```

## What "No Traces" Actually Means

| What stays clean | How |
|---|---|
| No programs installed | Everything runs from USB, portable Node.js |
| No files in user profile | APPDATA/LOCALAPPDATA/TEMP redirected to USB |
| No npm cache on host | NPM_CONFIG_CACHE points to USB |
| No Claude config on host | CLAUDE_CONFIG_DIR points to USB |
| No Node.js temp on host | NODE_COMPILE_CACHE + TMPDIR on USB |

| What we can't prevent (OS-level) | Why |
|---|---|
| USB device history in Windows registry | Windows logs all USB insertions |
| Event Viewer logs | OS-level, requires admin to clear |
| Prefetch / Superfetch entries | Windows caches program launches |
| `/var/log/syslog` USB mount entry on Linux | Kernel logs device attach |

This is fine for your use case — you're helping a friend, not evading forensics.

## Estimated USB Size

| Component | Size |
|---|---|
| Node.js Linux x64 | ~50 MB |
| Node.js Windows x64 | ~50 MB |
| Claude Code + deps (x2 platforms) | ~200 MB |
| Codex + deps (x2 platforms) | ~200 MB |
| Skills, config, scripts | ~1 MB |
| **Total** | **~500 MB** |

Any 1GB+ USB 3.0 drive will work. USB 3.0 strongly recommended — Node.js startup on USB 2.0 will be noticeably slow.

## Limitations & Caveats

1. **Performance**: USB I/O is slower than SSD. First launch of `claude` or `codex` may take a few seconds.
2. **Cross-platform npm install**: The `--os=win32 --cpu=x64` flag works for most packages but some edge cases may need a real Windows machine to `npm install`. Test before relying on it.
3. **Architecture**: This design is x64 only. ARM64 machines (some Surface devices, Chromebooks) won't work.
4. **Windows Terminal**: The launcher opens `cmd.exe`. For a nicer experience, you could bundle [PortableGit](https://git-scm.com/download/win) (~350MB) which includes mintty + bash.
5. **Auto-launch**: Neither Windows nor Linux auto-run programs from USB drives for security reasons. The user must manually double-click the launcher. This is fine.
