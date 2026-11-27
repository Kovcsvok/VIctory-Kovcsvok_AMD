# VIctory-Kovcsvok_AMD: VIctory RX 9070 XT-n

A [VIctory](https://github.com/Marvisak/VIctory) egy kompatibilitási réteg: egy Xbox Series játékot futtat közvetlenül Windowson, a felhasználó saját példányából. Ez az ág a [Belobug rx9070xt](https://github.com/Belobug/VIctory-Belobug-AMD/tree/rx9070xt) ágra épül, és **egyetlen gépre van hangolva és mérve: Radeon RX 9070 XT 16 GB, 32 GB RAM.**

**A repóban nincs a játékból semmi:** se fájl, se kód, se textúra, se képernyőkép. A játékból saját példány kell. A repónak nincs köze a játék fejlesztőjéhez vagy kiadójához.

> **Ha most veszed át (ember vagy AI):** olvasd el ezt a fájlt, utána a [HALADAS.md](HALADAS.md)-t, és a legutolsó jelentést ([Claude-28](haladas/jelentesek/Claude-28-20261127-1155.md)). A következő feladat lent, a [Mi a következő lépés](#mi-a-következő-lépés) részben van, kódhelyekkel együtt.

## Állapot: 2026. november 27.

**Mérve ezen a gépen:**
- Radeon RX 9070 XT 16 GB (RDNA4);
- Core i5-14600KF;
- 32 GiB DDR5;
- Windows 11.

**Profil:** Series S, 1080p kimenet, 512 px-es textúrakorlát, PC-s AMD FSR, ray tracing ki.

| Jelenet | Eredmény |
|---|---|
| Prológus: rablás, autós üldözés, főcím | **végigmegy**, összeomlás nélkül |
| Átvezetők (iroda, beszélgetések) | 30 FPS (a játék saját korlátja) |
| „Chapter 1” montázs | kb. 23 FPS |
| Hajós küldetés, hajózás | **20–25 FPS** (medián 22–23) |
| A játék memóriája | csúcson 27,3 GB saját; 11,1 GB VRAM; 7,5–9 GB megosztott |
| Szabad RAM menet közben | 4–6 GB, ha a böngésző és a többi nagy program be van zárva |

**Minimum: 32 GB RAM, és játék közben más nagy program ne fusson.** 1024 px-es textúrákkal a 32 GB nem elég.

### Ami működik

- **Kép:** a PC-s AMD FSR Series S-ben is működik, tiszta képpel.
- **Fák:** nem tűnnek el, nem villognak (`VICTORY_TWIN_MOVE`).
- **Hajók és alakok:** nem nyúlnak meg (`VICTORY_CARD_STEPS_LEARN`).
- **Arcok:** nem kékek (a 42 karakteres RT-feloldó shader kihagyva).
- **Memória:**
  - nincs 3–4 FPS-es szakasz és memóriahiány miatti összeomlás (512 px);
  - a montázsban nincsenek durva, textúra nélküli alakok (`VICTORY_PRELUDE_POOL`).
- **Mérés:** F9-cel videó, F8-cal jelölés, HUD órával; élő be/ki próba (`VICTORY_AB`).

### Ami még hibás

| Hiba | Ok | Állapot |
|---|---|---|
| Tarka, kockás foltok egyes arcokon; Cal szakálla és bajsza eltűnik; a turistahajó oldala távolról átlátszó; Lucia szemöldöke és szempillái furcsák | **Feltevés:** a játék a GPU-n maga ír tömörített (BC1/BC4/BC7) textúrákba, és ezek az írások nálunk elvesznek | **Következő feladat**, lásd lent |
| A szemüvegek eget tükröznek | ismeretlen render-lépés; a `CS_UpdateHistory` utáni korlát nem segített | nyitott |
| FPS hajózás közben 20–25 | a `CARD_STEPS_LEARN` képkockánként kb. 10–17 ms-ot vár | nyitott, a kép most fontosabb |
| A RAM szűkös (26–27 GB) | állandó host-listák (kb. 1900), nézetforma-tár (legfeljebb 1 GB) | nyitott |
| A felhők kicsit ugrálnak | nincs vizsgálva | nyitott |

A teljes történet a [HALADAS.md](HALADAS.md)-ben és a [jelentésekben](haladas/jelentesek) van.

## Mi új ebben az ágban

A Belobug `cd8dfc06`-hoz képest egy commit (`643a55a`), 24 fájl. Minden új viselkedés kapcsolóhoz kötött.

**Saját fejlesztések:**

| Kapcsoló / funkció | Mit csinál | A profilban |
|---|---|---|
| `VICTORY_TWIN_MOVE` | A fák kiválogatásának (`CS_Tree_BatchCull`) ikernézetei nem lesznek null-ok: nem a szál saját munkahelyén készülnek, ezért áthelyezzük őket (`descriptor/host.rs`) | **be** (a kódban is alapból) |
| `VICTORY_PRELUDE_POOL` | A host-listák előtét-listái közös, legfeljebb 192 darabos készletből jönnek. Az AMD-meghajtó listánként legalább 1 MB megosztott memóriát foglal, és nem adja vissza: 1909 helyett 432 előtét, kb. 1 GB-tal kevesebb (`host.rs`, `list.rs`) | **be** (a kódban alapból ki) |
| `VICTORY_LIST_IDLE_MOST` | a tétlen host-listák felső száma (alap 512) | nincs megadva |
| `VICTORY_REFLECT_HOLD` | a szemüvegpróba korlátja; mérve hatástalan | ki |
| F9-es videó (`record.rs`) | H.264 MP4 a futás mappájába (`VICTORY_RECORD_DIR`), a HUD órájával. Az ablak bezárásakor is lezárul (`lifecycle.rs` → `end_recording`). | mindig |
| Napló | az elveszett BC-textúra-írások nézetének mind a 16 szava; memóriasorok (előtétek, készlet, host-listák) a `copystat.rs`-ben | a `diagnostics` buildben |
| HUD | `AB` sor az élő próbához, további panelsorok (`host/panel.rs`) | `VICTORY_PANEL=1` |

**Más forkokból átvéve:**
- avatarmanz [PR 430](https://github.com/avatarmanz/VIctory-7900XTX/pull/430) (`VICTORY_WARM_BAD`);
- avatarmanz [PR 434](https://github.com/avatarmanz/VIctory-7900XTX/pull/434), átalakítva (`VICTORY_CARD_STEPS_LEARN`);
- avatarmanz [PR 437](https://github.com/avatarmanz/VIctory-7900XTX/pull/437) (`VICTORY_TWIN_EXACT`): **ezen a kártyán összeomlik, ne kapcsold be**;
- upstream fix/popin `7ab13ed`: itt lassít, ezért ki (`VICTORY_PORT_CONSTANTS_ORDER=0`);
- Belobug `f962387` (RDNA4 `GetDimensions`);
- a DexNom-féle PC-s FSR Series S-ben is (`VICTORY_FSR_PC`, `VICTORY_FSR_SHARPNESS`, `VICTORY_FSR_DLL`).

## Fordítás és indítás

**Kell hozzá:**
- Windows 10/11 x64, AVX2-es processzor;
- Direct3D 12 videokártya, Shader Model 6.6 és mesh shaderek;
- Rust (a verzió rögzítve van), MSVC build tools;
- a játék saját példánya.

```powershell
git clone https://github.com/Kovcsvok/VIctory-Kovcsvok_AMD
cd VIctory-Kovcsvok_AMD
copy victory.example.toml victory.toml      # állítsd be benne az útvonalakat (ezen a mappán kívülre)
cargo build --locked --profile diag -p victory --features diagnostics
```

**Első indítás előtt** (mindkettő félbeszakítható és folytatható):

```powershell
target\diag\victory.exe shaders <a játék shader-archívumai>   # minden shader lefordítva, percekig tart
target\diag\victory.exe warm --used                          # pipeline-ok előre, új drivernél vagy buildnél
```

**PC-s FSR:** a `VICTORY_FIDELITYFX_DIR` mutasson arra a mappára, amelyben az AMD aláírt `amd_fidelityfx_upscaler_dx12.dll`-je van ([FidelityFX SDK, `Kits/FidelityFX/signedbin`](https://github.com/GPUOpen-LibrariesAndSDKs/FidelityFX-SDK/tree/v2.4.0/Kits/FidelityFX/signedbin)).

### A mért profil (az `1`-es menü) kézzel

A mérésekhez a [`haladas/eszkozok/Inditas-Csomag.cmd`](haladas/eszkozok/Inditas-Csomag.cmd) menüje és a [`meres-csomag.ps1`](haladas/eszkozok/meres-csomag.ps1) indít. Ezek a `C:\Games\NOT_GTAVI` mappaszerkezetet várják. A játékmappa neve helyett `<JATEKMAPPA>` áll bennük. Ugyanaz kézzel:

```powershell
$s = @{
  VICTORY_TEXTURE_NO_WAIT='1'; VICTORY_RELAY='2'; VICTORY_WIDE_BACK='1'; VICTORY_CARD_REHASH_RUNS='1'
  VICTORY_JOIN_COPIES='1'; VICTORY_INDIRECT_WINDOW='1'; VICTORY_RELAY_COPY='1'; VICTORY_CARD_STEPS='2'
  VICTORY_INDIRECT_BATCH='2'; VICTORY_MAP_THREADS='1'; VICTORY_TITLE_PRIORITIES='0'; VICTORY_CARD_AWAKE='1'
  VICTORY_SHOW_AFTER='1'; VICTORY_AMBIENT='0.8'; VICTORY_D3D12_DRED='light'; VICTORY_THIN='1'
  VICTORY_JOIN_PARTS='8'; VICTORY_UPLOAD_AHEAD='1'; VICTORY_PORT_CONSTANTS='1'; VICTORY_PORT_DESCRIPTORS='1'
  VICTORY_PORT_CBV='1'; VICTORY_PORT_GUARD='1'; VICTORY_PORT_JOURNAL='1'; VICTORY_PANEL='1'
  VICTORY_PIPELINE_BOOK='1'; VICTORY_TEXTURE_MAX='512'; VICTORY_TEXTURE_LOOK_MS='250'
  VICTORY_PORT_CONSTANTS_ORDER='0'; VICTORY_PRELUDE_POOL='1'
  VICTORY_FIDELITYFX_DIR='<az FSR dll mappája>'; VICTORY_RECORD_DIR='<ide kerül az F9-es videó>'
}
$s.VICTORY_SKIP_PIPELINES = (Get-Content haladas\eszkozok\rt-feloldo-shaderek.txt | Where-Object { $_ -match '^[0-9a-f]{16}$' }) -join ','
foreach ($k in $s.Keys) { Set-Item "Env:$k" $s[$k] }
$env:RUST_LOG = 'info'
target\diag\victory.exe run "<a játék exe-je>" --execute --console series-s
```

**Játék közben:**
- **F3:** a HUD ki és be;
- **F9:** videó indul / áll le;
- **F8:** jelölés (csak a mérőindítóval, `jelolo.ps1`).

A fiókválasztó csak kontrollerre reagál. A felső mappa `scripts\play.ps1`-je az eredeti (avatarmanz/Belobug) indító. Mi nem azzal mérünk.

## Mi a következő lépés

### 1. Az elveszett tömörített-textúra-írások (most ez a legfontosabb)

**Mi látszik:**
- A napló ismétlődő figyelmeztetése: `placed unordered texture view not mirrored (null: writes through it are lost)`. Egy 6 perces menetben több mint 8000.
- A formátumok: 71 BC1_UNORM, 72 BC1_UNORM_SRGB, 80 BC4_UNORM, 98 BC7_UNORM; 32–1024 px, teljes mip-lánccal.
- Időben egybeesik a hibákkal: 4096 írásnál ott a tarka arc a videón.

**Hol van a kódban:**

| Hely | Mi van ott |
|---|---|
| `crates/victory-gpu/src/descriptor.rs`, `create_placed_uav` / `create_placed_srv` | A játék 0x238 és 0x230 eszközmetódusai: elhelyezett memória nézetei, `(resource desc [14 szó], view desc [16 szó], handle)` |
| `crates/victory-gpu/src/descriptor/host.rs`, `View::Placed` ág (keresd a figyelmeztetés szövegét) | Itt kap a textúrára mutató író nézet null-t |
| `placed_texture()` → `crate::resource::texture_at(address, resource)` | Az **olvasó** nézetek így kapják meg a memóriához készített host-textúrát. A cím a nézetleírás 10–11. szavában van. |
| `crates/victory-gpu/src/texback.rs` | a GPU által írt textúrák visszamásolása a játék memóriájába |

**A nyitott kérdés:**
- Az **író** nézetekben a 10–11. szó 0, ezért nem tudjuk, melyik textúra az.
- A mostani build ezért a nézet mind a 16 szavát naplózza.
- **Kell egy menet, amely betölt egy jelenetet**; elég a mentés betöltése és az első átvezető.

**A terv:**
1. Ha megvan a cím: minden (textúra, mip) író nézethez egy tömörítetlen „blokk-iker” textúra, negyed szélességgel és magassággal. BC1/BC4-hez `R32G32_UINT` (8 bájtos blokk), BC5/BC7-hez `R32G32B32A32_UINT` (16 bájtos blokk).
2. Az író nézet az ikerre mutat. A dispatch-ek után `CopyTextureRegion` másol az ikerből a BC-textúrába.
3. **Ellenőrizendő:** pontosan mit enged a D3D12 a BC és az azonos blokkméretű tömörítetlen formátum közötti másolásnál. A másik út a „relaxed format casting” (`D3D12_OPTIONS12`) castolható formátumlistával.
4. Kapcsoló: `VICTORY_BC_WRITES`. Élő A/B-vel kell mérni ugyanabban a jelenetben: a tarka arc, Cal szakálla, a turistahajó.

### 2. A szemüveg

**Kizárva:** a `sr_denoising:CS_UpdateHistory` (`Role::Reflect`) korlátja; mérve hatástalan, Claude-26.

**Következő:** a tükröző render-lépés megkeresése a képkocka-felvétel és visszajátszás eszközével ([docs/replay.md](docs/replay.md)).

### 3. FPS hajózás közben

A `crates/victory-gpu/src/host/card_steps.rs` `late` modulja (`LEARN`) a megtanult lapokra vár: képkockánként kb. 3,8 beküldés, 16–17 ms. Ötlet: finomabb, pufferenkénti tanulás.

### 4. RAM

- `list.rs`: minden játéklista beküldése után azonnal új, nyitott host-lista jár neki (kb. 1900 él). Ha ezt lustán kapná, 1–2 GB-tal kevesebb lehetne.
- `descriptor/host.rs`: a tárolt nézetformák (`SHAPES`, legfeljebb `1<<22`, kb. 1 GB).
- `VICTORY_RESIDENCY=1` csak `VICTORY_BURY_LAG=64`-gyel, mert 16-tal eszközvesztés jött.

## Hogyan dolgozunk (ezt tartsd meg)

1. **Semmi a játékból nem kerül a repóba:** fájl, shader-dump, képernyőkép, videó, napló sem ([docs/asset-policy.md](docs/asset-policy.md)).
2. **Minden új viselkedés `VICTORY_...` kapcsoló mögé kerül,** a kódban alapból kikapcsolva. A profil (az indító) kapcsolja be, ha a mérés igazolta.
3. **Mérés nélkül nincs döntés:**
   - a mérőindító menete naplót, másodpercenkénti memóriamintát és jelöléseket ír;
   - F9-es videó készül;
   - két változat élő A/B-vel kerül egy menetbe (`VICTORY_AB=<mp>,<kapcsoló>`).
4. **Minden mérésről jelentés** kerül a [`haladas/jelentesek`](haladas/jelentesek)-be, és egy dátumozott sor a [buildfigyelőbe](haladas/tervek/VIctory-buildfigyelo.md).
5. **Tesztek:** `cargo test --locked -p victory-gpu --lib <modul>::` (például `list::`). A játékkal való próbához a `diag` build kell.

## Fájltérkép

| Hol | Mi |
|---|---|
| `crates/victory-gpu/src/host.rs` | host-listák, előtétek, `PRELUDE_POOL` |
| `crates/victory-gpu/src/list.rs` | a listák életciklusa, tétlen készlet |
| `crates/victory-gpu/src/host/card_steps.rs` | csónak-lépések, `LEARN` |
| `crates/victory-gpu/src/descriptor/host.rs` | nézetek, elhelyezett textúrák, ikernézetek (`TWIN_MOVE`) |
| `crates/victory-gpu/src/record.rs` | F9-es videó |
| `crates/victory-gpu/src/ab.rs`, `host/panel.rs` | élő A/B, HUD |
| `crates/victory-gpu/src/copystat.rs` | a napló összesítő sorai |
| `crates/victory-hle/src/modules/lifecycle.rs` | kilépés |
| `crates/victory-hle/src/modules/fidelityfx.rs`, `apps/victory/src/run.rs` | PC-s FSR |
| `HALADAS.md`, `haladas/` | haladás, jelentések, tervek, mérőeszközök |
| `docs/README-7900XTX-alap.md` | az alap (avatarmanz 7900 XTX) eredeti README-je: kapcsolók, parancsok, háttér |

## In English, briefly

A fork of VIctory tuned and measured on **one machine: RX 9070 XT 16 GB, i5-14600KF, 32 GB RAM** (Series S profile, 512 px textures, PC AMD FSR). It plays through the prologue and the boat mission: 30 fps in cutscenes, 20–25 fps while sailing, with no crashes.

**Fixed here:**
- vanishing trees (`VICTORY_TWIN_MOVE`);
- stretching boats and characters (`CARD_STEPS_LEARN`);
- blue faces (character RT resolve skipped);
- memory (`VICTORY_PRELUDE_POOL`: AMD's driver keeps at least 1 MB of shared memory per command allocator).

**Next:** the title writes BC1/BC4/BC7 textures through UAVs, and those writes are lost here. This is the suspect for garbage faces, missing beards and see-through far boats. The plan is an uncompressed "block twin" plus a copy into the BC texture, behind `VICTORY_BC_WRITES`.

The progress log (in Hungarian) is in [HALADAS.md](HALADAS.md). The base's original README is in [docs/README-7900XTX-alap.md](docs/README-7900XTX-alap.md).

## Köszönet

Ez mások munkájára épül; a történet megmaradt, az átvett commitok megnevezik a forrásukat és a szerzőjüket.
- **[VIctory](https://github.com/Marvisak/VIctory):** Marvisak és a közreműködők. A betöltő, a futtatókörnyezet, a Direct3D 12 háttér és a shader-fordító.
- **[avatarmanz/VIctory-7900XTX](https://github.com/avatarmanz/VIctory-7900XTX):** a renderer-portok, PR 430, 434, 437.
- **[Belobug/VIctory-Belobug-AMD](https://github.com/Belobug/VIctory-Belobug-AMD):** az `rx9070xt` ág (RX 9070 XT-javítások, HUD, villódzásjavítás).
- **[DexNom/VIctory](https://github.com/DexNom/VIctory):** a PC-s FidelityFX FSR-híd, RT-javítások.
- **[fxceless/victory-fork](https://github.com/fxceless/victory-fork)**, **[myokex/victory-amd](https://github.com/myokex/victory-amd)**, **Geckomacabre**, **cxy0072019-sketch**, **[FQY55kai/ZJOU-VICTORY](https://github.com/FQY55kai/ZJOU-VICTORY)**: lásd az alap README-jét.
- Az ág változtatásai [Claude Code](https://claude.com/claude-code)-dal készültek; a koordinálás Codexszel, Antigravity párhuzamos ágával.

## Licenc

GPL-3.0-or-later, mint a VIctory. Lásd [LICENSE](LICENSE). Az egyetlen kivétel a [docs/asset-policy.md](docs/asset-policy.md)-ben szerepel.
