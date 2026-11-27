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
    [ValidateSet('1','2')][string]$IndirectBatch = '2',
    [ValidateRange(-1,3600)][int]$LombKezdet = -1,
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
if (Get-Process victory -ErrorAction SilentlyContinue) { throw 'Már fut egy victory.exe. Zárd be, és indítsd újra.' }

# --- Beállítások (a csomag scripts\play.ps1-e szerint) ----------------------------------------------
$settings = [ordered]@{
    VICTORY_TEXTURE_NO_WAIT = '1'; VICTORY_RELAY = '2'; VICTORY_WIDE_BACK = '1'; VICTORY_CARD_REHASH_RUNS = '1'
    VICTORY_JOIN_COPIES = '1'; VICTORY_INDIRECT_WINDOW = '1'; VICTORY_RELAY_COPY = '1'; VICTORY_CARD_STEPS = '2'
    VICTORY_INDIRECT_BATCH = $IndirectBatch; VICTORY_MAP_THREADS = '1'; VICTORY_TITLE_PRIORITIES = '0'; VICTORY_CARD_AWAKE = '1'
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
    $answer = Read-Host 'Folytatod mégis? (i/n)'
    if ($answer -notmatch '^[iIyY]') { Write-Host 'Leállítva.'; exit 2 }
}

# --- Futásmappa ------------------------------------------------------------------------------------
$dir = Join-Path $meresek "$(Get-Date -Format 'yyyyMMdd-HHmmss')-$Nev"
New-Item -ItemType Directory -Path $dir | Out-Null
$log = Join-Path $dir 'victory.log'; $memo = Join-Path $dir 'memoria.csv'; $info = Join-Path $dir 'futas.txt'
if ($LombKezdet -ge 0) {
    # A képek 30 másodperces ablaka a renderelő saját órája szerint indul.
    $settings.VICTORY_POP_WATCH = '{0}-{1}' -f $LombKezdet, ($LombKezdet + 30)
    $settings.VICTORY_POP_FOLDER = Join-Path $dir 'popwatch'
    $settings.VICTORY_WALLS_TRACE = '1'
}
$stop = Join-Path $dir '.mintavevo-leallit'; $marks = Join-Path $dir 'jelolesek.csv'
$head = (& git -C $tree rev-parse HEAD).Trim(); $branch = (& git -C $tree rev-parse --abbrev-ref HEAD).Trim()
$hash = (Get-FileHash -LiteralPath $victory -Algorithm SHA256).Hash
@(
    "Futás: $Nev",
    "Indítva (helyi idő): $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
    "Indítva (UTC): $((Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ'))",
    "Kódfa: $tree, ág $branch, HEAD $head",
    "victory.exe: $victory, SHA-256 $hash",
    "Profil: Belobug rx9070xt csomag, Series S, $(if ($Safe) { '-Safe, renderer-portok nélkül' } else { 'renderer-portok 1, 2, 5, 6, 7' }), textúrakorlát $(if ($TexMax -ne 'alap') { "$TexMax px" } else { 'a csomag alapértéke' }), $(if ($NoPcFsr) { 'a játék saját FSR-je' } else { 'PC-s AMD FSR' }), textúra-újranézés $(if ($LookMs -ne 'alap') { "legalább $LookMs ms-onként" } else { 'a csomag alapja' }), KEEP_SHOWN $(if ($KeepShown -ne 'alap') { $KeepShown } else { 'a csomag alapja (1)' })$(if ($Kepsor) { ', képsor 3 kép/s' }), FPS-korlát $(switch ($MaxFps) { '60' { '60' } 'nincs' { 'nincs' } default { 'a játéké (30)' } }), FSR-élesítés $(if ($Sharp -ne 'alap') { $Sharp } else { 'a játéké' })",
    "Beállítások: $(($settings.Keys | ForEach-Object { "$_=$($settings[$_])" }) -join ' ')",
    'Indítás előtti állapot:'
) + ($pre | ForEach-Object { "  $_" }) | Set-Content -LiteralPath $info -Encoding UTF8
if ($DryRun) { Write-Host "Próbafuttatás: a játék nem indult. Mappa: $dir"; exit 0 }

# --- Mintavevő és F8-jelölő ------------------------------------------------------------------------
$sampler = Start-Process -FilePath powershell.exe -WindowStyle Hidden -PassThru -ArgumentList @(
    '-NoProfile', '-ExecutionPolicy', 'RemoteSigned', '-File', "`"$PSScriptRoot\memoria-mintavevo.ps1`"",
    '-Out', "`"$memo`"", '-StopFile', "`"$stop`"")
$marker = Start-Process -FilePath powershell.exe -WindowStyle Hidden -PassThru -ArgumentList @(
    '-NoProfile', '-ExecutionPolicy', 'RemoteSigned', '-File', "`"$PSScriptRoot\jelolo.ps1`"",
    '-Out', "`"$marks`"", '-StopFile', "`"$stop`"")
$capture = if ($Kepsor) {
    Start-Process -FilePath powershell.exe -WindowStyle Hidden -PassThru -ArgumentList @(
        '-NoProfile', '-ExecutionPolicy', 'RemoteSigned', '-File', "`"$PSScriptRoot\kepsor.ps1`"",
        '-Out', "`"$(Join-Path $dir 'kepsor')`"", '-Seconds', '3600', '-Fps', '3', '-Quality', '75',
        '-NoMarker', '-StopFile', "`"$stop`"")
} else { $null }

# --- A játék ---------------------------------------------------------------------------------------
Get-ChildItem Env:VICTORY_* -ErrorAction SilentlyContinue | Remove-Item
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
