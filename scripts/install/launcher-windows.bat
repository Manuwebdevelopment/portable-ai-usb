:: Portable AI USB — Windows launcher (batch)
@echo off
setlocal EnabledelayedExpansion

:: ──Defaults────────────────────────────────────────────────
set PORT=11434
set MODEL=qwen2.5
set LOG_DIR="%USERPROFILE%\.portable-ai-usb\logs"
set MODELS_DIR="%USERPROFILE%\.portable-ai-usb\models"
set OLLAMA_HOME="%USERPROFILE%\.portable-ai-usb\ollama"

mkdir "%USERPROFILE%\.portable-ai-usb" >nul 2>&1
mkdir !LOG_DIR! >nul 2>&1
mkdir !MODELS_DIR! >nul 2>&1
mkdir !OLLAMA_HOME! >nul 2>&1

:: ──Parse arguments────────────────────────────────────────
:argloop
if "%~1"=="" goto :parseend
if /i "%~1"=="--port" set PORT=%~2 & shift & shift & goto :argloop
if /i "%~1"=="--model" set MODEL=%~2 & shift & shift & goto :argloop
if /i "%~1"=="--verbose" set OLLAMA_DEBUG=1 & export OLLAMA_DEBUG & shift & goto :argloop
if /i "%~1"=="--help" goto :help
goto :argloop
:parseend

:: ──Check for Ollama───────────────────────────────────────
where ollama >nul 2>&1
if errorlevel 1 (
    echo [WARN] Ollama not found in PATH
    echo [INFO] Please install Ollama first: https://ollama.com
    echo [INFO] Then copy this script to USB\scripts\launcher\
    pause
    exit /b 1
)

:: ──Check if already running───────────────────────────────
ollama list >nul 2>&1
if not errorlevel 1 (
    echo [OK] Ollama already running on port !PORT!
    start "http://localhost:!PORT!"
    exit /b 0
)

:: ──Start Ollama────────────────────────────────────────────
echo [START] Portable AI USB...
:: Set environment for Ollama
set OLLAMA_MODELS=!MODELS_DIR!
set OLLAMA_HOST=127.0.0.1:!PORT!
start "Ollama" cmd /c "set OLLAMA_MODELS=!MODELS_DIR!\&set OLLAMA_HOST=127.0.0.1:!PORT!\&ollama serve --port !PORT!"

:: Wait for Ollama
echo [WAIT] Waiting for Ollama to start...
for /l %%i in (1,1,30) do (
    ollama list >nul 2>&1
    if not errorlevel 1 (
        echo [OK] Ollama is running
        goto :launch
    )
    timeout /t 1 /nobreak >nul
)
echo [ERR] Ollama did not start in 30 seconds
exit /b 1

:: ──Launch UI──────────────────────────────────────────────
:launch
start "http://localhost:!PORT!"
echo [OK] Portable AI USB is running!
echo    - Ollama: http://localhost:!PORT!
echo    - Models: !MODELS_DIR!
echo    - Logs: !LOG_DIR!
timeout /t 3 /nobreak >nul
endlocal
