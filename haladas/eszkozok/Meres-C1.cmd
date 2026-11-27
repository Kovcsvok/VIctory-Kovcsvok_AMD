@echo off
setlocal
rem C1 meres (Claude, 2026-11-26): a KLBF C1 tesztaganak binarisa (VIctory-dev\klbf-c1),
rem a B2 profiljaval (-LowMemory, 512 px), ugyanazzal az allapottal es mentessel.
rem Negy menet, ki-be-be-ki sorrendben: a sorszambol jon a VICTORY_MAP_LEAN erteke.
rem Ne nevezd at ezt a fajlt.
echo.
echo C1 meres: MAP_LEAN, negy menet ki-be-be-ki sorrendben
echo.
echo   1 = elso menet   (MAP_LEAN ki)
echo   2 = masodik menet (MAP_LEAN be)
echo   3 = harmadik menet (MAP_LEAN be)
echo   4 = negyedik menet (MAP_LEAN ki)
echo.
set "N="
set /p "N=Hanyadik menet? [1-4]: "
set "LEAN="
if "%N%"=="1" set "LEAN=0"
if "%N%"=="2" set "LEAN=1"
if "%N%"=="3" set "LEAN=1"
if "%N%"=="4" set "LEAN=0"
if "%LEAN%"=="" (
  echo Csak 1, 2, 3 vagy 4 lehet.
  pause
  exit /b 2
)
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File "%~dp0eszkozok\meres-klbf.ps1" -Nev "C1-%N%-lean%LEAN%" -LowMemory -Fa klbf-c1 -MapLean %LEAN%
set "rc=%ERRORLEVEL%"
echo.
pause
exit /b %rc%
