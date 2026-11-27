# Futtatási útmutató – KLBF és Victory United

Minden indító a `C:\Games\NOT_GTAVI` mappában van. Dupla kattintással vagy terminálból is indíthatók. **Ne futtasd őket rendszergazdaként.**

## Hol tartunk most? (2026-11-26)

| Lépés | Állapot |
|---|---|
| Fordítás (KLBF és United) | Kész, 14:10 |
| KLBF shader-előfordítás | Kész, 14:36 (1 menet, kb. 23,5 perc) |
| Első játékmenet | Még nincs |

**Ma tehát nem kell fordítani és előfordítani: kezdd a 3. lépésnél.**

## A sorrend

### 1. Fordítás: `Forditas.cmd`

Csak akkor kell, ha változott a forráskód (új commit vagy javítás).

- Lefordítja a KLBF-et, majd a Victory Unitedet (`cargo build --release --locked -p victory`).
- A United DirectX-futtatókörnyezetét csak akkor tölti le, ha hiányzik.
- Hiba esetén nyitva marad az ablak (`pause`), siker esetén bezárul.
- Utána mindig jön a 2. lépés.

### 2. Shader-előfordítás: `Shader-eloforditas.cmd`

**Minden új fordítás után kell,** és csak a KLBF-hez. Ezen a gépen kb. 23–24 perc.

- Ha a videokártya drivere közben összeomlik, a szkript magától folytatja onnan, ahol abbahagyta (legfeljebb 120 menet). Ilyenkor ne avatkozz bele.
- Akkor van kész, amikor a naplóban `Pre-build done` jelenik meg.
- A már előfordított pipeline-okat átugorja, ezért az ismételt futás gyorsabb.
- **Series X módhoz külön előfordítás kell:** `Shader-eloforditas.cmd -SeriesX`. A `-LowMemory` kapcsolóhoz nem kell újra előfordítani.

### 3. Indítás: válassz egyet

| Mire kell? | Parancs |
|---|---|
| **Mérés naplózással** (a mostani feladat) | Dupla kattintás a `meresek\Meres-KLBF.cmd` fájlra, majd profil (`1` = alap, `2` = `-LowMemory`) és név (Enterrel az ajánlott) |
| Sima játék KLBF-fel | `Inditas-KLBF.cmd` |
| Kisebb textúrák, kevesebb memória | `Inditas-KLBF.cmd -LowMemory` (512 px-es textúrakorlát) |
| Series X mód, FSR nélkül (lassabb) | `Inditas-KLBF.cmd -SeriesX` (előtte: `Shader-eloforditas.cmd -SeriesX`) |
| Összehasonlító fork | `Inditas-United.cmd` |

A `Meres-KLBF.cmd` fájlt **ne nevezd át.** Dupla kattintásra először a profilra kérdez rá (`1` vagy Enter = alap 1024 px, `2` = `-LowMemory` 512 px), utána a futás nevére. Enterrel a profilhoz ajánlott nevet kapja (`A1-rablas-1024` vagy `B1-rablas-512`), de beírhatsz mást is. Terminálból paraméterként is megadhatod: `Meres-KLBF.cmd A1-ut-meleg` vagy `Meres-KLBF.cmd B1-ut-512 -LowMemory`. A név csak ékezet nélküli betűből, számból, pontból, kötőjelből és aláhúzásból állhat. A mappa neve elé a szkript odaírja a dátumot és az időt, így két futás nem írja felül egymást.

A United nem kap előfordítást. Az első percekben menet közben fordítja a shadereket, ezért eleinte lassabb és többet akad.

## Egy mérési menet (most így kell)

1. A Betöltés menüben mindig **ugyanazt a mentést** töltsd be (most: a 16:04-es automatikus mentés a rablás előtt).
2. Ugyanúgy játszd a rablásszakaszt, és jusson át azon a ponton is, ahol az A0 összeomlott.
3. **12 percig játssz** attól számítva, hogy irányítható a karakter, aztán lépj ki a játék menüjéből. Ha előbb összeomlik, az is értékes adat.
4. Utána ennyit írj meg: összeomlott-e (ha igen, mi történt előtte), átjutottál-e a rablásjeleneten, mikor és mit csinálva akadt meg nagyot a játék, és látszott-e hiányzó vagy életlen textúra. A naplókat a mappából én szedem ki.

Miért 12 perc: a memória már az első 1–2 percben szűkös lesz, a nagy akadások és az összeomlás 7–9 perc körül jöttek. A 12 perc mindkettőt lefedi, és megegyezik az A0b hosszával, így a futások összevethetők.

## C1-mérés (MAP_LEAN, négy menet)

1. Dupla kattintás a `meresek\Meres-C1.cmd` fájlra, és írd be a menet sorszámát: `1`, `2`, `3` vagy `4`, sorban, egymás után. A ki/be beállítást a sorszámból az indító intézi.
2. Ugyanazt a **16:04-es** mentést töltsd be, és ugyanúgy játssz, mint a B2-ben.
3. **F8:** egyszer, amikor megérkezel a büfébe, és egyszer, amikor elindul az autós üldözés. Hangjelzés jelzi, hogy rögzült. A billentyű a játék ablakában is működik.
4. 12 percig játssz attól számítva, hogy irányítható a karakter, aztán lépj ki a játék menüjéből.
5. A négy menet között ne indítsd újra a gépet, és a lapozófájl-beállítást se állítsd vissza.

## C2-mérés (Lab 63.2 + MAP_LEAN, négy menet)

Előtte egyszer kell: `meresek\Eloforditas-C2.cmd` (kb. 25 perc, közben ne indíts játékot).

1. Dupla kattintás a `meresek\Meres-C2.cmd` fájlra, és válaszd a menetet. Sorrend: `1`, `2`, `3`, `4`.
2. **`1` és `2`, benchmark:**
   - töltsd be a 16:04-es mentést, és utána ne nyúlj semmihez;
   - 5 perc után megjelenik egy eredménykártya;
   - egy gombnyomásra vagy 60 másodperc múlva a játék magától kilép.
3. **`3` és `4`, játék:**
   - ugyanaz a mentés, 12 perc a rabláson és az üldözésen át;
   - F8 a büfébe érkezéskor és az üldözés kezdetekor;
   - utána írd meg, milyenek voltak az arcok és az ajtók, és mikor akadt meg nagyot a játék.

## Csomag: ez most a játszható alap (Belobug rx9070xt + 512 px + PC-s FSR + gyorsabb textúrafrissítés)

1. Dupla kattintás a `meresek\Inditas-Csomag.cmd` fájlra, majd `1`.
   - `1`: a stabil alap, 30 FPS-korláttal, az új fa-javítással (`VICTORY_TWIN_MOVE`) és a csónak-javítással (`CARD_STEPS_LEARN`). A szereplők RT-feloldó shaderei ki vannak hagyva, különben kék arcot adtak. 2026-11-27 10:50 óta a csónak-javítás újra benne van, mert nélküle hajók nyúltak meg és szakállak tűntek el (Claude-25).
   - `2`: 60 FPS-ig, élesebb képpel.
   - `3`: mint a 2-es, nagyobb textúrákkal. Több memóriát eszik, akadhat.
   - `4`: mint a 2-es, képek mentésével, ha meg akarsz mutatni valamit.
   - `5`: biztonsági mód, ha semmi más nem indul.
   - `6`: fa-próba. Mint az 1-es, de az 1-es renderer-port nélkül.
   - `7`: gyors mód. Mint az 1-es, de a csónak-javítás nélkül. Kb. 6 FPS-sel gyorsabb, cserébe megnyúlhatnak a hajók és az alakok, és eltűnhet a szakáll.
   - `8`: mint a 6-os, a 2-es renderer-port nélkül is. Lassabb, és nem segített (2026-11-26 22:50).
   - `9`: kész, már nem kell. Mint az 1-es, de a csónak-lépések gyorsítása (`VICTORY_CARD_STEPS`) nélkül. A 11:31-es menetben Cal szakálla így is eltűnt, tehát nem ez az oka (Claude-28).
   - A játék bezárása után a fekete ablakot ne zárd be, amíg ki nem írja: „Vége.” Különben a jelölő az F8-at egy óráig foglalva tarthatja.
   - Indítás előtt zárd be a böngészőt, a ChatGPT-t, a Wordot és az Antigravityt. Együtt kb. 4 GB RAM-ot foglalnak, és a játéknak minden GB számít: tele RAM mellett jönnek a durva modellek.
   - 11-27 11:25 óta minden menüpontban be van kapcsolva a `VICTORY_PRELUDE_POOL=1` (kevesebb parancslista, kb. 1–1,5 GB-tal kevesebb RAM). A 11:31-es menetben a montázs alatt 4–6 GB maradt szabadon a korábbi 1,5–2,5 GB helyett.
2. Válaszd ki a fiókot, és töltsd be a legutóbbi mentést. A csomag saját mentésmappát használ, a KLBF-mentésekhez nem nyúl.
3. A kép sarkában az FPS látszik. **F3**: a HUD eltűnik vagy visszajön.
   - **F9: videófelvétel.** Megnyomod, és a HUD órája mellett piros `REC` jelenik meg; F9 újra, és leáll. A videó a menet mappájába kerül (`meresek\<dátum>-<név>\felvetel-<UTC idő>.mp4`), nem kell máshol keresni. 11-27 11:55 óta akkor is rendesen lezárul, ha felvétel közben az ablak X gombjával lépsz ki.
   - Felvétel közben hagyd látszani a HUD-ot: az órája alapján tudom a videót a naplóhoz igazítani.
4. Utána írd meg:
   - összeomlott-e;
   - mennyire bukkannak fel vagy tűnnek el a tárgyak;
   - mikor akadt meg nagyot a játék.

## Indítás előtt

1. **Csatlakoztasd a kontrollert.** A fiókválasztó csak a kontrollerre reagál, a billentyűzetre nem.
2. **Zárd be a nagy memóriahasználó programokat,** különösen a `llama-server`-t. Ha fut, a mérőindító figyelmeztet; ilyenkor írj `n`-t, zárd be, és indítsd újra.
3. Ne futtasd egyszerre a két forkot, és ne indíts két játékot.

## Játék közben és utána

- Az első percek egy új területen lassúak, mert a shaderek még töltődnek.
- **A játékból a játék menüjében lépj ki.** A terminálablakot ne zárd be előtte.
- A `Meres-KLBF.cmd` kilépés után megírja a futás összegzését, és csak egy billentyű lenyomására zárul be.
- **A két fork mentései külön helyen vannak,** egymás mentéseit nem látják:
  - KLBF: `VIctory-dev\state\klbf-lab\data\7952987A\storage`
  - United: `VIctory-dev\state\Victory-United\data`

## Hol vannak a naplók?

| Mi | Hol |
|---|---|
| Mérés naplói | `meresek\<dátum-idő>-<név>\`: `victory.log`, `frametime.csv`, `memoria.csv`, `osszegzes.md` |
| Összeomlási napló | `VIctory-dev\state\klbf-lab\data\7952987A\crashes.log` (a mérőindító bemásolja a futás mappájába) |
| Előfordítás naplója | `VIctory-dev\state\klbf-lab\shader-prebuild.log` |

Az `Inditas-KLBF.cmd` nem ment naplót. Ha a futásból adat kell, a `Meres-KLBF.cmd`-t használd.

## Ha valami nem megy

| Amit látsz | Teendő |
|---|---|
| `Build first` vagy `Run Forditas.cmd first` | 1. lépés |
| `AMD FSR not found` | Hiányzik a `VIctory-dev\FidelityFX-SDK\Kits\FidelityFX\signedbin\amd_fidelityfx_upscaler_dx12.dll`, vagy használd a `-SeriesX` kapcsolót |
| `Cargo build failed` | Küldd el az ablak utolsó sorait |
| Fekete ablak, majd kb. 3 másodperc múlva kilépés | Kevés a memória: zárj be más programokat |
| `Már fut egy victory.exe` | Zárd be a futó példányt (Feladatkezelő, `victory.exe`) |
| A játék lefagy és nem reagál | Feladatkezelőben állítsd le a `victory.exe`-t, a naplót és a futás mappáját pedig hagyd meg |

## Egy menetben

```text
(ha változott a kód)  Forditas.cmd  →  Shader-eloforditas.cmd  →  meresek\Meres-KLBF.cmd (név + Enter)  vagy  Inditas-KLBF.cmd
(ha nem változott)                                               meresek\Meres-KLBF.cmd (név + Enter)  vagy  Inditas-KLBF.cmd
```
