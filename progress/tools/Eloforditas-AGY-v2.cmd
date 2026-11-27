@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File "%~dp0eszkozok\eloforditas-agy-v2.ps1" %*
set "rc=%errorlevel%"
echo.
if not "%rc%"=="0" (
    echo Hibakod: %rc%
) else (
    echo Eloforditas sikeresen befejezodott.
)
pause
exit /b %rc%
