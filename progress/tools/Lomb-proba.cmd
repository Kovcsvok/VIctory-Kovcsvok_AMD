@echo off
setlocal
set "RUNNER=%~dp0eszkozok\meres-lomb.ps1"
if "%~1"=="" goto probe
if /i "%~1"=="alap" goto base
if /i "%~1"=="diag" goto trace
echo Hasznalat: Lomb-proba.cmd [alap ^| diag kezdo_masodperc]
exit /b 2
:probe
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File "%RUNNER%" -Nev lomb-batch1 -TexMax 512 -LookMs 250 -IndirectBatch 1
goto done
:base
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File "%RUNNER%" -Nev lomb-batch2 -TexMax 512 -LookMs 250 -IndirectBatch 2
goto done
:trace
if "%~2"=="" (
  echo Add meg a 30 masodperces rogzites kezdetet, pl. Lomb-proba.cmd diag 210
  exit /b 2
)
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File "%RUNNER%" -Nev lomb-alap-diag -TexMax 512 -LookMs 250 -IndirectBatch 2 -LombKezdet "%~2"
:done
set "RC=%ERRORLEVEL%"
if not "%RC%"=="0" pause
exit /b %RC%
