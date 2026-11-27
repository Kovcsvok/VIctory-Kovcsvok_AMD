@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File "%~dp0eszkozok\eloforditas-agy-dxr.ps1" %*
set "rc=%errorlevel%"
echo.
if not "%rc%"=="0" (
    echo Hibakod: %rc%
) else (
    echo Shader eloforditas sikeresen befejezodott.
)
pause
exit /b %rc%
