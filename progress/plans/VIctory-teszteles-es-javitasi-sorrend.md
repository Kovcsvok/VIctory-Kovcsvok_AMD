# VIctory tesztelési és javítási sorrend az RX 9070 XT-hez

**Elsőként azt próbáld ki, hogy a KLBF-fel eljutsz-e az első irányítható jelenetig, ott működik-e a kép, a hang és a vezérlés, majd a játék később vissza tud-e tölteni egy mentést.** Ha ez rendben van, az első teljesítményteszt egy megismételhető autós út legyen. Első javításként a textúrafeltöltést akkor venném elő, ha az akadás pillanatában a naplóban a feltöltési idő vagy a várakozó textúrák száma is megugrik.

## Mi a helyi kiindulópont?

A gépben i5-14600KF, RX 9070 XT 16 GB és 32 GiB fizikai RAM van. A Radeon-driver verziója `32.0.32029.2010`. A KLBF Lab 62 (`643939a7`) és a Victory United (`6757b6ef`) külön mentési könyvtárat és gyorsítótárat használ. Az importkötési próba mindkettőn átment. A KLBF előfordítása egy menetben, 23 perc 27 másodperc alatt végigért. Hét compute shader fordítása kimaradt. **Az első helyi játékmenet FPS-e, stabilitása és képhibái még mérésre várnak.**

## Az első három próba

| Próba | Mit csinálj? | Mit jegyezz fel? |
|---|---|---|
| 1. Indítás és vezérlés | A `C:\Games\NOT_GTAVI\Inditas-KLBF.cmd` indítót használd. Ha kontrollerrel játszol, indulás előtt csatlakoztasd. Az első irányítható jelenetben járj körbe, fordítsd el a kamerát, nyisd meg és zárd be a menüt. | Elért utolsó képernyő, van-e kép és hang, reagál-e a karakter, működik-e a menüből visszatérés. Ha itt megáll, ez az első javítandó hiba. |
| 2. Mentés és visszatöltés | Az első elérhető kézi mentési ponton ments külön helyre. Lépj ki, indítsd újra ugyanazt a forkot, majd a **Betöltés** menüből válaszd ki ezt a mentést. | Ugyanaz a helyszín és haladás töltődik-e vissza? Ha igen, ezt a mentést használd a következő ismétléshez. |
| 3. Textúrabetöltés menet közben | Amikor eléred Jason házát, készíts reggeli kézi mentést. Menj ki az autóhoz, jelöld ki a közeli dollárjeles célt, és kövesd ugyanazt a GPS-útvonalat a parkolásig. Ha még a prológusban jársz, addig ugyanazt a rövid beltéri sétát ismételd. | Írd fel, hol áll meg a kép, késve jelenik-e meg az út vagy az autó textúrája, és ugyanott megismétlődik-e a hiba. A házból kilépés és az első forgalmas kereszteződés jó összevetési pont. |

## Így marad napló az első menetről

Nyiss **Parancssort** (`cmd.exe`), majd futtasd a következőket. Hagyd nyitva az ablakot a játékból való kilépésig. Az `A1` helyére minden új menethez írj új nevet, mert a kimeneti átirányítás felülírja az azonos nevű naplót.

```bat
cd /d C:\Games\NOT_GTAVI
if not exist meresek mkdir meresek
set "RUST_LOG=info"
Inditas-KLBF.cmd > "meresek\A1.log" 2>&1
```

Egy másik Parancssorban ezzel láthatod az összesített képkockaadatokat:

```bat
cd /d C:\Games\NOT_GTAVI
findstr /C:"draws/frame" "meresek\A1.log"
```

A KLBF naplósorában a `preparing` a CPU-oldali előkészítés, a `textures` a textúrákra fordított idő és adatmennyiség, a `copying back` a visszamásolás. A `waiting` a textúrákra váró sor értelmezésében segít. A játékmenetből vegyél mintát. Összeomlásnál őrizd meg a menet naplóját, az utolsó látható jelenet nevét és – ha létrejött – a `VIctory-dev\state\klbf-lab\data\7952987A\crashes.log` fájlt.

## Melyik javítás kerüljön előre?

| Amit ténylegesen tapasztalsz | Első ellenpróba | Első fejlesztési cél |
|---|---|---|
| Fekete kép, kilépés vagy elveszett GPU-eszköz ugyanabban a jelenetben | Ismételd meg egyszer azonos beállítással. Próbáld meg ugyanazt a jelenetet az `Inditas-United.cmd` indítóval is, és jegyezd fel, meddig jut. A két gyári profil eltérhet. | A legkorábbi reprodukálható hibát javítsd. Ha a napló konkrét shader- vagy pipeline-azonosítót ad, abból indulj ki. A hét kihagyott compute shader akkor kapjon elsőbbséget, ha valamelyik összeköthető a hibás jelenettel. |
| Vezetéskor hosszú akadások és növekvő textúrasor | Mérd meg ugyanazt az útvonalat az alapbeállítással, majd az `Inditas-KLBF.cmd -LowMemory` kapcsolóval. Ez 1024-ről 512 pixelre veszi a textúrakorlátot. Figyeld a képet, a megállásokat, a dedikált és megosztott GPU-memóriát. | Ha a kisebb textúrákkal csökkennek az akadások, a feltöltési sor és a memóriakeret vizsgálata következzen. Ha több nézet ugyanazt a textúrát tölti fel, az AnyXboxX #304 célzott jelölt. A helyi patch kézi átültetést igényel. |
| Álló kameránál és autózáskor is lassú, a `preparing` tartósan magas | Hasonlítsd össze a `copies`, `textures`, `heap buffers` és `copying back` időket ugyanazon jelenet több naplósorában. | Ha a heap bejárása drága, a Flamingo változott descriptorokat követő megoldását vizsgáld. Ha a másolás drága, a 7900XTX módosult 4 KiB-os tartományokat másoló javítását. A KLBF-ben a konstans- és descriptorport már aktív. |
| Elfogadható sebesség mellett hibás a víz, a bőr, az üveg vagy a beltéri fény | Készíts képpárt ugyanarról a mentésről, napszakról és kameranézetről. Víznél külön jegyezd fel, hogy látszik-e a felület, illetve úszik-e és irányítható-e a hajó. | Egyetlen látható hibát válassz. A bőrön vagy autófestéken megjelenő háromszögmintához Belobug AMD-s quad-olvasási javítása, a vízhez a shaderkimenet és a textúranézet ellenőrzése ad kiindulópontot. |

## Mikor tarts meg egy módosítást?

Egy bemelegítő kör után fuss három mért kört az eredeti és három kört a módosított beállítással, felváltva. Azonos kézi mentés, útvonal, felbontás és FSR-profil mellett mérj. Az alapverzióra váltáskor is őrizd meg a már felépített cache-t. Forkok között a gyorsítótárak maradjanak külön.

Minden menethez elég egy sor:

| Futás és commit | Profil | Útvonal teljesült? | Medián FPS | Észlelt nagy megállások száma és helye | Képi vagy működési hiba |
|---|---|---|---:|---|---|
| A1 · 643939a7 | KLBF, Series S + FSR, 1024 px | | | | |
| B1 · 643939a7 | KLBF, Series S + FSR, 512 px | | | | |

A repó `tools\fps-session.py` eszköze a naplóból átlagot, mediánt és 1% low-t számít. Ha van működő Python 3 a gépen, a játék főmappájában az első napló így összegezhető:

```bat
py -3 VIctory-dev\klbf-lab\tools\fps-session.py meresek\A1.log --build 643939a7 --out meresek\A1.json
```

Az eszköz legalább 1000 rajzolás/képkocka értékű mintákat tart meg. Az 1% low az összesített FPS-minták legrosszabb egy százalékának átlaga. Egy-egy rövid megakadás ezért külön megfigyelésként is kerüljön a táblába.

**A változást akkor érdemes megtartani, ha ugyanazon a szakaszon ismételten eltűnik a célzott hiba, vagy a javulás nagyobb az alapfutások közötti szórásnál, és a kép, a vezérlés és a mentés továbbra is rendben van.** A forktervben szereplő javítások közül így az első helyi hiba választja ki a következőt.

Hivatkozások: [KLBF mérési útvonal](https://github.com/PastiiJay/klbf-lab/blob/beta-2/docs/klbf/MEASUREMENT.md) · [KLBF indítóbeállítások](https://github.com/PastiiJay/klbf-lab/blob/beta-2/play.ps1) · [AnyXboxX #304](https://github.com/LooperSalty/AnyXboxX/pull/304) · [Victory United átvételi jegyzék](https://github.com/Fayberr/Victory-United/blob/main/PROVENANCE.md).
