@echo off
setlocal EnableDelayedExpansion

REM ── Portable Agent USB Launcher (Windows) ──

REM Detect USB drive root (where this script lives)
set "USB=%~dp0"
REM Remove trailing backslash for consistency
if "%USB:~-1%"=="\" set "USB=%USB:~0,-1%"

REM ── Find Node.js version dynamically ──
for /d %%D in ("%USB%\bin\win\node-v*-win-x64") do set "NODE_DIR=%%D"
if not defined NODE_DIR (
    echo ERROR: Node.js not found in bin\win\
    echo Run setup.sh first to build this USB drive.
    pause
    exit /b 1
)

REM ── Portable Node.js ──
set "PATH=%NODE_DIR%;%PATH%"

REM ── Claude Code + Codex on PATH ──
set "PATH=%USB%\tools\win\claude-code\node_modules\.bin;%PATH%"
set "PATH=%USB%\tools\win\codex\node_modules\.bin;%PATH%"

REM ── API keys (optional if using OAuth) ──
if exist "%USB%\config\env.bat" (
    call "%USB%\config\env.bat"
)

REM ── Claude Code config ──
set "CLAUDE_CONFIG_DIR=%USB%\config\.claude"

REM ── Redirect all temp/cache to USB (no traces on host) ──
set "APPDATA=%USB%\temp\appdata"
set "LOCALAPPDATA=%USB%\temp\localappdata"
set "TEMP=%USB%\temp"
set "TMP=%USB%\temp"
set "NPM_CONFIG_CACHE=%USB%\temp\npm-cache"
set "NODE_COMPILE_CACHE=%USB%\temp\node-cache"
set "XDG_CONFIG_HOME=%USB%\config"

REM ── Create temp dirs ──
if not exist "%USB%\temp\appdata" mkdir "%USB%\temp\appdata"
if not exist "%USB%\temp\localappdata" mkdir "%USB%\temp\localappdata"
if not exist "%USB%\temp\npm-cache" mkdir "%USB%\temp\npm-cache"
if not exist "%USB%\temp\node-cache" mkdir "%USB%\temp\node-cache"

REM ── Launch ──
cls
echo.
echo  ======================================
echo   Portable Agent USB
echo  ======================================
echo   Type 'claude' for Claude Code
echo   Type 'codex'  for OpenAI Codex
echo   Type 'exit'   to close
echo  ======================================
if "%ANTHROPIC_API_KEY%"=="YOUR_KEY_HERE" (
    echo.
    echo   No API key found - claude will
    echo   prompt OAuth login on first use.
    echo  ======================================
)
if not defined ANTHROPIC_API_KEY (
    echo.
    echo   No API key found - claude will
    echo   prompt OAuth login on first use.
    echo  ======================================
)
echo.

cmd /k "cd /d %USERPROFILE%"
