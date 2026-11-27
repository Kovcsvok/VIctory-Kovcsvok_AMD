@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File "%~dp0VIctory-dev\Kezeles.ps1" -Mode Build %*
set "rc=%ERRORLEVEL%"
if not "%rc%"=="0" pause
exit /b %rc%
