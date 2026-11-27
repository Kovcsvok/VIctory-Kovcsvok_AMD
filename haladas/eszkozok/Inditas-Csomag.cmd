@echo off
setlocal
rem Belobug rx9070xt csomag (Claude, 2026-11-26): avatarmanz + RX 9070 XT javitasok + villodzasjavitas
rem + DexNom FSR-port, VIctory-dev\belobug-9070. Sajat mentesmappa (a KLBF-mentesek masolata).
rem Alap (21:05): 512 px + PC-s AMD FSR + VICTORY_TEXTURE_LOOK_MS=250.
rem 22:20: az avatarmanz fix/popin (7ab13ed) alapbol KI (ezen a gepen lassu, a fak villogasa maradt);
rem 6 = fa-proba az 1-es renderer-port nelkul, 7 = a fix bekapcsolva, 8 = 1-es es 2-es port nelkul (22:35).
rem 11-27: fa-javitas (VICTORY_TWIN_MOVE, sajat, az avatarmanz PR 437 nyoman) es csonak-javitas
rem (CARD_STEPS_LEARN, avatarmanz PR 434) minden menupontban bekapcsolva; 9 = elo proba: csak a LEARN
rem 10 mp-enkent be/ki (Codex, 11-27 10:00), a HUD AB sora mutatja (KI: LEARN = kikapcsolva).
rem 11-27 10:30: alapbol LEARN ki (gyorsabb) es a 42 karakteres RT-shader kihagyva (kek arc); 7 = LEARN be.
rem 11-27 10:50: LEARN ujra alapbol BE (LEARN nelkul nyult egy hajo es eltunt Jason es Cal szakalla, Claude-25);
rem 7 = GYORS: LEARN ki. 9 = elo proba: a szemuveg-korlat (VICTORY_REFLECT_HOLD, Antigravity ebd4988 nyoman)
rem 10 mp-enkent be/ki, a LEARN bekapcsolva (KI: HOLD = korlat kikapcsolva).
rem 11-27 11:30: a szemuveg-korlat a 10:52-es probaban semmit nem valtoztatott (Claude-26), kikerult;
rem 9 = ELLENORZES: csonak-lepesek (VICTORY_CARD_STEPS) nelkul, Cal feloldalas szakalla miatt.
rem 11-27 11:25: minden menupontban VICTORY_PRELUDE_POOL=1 (elotet-listak kozos keszletben, kb. 1-1,5 GB-tal kevesebb RAM, Claude-27).
rem 11-27 11:55: a 9-es menet (11:31) szerint Cal szakalla csonak-lepesek nelkul is eltunik, nem az az oka (Claude-28);
rem a 9-es mar nem kell. Uj exe: a video az ablak X gombjaval kilepve is lezarul; az elveszett texturairasok teljes leirasa a naploba kerul.
rem Naploz es memoriat mer, mint a Meres-*.cmd. Ne nevezd at ezt a fajlt.
echo.
echo Csomag (Belobug rx9070xt, Series S, PC-s AMD FSR)
echo.
echo   1 = ALAP: 30 FPS-korlat, 512 px, fa-javitas, csonak-javitas (kephu)   - EZT HASZNALD
echo   2 = 60 FPS-ig + elesebb kep (FSR-elesites 0.5)
echo   3 = mint a 2-es + nagyobb texturak (1024 px; tobb memoria, akadhat)
echo   4 = mint a 2-es, kepsorral (ha meg akarsz mutatni valamit)
echo   5 = -Safe (gyorsitasok nelkul), ha semmi mas nem indul
echo   6 = FA-PROBA: mint az 1-es, de az 1-es renderer-port nelkul
echo   7 = GYORS: mint az 1-es, csonak-javitas nelkul (kb. 6 FPS-sel gyorsabb, de
echo       nyulhatnak az alakok es a hajok, eltunhet a szakall)
echo   8 = FA-PROBA 2: mint a 6-os, de a 2-es renderer-port nelkul is (lassabb, nem segitett)
echo   9 = (kesz, nem kell) mint az 1-es, csonak-lepesek gyorsitasa nelkul:
echo       Cal szakalla igy is eltunt, tehat nem ez az oka
echo.
echo   Jatek kozben: F3 = HUD ki/be, F9 = videofelvetel indul / F9 ujra = leall
echo   (a video a menet mappajaba kerul, felvetel-....mp4 neven; az ablak X gombjaval
echo   kilepve is rendesen lezarul)
echo   A jatek bezarasa utan ezt az ablakot ne zard be, amig ki nem irja: Vege.
echo   Inditas elott zard be a bongeszot, a ChatGPT-t, a Wordot es az Antigravityt:
echo   kb. 4 GB-tal tobb RAM marad a jateknak (kevesebb durva modell).
echo.
set "N="
set /p "N=Melyik? [1-9]: "
set "ARGS="
if "%N%"=="1" set "ARGS=-Nev csomag-alap -TexMax 512 -LookMs 250"
if "%N%"=="2" set "ARGS=-Nev csomag-60fps-eles -TexMax 512 -LookMs 250 -MaxFps 60 -Sharp 0.5"
if "%N%"=="3" set "ARGS=-Nev csomag-60fps-eles-1024 -TexMax 1024 -LookMs 250 -MaxFps 60 -Sharp 0.5"
if "%N%"=="4" set "ARGS=-Nev csomag-60fps-eles-kepsor -TexMax 512 -LookMs 250 -MaxFps 60 -Sharp 0.5 -Kepsor"
if "%N%"=="5" set "ARGS=-Nev csomag-safe-512-pcfsr -Safe -TexMax 512 -LookMs 250"
if "%N%"=="6" set "ARGS=-Nev csomag-faproba-port1-ki -TexMax 512 -LookMs 250 -Port1 ki"
if "%N%"=="7" set "ARGS=-Nev csomag-gyors -TexMax 512 -LookMs 250 -Learn ki"
if "%N%"=="8" set "ARGS=-Nev csomag-faproba-port12-ki -TexMax 512 -LookMs 250 -Port1 ki -Port2 ki"
if "%N%"=="9" set "ARGS=-Nev csomag-kartyalepes-ki -TexMax 512 -LookMs 250 -KartyaLepes ki"
if "%ARGS%"=="" (
  echo Csak 1-9 lehet.
  pause
  exit /b 2
)
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File "%~dp0eszkozok\meres-csomag.ps1" %ARGS%
set "rc=%ERRORLEVEL%"
echo.
pause
exit /b %rc%
