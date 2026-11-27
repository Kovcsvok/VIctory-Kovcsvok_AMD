@echo off
setlocal
rem KLBF meres naplozassal.
rem Dupla kattintas: rakerdez a profilra (1 = alap 1024 px, 2 = -LowMemory 512 px) es a futas nevere.
rem Terminalbol:     Meres-KLBF.cmd A1-rablas-1024
rem                  Meres-KLBF.cmd B1-rablas-512 -LowMemory
rem A FAJLT NE NEVEZD AT: a futas nevet itt kell megadni, nem a fajlnevben.
rem A futas mappaja: meresek\<datum-ido>-<nev>\ (victory.log, frametime.csv, memoria.csv, osszegzes.md)
set "NEV=%~1"
set "EXTRA=%2 %3"
if not "%NEV%"=="" goto indit
echo.
echo KLBF meres naplozassal
echo.
echo Profil:  1 = alapbeallitas (1024 px-es texturak)
echo          2 = -LowMemory (512 px-es texturak, kevesebb memoria)
set "PROF="
set /p "PROF=Valassz profilt [Enter = 1]: "
set "EXTRA="
set "ALAPNEV=A1-rablas-1024"
if "%PROF%"=="2" set "EXTRA=-LowMemory"
if "%PROF%"=="2" set "ALAPNEV=B1-rablas-512"
echo.
echo A futas neve ekezet nelkuli betu, szam, pont, kotojel es alahuzas lehet.
echo Minden futas kulon mappat kap, a neve ele kerul a datum es az ido.
set /p "NEV=Futas neve [Enter = %ALAPNEV%]: "
if "%NEV%"=="" set "NEV=%ALAPNEV%"
:indit
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File "%~dp0eszkozok\meres-klbf.ps1" -Nev "%NEV%" %EXTRA%
set "rc=%ERRORLEVEL%"
echo.
pause
exit /b %rc%
