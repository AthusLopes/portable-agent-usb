#!/usr/bin/env bash
# Portable Agent USB Launcher (Linux)
set -euo pipefail

USB="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Find Node.js version dynamically ──
NODE_DIR=$(find "$USB/bin/linux" -maxdepth 1 -name "node-v*-linux-x64" -type d | head -1)
if [ -z "$NODE_DIR" ]; then
    echo "ERROR: Node.js not found in bin/linux/"
    echo "Run setup.sh first to build this USB drive."
    exit 1
fi

# ── Portable Node.js ──
export PATH="$NODE_DIR/bin:$PATH"

# ── Claude Code + Codex on PATH ──
export PATH="$USB/tools/linux/claude-code/node_modules/.bin:$PATH"
export PATH="$USB/tools/linux/codex/node_modules/.bin:$PATH"

# ── API keys ──
if [ -f "$USB/config/env.sh" ]; then
    source "$USB/config/env.sh"
else
    echo "WARNING: config/env.sh not found. API keys not loaded."
fi

# ── Claude Code config ──
export CLAUDE_CONFIG_DIR="$USB/config/.claude"

# ── Redirect temp/cache to USB ──
export TMPDIR="$USB/temp"
export NPM_CONFIG_CACHE="$USB/temp/npm-cache"
export NODE_COMPILE_CACHE="$USB/temp/node-cache"
export XDG_CONFIG_HOME="$USB/config"

mkdir -p "$USB/temp/npm-cache" "$USB/temp/node-cache"

# ── Launch ──
echo ""
echo " ======================================"
echo "  Portable Agent USB"
echo " ======================================"
echo "  Type 'claude' for Claude Code"
echo "  Type 'codex'  for OpenAI Codex"
echo "  Type 'exit'   to close"
echo " ======================================"
echo ""

cd "$HOME"
exec bash --norc --noprofile
