# AGY v2 – döntés az FPS-ről és a beltéri tükröződésről

2026. november 27. A 7. commitból most a fa-javítás és az önálló LEARN-próba indokolt. A 30 FPS-es profil maradjon az összevetés alapja. A 60 FPS mód már külön menüpont.

## Mekkora a veszteség?

A helyi naplókban a 3300–5600 rajzolás/képkocka közötti jelentési ablakokat vettem. Az FPS-t és a várakozást azonos UTC-másodpercben kiírt számlálókból párosítottam. Az értékek az ablakok mediánjai.

| Menet | Ablak | FPS | Beküldött GPU-munkára várás, ms/kép | Megtanult lap miatt váró beküldés/kép |
|---|---:|---:|---:|---:|
| 09:32, LEARN aktív | 32 | 22,45 | 16,55 | 3,80 |
| Tegnap 20:51, gyors textúrafrissítés | 17 | 30,0 | 0,0 | még nem mérték |
| Tegnap 22:17, Port 1 ki | 86 | 30,0 | 0,0 | még nem mérték |

A mai 32 ablakban a várakozás 13,9–20,6 ms között volt. A helyi kód tényleg várakozásra tér át, amikor egy fill későn újraírt lapot érint. A régi menetek eltérő builddel és útvonalon futottak. A különbség nagy és a mechanizmus illik rá, de a nyereség pontos értéke, a kizárólagos ok és a feloldott FPS még nyitott. [A #434 eredeti leírása](https://github.com/avatarmanz/VIctory-7900XTX/pull/434)

## Antigravity és Claude feladata

1. **Antigravity** vegye át a kész `csomag/claude-twin-move-agy.patch` fájlt. Most is tisztán illeszkedik (`git apply --check`). Az `eszkozok/agy-v2-profil.ps1` fájlban **külön is** állítsa `TWIN_EXACT=0`, `TWIN_MOVE=1` értékre a megfelelő `VICTORY_` kapcsolókat. A profil jelenleg kifejezetten visszakapcsolja az EXACT-ot. A 9070 XT-n ezzel már kétszer eszközvesztést láttatok.
2. **Claude** ugyanazon a hajós szakaszon rögzített MOVE mellett váltson kizárólag LEARN-t. Az indító már fogadja a `-AB '10,VICTORY_CARD_STEPS_LEARN'` paramétert. A 9-es menü jelenleg mindkét kapcsolót váltja. Mutató legyen az FPS, a várakozás és a csónak vagy az alakok nyúlása. Ha a LEARN kikapcsolva visszaadja a sebességet és szép marad a kép, ez legyen a gyors alap. Ha a nyúlás visszatér, maradjon külön választható a képhű mód. A `PORT_CBV_WRITTEN=2` már aktív az AGY-ban. A shader által írható konstanspufferek olvasását módosítja, más esetre szolgál, mint a #434.
3. **Képminőség.** A Claude-23-ban a javított Belobug 42 régi tiltást vizsgált újra, több karakteres resolve pipeline-nál az első kötés is látszik. Egy külön BVH-skinning shader még hibázott. A szemüveget először ezzel a builddel, ugyanabban a jelenetben nézzétek meg. Ha még égkék, a `Role::Reflect` tükröződéskorlátozása külön kapcsolható jelölt. A donor első commitja LDS- és RT-portot is hoz, a második sok egyéb optimalizálást tartalmaz. Csak a tükröződési útvonalat és a szükséges bekötéseket érdemes átvenni. A külső króm vagy víz fényessége jó kontroll, mert a korlát felületekre hat, nem a szemüveget azonosítja. [Első donorcommit](https://github.com/maren-halv/VIctory-DXR/commit/6c30d582ec1767f621a367848d20bca576c05fd3) · [A végrehajtási feltétel pontosítása](https://github.com/maren-halv/VIctory-DXR/commit/dd83629436e169c315c21b550aeeb9ff4118b00d)
4. **Zöld fal.** A helyi `ambient.rs` a `MOST`-ból felső korlátot számol, és a régi fényt legfeljebb 1-es szorzóval skálázza. A négyszeres zöld erősítés ebből nem következik. A HUD összesített DROP értékéből nem azonosítható egy hibás pixel eredete. Ha az RT-javítás mellett is megmarad, egy hibás képkockán mérjétek meg a gyanús világítási puffer értékeit. A BVH nélküli MISS külön jelölt; forrása a BVH-építő alapértékét is megfordítja, ezért a teljes commit átvétele más működést is módosítana. [fxceless commit](https://github.com/fxceless/victory-fork/commit/4966cd671b990d3e02b7928f4a28debb56c0a3bb)
