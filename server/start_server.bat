@echo off
title OLOF Clinic - Local Storage & Streaming Server (Port 8080)
color 0B

:start
cls
echo ==============================================================================
echo     OUR LADY OF FATIMA EYE, EAR, NOSE ^& THROAT CENTER
echo     Server Room Local Big Data Storage API
echo ==============================================================================
echo.

:: Check if venv exists
if not exist "venv\Scripts\activate.bat" (
    echo [NOTICE] First time running? Setting up environment first...
    call setup.bat
    if errorlevel 1 goto error
)

:: Activate virtual environment
call venv\Scripts\activate.bat

:: Display Network IP for tablets
echo [NETWORK CONFIGURATION]
echo Available IP addresses for tablets/kiosks to connect:
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4 Address"') do (
    echo   -> http:%%a:8080
    echo   -> API Docs: http:%%a:8080/docs
)
echo.
echo Server root storage directory: %~dp0storage
echo Press CTRL+C to safely stop the server.
echo ==============================================================================
echo.

:: Run FastAPI server using uvicorn binding to all interfaces on port 8080
venv\Scripts\python.exe -m uvicorn main:app --host 0.0.0.0 --port 8080

if errorlevel 1 (
    echo.
    echo [WARNING] Server stopped with an error code.
    echo Restarting in 5 seconds... (Press CTRL+C to terminate)
    timeout /t 5 /nobreak >nul
    goto start
)

echo.
echo Server shut down cleanly.
pause
exit /b 0

:error
echo [FATAL ERROR] Setup failed. Please check Python installation and dependencies.
pause
exit /b 1
