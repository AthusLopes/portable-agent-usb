@echo off
REM ── Windows-side setup ──
REM Use this ONLY if cross-platform npm install from Linux failed
REM for some packages. Run this on a Windows machine with the USB plugged in.

setlocal EnableDelayedExpansion

set "USB=%~dp0"
if "%USB:~-1%"=="\" set "USB=%USB:~0,-1%"

REM Find Node.js
for /d %%D in ("%USB%\bin\win\node-v*-win-x64") do set "NODE_DIR=%%D"
if not defined NODE_DIR (
    echo ERROR: Node.js for Windows not found.
    echo Run the Linux setup.sh first to download Node.js binaries.
    pause
    exit /b 1
)

set "PATH=%NODE_DIR%;%PATH%"
set "NPM_CONFIG_CACHE=%USB%\temp\npm-cache"

echo ==> Reinstalling Claude Code for Windows...
cd /d "%USB%\tools\win\claude-code"
if exist node_modules rmdir /s /q node_modules
call npm init -y >nul 2>&1
call npm install @anthropic-ai/claude-code

echo ==> Reinstalling Codex CLI for Windows...
cd /d "%USB%\tools\win\codex"
if exist node_modules rmdir /s /q node_modules
call npm init -y >nul 2>&1
call npm install @openai/codex

echo.
echo ==> Done! Windows packages reinstalled.
pause
