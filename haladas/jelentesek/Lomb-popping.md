# Eltűnő fák és környezeti tárgyak

**Első javítási próba:** az 1-es profil beállításaival, de az indirekt GPU-parancsok óvatosabb kötegelésével indítsd a játékot. A külön indító a gépen a `C:\Games\NOT_GTAVI\meresek\Lomb-proba.cmd`. Nem igényel fordítást.

| Indítás a mérésmappából | Mire való? |
|---|---|
| `Lomb-proba.cmd` | Az 1-es profil egyetlen módosítással: `VICTORY_INDIRECT_BATCH=1`. A portok, PC-s FSR, 512 px és a 250 ms-os textúra-újranézés maradnak. |
| `Inditas-Csomag.cmd` → `1` | A játszható alap, kötegelés 2. Azonos mentésből ennek a képéhez és sebességéhez hasonlíts. |
| `Lomb-proba.cmd diag 210` | Az alap kötegeléssel naplózza a láthatósági számításokat, és a renderelő saját időszámításának 210–240. másodpercében keresi a képi villanásokat. A 210 tetszés szerint cserélhető. A részletes számlálás az egész futásban aktív, ezért a diagnosztikai menet sebessége nem összehasonlítási alap. |

**Mit nézz játék közben?** Amikor látszik egy villogó fasor, egy pillanatra állítsd meg a járművet, és tartsd ugyanott a kamerát. Külön jelenség, amikor egy távoli fa először jelenik meg közeledéskor, és amikor a már megrajzolt lombkorona ugyanott eltűnik és visszajön. Elsősorban a második jelenséget próbáljuk javítani. Ha a próba nem segít, a játszható alap továbbra is az eredeti 1-es.

## Mi indokolja a próbát?

- A 20:51-es és 20:56-os menetből 271 + 324 olyan naplósor volt, amely az indirekt parancslista keretének kimerülése miatt üresen lefutó rekordokat méri. A legnagyobb kiírt érték mindkettőben **0,00 rekord/képkocka**. Ezek kerekített intervallumátlagok. A keret megemelésére gyenge az indok.
- Mindkét menet naplójában szerepel a `tree` (`55679a0547649d0b`), `tree_imposter` (`89d08e561897d4e5`), `slod` (`1c4b3c0547e3e6fa`) és `meshlet_args` (`9146291b38ea9ce1`) compute shader első bekötése. Ez csak a programok elérhetőségét igazolja. Az egyes fákhoz előállított példányszámot az eddigi napló nem tartalmazza. A két képsor eltérő útvonalat és átvezetőket mutat, emiatt belőlük nem állapítható meg a két profil közti villogási arány.
- A `crates/victory-gpu/src/draw.rs` fájlban a `State::buffers_written` 1-es módban eldobja az addigi köteget, miután egy shader írhatta a puffert. A 2-es módban megjelöli, és a következő felismert szinkronizációig vagy rajzolásig tovább használhatja az indirekt számítások közt. Ha a láthatósági lánc egy lépése régi argumentumokat kap, az egész tárgy hiányozhat. Ez a próba hipotézise. A sűrűbb újraszámítás időbe kerülhet. A szükséges kapcsoló a jelenlegi programban benne van.

## Ha még villog

A `VICTORY_WALLS_TRACE=1` által kiírt `walls trace: the frame's main pass` sorok a `tree`, `tree_imposter`, `slod`, `meshlet_args` és `depth_pyramid_cpu_occlusion` műveletek rögzítéseit számolják. A `VICTORY_POP_WATCH` a szomszédos kiírt képek eltéréseit keresi. A diagnosztikai futás saját mappájában a `victory.log` és a `popwatch` könyvtár tartozik össze. A szerző implementációja kihagyhat mintákat, például összetett képrétegek megjelenítésekor. Üres képmappa esetén a már meglévő képsor időpontja használható tájékozódásra.

A villanás előtti, alatti és utáni képen ugyanazt a parti foltot hasonlítsd össze a környező frame-azonosítók műveleteivel. Ha a fa és távoli helyettesítője közötti váltásra mutatnak az adatok, a következő kódmódosítás a kiválasztott GPU-argumentumpuffer **végrehajtáskor ténylegesen kiolvasott** darabszámát kövesse. A compute-hívások darabszámából egy fa láthatósága nem állapítható meg. Ha a rajzolás megmarad a villanáskor is, a lomb anyagának átlátszósági maszkját és mipválasztását vizsgáljuk.
