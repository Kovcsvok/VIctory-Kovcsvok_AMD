@echo off
setlocal
rem C2 meres (Claude, 2026-11-26): KLBF Lab 63.2 + C1 (VIctory-dev\klbf-c2), -LowMemory (512 px),
rem sajat shader-cache, kozos mentesek. Elotte egyszer: Eloforditas-C2.cmd.
rem Sorrend (Codex, 2026-11-26): 1, 2, 3, 4. Ne nevezd at ezt a fajlt.
echo.
echo C2 meres: KLBF Lab 63.2 + MAP_LEAN
echo.
echo   1 = benchmark, MAP_LEAN ki  (5 perc: toltsd be a mentest, utana ne nyulj semmihez)
echo   2 = benchmark, MAP_LEAN be  (ugyanigy)
echo   3 = jatek 12 perc, MAP_LEAN be (16:04-es mentes, rablas es uldozes)
echo   4 = jatek 12 perc, MAP_LEAN ki (ugyanigy)
echo.
set "N="
set /p "N=Melyik? [1-4]: "
set "ARGS="
if "%N%"=="1" set "ARGS=-Nev C2-1-bench-lean0 -Bench -MapLean 0"
if "%N%"=="2" set "ARGS=-Nev C2-2-bench-lean1 -Bench -MapLean 1"
if "%N%"=="3" set "ARGS=-Nev C2-3-jatek-lean1 -MapLean 1"
if "%N%"=="4" set "ARGS=-Nev C2-4-jatek-lean0 -MapLean 0"
if "%ARGS%"=="" (
  echo Csak 1, 2, 3 vagy 4 lehet.
  pause
  exit /b 2
)
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File "%~dp0eszkozok\meres-klbf.ps1" %ARGS% -LowMemory -Fa klbf-c2
set "rc=%ERRORLEVEL%"
echo.
pause
exit /b %rc%
