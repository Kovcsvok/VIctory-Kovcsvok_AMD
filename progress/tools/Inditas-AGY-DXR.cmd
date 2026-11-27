@echo off
setlocal
chcp 65001 >nul
cd /d "%~dp0"

:menu
cls
echo ============================================================================
echo   VIctory AGY-DXR-Fast  (RX 9070 XT / RDNA 4 - Nativ DXR 1.1 + caf96a opt)
echo ============================================================================
echo.
echo   [1] Series X Nativ DXR 1.1 + caf96a opt (Alapertelmezett Release 30 FPS meres)
echo   [2] Series X Nativ DXR 1.1 - 30 FPS korlat feloldva (^>30 FPS, 1:1 jatekido)
echo   [3] Series X Diagnosztikai GPU-idobelyeges futas (VICTORY_GPU_TIMING=1)
echo   [4] Series X A/B kontroll (VICTORY_DXR_OPT=0 - eredeti VIctory-Fast DXR)
echo   [5] Series S Nativ DXR 1.1 + caf96a opt (kulon feliratozva)
echo   [9] Shader eloforditas (Eloforditas-AGY-DXR.cmd)
echo.
set /p "choice=Melyik? [1-5, 9]: "

if "%choice%"=="1" goto opt1
if "%choice%"=="2" goto opt2
if "%choice%"=="3" goto opt3
if "%choice%"=="4" goto opt4
if "%choice%"=="5" goto opt5
if "%choice%"=="9" goto opt9

echo Ervenytelen valasztas: %choice%
timeout /t 2 >nul
goto menu

:opt1
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File "%~dp0eszkozok\meres-agy-dxr.ps1" -Nev agy-dxr-sx-30fps -Console series-x -DxrOpt 1
goto done

:opt2
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File "%~dp0eszkozok\meres-agy-dxr.ps1" -Nev agy-dxr-sx-unlocked -Console series-x -DxrOpt 1 -UnlockFps
goto done

:opt3
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File "%~dp0eszkozok\meres-agy-dxr.ps1" -Nev agy-dxr-sx-gputiming -Console series-x -DxrOpt 1 -GpuTiming
goto done

:opt4
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File "%~dp0eszkozok\meres-agy-dxr.ps1" -Nev agy-dxr-sx-ab-opt0 -Console series-x -DxrOpt 0
goto done

:opt5
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File "%~dp0eszkozok\meres-agy-dxr.ps1" -Nev agy-dxr-ss-30fps -Console series-s -DxrOpt 1
goto done

:opt9
call "%~dp0Eloforditas-AGY-DXR.cmd"
exit /b %errorlevel%

:done
set "rc=%errorlevel%"
echo.
echo Kesz (exit=%rc%).
pause
exit /b %rc%
