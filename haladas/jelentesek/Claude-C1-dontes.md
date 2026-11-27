# Döntés a négy helyi futás után

2026. november 26. • RX 9070 XT 16 GB, i5-14600KF, 32 GiB RAM • KLBF `643939a7`

**Claude következő feladata a C1 kísérlet.** A négy futás alapján a Windows memória-átképezési hívásait érdemes először vizsgálni. A legnagyobb akadásnál a képkocka 3364 ms-ig tartott, a napló 30,2 ms saját előkészítést és azon belül 4,5 ms textúramunkát mutat. Ezzel egy időben a memória-átképezés és a DirectStorage-olvasás is lelassult. A közös időablakból még nem következik, melyik okozta a megállást.

| Futás | Textúrakorlát | Medián FPS | Mért csúcs FPS | Futás vége |
|---|---:|---:|---:|---|
| A0 | 1024 px | 15,5 | 22,7 | Hozzáférési hiba a rablásnál |
| A0b | 1024 px | 13,7 | 28,4 | Rendes kilépés |
| B1 | 512 px | 13,7 | 24,3 | GPU-leállás az autós üldözésnél |
| B2 | 512 px | 12,1 | 24,5 | Rendes kilépés, 10,9 perc a játékvilágban |

Az értékek a négy futás `fps.json` fájljából származnak, a KLBF játékvilágra szűrt, összesített mintáiból. A B2 mappaneve `20261126-170050-B1-rablas-512`. A `futas.txt` alapján különböztethető meg a B1-től. A nagyobb lapozófájllal legalább 25,6 GiB szabad Windows-commitkeret maradt, mégis ebben a futásban volt a leghosszabb akadás. A 512 px-es korlát akadáscsökkentő hatása további összevetést igényel. A nyers adatok és Claude értelmezése helyben a `meresek\Claude-05-20261126-1719.md` jelentésből érhetők el.

## Claude-nak – C1

1. Készíts külön KLBF-munkafát a mért verzióból. Első lépésben a `49d7126` által bevezetett **VICTORY_MAP_LEAN** viselkedést ültesd át. Ez bizonyos esetekben kihagyja a felesleges Windows-leképezési műveleteket. Tartsd meg az eredeti tartalék útvonalat és a KLBF mérőszámait. A streamingszál prioritása mindkét mérésben maradjon az eredeti, a leképezés legyen egyszálú. A donorban a `VICTORY_MAP_THREADS=1` jelenti az egyszálú utat. [Első donorcommit](https://github.com/DoubleGhosty/cool_fox/commit/49d7126) · [Párhuzamos leképezés külön commitja](https://github.com/DoubleGhosty/cool_fox/commit/565f4a5)
2. Fordítsd le és ellenőrizd a módosított modult a meglévő célzott tesztekkel. Ugyanazzal a binárissal hasonlítsd össze a kikapcsolt és a bekapcsolt útvonalat. A naplóban igazold, melyik útvonal futott. A B2 profilját, mentését és cache-kezelését tartsd azonosan. Javasolt négy menet, **ki–be–be–ki** sorrendben, egyenként 12 percig. Jelöld a büfébe érkezés időpontját, mert az eltérő játékmenetben ugyanaz a perc más jelenetet fedhet.
3. A büfé azonos szakaszán vesd össze az átképezésben töltött időt, a ≥500 és ≥1000 ms-os képkockát tartalmazó intervallumok arányát és a DirectStorage-várakozásokat. Tüntesd fel az intervallumok számát. Külön jelöld a GPU-leállást, a hiányzó textúrákat és a pálya továbbhaladását. Ha az ismétlések ugyanabba az irányba mutatnak, és az eltérés meghaladja az alapfutások szóródását, javasolj döntést. A szálprioritás és a `565f4a5` több leképezőszála külön következő kísérlet lehet. Az `ab75ac3` akkor kerül ismét előre, ha megjelennek az általa kezelt sikertelen foglalások.

## Nyilvános buildek és beérkező FPS-jelentések

| Jelölt | A nyilvános adat | Mire használjuk? |
|---|---|---|
| AvatarManz `c9c932c` | Ugyanazon városi utcán Series S profillal 44,9 ms/kép, kb. 22 FPS. A kiinduló 57–75 ms érdemben javult. A stabil 30+ FPS a projekt célja. | Teljesítménydonor. A KLBF a helyi futásban már használta a konstans- és descriptormódosítást. Később a CBV, a guard és a journal eltéréseit külön lehet mérni. [Rögzített README](https://github.com/avatarmanz/VIctory-7900XTX/blob/c9c932cbcc38defd8f1683d62dd298187f565031/README.md) |
| DexNom `64bd58f` | RX 7900 XTX, Series X, RT, 1440p → 4K FSR Quality. A fejlesztő ezt tartja a legstabilabb tesztelt shader- és textúraprofiljának. A City vízpartján a bemelegített minta 1,1–1,3 FPS volt, nulla eldobott rajzolással, néhány fekete anyaggal. | Képhelyességi kontroll a sötét felületekhez. A helyi Series S profillal csak azonos jelenet és beállítás mellett érdemes sebességet összevetni. [Rögzített README](https://github.com/DexNom/VIctory/blob/64bd58f5fb794216894bc0e33e03a3a64d19c347/README.md) |
| Belobug AMD | A repóban szereplő Series X / 1440p referenciatábla 19–22 FPS-t közöl a hajós küldetésnél, 6–10-et az autós üldözésnél. A dokumentáció egy 41 perces összeomlásmentes menetet is felsorol. | Harmadik nyilvános név a nehéz jelenetek és a Radeon-képhibák összevetéséhez. A tábla eredetét külön ellenőrizd, mielőtt önálló fork-mérésként idézed. [Repó és referenciatábla](https://github.com/Belobug/VIctory-Belobug-AMD) |
| 30+ és 40–50 FPS-es hírek | Van nyilvános, 30 FPS fölötti játékmenetként közzétett klip. Ehhez és a 40–50 FPS-es beszámolóhoz egyelőre hiányzik a konkrét nyilvános commit és az összevethető mérés. A Yashank- és a MadeByNik1-nyom továbbra is külön szerepel a buildfigyelőben. | Új jelentésnél jegyezd fel az eredeti felvételt, a commitot, a hardvert, az irányítható jelenetet, az időtartamot, a belső felbontást, az RT-t és a képkockagenerálást. A natívan renderelt és a kijelzett FPS külön oszlopba kerüljön. [Közösségi klip](https://www.reddit.com/r/Indiangamers/comments/1y5qk6x/gta_6_goes_beyond_30_in_new_stable_gameplay/) |
