# A hajós jelenet és a következő kiadás

2026. november 27. · RX 9070 XT · i5-14600KF · 32 GB · Belobug `rx9070xt`

Az 1-es menü maradjon a játszható alap. A Claude-21 jelentés szerint a saját `VICTORY_TWIN_MOVE` bekapcsolásakor a hibás null nézetek száma az élő váltáskor 140–156/képkockáról nullára esett. A játékos is javulást látott. A #437 eredeti `TWIN_EXACT` útja kétszer összeomlott ezen a gépen, maradjon kikapcsolva. A #434 maradhat kapcsolhatóan az alapban. A csónak nyúlásának megszűnésére még kell képi megerősítés.

## A következő látható hiba a vízen lévő téglalap

Az fxceless két vízshadert azonosított. Mindkettő a mi gépünkön is eljutott a GPU-parancslistára. A helyi `victory.log` fájlokban az első kötésük:

| Menet | `5dc3b25986622949` | `6f225b641c5b0708` |
|---|---:|---:|
| `20261126-193520-csomag-jatek` | 2817. képkocka, 16264. sor | 2817. képkocka, 16266. sor |
| `20261126-224719-csomag-faproba-port12-ki` | 2564. képkocka, 15873. sor | 2564. képkocka, 15887. sor |

A donor nyílt vízen eltűnő fekete/szürke foltokról számol be, miután ezt a két programot kivette a kényszerített wave-wide módból. A #1419 után tovább javította az összegzés pontosságát. Egy külön javítása a villogó vízcsempéket célozza: a csempe szélsőértékeit akkor is inicializálja, ha a sarokhoz tartozó szál idő előtt kilép. Utóbbit a szerző a jelentésében még nem igazolta játék közben. A mi képernyőnkön látható téglalap eredete továbbra is nyitott. [Donor mérései](https://github.com/fxceless/victory-fork/blob/674290601fb9dba441e711cc951a8950ff08ddc6/README.md) · [Pontosított összegzés](https://github.com/fxceless/victory-fork/commit/e3307c7727a604d8847ace8751cc6623bad26b5c) · [Vízcsempék inicializálása](https://github.com/fxceless/victory-fork/commit/a918163849d506fc15a7c5d20106da03e2138365)

**Feladat Claude-nak.** A két azonosítóhoz írd ki egyszer a helyi fordító tényleges wave-módját és a shader-cache találatát. A donor két wave-szűrőjének nevét nem találtam a helyi forrásban vagy az indítóban. Az ottani környezeti változók bemásolása ezért önmagában nem próba. Ha a fordítás eltér, a pontosított útvonalat először erre a két shaderre alkalmazd, a mód kapjon külön cache-kulcsot. A hajós mentésben ugyanazzal a kamerával elég egy rövid felvétel. Ha a téglalap marad, külön kapcsold az inicializálási javítást. Így nem kell újra végigjátszani a küldetést.

## Három további javítás a helyi forráshoz

| Sor | Javítás | Helyi ellenőrzés és javaslat |
|---|---|---|
| 1 | ka1qux · Hiányzó konstanspuffer megfelelő típusa | Az 5-ös port aktív az alapban. Egy hiányzó bejegyzésnél a helyi kód null textúranézetet adhat egy nyers puffert olvasó shadernek. A patch csak ezt az esetet módosítja. A `git apply --check` sikeres. [Commit](https://github.com/ka1qux/BRVIctory-ka1qux/commit/95d571feb3aea43e62866b3f82f4b2971f39e45a) |
| 2 | cool_fox · DirectStorage memória | A fájlútvonalak listája nálunk kikapcsolt diagnosztikával is nő. A patch csak aktív nyomkövetésnél gyűjti őket, a zlib + BCPack kéréseknél pedig korábban elengedi a tömörített bemenetet. A `git apply --check` sikeres. A megtakarítás méretét ezen a gépen még nem mértük. [Commit](https://github.com/DoubleGhosty/cool_fox/commit/a96549d3ef4a2533dd0af0ac42957f81a7f0d005) |
| 3 | fxceless #1324 · GPU-leíróhelyek felszabadítása | A helyi kód címmel azonosítja a heapet. Ha a cím újra használatba kerül, egy régi parancslista felszabadíthatja az új heap másnak kiosztott helyeit. A donor generációazonosítót ad hozzá és külön WARP-teszttel mutatta ki a hibát. A tényleges PR diffje mindhárom fájlban eltér a helyi forrástól, kézi átvétel szükséges. Helyi képhibát még nem kötöttünk hozzá. [PR és regressziós teszt](https://github.com/fxceless/victory-fork/pull/1324/files) |

Az első kettő elfér egy integrációs ágban, egy közös fordítással és a következő rendes játékmenettel. A patch-illesztést ellenőriztem, ezeket a változtatásokat nem fordítottam és nem futtattam. A #1324 saját tesztje áthozható a kóddal. A másik forkban bevált descriptor-kapacitásnövelést egyelőre kihagynám: három korábbi helyi menet összesen 260 jelentett időablakában nulla elutasított kiosztást találtam. A felszabadítási hiba ettől független.

**Az F9-es felvételhez egy kiegészítés.** A menet naplójába a felvétel kezdetekor és az A/B állapot minden váltásakor kerüljön képkockaszám, monoton idő és a MOVE/LEARN állapot. A videón maradjon a HUD-jelzés. Ha egy másik gépen felvillan a hiba, a felvétel és a megfelelő naplósor együtt értelmezhető. Ehhez nem kell egy második felvevő.

## Mit érdemes megosztani GitHubon?

Első kiadásként egy önálló, forráspatchet tartalmazó repót javaslok. A már elkészült `meresek/csomag/csomag-belobug-9070.patch` a tiszta `cd8dfc06ace7ccb91a19431e74bc2d0de2a10145` alapra külön Git-indexben hibamentesen illeszkedett. SHA-256: `D558583BDE4310F7438F8D9C9BD8148560B1E5DBDAE08478E9A8E285B5FD41E6`. Ez a Claude-21 állapot azonosítója. Egy újabb, F9-et tartalmazó változat külön kiadás legyen. [Pontos Belobug-alap](https://github.com/Belobug/VIctory-Belobug-AMD/tree/cd8dfc06ace7ccb91a19431e74bc2d0de2a10145)

A patch mellé kell a GPL-licenc és a szerzői megjelölések, a változtatások dátuma és eredete, a fordítási útmutató és egy indító, amely paraméterként fogadja a játék és a cache mappáját. Az aktuális helyi indító a patchen kívül él és a gép saját útvonalait használja. A README-ben szerepeljen a tesztelt hardver, az 512 px-es profil, a közel 30 FPS-t adó jelenet, a kapcsolók és a nyitott víz-/csónakhiba. Így mások saját játékfájlokkal felépíthetik és összevethetik a változatot. A hibajegyhez elég a build azonosítója, GPU/driver, helyszín és rövid naplórészlet. [GNU GPLv3, 5–6. szakasz](https://www.gnu.org/licenses/gpl-3.0.html#section5)

A kész EXE kiadásával várnék. A `bcpack.rs` fordításkor az EXE-be ágyazza a `bcpack-tables.bin` táblát, amelyet az upstream saját szabályzata kifejezetten kivesz a repo licencének hatálya alól. A bináris kiadáshoz tisztázni kell a tábla és a mellékelt külső komponensek terjesztési jogát, és biztosítani kell a pontosan megfelelő forrást. A tiszta patch 12 forrásfájlt érint. A játékfájlok, mentések, gyorsítótárak, videók és a helyi SDK/DLL-ek maradjanak a gépen. [Belobug asset policy](https://github.com/Belobug/VIctory-Belobug-AMD/blob/cd8dfc06ace7ccb91a19431e74bc2d0de2a10145/docs/asset-policy.md)

A reggeli keresés 43 ismert repó alapértelmezett ágát kérdezte le, repónként legfeljebb 40 friss bejegyzéssel. Négy repo lekérése sikertelen volt. A fenti lista az ellenőrzött jelölteket tartalmazza.
