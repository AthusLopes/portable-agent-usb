#!/usr/bin/env bash
# Build a portable agent USB drive.
# Usage: bash setup.sh /path/to/usb/mount
set -euo pipefail

USB="${1:?Usage: bash setup.sh /path/to/usb/mount}"
NODE_VERSION="22.14.0"

# Verify target exists
if [ ! -d "$USB" ]; then
    echo "Error: $USB is not a directory. Mount your USB drive first."
    exit 1
fi

echo "==> Building portable agent USB at: $USB"
echo "    Node.js version: $NODE_VERSION"
echo ""

# ── Directory structure ──────────────────────────────────────────────

echo "==> Creating directory structure..."
mkdir -p "$USB"/{bin/{win,linux},tools/{win/{claude-code,codex},linux/{claude-code,codex}},config/.claude/skills,temp}

# ── Node.js binaries ────────────────────────────────────────────────

if [ ! -d "$USB/bin/linux/node-v${NODE_VERSION}-linux-x64" ]; then
    echo "==> Downloading Node.js $NODE_VERSION for Linux..."
    curl -fSL --progress-bar \
        "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz" \
        | tar -xJ -C "$USB/bin/linux/"
else
    echo "==> Node.js Linux already present, skipping."
fi

if [ ! -d "$USB/bin/win/node-v${NODE_VERSION}-win-x64" ]; then
    echo "==> Downloading Node.js $NODE_VERSION for Windows..."
    TMP_ZIP=$(mktemp /tmp/node-win-XXXXXX.zip)
    curl -fSL --progress-bar \
        "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-win-x64.zip" \
        -o "$TMP_ZIP"
    unzip -q "$TMP_ZIP" -d "$USB/bin/win/"
    rm "$TMP_ZIP"
else
    echo "==> Node.js Windows already present, skipping."
fi

LINUX_NODE="$USB/bin/linux/node-v${NODE_VERSION}-linux-x64/bin/node"
LINUX_NPM="$USB/bin/linux/node-v${NODE_VERSION}-linux-x64/bin/npm"

# ── Install tools for Linux ─────────────────────────────────────────

echo "==> Installing Claude Code (Linux)..."
if [ ! -d "$USB/tools/linux/claude-code/node_modules" ]; then
    (cd "$USB/tools/linux/claude-code" && "$LINUX_NPM" init -y --silent 2>/dev/null && "$LINUX_NPM" install @anthropic-ai/claude-code)
else
    echo "    Already installed, skipping. Delete tools/linux/claude-code/node_modules to reinstall."
fi

echo "==> Installing Codex CLI (Linux)..."
if [ ! -d "$USB/tools/linux/codex/node_modules" ]; then
    (cd "$USB/tools/linux/codex" && "$LINUX_NPM" init -y --silent 2>/dev/null && "$LINUX_NPM" install @openai/codex)
else
    echo "    Already installed, skipping. Delete tools/linux/codex/node_modules to reinstall."
fi

# ── Install tools for Windows (cross-platform) ──────────────────────

echo "==> Installing Claude Code (Windows, cross-platform)..."
if [ ! -d "$USB/tools/win/claude-code/node_modules" ]; then
    (cd "$USB/tools/win/claude-code" && "$LINUX_NPM" init -y --silent 2>/dev/null && "$LINUX_NPM" install --os=win32 --cpu=x64 @anthropic-ai/claude-code)
else
    echo "    Already installed, skipping."
fi

echo "==> Installing Codex CLI (Windows, cross-platform)..."
if [ ! -d "$USB/tools/win/codex/node_modules" ]; then
    (cd "$USB/tools/win/codex" && "$LINUX_NPM" init -y --silent 2>/dev/null && "$LINUX_NPM" install --os=win32 --cpu=x64 @openai/codex)
else
    echo "    Already installed, skipping."
fi

# ── Launcher scripts ────────────────────────────────────────────────

echo "==> Copying launcher scripts..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cp "$SCRIPT_DIR/start.sh" "$USB/start.sh"
cp "$SCRIPT_DIR/start.bat" "$USB/start.bat"
cp "$SCRIPT_DIR/autorun.inf" "$USB/autorun.inf"
cp "$SCRIPT_DIR/icon.ico" "$USB/icon.ico" 2>/dev/null || true

# ── Config templates ────────────────────────────────────────────────

if [ ! -f "$USB/config/env.sh" ]; then
    echo "==> Creating API key templates..."
    cat > "$USB/config/env.sh" << 'ENVEOF'
export ANTHROPIC_API_KEY="YOUR_KEY_HERE"
export OPENAI_API_KEY="YOUR_KEY_HERE"
ENVEOF

    cat > "$USB/config/env.bat" << 'ENVEOF'
set "ANTHROPIC_API_KEY=YOUR_KEY_HERE"
set "OPENAI_API_KEY=YOUR_KEY_HERE"
ENVEOF
else
    echo "==> API key files already exist, not overwriting."
fi

if [ ! -f "$USB/config/.claude/CLAUDE.md" ]; then
    cat > "$USB/config/.claude/CLAUDE.md" << 'MDEOF'
# Portable Agent

You are running from a portable USB drive on someone else's machine.
Be mindful of the host system — don't modify system files without asking.
MDEOF
fi

# ── Windows setup fallback script ───────────────────────────────────

cp "$SCRIPT_DIR/setup-windows.bat" "$USB/setup-windows.bat"

# ── Done ─────────────────────────────────────────────────────────────

echo ""
echo "====================================="
echo "  Portable Agent USB ready!"
echo "====================================="
echo ""
echo "Next steps:"
echo "  1. Authenticate (choose one):"
echo "     a) OAuth: just launch and log in via browser (Pro/Max/Plus subscribers)"
echo "     b) API keys: edit config/env.sh and config/env.bat"
echo "  2. (Optional) Add skills to config/.claude/skills/"
echo "  3. (Optional) Edit config/.claude/CLAUDE.md"
echo "  4. Safely eject the USB drive"
echo ""
echo "Usage:"
echo "  Windows: double-click start.bat"
echo "  Linux:   bash start.sh"
