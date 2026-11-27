@echo off
setlocal
rem C2 shader-eloforditas (Claude, 2026-11-26): a KLBF Lab 63.2 + C1 tesztaganak
rem (VIctory-dev\klbf-c2) sajat shader-cache-e (state\klbf-c2\cache). Egyszer kell, kb. 25 perc.
rem Kozben ne indits jatekot. Ne nevezd at ezt a fajlt.
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File "%~dp0eszkozok\meres-klbf.ps1" -Nev "C2-eloforditas" -Fa klbf-c2 -Elofordit
set "rc=%ERRORLEVEL%"
echo.
pause
exit /b %rc%
