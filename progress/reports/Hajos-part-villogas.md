# Hajós küldetés – a jobb parti lombkorona villogása

A 20261126-202038-csomag-512-pcfsr menethez tartozó képsor első fájlja 20:28:26.765-kor készült. A vizsgált perc a felvétel 3:00–4:00 szakasza. A napló UTC-ben, a JPEG-fájlnevek helyi időben vannak.

| Felvétel | Eredeti JPEG | Mi látszik a jobb parton? |
|---|---|---|
| 3:44.116 | 203210-881.jpg | Nagy, sötét lombkorona az ég előtt. |
| 3:44.368 | 203211-133.jpg | A nagy lombkorona helyén ég és alacsonyabb növényzet látszik. |
| 3:44.619 | 203211-384.jpg | A nagy lombkorona visszatér, miközben a hajó tovább halad. |

[A három eredeti képből vett azonos képkivágás](Hajos-part-3m44.jpg). A teljes képek a játék mappájától a `meresek/kepsor/20261126-202826-csomag-pcfsr/` útvonalon találhatók. A képsor kb. 4 kép/s-os. A jelenség bizonyítható, a pontos időtartama nem olvasható ki.

A `victory.log` 19:32:11.954895Z-kor kiírt összesítése 30,1 FPS, 9683 várakozó textúraslot, 86 host pipeline hiányában eldobott művelet és 78 eldobott indirekt művelet képkockánként. A közel egyidejű diagnosztika 0,00 olyan indirekt rekordot mér képkockánként, amely a lista keretének elfogyása miatt futott üresen. Az összesített számlálókhoz nem tartozik tárgyazonosító. A megelőző részletes bontás a kikapcsolt sugárkövetéshez tartozó műveleteket is felsorol az eldobások között.

**Fejlesztési irány.** Az eltűnés–visszatérés erősebb nyom, mint a textúrasor hossza. A már előkészített 250 ms-os profil próbakörében ugyanezt a sziluettváltást keressük. Ha fennmarad, nézzük meg, hogy a növényzet rajzolási parancsa mindkét állapotban lefut-e. Ha eltűnik a parancs vagy a példányszám, az objektum láthatóságát és a részletességi szintek váltását vizsgáljuk. Ha a rajzolás és a példányszám megmarad, a levélanyag átlátszósági maszkja, a kiválasztott mip és a hozzá kötött textúra a következő nyom. A fa konkrét shaderét a jelenlegi napló nem azonosítja.
