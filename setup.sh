#!/usr/bin/env bash
# Build a portable agent USB drive.
# Usage: bash setup.sh /path/to/usb/mount
set -euo pipefail

USB="${1:?Usage: bash setup.sh /path/to/usb/mount}"
NODE_VERSION="22.14.0"
STAGING="/tmp/portable-agent-staging"

# Verify target exists
if [ ! -d "$USB" ]; then
    echo "Error: $USB is not a directory. Mount your USB drive first."
    exit 1
fi

echo "==> Building portable agent USB at: $USB"
echo "    Node.js version: $NODE_VERSION"
echo "    Staging area: $STAGING"
echo ""

# ── Helper: copy tree, resolving symlinks ────────────────────────────

copy_resolved() {
    # Copy $1 to $2, replacing symlinks with real files (exFAT has no symlinks)
    rm -rf "$2"
    cp -rL "$1" "$2"
}

# ── Directory structure ──────────────────────────────────────────────

echo "==> Creating directory structure..."
mkdir -p "$USB"/{bin/{win,linux},tools/{win/{claude-code,codex},linux/{claude-code,codex}},config/.claude/skills,temp}

# Clean any corrupted config from previous runs
rm -f "$USB/config/.claude/.claude.json" "$USB/config/.claude/.credentials.json" 2>/dev/null
mkdir -p "$STAGING"/{node-linux,tools-linux/{claude-code,codex},tools-win/{claude-code,codex}}

# ── Node.js for Linux ───────────────────────────────────────────────

if [ ! -d "$USB/bin/linux/node-v${NODE_VERSION}-linux-x64" ]; then
    echo "==> Downloading Node.js $NODE_VERSION for Linux..."
    curl -fSL --progress-bar \
        "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz" \
        | tar -xJ -C "$STAGING/node-linux/"

    echo "==> Copying Node.js Linux to USB (resolving symlinks)..."
    copy_resolved "$STAGING/node-linux/node-v${NODE_VERSION}-linux-x64" \
                  "$USB/bin/linux/node-v${NODE_VERSION}-linux-x64"
else
    echo "==> Node.js Linux already present, skipping."
fi

# ── Node.js for Windows ─────────────────────────────────────────────

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

# Use staging Node.js for npm installs (symlinks work on local fs)
LINUX_NODE="$STAGING/node-linux/node-v${NODE_VERSION}-linux-x64/bin/node"
LINUX_NPM="$STAGING/node-linux/node-v${NODE_VERSION}-linux-x64/bin/npm"

# ── Install tools for Linux (in staging, then copy) ─────────────────

if [ ! -d "$USB/tools/linux/claude-code/node_modules" ]; then
    echo "==> Installing Claude Code (Linux)..."
    (cd "$STAGING/tools-linux/claude-code" && "$LINUX_NPM" init -y --silent 2>/dev/null && "$LINUX_NPM" install @anthropic-ai/claude-code)
    echo "==> Copying to USB (resolving symlinks)..."
    copy_resolved "$STAGING/tools-linux/claude-code" "$USB/tools/linux/claude-code"
else
    echo "==> Claude Code (Linux) already installed, skipping."
fi

if [ ! -d "$USB/tools/linux/codex/node_modules" ]; then
    echo "==> Installing Codex CLI (Linux)..."
    (cd "$STAGING/tools-linux/codex" && "$LINUX_NPM" init -y --silent 2>/dev/null && "$LINUX_NPM" install @openai/codex)
    echo "==> Copying to USB (resolving symlinks)..."
    copy_resolved "$STAGING/tools-linux/codex" "$USB/tools/linux/codex"
else
    echo "==> Codex CLI (Linux) already installed, skipping."
fi

# ── Install tools for Windows (in staging, then copy) ────────────────

if [ ! -d "$USB/tools/win/claude-code/node_modules" ]; then
    echo "==> Installing Claude Code (Windows, cross-platform)..."
    (cd "$STAGING/tools-win/claude-code" && "$LINUX_NPM" init -y --silent 2>/dev/null && "$LINUX_NPM" install --os=win32 --cpu=x64 @anthropic-ai/claude-code)
    echo "==> Copying to USB (resolving symlinks)..."
    copy_resolved "$STAGING/tools-win/claude-code" "$USB/tools/win/claude-code"
else
    echo "==> Claude Code (Windows) already installed, skipping."
fi

if [ ! -d "$USB/tools/win/codex/node_modules" ]; then
    echo "==> Installing Codex CLI (Windows, cross-platform)..."
    (cd "$STAGING/tools-win/codex" && "$LINUX_NPM" init -y --silent 2>/dev/null && "$LINUX_NPM" install --os=win32 --cpu=x64 @openai/codex)
    echo "==> Copying to USB (resolving symlinks)..."
    copy_resolved "$STAGING/tools-win/codex" "$USB/tools/win/codex"
else
    echo "==> Codex CLI (Windows) already installed, skipping."
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

# ── Flush writes to USB ──────────────────────────────────────────────

echo "==> Syncing writes to USB..."
sync

# ── Verify key binaries ─────────────────────────────────────────────

echo "==> Verifying installation..."
FAIL=0

NODE_BIN="$USB/bin/linux/node-v${NODE_VERSION}-linux-x64/bin/node"
if file "$NODE_BIN" | grep -q "ELF 64-bit"; then
    echo "    Node.js binary: OK"
else
    echo "    ERROR: Node.js binary is corrupted!"
    FAIL=1
fi

CLAUDE_BIN="$USB/tools/linux/claude-code/node_modules/.bin/claude"
if [ -s "$CLAUDE_BIN" ]; then
    echo "    Claude Code: OK ($(wc -c < "$CLAUDE_BIN") bytes)"
else
    echo "    ERROR: Claude Code binary is missing or empty!"
    FAIL=1
fi

CODEX_BIN="$USB/tools/linux/codex/node_modules/.bin/codex"
if [ -s "$CODEX_BIN" ]; then
    echo "    Codex CLI: OK ($(wc -c < "$CODEX_BIN") bytes)"
else
    echo "    ERROR: Codex CLI binary is missing or empty!"
    FAIL=1
fi

if [ "$FAIL" -eq 1 ]; then
    echo ""
    echo "ERROR: Verification failed. Try deleting the failed component and re-running setup."
    exit 1
fi

# ── Cleanup staging ─────────────────────────────────────────────────

echo "==> Cleaning up staging area..."
rm -rf "$STAGING"

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
