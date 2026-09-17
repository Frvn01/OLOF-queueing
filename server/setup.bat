@echo off
title OLOF Clinic - Local Storage API Setup
color 0A

echo ==============================================================================
echo     OUR LADY OF FATIMA EYE, EAR, NOSE ^& THROAT CENTER
echo     Server Room Local Storage API Setup
echo ==============================================================================
echo.

:: 1. Check Python or Py launcher
set "PYTHON_CMD=python"
python --version >nul 2>&1
if errorlevel 1 (
    py --version >nul 2>&1
    if errorlevel 1 (
        echo [ERROR] Python is not installed or not in PATH!
        echo Please install Python 3.10+ from python.org and ensure "Add to PATH" is checked.
        pause
        exit /b 1
    )
    set "PYTHON_CMD=py"
)

echo [1/4] Python detected using %PYTHON_CMD%:
%PYTHON_CMD% --version
echo.

:: 2. Create Virtual Environment
echo [2/4] Setting up Python virtual environment (venv)...
if not exist "venv" (
    %PYTHON_CMD% -m venv venv
    echo Virtual environment created.
) else (
    echo Virtual environment already exists.
)
echo.

:: 3. Install Dependencies
echo [3/4] Installing dependencies from requirements.txt...
call venv\Scripts\activate.bat
venv\Scripts\python.exe -m pip install --upgrade pip
venv\Scripts\pip.exe install -r requirements.txt
if errorlevel 1 (
    echo [ERROR] Failed to install requirements!
    pause
    exit /b 1
)
echo Dependencies installed successfully.
echo.

:: 4. Create Storage Folders & Initialize DB
echo [4/4] Initializing local storage folders and SQLite database...
if not exist "storage" mkdir storage
if not exist "storage\photos" mkdir storage\photos
if not exist "storage\drawings" mkdir storage\drawings
if not exist "storage\attachments" mkdir storage\attachments
if not exist "storage\backups" mkdir storage\backups

venv\Scripts\python.exe -c "import database; database.init_db(); print('Database initialized successfully at storage/olof_local.db')"
echo.

echo ==============================================================================
echo [SUCCESS] Setup completed successfully!
echo.
echo To start the server, double click "start_server.bat".
echo Your tablets can connect to: http://<THIS_PC_IP>:8080
echo ==============================================================================
echo.
pause
