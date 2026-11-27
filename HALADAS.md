# Haladás: VIctory RX 9070 XT-n (Kovcsvok AMD-ág)

Állapot: **2026. november 27., 12:00** (helyi idő). A részletek a [`haladas/jelentesek`](haladas/jelentesek) mappában, mérésenként egy jelentésben vannak (Claude-01 … Claude-28).

## Röviden: hol tartunk?

**Ami működik:**
- A „Belobug rx9070xt csomag” ezen a gépen végigviszi a prológust: a rablást, az autós üldözést, a főcímet és a hajós küldetést. Átvezetőkben 30 FPS (a játék saját korlátja), hajózás közben 20–25 FPS.
- **Megszűnt:**
  - a fák és a lombkorona eltűnése (`VICTORY_TWIN_MOVE`);
  - a hajók és az alakok „megnyúlása” (`VICTORY_CARD_STEPS_LEARN`);
  - a kék arcok (a karakteres RT-feloldó shaderek kihagyva);
  - a memória elfogyása miatti 3–4 FPS-es szakaszok (512 px-es textúrakorlát);
  - a „Chapter 1” montázs durva, textúra nélküli alakjai (közös előtét-készlet és a többi program bezárása).
- A kép a PC-s AMD FSR-rel tiszta.

**Ami még hibás:**
1. **Tarka, kockás foltok egyes arcokon**, **eltűnő szakáll** (Cal), **távolról eltűnő hajóoldal** (turistahajó). A közös gyanúsított: a játék a videokártyán maga tömörít textúrákat, és ezek az írásai nálunk elvesznek. **Ez a következő javítás.**
2. **A szemüvegek eget tükröznek.** Az okozó render-lépés még nincs meg.
3. **FPS:** a csónak-javítás (`LEARN`) hajózás közben kb. 5–6 FPS-be kerül.
4. **RAM:** 32 GB-on a játék 26–27 GB-ot foglal. Van még javítható tétel (állandó host-listák, nézetforma-tár).

## A gép és a cél

| | |
|---|---|
| Videokártya | AMD Radeon RX 9070 XT, 16 GB (RDNA4) |
| Processzor | Intel Core i5-14600KF |
| Memória | 32 GiB DDR5 |
| Rendszer | Windows 11 |
| Profil | Series S, 512 px-es textúrakorlát, PC-s AMD FSR |

**A cél:** stabil, hibátlan kép és minél magasabb FPS ezen a gépen. Mindent mérés dönt el: naplóval, videóval, és élő be/ki kapcsolással ugyanabban a menetben.

## Kik dolgoznak rajta

| Ki | Szerep |
|---|---|
| A felhasználó (Kovcsvok) | játszik és tesztel; F8-cal jelöli a hibákat, F9-cel videót vesz fel |
| Claude | helyben mér, elemez és épít; ő írja a jelentéseket |
| Codex | koordinál, és dönt a következő lépésről; minden jelentés egy döntést kér tőle |
| Antigravity | saját ágon (`agy-9070-v2`) épít; ez nincs ebben a repóban |

## A kódágak

| Ág / fa | Szerepe |
|---|---|
| [PastiiJay/klbf-lab](https://github.com/PastiiJay/klbf-lab) `beta-2` | Az első helyi alap (KLBF). Ezen futottak az A0–C2 mérések. |
| [Fayberr/Victory-United](https://github.com/Fayberr/Victory-United) | Összehasonlító változat. |
| [Belobug/VIctory-Belobug-AMD](https://github.com/Belobug/VIctory-Belobug-AMD) `rx9070xt` | **A csomag alapja** (`cd8dfc06`). RX 9070 XT-javítások, HUD, a DexNom-féle PC-s FSR. |
| **Ez a repó, `main`** | A Belobug `cd8dfc06` és rá egy commit: a csomag minden változtatása (lásd lent). |
| Antigravity `agy-9070-v2` | Antigravity saját buildje. Nem itt van, és nem írunk bele. |

A tervek és a forrásnyilvántartás: [`haladas/tervek`](haladas/tervek):
- [buildfigyelő](haladas/tervek/VIctory-buildfigyelo.md): minden forrás és mérés dátummal;
- [forkterv](haladas/tervek/VIctory-forkterv.md);
- [tesztelési sorrend](haladas/tervek/VIctory-teszteles-es-javitasi-sorrend.md).

## Idővonal

### 1. KLBF-szakasz (11-26 délután): mire elég a memória?

| Menet | Beállítás | Medián FPS | Eredmény |
|---|---|---:|---|
| A0 | 1024 px | 15,5 | összeomlás a rablásnál |
| A0b | 1024 px | 13,7 | rendes kilépés, de nagy akadások |
| B1 | 512 px (`-LowMemory`) | 13,7 | GPU-leállás az autós üldözésnél |
| B2 | 512 px, nagy lapozófájl | 12,1 | rendes kilépés, 10,9 perc |

**Tanulság:**
- az akadások a memória átképezéséből jönnek;
- a `VICTORY_MAP_LEAN` (C1 és C2) a betöltéskor segített: a leghosszabb képkocka 2483 ms helyett 552 ms lett;
- utána mindkét változat kb. 20 FPS-sel ment;
- jelentések: Claude-01 … 08 és a C1-döntés.

### 2. A csomag (11-26 este): átjut a rabláson

- **Claude-09:** a Belobug `rx9070xt` ága egyben lefordítva, és elindult.
- **Claude-10–11:** gyors, de a rablásnál 3–4 FPS; az ok a memóriahiány.
- **Claude-12:** 512 px-es textúrakorláttal **először jut el a főcímig**. A PC-s FSR Series S-ben is bekapcsolva.
- **Claude-13–15:**
  - sokkal jobb a kép;
  - a felbukkanó tárgyak a textúrasor miatt vannak;
  - a 250 ms-os textúra-újranézés lett az alap.
- **Claude-16:** a 2–4. menüpontba 60 FPS-korlát és FSR-élesítés került.

### 3. Fák és villogás (11-26 éjjel – 11-27 reggel)

- **Claude-17–20:** a lombpróbák (`INDIRECT_BATCH`, fix/popin, a renderer-portok kikapcsolása) nem segítettek. A fix/popin ezen a gépen lassít.
- **Claude-21:** **megvan a fák eltűnésének oka.**
  - A `CS_Tree_BatchCull` ikernézetei null-t kaptak, mert nem a szál saját munkahelyén készültek.
  - Saját javítás: `VICTORY_TWIN_MOVE`. Az avatarmanz PR 437 (`TWIN_EXACT`) ezen a kártyán összeomlik.
  - Új eszköz: élő be/ki próba (`VICTORY_AB`) a HUD-on.

### 4. Videó, hajós jelenet, FPS (11-27 délelőtt)

- **Claude-22:** F9-es videófelvétel a csomagban. A HUD órája alapján a videó a naplóhoz igazítható.
- **Claude-23–24:**
  - a kép „patika”, nincs fa-eltűnés;
  - az FPS-t a csónak-javítás (`LEARN`) viszi el: képkockánként kb. 10 ms;
  - a karakteres RT-feloldás kék arcot ad, ezért 42 shadere kihagyva (`haladas/eszkozok/rt-feloldo-shaderek.txt`).
- **Claude-25:** `LEARN` nélkül a hajók megnyúlnak, és eltűnik a szakáll, ezért **a `LEARN` újra alap**. A gyors, `LEARN` nélküli változat a 7-es menüben maradt.

### 5. Arcok, szakáll, RAM (11-27 délelőtt)

- **Claude-26:**
  - a szemüveg-korlát (`VICTORY_REFLECT_HOLD`) hatástalan, kikerült;
  - a tarka arcok gyanúsítottja az elveszett textúra-írás;
  - Cal szakálla féloldalas.
- **Claude-27:** hova megy a RAM?
  - Az AMD-meghajtó minden parancslistára legalább 1 MB megosztott memóriát foglal, és ezt nem adja vissza. A játékban kb. 4000 ilyen volt.
  - Javítás: közös készlet az előtét-listáknak (`VICTORY_PRELUDE_POOL`).
- **Claude-28:**
  - a RAM-javítás bevált: a montázs alatt 4–6 GB szabad a korábbi 1,5–2,5 helyett, és nincs durva modell;
  - Cal szakálla a csónak-lépések nélkül is eltűnik, tehát nem azok okozzák;
  - a szakáll, a tarka arc és a turistahajó közös gyanúsítottja az elveszett tömörített-textúra-írás;
  - a videó az ablak bezárásakor is lezárul.

## A csomag mostani beállításai (1-es menü)

| Kapcsoló | Mit csinál |
|---|---|
| `VICTORY_TEXTURE_MAX=512` | 512 px-es textúrakorlát: belefér a 32 GB-ba |
| `VICTORY_TEXTURE_LOOK_MS=250` | a textúrákat legalább 250 ms-onként újranézi (kevesebb felbukkanás) |
| PC-s AMD FSR (`VICTORY_FIDELITYFX_DIR`, `VICTORY_FSR_*`) | a konzolos FSR helyett a PC-s, élesebb kép |
| `VICTORY_PORT_CONSTANTS`, `_DESCRIPTORS`, `_CBV`, `_GUARD`, `_JOURNAL` | renderer-portok (avatarmanz): a konzolos memóriamásolás helyett PC-s út |
| `VICTORY_TWIN_MOVE` | fa-javítás (saját) |
| `VICTORY_CARD_STEPS=2` + `VICTORY_CARD_STEPS_LEARN` | csónak-javítás (avatarmanz PR 434), képhű, de lassabb |
| `VICTORY_SKIP_PIPELINES=…` | a 42 karakteres RT-feloldó shader kihagyva (kék arc ellen) |
| `VICTORY_PRELUDE_POOL=1` | közös előtét-készlet, kb. 1 GB-tal kevesebb RAM |
| `VICTORY_TEXTURE_NO_WAIT`, `VICTORY_RELAY=2`, `VICTORY_JOIN_*`, `VICTORY_INDIRECT_*`, `VICTORY_UPLOAD_AHEAD`, `VICTORY_THIN` … | a Belobug-csomag gyorsításai |

A teljes lista a menetek `futas.txt`-jében és a [`meres-csomag.ps1`](haladas/eszkozok/meres-csomag.ps1)-ben van. A menüpontok: [`Inditas-Csomag.cmd`](haladas/eszkozok/Inditas-Csomag.cmd).

## Megoldott hibák

| Hiba | Ok | Javítás | Jelentés |
|---|---|---|---|
| 3–4 FPS, összeomlás a rablásnál | elfogyott a memória | 512 px-es korlát | Claude-11, 12 |
| homályos, csúnya kép Series S-ben | a konzolos FSR fordítva futott | PC-s AMD FSR Series S-ben | Claude-12, 13 |
| felbukkanó tárgyak | a textúrasor ritkán nézett újra | `TEXTURE_LOOK_MS=250` | Claude-13, 15 |
| eltűnő fák és lombkorona | null ikernézetek a fák kiválogatásánál | `VICTORY_TWIN_MOVE` | Claude-21 |
| megnyúló hajók és alakok | a játék beküldés után újraírja a konstans puffereit | `CARD_STEPS_LEARN` | Claude-21, 25 |
| kék arcok | a karakteres RT-feloldás ezen a kártyán | 42 shader kihagyva | Claude-24 |
| durva modellek a montázsban | tele RAM (1,5 GB szabad) | `PRELUDE_POOL` és a többi program bezárása | Claude-27, 28 |
| lezáratlan videó az ablak bezárása után | a kilépés nem zárta le a felvételt | `record::end_at_exit` | Claude-28 |

## Nyitott hibák és a következő lépések

| # | Hiba | Hol tartunk | Következő lépés |
|---|---|---|---|
| 1 | tarka arc, eltűnő szakáll, távolról eltűnő hajóoldal, furcsa szemöldök és szempilla | A naplóban több ezer elveszett írás BC1/BC4/BC7 textúrákba (`placed unordered texture view not mirrored`). A D3D12 nem enged írható nézetet tömörített formátumra. | Az új build naplózza a nézet teljes leírását. Egy rövid menetből kiderül, melyik textúrába ír a játék. Utána: tömörítetlen „blokk-iker” textúra és másolás a valódiba, `VICTORY_BC_WRITES` kapcsolóval. |
| 2 | szemüveg eget tükröz | A `CS_UpdateHistory` utáni korlát hatástalan, a forrás más render-lépés. | Megkeresni a tükröző render-lépést. |
| 3 | FPS hajózás közben (20–25) | A `LEARN` képkockánként kb. 10 ms várakozást ad. | Később: célzottabb tanulás. |
| 4 | RAM (26–27 GB a játéké) | Az előtét-készlet kész. | Az állandó host-listák lustítása (1–2 GB); a nézetforma-tár (legfeljebb 1 GB); `VICTORY_RESIDENCY` csak `VICTORY_BURY_LAG=64`-gyel. |
| 5 | ugráló felhők | Csak megfigyelés. | — |

**Codex nyitott döntései:**
- Claude-26: az elveszett írások pótlásának iránya;
- Claude-27: a `PRELUDE_POOL` legyen-e mindenhol alap;
- Claude-28: a tömörített textúrák írása legyen-e a következő javítás.

## Hogyan mérünk

1. **Indítás:** `Inditas-Csomag.cmd`, a menüből választva. A menüpont beállítja a kapcsolókat, és a menet mappájába naplóz:
   - `victory.log`;
   - `memoria.csv` (másodpercenkénti memóriaminta);
   - `futas.txt` (beállítások, exe-azonosító);
   - `jelolesek.csv`.
2. **Játék közben:**
   - **F8** jelöl (hangjelzés, idő a `jelolesek.csv`-be);
   - **F9** videót vesz fel a menet mappájába;
   - **F3** ki- és bekapcsolja a HUD-ot. A HUD órája alapján a videó képkockára pontosan a naplóhoz igazítható.
3. **Élő A/B:** `VICTORY_AB=<mp>,<kapcsoló>`. A program a kapcsolót menet közben váltogatja, a HUD `AB` sora mutatja. Így egy menetben látszik a különbség.
4. **Elemzés:**
   - képkockák a videóból (Windows Media Foundation);
   - a jelölések köré képsorok;
   - a napló összesítő sorai (memória, listák, textúrák, FPS) a régi menetekkel összevetve.

**Fordítás:** `cargo build --locked --profile diag -p victory --features diagnostics`. A mérőindító a `target\diag\victory.exe`-t indítja.

## Mi van ebben a repóban, és mi nincs

**Benne van:**
- a teljes forráskód (GPL-3.0, mint a VIctory);
- a [`haladas/`](haladas) mappa: jelentések, tervek, a mérőindítók és szkriptek.

**Nincs benne:**
- a játék fájljai;
- videók, naplók, képernyőképek (a repó csak szöveg, lásd `docs/asset-policy.md`; a jelentések képhivatkozásai ezért itt nem nyílnak meg);
- személyes adatok.

**A szkriptekről:** a játékmappa neve helyén `<JATEKMAPPA>` áll. Futtatás előtt írd be a saját mappádat. A szkriptek a `C:\Games\NOT_GTAVI` mappaszerkezetre épülnek.
