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
rem 11-27 13:10: minden menupontban VICTORY_AUTO_A=1: a fiokvalasztonal a jatek virtualis kontrollere
rem magatol megnyomja az A-t (25-150. mp, 5 mp-enkent), amig a felhasznalo barmit meg nem nyom; elotte masolat
rem a mentesekrol (state\belobug-9070\mentes-masolatok). A kesei toltesek (VICTORY_LATE_FILLS,
rem Claude-30) a 13:17-es elo probaban lassabbak voltak (39,9 ms/kep a 33,5-35,9 helyett): nincsenek a menuben.
rem 11-27 16:55: minden menupontban VICTORY_LANDED_EARLY=1 (Claude-31): a lefutott listak azonnal vissza a keszletbe,
rem amire hivatkoztak, az ugyanannyi ideig marad. 16:47-es proba: 1133 elo lista 1940 helyett, privat csucs 25,8 GB
rem 27,4 helyett, munkakeszlet csucs 21,6 GB 23,0 helyett, lassulas nelkul.
rem 11-27 17:25: minden menupontban VICTORY_LIST_LAZY=1 is (Claude-32): a bekuldott lista csak ujrairaskor kap uj
rem gepi listat, az ures lista lezarasakor visszaadja. 17:14-es proba: 409 elo lista 1133 helyett, munkakeszlet
rem median 17,96 GiB 18,95 helyett, kepido 42,3 ms 45,1 helyett, eszkozhiba nelkul.
rem 11-27 18:10: minden menupontban VICTORY_PIPELINE_WAIT_ONCE=1 is (Claude-33): egy uj shaderre csak egy kepkockaban
rem var (legfeljebb fel mp), nem minden kepkockaban ujra. 17:59-es proba: a betoltes utan 2 akadas 250 ms folott,
rem az elotte levo probakban 10 es 14.
rem 11-27 21:55: a VICTORY_VIEW_BUFFERS alapbol be (Claude-34): a puffer-nezetek merete a leiroban van, nem
rem egy soha nem urulo tablazatban. Elotte 40 perc jatek utan 20 millio bejegyzes, 9,5 GB, privat 36 GB.
rem 21:42-es elo A/B: a tablazat 6 MB marad, a kepido 8,9 ms-mal rovidebb, eszkozhiba nelkul.
rem 11-27 22:40: uj 0-s pont, HOSSZU MERES (Claude-35): idovonal akadasnal, 20 FPS alatt es F8-ra,
rem a memoria novekvo helyei percenkent, adatbetoltesi naplo. Ld. meres-csomag.ps1 -Figyelo.
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
echo   0 = HOSSZU MERES: mint az 1-es, de amig jatszol, mindent figyel: akadasok,
echo       alacsony FPS, a memoria novekedese, a durva modellek. Nincs idokorlat.
echo       Nyomj F8-at, ha akad, lassu, vagy durva modell jon: azt kulon rogziti.
echo.
echo   Jatek kozben: F3 = HUD ki/be, F9 = videofelvetel indul / F9 ujra = leall
echo   (a video a menet mappajaba kerul, felvetel-....mp4 neven; az ablak X gombjaval
echo   kilepve is rendesen lezarul)
echo   A fiokvalasztonal az A-t a jatek magatol is megnyomja (25. mp-tol); ha te
echo   nyomod meg elobb, az sem baj: amint barmit megnyomsz, abbahagyja.
echo   A jatek bezarasa utan ezt az ablakot ne zard be, amig ki nem irja: Vege.
echo   Inditas elott zard be a bongeszot, a ChatGPT-t, a Wordot es az Antigravityt:
echo   kb. 4 GB-tal tobb RAM marad a jateknak (kevesebb durva modell).
echo.
set "N="
set /p "N=Melyik? [0-9]: "
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
if "%N%"=="0" set "ARGS=-Nev hosszu-meres -TexMax 512 -LookMs 250 -Figyelo"
if "%ARGS%"=="" (
  echo Csak 0-9 lehet.
  pause
  exit /b 2
)
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File "%~dp0eszkozok\meres-csomag.ps1" %ARGS%
set "rc=%ERRORLEVEL%"
echo.
pause
exit /b %rc%
