@echo off
setlocal
chcp 65001 >nul
cd /d "%~dp0"

:menu
cls
echo ============================================================
echo   VIctory AGY-9070-v2  (RX 9070 XT / RDNA 4 + Intel Core Ultra)
echo ============================================================
echo.
echo   [1] Ajanlott stabil (30 FPS, FSR 0.5, 512 MB tex, osszes fix + Port 1)
echo   [2] 60 FPS es elesseg teszt (MaxFPS 60, FSR 0.5, 512 MB tex)
echo   [3] Port 1 nelkul (ha Port 1 meg fagyna vagy torzitana - A/B teszt)
echo   [4] Magasabb texturak (1024 MB tex, MaxFPS 60, FSR 0.5)
echo   [5] Kepernyokepes + teljes diagnozis (30 FPS + kepsor.ps1)
echo   [6] Shader + Compute PSO eloforditas futtatasa (Eloforditas-AGY-v2.cmd)
echo.
set /p "choice=Melyik? [1-6]: "

if "%choice%"=="1" goto opt1
if "%choice%"=="2" goto opt2
if "%choice%"=="3" goto opt3
if "%choice%"=="4" goto opt4
if "%choice%"=="5" goto opt5
if "%choice%"=="6" goto opt6

echo Ervenytelen valasztas: %choice%
timeout /t 2 >nul
goto menu

:opt1
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File "%~dp0eszkozok\meres-agy-v2.ps1" -Nev agyv2-stabil-30 -TexMax 512 -Sharp 0.5 -MaxFps alap
goto done

:opt2
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File "%~dp0eszkozok\meres-agy-v2.ps1" -Nev agyv2-60fps-eles -TexMax 512 -Sharp 0.5 -MaxFps 60
goto done

:opt3
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File "%~dp0eszkozok\meres-agy-v2.ps1" -Nev agyv2-30fps-port1ki -TexMax 512 -Sharp 0.5 -MaxFps alap -Port1 ki
goto done

:opt4
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File "%~dp0eszkozok\meres-agy-v2.ps1" -Nev agyv2-1024-60fps -TexMax 1024 -Sharp 0.5 -MaxFps 60
goto done

:opt5
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File "%~dp0eszkozok\meres-agy-v2.ps1" -Nev agyv2-30fps-kepsor -TexMax 512 -Sharp 0.5 -MaxFps alap -Kepsor
goto done

:opt6
call "%~dp0Eloforditas-AGY-v2.cmd"
exit /b %errorlevel%

:done
set "rc=%errorlevel%"
echo.
echo Kesz (exit=%rc%).
pause
exit /b %rc%
