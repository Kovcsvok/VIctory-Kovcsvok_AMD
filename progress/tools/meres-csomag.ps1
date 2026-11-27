# Mérőindító a Belobug rx9070xt csomaghoz (Claude, 2026-11-26).
# A csomag: avatarmanz/VIctory-7900XTX c9c932c + Belobug RX 9070 XT-javítások és HUD (e942896)
# + villódzásjavítás (5d6bd84) + DexNom FSR 4.1.2 port (cd8dfc0), VIctory-dev\belobug-9070.
# A beállítások a csomag scripts\play.ps1-éből valók, rajta az öt renderer-port (1, 2, 5, 6, 7),
# a Series S profil és a HUD (VICTORY_PANEL=1). Saját mentésmappa: state\belobug-9070\data
# (a KLBF-mentések másolata), saját cache: state\belobug-9070\cache.
#   -Nev      a futás neve (mappanév része)
#   -Safe     a csomag -Safe módja, renderer-portok nélkül (ha valami nem megy)
#   -TexMax   VICTORY_TEXTURE_MAX: a textúrák legnagyobb oldala px-ben (a KLBF -LowMemory-ja 512);
#             'alap' = a csomag alapértéke (1024, 92% VRAM fölött 512, 97% fölött 256)
#   -NoPcFsr  a játék saját (konzolos, fordított) FSR-je a PC-s AMD FSR helyett
#   -LookMs   VICTORY_TEXTURE_LOOK_MS: a memóriájára váró textúraslotot legalább ennyi ms-onként
#             újra megnézi (a csomag alapja: visszalépő várakozás kb. 4 s-ig; 'alap' = az marad)
#   -KeepShown VICTORY_KEEP_SHOWN: a másik textúrával felülírt slot az újig a régit mutatja
#             (0: soha, nullákat olvas; 1: a csomag alapja, csak azonos fajtánál; 2: minden azonos
#             dimenziójúnál). A villogó, eltűnő lombkoronák (Hajos-part-villogas.md) ellen.
#   -Kepsor   a futás alatt képsor a játék ablakáról (3 kép/s) a futás mappájának kepsor almappájába
#   -MaxFps   'alap' = a játék saját 30-as korlátja; 60 = VICTORY_FRAME_INTERVAL_MS=16.667 (a csomag
#             frame.rs-e, a betöltő a játéknak is 60-at ad); 'nincs' = VICTORY_FRAME_INTERVAL_MS=0
#   -Sharp    VICTORY_FSR_SHARPNESS (0..1): a PC-s FSR élesítése a játék sajátja helyett
#             (a csomag fidelityfx.rs-ében, Claude, 2026-11-26); 'alap' = a játék értéke
#   -FaJavitas 'ki' (alap) = VICTORY_PORT_CONSTANTS_ORDER=0: az avatarmanz fix/popin (7ab13ed) kikapcsolva,
#             mert ezen a gépen képkockánként kb. 15-20 ms GPU-idő és a fák villogása maradt (Claude-19);
#             'be' = a fix bekapcsolva: az 1-es port helyben olvasott indirekt argumentumai egyenként,
#             közvetlenül a futásuk előtt korlátozva
#   -Port1    'be' (alap) = VICTORY_PORT_CONSTANTS=1; 'ki' = az 1-es renderer-port nélkül (a 2, 5, 6, 7
#             marad; az 5-ös port ilyenkor másol). Az avatarmanz pop-10 menetében 1-es és 5-ös port nélkül
#             nem villogtak a fák: ez a fa-próba
#   -Port2    'be' (alap) = VICTORY_PORT_DESCRIPTORS=1; 'ki' = a 2-es renderer-port nélkül: minden képkockánál
#             a leírótábla összes megváltozott lapja átnézve, nem a foltozott tárolók jelzései és a 16 lapos
#             tartalék keresés (a 22:21-es menetben képkockánként ~25 rajzolási tábla-rekordot csak az talált meg)
#   -AB       VICTORY_AB=<mp>,<kapcsoló>[,..]: a kapcsolók futás közben váltogatva, minden kombináció
#             sorban, <mp> másodpercenként (a csomag ab.rs-e); a HUD órasávja alatt 'AB <bitek> | KI: ..'
#             sor mutatja, mi van épp kikapcsolva, a napló 'A/B phase' sorai a szakaszok idejét
#   -Learn    'be' (alap, 11-27 10:50 óta újra) = a csónak-javítás (avatarmanz PR 434): a beküldés utáni
#             írásokat megtanulja és megvárja; 'ki' = VICTORY_CARD_STEPS_LEARN=0, gyors, de a 10:22-es menetben
#             (Claude-25) egy hajó óriási ékké nyúlt, a hidroplánból vonalak futottak ki, és Jason és Cal szakálla
#             eltűnt; a 9-es élő próbában (11-27 10:04) hajózás közben ki 34-38 ms/kép, be 41-52 (Claude-24)
#   -RtFeloldas 'ki' (alap) = a 42 karakteres CS_RaytracingResolve shader kihagyva (VICTORY_SKIP_PIPELINES,
#             csomag\rt-feloldo-shaderek.txt): kikapcsolt BVH mellett lefutva kék arcot és fénylő szemet adtak
#             (11-27 10:06, Claude-24); 'be' = lefutnak (a Belobug f962387 + avatarmanz #430 óta elkészülnek)
#   -Tukrozes 'ki' (alap) / 'be' = VICTORY_REFLECT_HOLD=1: a sr_denoising:CS_UpdateHistory tükröződéseit a
#             szoba fényéhez köti (Antigravity agy-9070-v2 ebd4988 nyomán, saját kapcsolóval; a szemüvegben
#             látszó ég ellen, Claude-25); a 11-27 10:52-es élő próbában a szemüvegen nem változott semmi
#             (Claude-26), ezért nincs a menüben
#   -KartyaLepes 'be' (alap) = VICTORY_CARD_STEPS=2 (a csomag gyorsítása: a beküldés lépései a kártyán);
#             'ki' = nincs (a pontos, régi várakozás, lassabb): ellenőrzés, hogy Cal féloldalas szakálla
#             (Claude-26) a kártyás lépésekből jön-e
#   -ListaKeszlet 'be' (alap, 11-27 11:25 óta) = VICTORY_PRELUDE_POOL=1: a parancslisták előtét-listái futás
#             után egy közös, legfeljebb 192 darabos készletbe kerülnek. Ezen a kártyán minden lista legalább 1 MB
#             megosztott RAM-ot foglal; a 10:52-es menetben 1909 előtét élt, a próbán 292 (kb. 1-1,5 GB-tal
#             kevesebb, Claude-27); 'ki' = a régi mód
#   -FeltoltoBlokk '2' (alap, 11-27 12:20 óta) = VICTORY_STAGING_SPARES=2: a textúrák 64 MB-os feltöltő
#             blokkjaiból legfeljebb ennyi üres marad, másodpercenként ellenőrizve (Codex ötlete és kódja,
#             Claude-29). A 11:31-es menetben ezek a betöltéstől végig 576 MB-ot foglaltak; 'alap' = 8, a régi mód
#   -AutoA    'be' (alap, 11-27 13:10 óta) = VICTORY_AUTO_A=1: a játék virtuális kontrollere a 25. és a 150.
#             másodperc között 5 másodpercenként megnyomja az A-t (a fiókválasztó csak kontrollerre lép tovább),
#             amíg a játék a mentéseit nem listázza (= túl van a fiókválasztón; a 13:09-es próbában 0,5 s-mal az
#             első nyomás után). Amint a felhasználó bármit megnyom (kontroller vagy billentyű), végleg abbahagyja.
#             '<tól>,<ig>,<mp>' = tesztmenethez: a menükön át is nyomja (a 13:09-es próbában kb. 70 s-ra betöltött) Bekapcsolva a
#             mentések mappájáról indulás előtt másolat készül (state\belobug-9070\mentes-masolatok); 'ki' = nincs
#   -KesoToltes 'ki' (alap) / '1' / '2' = VICTORY_LATE_FILLS: a csónak-javítás megtanult lapjait egy saját szál
#             tölti újra közvetlenül azelőtt, hogy a kártya a beküldést futtatja, és a beküldő szál nem vár
#             (Claude-30; a 20 ms-os várakozás ellen). '1' = az előtte lévők beérkezése után (a régi várakozás
#             pillanata), '2' = már amikor a kártya lefuttatta őket
#   -KesoCbv  'ki' (alap) / '1' / '2' = VICTORY_INPLACE_LATE_CBV (Claude-31, az Antigravity 141b746 nyomán, a GPT
#             által talált határhiba javításával): a csónak-javítás megtanult lapjait a kártya közvetlenül a játék
#             memóriájából olvassa (64 KiB-os lapok), így ott nincs mit várni. Csak egy lapon belüli pufferre;
#             a többi a régi, várakozó úton marad. '1' = ahol futó beküldés írhat, ott nem; '2' = ott is
#   -ListaKorai 'be' (alap, 11-27 16:55 óta) / 'ki' = VICTORY_LANDED_EARLY=1 + VICTORY_LIST_IDLE_MOST=256 (Claude-31, RAM): a lefutott
#             beküldések parancslistái azonnal visszakerülnek a készletbe (nem 64 beküldésnyi várakozás után); amire a
#             parancsaik hivatkoztak, az ugyanannyi ideig marad meg, mint eddig. A 16:33-as menetben 1959 élő listából
#             803 volt ilyen visszatartott lista. A 16:47-es próbában 1133 élő lista (1940 helyett), a privát csúcs
#             25,8 GB (27,4 helyett), a munkakészlet csúcsa 21,6 GB (23,0 helyett), lassulás nélkül; 'ki' = a régi mód
#   -ListaLusta 'be' (alap, 11-27 17:25 óta) / 'ki' = VICTORY_LIST_LAZY=1 (Claude-32, RAM): a beküldött lista nem
#             kap azonnal új gépi listát, csak amikor a játék újra írni kezd bele; az üres (csak nyitott és lezárt)
#             lista a lezárásakor visszaadja; a tartalékkészlet felső határa rugalmas (2 mp-ig használatlan fölösleg
#             megy el). A 17:14-es próbában 409 élő lista 1133 helyett, munkakészlet medián 17,96 GiB 18,95 helyett,
#             képidő 42,3 ms 45,1 helyett; 'ki' = a régi mód
#   -ShaderVaras 'egyszer' (alap, 11-27 18:10 óta) / 'mindig' = VICTORY_PIPELINE_WAIT_ONCE=1 (Claude-32, akadások): egy új
#             gépi shaderre csak az első használat képkockájában vár (legfeljebb fél mp-et), utána a rajzolása kimarad,
#             amíg el nem készül. Előtte egy több mp-ig forduló shaderre minden képkocka újra fél mp-et várt: 8 képkocka
#             480 ms-mal egymás után (17:33-as próba); 'mindig' = a régi mód
#   -Idovonal '<mp>[+<mp>..],<képkocka>' = VICTORY_TIMELINE a menet mappájába (idovonal*.json és .txt): ennyi
#             másodperc után ennyi képkocka minden szál munkájáról és várakozásáról (Claude-32)
#   -IdovonalLassu <ms> = VICTORY_TIMELINE_SLOW: az idővonal az idő eljötte után az első ennyi ms-nál lassabb
#             képkockánál indul (akadások elkapására)
#   -Figyelo  HOSSZÚ JÁTÉK-MÉRÉS (Claude-35, a menü 0-s pontja): amíg játszol, egy menetben figyel mindent:
#             - akadások: 6 képkockás idővonal-felvétel minden 250 ms-nál hosszabb képkockánál;
#             - alacsony FPS: felvétel, ha az utolsó 30 képkocka átlaga 50 ms fölött van (20 FPS alatt);
#             - F8: minden lenyomásra felvétel is (nem csak jelölés): nyomd meg, ha akad, lassú vagy durva
#               modellek jönnek; az automatikus felvételek között legalább 90 mp, az F8-é nem vár;
#             - legfeljebb 60 felvétel a 180. mp-től; az első 4-nek a nagy (15 MB-os) fájlja is, a többinek
#               csak a 70 KB-os összefoglalója (idovonal.<mp>-<ok>.txt; ok: hitch, low, mark);
#             - memória: percenként a naplóba, melyik programrészünk foglalja a még növő memóriát
#               (VICTORY_HEAP_SITES=1, minden ezredik foglalás helye);
#             - adatbetöltés: a játék adatkérései (betoltes.tsv, mint a -BetoltesNaplo; 40 perc kb. 280 MB).
#             Nincs időkorlát: addig mér, amíg játszol.
#   -BetoltesNaplo = VICTORY_DSTORAGE_LOG a menet mappájába (betoltes.tsv): a játék minden adatkérése a
#             beküldés, indulás és kész idejével, és másodpercenként a lapbekötések ára (10 perc kb. 70 MB)
#   -Perc     felügyelet nélküli menet: ennyi perc után az ablakot bezárja (mint az X gomb); kevés memória
#             esetén ilyenkor nem kérdez, hanem leáll
#   -Felvetel VICTORY_RECORD_AT='<tól>,<ig>' másodpercben: magától induló videó (felügyelet nélküli menethez)
#   Videó: a játékban F9 indítja és ugyanaz állítja le a felvételt (HUD: piros REC); a fájl
#             a menet mappájába kerül, felvetel-<UTC idő>.mp4 néven.
#   -DryRun   csak előkészít, nem indít játékot
[CmdletBinding()]
param(
    [string]$Nev = 'csomag-jatek',
    [switch]$Safe,
    [ValidateSet('alap', '256', '512', '1024')][string]$TexMax = '512',
    [switch]$NoPcFsr,
    [ValidateSet('alap', '100', '250', '500', '1000')][string]$LookMs = 'alap',
    [ValidateSet('alap', '0', '1', '2')][string]$KeepShown = 'alap',
    [switch]$Kepsor,
    [ValidateSet('alap', '60', 'nincs')][string]$MaxFps = 'alap',
    [ValidateSet('alap', '0', '0.25', '0.5', '0.75', '1')][string]$Sharp = 'alap',
    [ValidateSet('ki', 'be')][string]$FaJavitas = 'ki',
    [ValidateSet('be', 'ki')][string]$Port1 = 'be',
    [ValidateSet('be', 'ki')][string]$Port2 = 'be',
    [ValidatePattern('^$|^\d+(\.\d+)?(,VICTORY_[A-Z0-9_]+){1,8}$')][string]$AB = '',
    [ValidateSet('ki', 'be')][string]$Learn = 'be',
    [ValidateSet('ki', 'be')][string]$RtFeloldas = 'ki',
    [ValidateSet('ki', 'be')][string]$Tukrozes = 'ki',
    [ValidateSet('be', 'ki')][string]$KartyaLepes = 'be',
    [ValidateSet('be', 'ki')][string]$ListaKeszlet = 'be',
    [ValidateSet('alap', '0', '1', '2', '4')][string]$FeltoltoBlokk = '2',
    [ValidatePattern('^(be|ki|[0-9]+,[0-9]+,[0-9]+)$')][string]$AutoA = 'be',
    [ValidateSet('ki', '1', '2')][string]$KesoToltes = 'ki',
    [ValidateSet('ki', '1', '2')][string]$KesoCbv = 'ki',
    [ValidateSet('ki', 'be')][string]$ListaKorai = 'be',
    [ValidateSet('ki', 'be')][string]$ListaLusta = 'be',
    [ValidateSet('egyszer', 'mindig')][string]$ShaderVaras = 'egyszer',
    [ValidatePattern('^$|^\d+(\+\d+)*,\d+$')][string]$Idovonal = '',
    [ValidateRange(0, 5000)][int]$IdovonalLassu = 0,
    [switch]$BetoltesNaplo,
    [switch]$Figyelo,
    [ValidateRange(0, 120)][int]$Perc = 0,
    [ValidatePattern('^$|^\d+,\d+$')][string]$Felvetel = '',
    [switch]$DryRun
)
$ErrorActionPreference = 'Stop'
$meresek = Split-Path $PSScriptRoot -Parent
$root    = Split-Path $meresek -Parent
$dev     = Join-Path $root 'VIctory-dev'
$tree    = Join-Path $dev 'belobug-9070'
$game    = Join-Path $root '<JATEKMAPPA>'
$title   = Join-Path $game 'game_scarlett_master.exe'
$victory = Join-Path $tree 'target\diag\victory.exe'
$ffx     = Join-Path $dev 'FidelityFX-SDK\Kits\FidelityFX\signedbin'
$crashes = Join-Path $dev 'state\belobug-9070\data\7952987A\crashes.log'
$inv     = [Globalization.CultureInfo]::InvariantCulture

if ($Nev -notmatch '^[A-Za-z0-9._-]+$') { throw "A futás neve csak ékezet nélküli betű, szám, pont, kötőjel és aláhúzás lehet: '$Nev'" }
foreach ($p in $victory, $title, (Join-Path $tree 'victory.toml')) {
    if (-not (Test-Path -LiteralPath $p)) { throw "Hiányzik: $p" }
}
# Csak egy másik játék (victory.exe run) állít meg; egy háttérbeli fordítás (translate, warm) nem.
if (Get-CimInstance Win32_Process -Filter "Name='victory.exe'" | Where-Object { $_.CommandLine -match '\srun\s' }) { throw 'Már fut egy játék (victory.exe). Zárd be, és indítsd újra.' }

# --- Beállítások (a csomag scripts\play.ps1-e szerint) ----------------------------------------------
$settings = [ordered]@{
    VICTORY_TEXTURE_NO_WAIT = '1'; VICTORY_RELAY = '2'; VICTORY_WIDE_BACK = '1'; VICTORY_CARD_REHASH_RUNS = '1'
    VICTORY_JOIN_COPIES = '1'; VICTORY_INDIRECT_WINDOW = '1'; VICTORY_RELAY_COPY = '1'; VICTORY_CARD_STEPS = '2'
    VICTORY_INDIRECT_BATCH = '2'; VICTORY_MAP_THREADS = '1'; VICTORY_TITLE_PRIORITIES = '0'; VICTORY_CARD_AWAKE = '1'
    VICTORY_SHOW_AFTER = '1'; VICTORY_AMBIENT = '0.8'; VICTORY_D3D12_DRED = 'light'
}
if ($Safe) {
    $settings.VICTORY_UNDER_WIDE = '0'; $settings.VICTORY_LAND_ECHO = '0'
} else {
    $settings.VICTORY_THIN = '1'; $settings.VICTORY_JOIN_PARTS = '8'; $settings.VICTORY_UPLOAD_AHEAD = '1'
    # Az öt renderer-port (README: a leggyorsabb mért összeállítás, 44,9 ms/kép).
    $settings.VICTORY_PORT_CONSTANTS = '1'; $settings.VICTORY_PORT_DESCRIPTORS = '1'; $settings.VICTORY_PORT_CBV = '1'
    $settings.VICTORY_PORT_GUARD = '1'; $settings.VICTORY_PORT_JOURNAL = '1'
}
$settings.VICTORY_PANEL = '1'   # FPS-kijelző a képen
# A játék által létrehozott pipeline-ok könyve (a csomag cache mappaja): utána a `victory warm --used`
# a ténylegesen használtakat előre lefordítja a driver gyorsítótárába (Codex, 2026-11-27).
$settings.VICTORY_PIPELINE_BOOK = '1'
if ($TexMax -ne 'alap') { $settings.VICTORY_TEXTURE_MAX = $TexMax }   # kevesebb VRAM és RAM (a KLBF 512 px-éhez hasonló)
# PC-s AMD FSR a játék saját FSR-hívásaira: a csomag run.rs-ében Series S-re is feloldva,
# ahogy a KLBF VICTORY_FSR_DLL-je teszi. -NoPcFsr: a játék saját, fordított FSR-je marad.
if ($LookMs -ne 'alap') { $settings.VICTORY_TEXTURE_LOOK_MS = $LookMs }   # kevesebb késve felbukkanó textúra
if ($KeepShown -ne 'alap') { $settings.VICTORY_KEEP_SHOWN = $KeepShown }  # kevesebb eltűnő lombkorona
if ($MaxFps -eq '60') { $settings.VICTORY_FRAME_INTERVAL_MS = '16.667' }
elseif ($MaxFps -eq 'nincs') { $settings.VICTORY_FRAME_INTERVAL_MS = '0' }
if ($Sharp -ne 'alap') {
    if ($NoPcFsr) { throw 'A -Sharp csak a PC-s FSR-rel működik (a -NoPcFsr mellett nem).' }
    $settings.VICTORY_FSR_SHARPNESS = $Sharp
}
if ($FaJavitas -eq 'ki') { $settings.VICTORY_PORT_CONSTANTS_ORDER = '0' }
if ($Port1 -eq 'ki') {
    if ($Safe) { throw 'A -Port1 ki a -Safe mellett értelmetlen (ott egyik port sincs bekapcsolva).' }
    $settings.VICTORY_PORT_CONSTANTS = '0'
}
if ($Port2 -eq 'ki') {
    if ($Safe) { throw 'A -Port2 ki a -Safe mellett értelmetlen (ott egyik port sincs bekapcsolva).' }
    $settings.VICTORY_PORT_DESCRIPTORS = '0'
}
if ($Learn -eq 'ki') { $settings.VICTORY_CARD_STEPS_LEARN = '0' }
if ($KartyaLepes -eq 'ki') { $settings.Remove('VICTORY_CARD_STEPS') }
if ($ListaKeszlet -eq 'be') { $settings.VICTORY_PRELUDE_POOL = '1' }   # kevesebb RAM (Claude-27)
if ($FeltoltoBlokk -ne 'alap') { $settings.VICTORY_STAGING_SPARES = $FeltoltoBlokk }   # kevesebb RAM (Codex, Claude-29)
if ($RtFeloldas -eq 'ki') {
    $rtList = Join-Path $meresek 'csomag\rt-feloldo-shaderek.txt'
    if (-not (Test-Path -LiteralPath $rtList)) { throw "Hiányzik: $rtList" }
    $settings.VICTORY_SKIP_PIPELINES = ((Get-Content -LiteralPath $rtList) | Where-Object { $_ -match '^[0-9a-f]{16}$' }) -join ','
}
if ($Tukrozes -eq 'be') { $settings.VICTORY_REFLECT_HOLD = '1' }
if ($AutoA -eq 'be') { $settings.VICTORY_AUTO_A = '1' } elseif ($AutoA -ne 'ki') { $settings.VICTORY_AUTO_A = $AutoA }   # A gomb magától a fiókválasztónál (Claude-30)
if ($KesoToltes -ne 'ki') { $settings.VICTORY_LATE_FILLS = $KesoToltes }   # a 20 ms-os várakozás ellen (Claude-30)
if ($KesoCbv -ne 'ki') { $settings.VICTORY_INPLACE_LATE_CBV = $KesoCbv }   # közvetlen olvasás (Claude-31)
if ($ListaKorai -eq 'be') { $settings.VICTORY_LANDED_EARLY = '1'; $settings.VICTORY_LIST_IDLE_MOST = '256' }   # RAM (Claude-31)
if ($ListaLusta -eq 'be') { $settings.VICTORY_LIST_LAZY = '1' }   # RAM (Claude-32)
if ($ShaderVaras -eq 'egyszer') { $settings.VICTORY_PIPELINE_WAIT_ONCE = '1' }   # akadások (Claude-32)
if ($Felvetel) { $settings.VICTORY_RECORD_AT = $Felvetel }
if ($AB) { $settings.VICTORY_AB = $AB }
if ($NoPcFsr) { $settings.VICTORY_FSR_PC = '0' }
else {
    if (-not (Test-Path -LiteralPath (Join-Path $ffx 'amd_fidelityfx_upscaler_dx12.dll'))) { throw "Hiányzik az AMD FSR: $ffx" }
    $settings.VICTORY_FIDELITYFX_DIR = $ffx
}

# --- Indítás előtti állapot ------------------------------------------------------------------------
$mem  = Get-CimInstance Win32_PerfFormattedData_PerfOS_Memory
$free = ($mem.CommitLimit - $mem.CommittedBytes) / 1GB
$heavy = @(Get-Process | Where-Object { $_.PrivateMemorySize64 -gt 2GB -or $_.Name -match 'llama|ollama|lmstudio|koboldcpp' })
$pre = @(
    [string]::Format($inv, 'Commitkeret: {0:F2} GiB, szabad {1:F2} GiB', $mem.CommitLimit / 1GB, $free),
    [string]::Format($inv, 'Szabad fizikai RAM: {0:F2} GiB', $mem.AvailableMBytes / 1024)
)
foreach ($h in $heavy) { $pre += [string]::Format($inv, 'Nagy memóriahasználó folyamat: {0} {1:F2} GiB', $h.Name, $h.PrivateMemorySize64 / 1GB) }
$pre | ForEach-Object { Write-Host $_ }
if (($heavy.Count -gt 0 -or $free -lt 20) -and -not $DryRun) {
    Write-Host 'FIGYELEM: kevés a szabad memória, vagy nagy program fut. Zárd be (pl. llama-server).' -ForegroundColor Yellow
    if ($Perc -gt 0) { Write-Host 'Felügyelet nélküli menet: leállítva.'; exit 2 }
    $answer = Read-Host 'Folytatod mégis? (i/n)'
    if ($answer -notmatch '^[iIyY]') { Write-Host 'Leállítva.'; exit 2 }
}

# --- Futásmappa ------------------------------------------------------------------------------------
$dir = Join-Path $meresek "$(Get-Date -Format 'yyyyMMdd-HHmmss')-$Nev"
New-Item -ItemType Directory -Path $dir | Out-Null
$log = Join-Path $dir 'victory.log'; $memo = Join-Path $dir 'memoria.csv'; $info = Join-Path $dir 'futas.txt'
$stop = Join-Path $dir '.mintavevo-leallit'; $marks = Join-Path $dir 'jelolesek.csv'
$head = (& git -C $tree rev-parse HEAD).Trim(); $branch = (& git -C $tree rev-parse --abbrev-ref HEAD).Trim()
$hash = (Get-FileHash -LiteralPath $victory -Algorithm SHA256).Hash
@(
    "Futás: $Nev",
    "Indítva (helyi idő): $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
    "Indítva (UTC): $((Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ'))",
    "Kódfa: $tree, ág $branch, HEAD $head",
    "victory.exe: $victory, SHA-256 $hash",
    "Profil: Belobug rx9070xt csomag, Series S, $(if ($Safe) { '-Safe, renderer-portok nélkül' } else { 'renderer-portok ' + ((@(@('1', $Port1), @('2', $Port2), @('5', 'be'), @('6', 'be'), @('7', 'be')) | Where-Object { $_[1] -eq 'be' } | ForEach-Object { $_[0] }) -join ', ') + $(if ($Port1 -eq 'ki' -or $Port2 -eq 'ki') { ' (' + ((@(@('1', $Port1), @('2', $Port2)) | Where-Object { $_[1] -eq 'ki' } | ForEach-Object { $_[0] + '-es' }) -join ' és ') + ' nélkül)' } else { '' }) }), textúrakorlát $(if ($TexMax -ne 'alap') { "$TexMax px" } else { 'a csomag alapértéke' }), $(if ($NoPcFsr) { 'a játék saját FSR-je' } else { 'PC-s AMD FSR' }), textúra-újranézés $(if ($LookMs -ne 'alap') { "legalább $LookMs ms-onként" } else { 'a csomag alapja' }), KEEP_SHOWN $(if ($KeepShown -ne 'alap') { $KeepShown } else { 'a csomag alapja (1)' })$(if ($Kepsor) { ', képsor 3 kép/s' }), FPS-korlát $(switch ($MaxFps) { '60' { '60' } 'nincs' { 'nincs' } default { 'a játéké (30)' } }), FSR-élesítés $(if ($Sharp -ne 'alap') { $Sharp } else { 'a játéké' }), fa-javítás (fix/popin 7ab13ed) $(if ($Safe -or $Port1 -eq 'ki') { 'hatástalan (1-es port nélkül)' } elseif ($FaJavitas -eq 'ki') { 'kikapcsolva' } else { 'bekapcsolva' }), fa-eltűnés elleni VICTORY_TWIN_MOVE bekapcsolva (saját, az avatarmanz PR 437 nyomán; a PR saját TWIN_EXACT-je ezen a kártyán összeomlik), előtét-listák közös készletben (VICTORY_PRELUDE_POOL) $(if ($ListaKeszlet -eq 'be') { 'bekapcsolva' } else { 'kikapcsolva' }), üres feltöltő blokkok legfeljebb $(if ($FeltoltoBlokk -eq 'alap') { '8 (régi mód)' } else { "$FeltoltoBlokk (VICTORY_STAGING_SPARES)" }), csónak-lépések a kártyán (VICTORY_CARD_STEPS)$(if ($KartyaLepes -eq 'ki') { 'kikapcsolva (pontos, lassabb ellenőrzés)' } else { '2' }), csónak-javítás (CARD_STEPS_LEARN, avatarmanz PR 434) $(if ($Learn -eq 'be') { 'bekapcsolva (képhű, lassabb)' } else { 'kikapcsolva (gyors; nyúló alakok és eltűnő szakáll)' }), karakteres RT-feloldás (42 CS_RaytracingResolve) $(if ($RtFeloldas -eq 'be') { 'fut' } else { 'kihagyva' }), szemüveg-korlát (VICTORY_REFLECT_HOLD) $(if ($AB -match 'VICTORY_REFLECT_HOLD') { 'élő próbában váltva' } elseif ($Tukrozes -eq 'be') { 'bekapcsolva' } else { 'kikapcsolva' })$(if ($AutoA -eq 'be') { ', A gomb magától (VICTORY_AUTO_A) a fiókválasztóig' } elseif ($AutoA -ne 'ki') { ", A gomb magától (VICTORY_AUTO_A=$AutoA, a menükön át)" })$(if ($KesoToltes -ne 'ki') { ", késő töltések a kártya előtt (VICTORY_LATE_FILLS=$KesoToltes)" })$(if ($ListaKorai -eq 'be') { ', lefutott listák azonnal vissza (VICTORY_LANDED_EARLY, legfeljebb 256 tartalék)' })$(if ($ListaLusta -eq 'be') { ', beküldött lista új gépi listát csak újraíráskor kap (VICTORY_LIST_LAZY)' })$(if ($ShaderVaras -eq 'egyszer') { ', új shaderre csak egy képkockában vár (VICTORY_PIPELINE_WAIT_ONCE)' })$(if ($KesoCbv -ne 'ki') { ", késői konstanspufferek helyben (VICTORY_INPLACE_LATE_CBV=$KesoCbv)" })$(if ($Perc -gt 0) { ", felügyelet nélkül, $Perc perc után bezárva" })$(if ($AB) { ", élő kapcsolók (VICTORY_AB): $AB" })$(if ($Figyelo) { ', HOSSZÚ JÁTÉK-MÉRÉS: idővonal akadásnál (250 ms), 20 FPS alatti jelenetnél és F8-ra, memória-helyek, adatbetöltési napló' })",
    "Beállítások: $(($settings.Keys | ForEach-Object { "$_=$($settings[$_])" }) -join ' ')",
    'Indítás előtti állapot:'
) + ($pre | ForEach-Object { "  $_" }) | Set-Content -LiteralPath $info -Encoding UTF8
if ($DryRun) { Write-Host "Próbafuttatás: a játék nem indult. Mappa: $dir"; exit 0 }

# --- Mintavevő és F8-jelölő ------------------------------------------------------------------------
# Egy korábbi menet segédje tovább futhat, ha az ablakát a lezárás előtt bezárták: a 10:04-es menet
# jelölője egy óráig foglalta az F8-at, ezért a 10:22-es és a 10:52-es menet jelölései a 10:04-es
# mappába kerültek (Windows-hibakód 1409). Indulás előtt ezeket a saját segédeket leállítjuk.
Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" -ErrorAction SilentlyContinue |
    Where-Object { $_.ProcessId -ne $PID -and $_.CommandLine -match '\\eszkozok\\(jelolo|memoria-mintavevo|kepsor)\.ps1' } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
$sampler =Start-Process -FilePath powershell.exe -WindowStyle Hidden -PassThru -ArgumentList @(
    '-NoProfile', '-ExecutionPolicy', 'RemoteSigned', '-File', "`"$PSScriptRoot\memoria-mintavevo.ps1`"",
    '-Out', "`"$memo`"", '-StopFile', "`"$stop`"")
$marker = Start-Process -FilePath powershell.exe -WindowStyle Hidden -PassThru -ArgumentList @(
    '-NoProfile', '-ExecutionPolicy', 'RemoteSigned', '-File', "`"$PSScriptRoot\jelolo.ps1`"",
    '-Out', "`"$marks`"", '-StopFile', "`"$stop`"", '-MaxSeconds', $(if ($Figyelo) { '14400' } else { '3600' }))
$capture = if ($Kepsor) {
    Start-Process -FilePath powershell.exe -WindowStyle Hidden -PassThru -ArgumentList @(
        '-NoProfile', '-ExecutionPolicy', 'RemoteSigned', '-File', "`"$PSScriptRoot\kepsor.ps1`"",
        '-Out', "`"$(Join-Path $dir 'kepsor')`"", '-Seconds', '3600', '-Fps', '3', '-Quality', '75',
        '-NoMarker', '-StopFile', "`"$stop`"")
} else { $null }

# --- A játék ---------------------------------------------------------------------------------------
# A mentések másolata, mielőtt a virtuális kontroller magától nyom (2-3 MB; Claude-30).
if ($AutoA -ne 'ki') {
    $saves = Join-Path $dev 'state\belobug-9070\data\7952987A\saves'
    if (Test-Path -LiteralPath $saves) {
        $copy = Join-Path $dev "state\belobug-9070\mentes-masolatok\$(Split-Path $dir -Leaf)"
        New-Item -ItemType Directory -Force -Path $copy | Out-Null
        Copy-Item -LiteralPath $saves -Destination $copy -Recurse -Force
    }
}
# Felügyelet nélküli menet: az időzítő -Perc perc után bezárja az ablakot (mint az X gomb).
$closer = if ($Perc -gt 0) {
    Start-Process -FilePath powershell.exe -WindowStyle Hidden -PassThru -ArgumentList @(
        '-NoProfile', '-ExecutionPolicy', 'RemoteSigned', '-File', "`"$PSScriptRoot\idozito-zaro.ps1`"",
        '-Perc', "$Perc", '-StopFile', "`"$stop`"")
} else { $null }
Get-ChildItem Env:VICTORY_* -ErrorAction SilentlyContinue | Remove-Item
# F9 a játékban: videófelvétel indul/áll le (a csomag record.rs-e); a fájl a menet mappájába kerül.
$settings.VICTORY_RECORD_DIR = $dir
if ($Idovonal) { $settings.VICTORY_TIMELINE = "$Idovonal,$(Join-Path $dir 'idovonal.json')" }   # Claude-32
if ($IdovonalLassu -gt 0) { $settings.VICTORY_TIMELINE_SLOW = "$IdovonalLassu" }
if ($BetoltesNaplo) { $settings.VICTORY_DSTORAGE_LOG = (Join-Path $dir 'betoltes.tsv') }   # Claude-32
if ($Figyelo) {   # Claude-35: a hosszú játék-mérés
    $settings.VICTORY_TIMELINE = "180x60,6,$(Join-Path $dir 'idovonal.json')"
    $settings.VICTORY_TIMELINE_SLOW = '250'
    $settings.VICTORY_TIMELINE_LOW = '50'
    $settings.VICTORY_TIMELINE_MARKS = $marks
    $settings.VICTORY_TIMELINE_GAP = '90'
    $settings.VICTORY_TIMELINE_JSON_MOST = '4'
    $settings.VICTORY_HEAP_SITES = '1'
    $settings.VICTORY_DSTORAGE_LOG = (Join-Path $dir 'betoltes.tsv')
}
foreach ($k in $settings.Keys) { Set-Item "Env:$k" $settings[$k] }
$env:RUST_LOG = 'info'; $env:NO_COLOR = '1'
Write-Host ''
Write-Host "Indul a csomag (Belobug rx9070xt). Napló: $log"
Write-Host 'Ez az ablak a játékból való kilépésig várakozik; ne zárd be. F8 = időpont-jelölés.'
$started = Get-Date
$crashLen = if (Test-Path -LiteralPath $crashes) { (Get-Item -LiteralPath $crashes).Length } else { 0 }
Push-Location $tree   # a victory.toml-t innen olvassa
try {
    cmd.exe /c "`"$victory`" run `"$title`" --execute --console series-s > `"$log`" 2>&1"
    $rc = $LASTEXITCODE
} finally { Pop-Location }
$ended = Get-Date

# --- Lezárás ---------------------------------------------------------------------------------------
New-Item -ItemType File -Path $stop -Force | Out-Null
if (-not $sampler.WaitForExit(20000)) { Stop-Process -Id $sampler.Id -Force -ErrorAction SilentlyContinue }
if (-not $marker.WaitForExit(5000)) { Stop-Process -Id $marker.Id -Force -ErrorAction SilentlyContinue }
if ($capture -and -not $capture.WaitForExit(10000)) { Stop-Process -Id $capture.Id -Force -ErrorAction SilentlyContinue }
if ($closer -and -not $closer.WaitForExit(5000)) { Stop-Process -Id $closer.Id -Force -ErrorAction SilentlyContinue }
Remove-Item -LiteralPath $stop -ErrorAction SilentlyContinue
if ((Test-Path -LiteralPath $crashes) -and (Get-Item -LiteralPath $crashes).LastWriteTime -ge $started) {
    $all = [IO.File]::ReadAllBytes($crashes)
    $from = if ($crashLen -le $all.Length) { $crashLen } else { 0 }
    if ($all.Length -gt $from) {
        $new = New-Object byte[] ($all.Length - $from)
        [Array]::Copy($all, $from, $new, 0, $new.Length)
        [IO.File]::WriteAllBytes((Join-Path $dir 'crashes.log'), $new)
    }
}
@(
    "Kilépés (helyi idő): $($ended.ToString('yyyy-MM-dd HH:mm:ss'))",
    [string]::Format($inv, 'Futásidő: {0:F1} perc', ($ended - $started).TotalMinutes),
    "Kilépési kód: $rc"
) | Add-Content -LiteralPath $info -Encoding UTF8
Write-Host ''
Write-Host "Vége. Futásidő: $([math]::Round(($ended - $started).TotalMinutes, 1)) perc, kilépési kód $rc. A naplót Claude elemzi: $dir"
exit $rc
