# KLBF mérőindító (Claude, 2026-11-26).
# Ugyanazokkal a beállításokkal indítja a KLBF-et, mint az Inditas-KLBF.cmd (klbf-lab\play.ps1),
# és mellé teszi:
#   - victory.log      : a teljes napló (RUST_LOG=info), stdout+stderr egy fájlban
#   - frametime.csv    : VICTORY_FRAMETIME_DUMP, kb. másodpercenként egy sor az intervallum
#                        legrosszabb és átlagos képkockaidejével (NEM képkockánkénti adatsor)
#   - memoria.csv      : másodpercenkénti Windows-commit, RAM, lapozás és GPU-memória minta
#   - futas.txt        : commit, profil, indítás előtti memóriaállapot
#   - osszegzes.md     : a kilépés után automatikusan készülő elemzés
# A klbf-lab\play.ps1 változatlan marad: a futás mappájába egy másolat kerül, amelyben csak a
# két $PSScriptRoot-útvonal és egy VICTORY_FRAMETIME_DUMP sor tér el (a play.ps1 induláskor
# törli az összes VICTORY_* változót, ezért kívülről nem adható át).
#   - jelolesek.csv    : az F8 jelölőgomb lenyomásainak ideje (pl. a büfébe érkezés)
# -Fa klbf-c1 a C1 tesztág binárisát indítja (VIctory-dev\klbf-c1). Az állapot, a mentések
# és a shader-cache ugyanaz marad, mert a munkakönyvtár mindig a klbf-lab (victory.toml).
# -MapLean 0|1 a VICTORY_MAP_LEAN értékét rögzíti; csak a C1/C2 binárissal van hatása.
# -Fa klbf-c2 (KLBF Lab 63.2 + C1) saját shader-cache-t kap (state\klbf-c2\cache), mert a
# shaderfordítása eltér; a mentések közösek maradnak.
# -Bench: a KLBF beépített BM-v1 benchmarkja (KLBF_BENCH=bm-v1, 5:00 lezárt bemenettel; csak C2).
# -Elofordit: a játék helyett a shader-előfordítás fut (play.ps1 -Prebuild), mérés nélkül.
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Nev,
    [switch]$LowMemory,
    [ValidateSet('klbf-lab', 'klbf-c1', 'klbf-c2')][string]$Fa = 'klbf-lab',
    [ValidateSet('', '0', '1')][string]$MapLean = '',
    [switch]$Bench,
    [switch]$Elofordit,
    [switch]$DryRun
)
$ErrorActionPreference = 'Stop'
$meresek = Split-Path $PSScriptRoot -Parent
$root    = Split-Path $meresek -Parent
$dev     = Join-Path $root 'VIctory-dev'
$klbf    = Join-Path $dev 'klbf-lab'
$tree    = Join-Path $dev $Fa
$game    = Join-Path $root '<JATEKMAPPA>'
$title   = Join-Path $game 'game_scarlett_master.exe'
$fsr     = Join-Path $dev 'FidelityFX-SDK\Kits\FidelityFX\signedbin'
$victory = Join-Path $tree 'target\release\victory.exe'
if ($MapLean -ne '' -and $Fa -eq 'klbf-lab') {
    throw 'A -MapLean csak a C1/C2 binárissal (-Fa klbf-c1 vagy klbf-c2) értelmes: a klbf-lab nem ismeri a VICTORY_MAP_LEAN kapcsolót.'
}
if ($Bench -and $Fa -ne 'klbf-c2') { throw 'A beépített benchmark (-Bench) csak a Lab 63.2-ben (-Fa klbf-c2) van meg.' }
$cacheDir = if ($Fa -eq 'klbf-c2') { Join-Path $dev 'state\klbf-c2\cache' } else { '' }
$crashes = Join-Path $dev 'state\klbf-lab\data\7952987A\crashes.log'
$inv     = [Globalization.CultureInfo]::InvariantCulture

if ($Nev -notmatch '^[A-Za-z0-9._-]+$') {
    throw "A futás neve csak ékezet nélküli betűt, számot, pontot, kötőjelet és aláhúzást tartalmazhat: '$Nev'"
}
foreach ($p in $victory, $title, (Join-Path $fsr 'amd_fidelityfx_upscaler_dx12.dll')) {
    if (-not (Test-Path -LiteralPath $p)) { throw "Hiányzik: $p" }
}
if (Get-Process victory -ErrorAction SilentlyContinue) {
    throw 'Már fut egy victory.exe. Zárd be, és indítsd újra a mérést.'
}

# --- Indítás előtti memóriaállapot -------------------------------------------------------
$mem  = Get-CimInstance Win32_PerfFormattedData_PerfOS_Memory
$free = ($mem.CommitLimit - $mem.CommittedBytes) / 1GB
$ad   = Get-CimInstance Win32_PerfFormattedData_GPUPerformanceCounters_GPUAdapterMemory |
        Sort-Object TotalCommitted -Descending | Select-Object -First 1
$adDed = $ad.DedicatedUsage / 1GB
$heavy = @(Get-Process | Where-Object { $_.PrivateMemorySize64 -gt 2GB -or $_.Name -match 'llama|ollama|lmstudio|koboldcpp' } |
        Sort-Object PrivateMemorySize64 -Descending)
$pre = @(
    [string]::Format($inv, 'Commitkeret: {0:F2} GiB, lefoglalva {1:F2} GiB, szabad {2:F2} GiB',
        $mem.CommitLimit / 1GB, $mem.CommittedBytes / 1GB, $free),
    [string]::Format($inv, 'Szabad fizikai RAM: {0:F2} GiB', $mem.AvailableMBytes / 1024),
    [string]::Format($inv, 'GPU dedikált memória használatban (minden folyamat): {0:F2} GiB, megosztott: {1:F2} GiB',
        $adDed, $ad.SharedUsage / 1GB)
)
foreach ($h in $heavy) {
    $pre += [string]::Format($inv, 'Nagy memóriahasználó folyamat: {0} (PID {1}) {2:F2} GiB privát', $h.Name, $h.Id, $h.PrivateMemorySize64 / 1GB)
}
$pre | ForEach-Object { Write-Host $_ }
$warn = ($heavy.Count -gt 0) -or ($adDed -gt 3) -or ($free -lt 20)
if ($warn -and -not $DryRun) {
    Write-Host ''
    Write-Host 'FIGYELEM: a fenti folyamat(ok) vagy a már foglalt VRAM/commit torzítja a mérést.' -ForegroundColor Yellow
    Write-Host 'Javaslat: zárd be őket (pl. llama-server), majd indítsd újra ezt a mérést.' -ForegroundColor Yellow
    $answer = Read-Host 'Folytatod mégis? (i/n)'
    if ($answer -notmatch '^[iIyY]') { Write-Host 'Leállítva, nem indult játék.'; exit 2 }
}

# --- Futásmappa és metaadatok ---------------------------------------------------------------
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$dir = Join-Path $meresek "$stamp-$Nev"
New-Item -ItemType Directory -Path $dir | Out-Null
$log  = Join-Path $dir 'victory.log'
$csv  = Join-Path $dir 'frametime.csv'
$memo = Join-Path $dir 'memoria.csv'
$info = Join-Path $dir 'futas.txt'
$stop = Join-Path $dir '.mintavevo-leallit'
$marks = Join-Path $dir 'jelolesek.csv'

$head   = (& git -C $tree rev-parse HEAD).Trim()
$branch = (& git -C $tree rev-parse --abbrev-ref HEAD).Trim()
$dirty  = @(& git -C $tree status --porcelain).Count
$exe   = Get-Item -LiteralPath $victory
$hash  = (Get-FileHash -LiteralPath $victory -Algorithm SHA256).Hash
$profil = if ($LowMemory) { 'KLBF, Series S + FSR, VICTORY_TEXTURE_MAX_DIM=512 (-LowMemory)' } else { 'KLBF, Series S + FSR, VICTORY_TEXTURE_MAX_DIM=1024' }
@(
    "Futás: $Nev",
    "Indítva (helyi idő): $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
    "Indítva (UTC): $((Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ'))",
    "Kódfa: $tree, ág $branch, HEAD $head (nem commitolt változás: $dirty fájl)",
    "VICTORY_MAP_LEAN: $(if ($MapLean -eq '') { 'nincs beállítva' } else { $MapLean })",
    "victory.exe: $($exe.FullName), $($exe.Length) bájt, módosítva $($exe.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss')), SHA-256 $hash",
    "Profil: $profil",
    "Indító: meresek\eszkozok\meres-klbf.ps1 -> play-meres.ps1 (a $Fa\play.ps1 másolata + VICTORY_FRAMETIME_DUMP$(if ($MapLean -ne '') { ' + VICTORY_MAP_LEAN' })); munkakönyvtár és állapot: klbf-lab (victory.toml)",
    'Indítás előtti állapot:'
) + ($pre | ForEach-Object { "  $_" }) | Set-Content -LiteralPath $info -Encoding UTF8

# --- play.ps1 másolata a frametime-dumppal -----------------------------------------------------
$src = Get-Content -LiteralPath (Join-Path $tree 'play.ps1') -Raw
$n1 = ([regex]::Matches($src, [regex]::Escape('$PSScriptRoot'))).Count
$n2 = ([regex]::Matches($src, [regex]::Escape("VICTORY_OVERLAY = '0'"))).Count
if ($n1 -ne 2 -or $n2 -ne 1) {
    throw "A $Fa\play.ps1 szerkezete megváltozott ($n1 db `$PSScriptRoot, $n2 db VICTORY_OVERLAY). Frissíteni kell a mérőindítót."
}
$extra = "; VICTORY_FRAMETIME_DUMP = '$csv'"
if ($MapLean -ne '') { $extra += "; VICTORY_MAP_LEAN = '$MapLean'" }
if ($cacheDir) { $extra += "; VICTORY_CACHE_DIR = '$cacheDir'" }
$patched = $src.Replace('$PSScriptRoot', "'$tree'").Replace("VICTORY_OVERLAY = '0'", "VICTORY_OVERLAY = '0'$extra")
$play = Join-Path $dir 'play-meres.ps1'
Set-Content -LiteralPath $play -Value $patched -Encoding UTF8

@(
    "Shader-cache: $(if ($cacheDir) { $cacheDir } else { 'a victory.toml szerinti (state\klbf-lab\cache)' })",
    "Mód: $(if ($Elofordit) { 'shader-előfordítás' } elseif ($Bench) { 'KLBF beépített benchmark BM-v1 (KLBF_BENCH=bm-v1)' } else { 'játék' })"
) | Add-Content -LiteralPath $info -Encoding UTF8

if ($DryRun) {
    Write-Host "Próbafuttatás: a játék nem indult. Előkészített mappa: $dir"
    exit 0
}

# --- Shader-előfordítás mérés nélkül -------------------------------------------------------------
if ($Elofordit) {
    $plog = Join-Path $dir 'eloforditas.log'
    Write-Host "Shader-előfordítás indul ($Fa). Napló: $plog"
    Write-Host 'Ez kb. 25 percig tart, közben a videokártya foglalt: ne indíts játékot. Ha a driver összeomlik, magától folytatja.'
    $t0 = Get-Date
    Push-Location $klbf
    # A Windows PowerShell 5.1 a 2>&1 alatt minden stderr-sort hibarekordba csomagol; 'Stop' mellett
    # már az első sor (a shader-csomag leírása) megszakítaná az előfordítást.
    $ErrorActionPreference = 'Continue'
    try {
        & powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File $play -GameDir $game -Exe $title -FfxDir $fsr -Prebuild 2>&1 |
            ForEach-Object {
                $l = "$_"
                Add-Content -LiteralPath $plog -Value $l -Encoding UTF8
                if ($l -match 'Pre-build done|Pass \d+ ended|error|panicked') { Write-Host $l }
            }
        $rc = $LASTEXITCODE
    } finally { Pop-Location; $ErrorActionPreference = 'Stop' }
    @("Előfordítás vége: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $([math]::Round(((Get-Date) - $t0).TotalMinutes, 1)) perc, kilépési kód $rc") |
        Add-Content -LiteralPath $info -Encoding UTF8
    if (Select-String -LiteralPath $plog -Pattern 'Pre-build done' -Quiet) { Write-Host 'Kész: az előfordítás befejeződött.' } else { Write-Host 'FIGYELEM: a naplóban nincs "Pre-build done" sor.' -ForegroundColor Yellow }
    exit $rc
}

# --- Memória-mintavevő a háttérben ------------------------------------------------------------
$sampler = Start-Process -FilePath powershell.exe -WindowStyle Hidden -PassThru -ArgumentList @(
    '-NoProfile', '-ExecutionPolicy', 'RemoteSigned', '-File', "`"$PSScriptRoot\memoria-mintavevo.ps1`"",
    '-Out', "`"$memo`"", '-StopFile', "`"$stop`"")
$marker = Start-Process -FilePath powershell.exe -WindowStyle Hidden -PassThru -ArgumentList @(
    '-NoProfile', '-ExecutionPolicy', 'RemoteSigned', '-File', "`"$PSScriptRoot\jelolo.ps1`"",
    '-Out', "`"$marks`"", '-StopFile', "`"$stop`"")

# --- A játék ------------------------------------------------------------------------------------
$env:RUST_LOG = 'info'
$env:NO_COLOR = '1'
# A KLBF a forrásfán belülre (.victory-root) nem ír eredményt, ezért a futás mappájába kérjük.
if ($Bench) { $env:KLBF_BENCH = 'bm-v1'; $env:KLBF_BENCH_DIR = $dir }
else { Remove-Item Env:KLBF_BENCH, Env:KLBF_BENCH_DIR -ErrorAction SilentlyContinue }
$playArgs = "-NoProfile -ExecutionPolicy RemoteSigned -File `"$play`" -GameDir `"$game`" -Exe `"$title`" -FfxDir `"$fsr`""
if ($LowMemory) { $playArgs += ' -LowMemory' }
Write-Host ''
Write-Host "Indul a KLBF. Napló: $log"
Write-Host 'Ez az ablak a játékból való kilépésig várakozik; ne zárd be.'
Write-Host 'Jelölés: nyomd meg az F8-at (a játék ablakában is működik), hangjelzés jön.'
$started = Get-Date
$crashLen = if (Test-Path -LiteralPath $crashes) { (Get-Item -LiteralPath $crashes).Length } else { 0 }
Push-Location $klbf
try {
    cmd.exe /c "powershell.exe $playArgs > `"$log`" 2>&1"
    $rc = $LASTEXITCODE
} finally {
    Pop-Location
}
$ended = Get-Date

# --- Lezárás -------------------------------------------------------------------------------------
New-Item -ItemType File -Path $stop -Force | Out-Null
if (-not $sampler.WaitForExit(20000)) { Stop-Process -Id $sampler.Id -Force -ErrorAction SilentlyContinue }
if (-not $marker.WaitForExit(5000)) { Stop-Process -Id $marker.Id -Force -ErrorAction SilentlyContinue }
Remove-Item -LiteralPath $stop -ErrorAction SilentlyContinue
# A crashes.log a futások között gyűlik: csak az e futás alatt hozzáírt rész kerül a mappába.
if ((Test-Path -LiteralPath $crashes) -and (Get-Item -LiteralPath $crashes).LastWriteTime -ge $started) {
    $all = [IO.File]::ReadAllBytes($crashes)
    $from = if ($crashLen -le $all.Length) { $crashLen } else { 0 }
    if ($all.Length -gt $from) {
        $new = New-Object byte[] ($all.Length - $from)
        [Array]::Copy($all, $from, $new, 0, $new.Length)
        [IO.File]::WriteAllBytes((Join-Path $dir 'crashes.log'), $new)
    }
}
if ($Bench) {
    $cards = @(Get-ChildItem -LiteralPath $dir -Filter 'KLBF-Bench-*' -File)
    if ($cards.Count -gt 0) { "Benchmark-eredmény: $($cards.Name -join ', ')" | Add-Content -LiteralPath $info -Encoding UTF8 }
    else { 'Benchmark-eredmény: nincs (a napló "KLBF Lab Bench" sorai mutatják, miért)' | Add-Content -LiteralPath $info -Encoding UTF8 }
}
@(
    "Kilépés (helyi idő): $($ended.ToString('yyyy-MM-dd HH:mm:ss'))",
    [string]::Format($inv, 'Futásidő: {0:F1} perc', ($ended - $started).TotalMinutes),
    "Kilépési kód: $rc"
) | Add-Content -LiteralPath $info -Encoding UTF8

$py = Get-Command py -ErrorAction SilentlyContinue
if ($py) {
    & py -3 -I (Join-Path $PSScriptRoot 'elemzes.py') $dir
    & py -3 -I (Join-Path $klbf 'tools\fps-session.py') $log --build $head.Substring(0, 8) `
        --gpu 'RX 9070 XT 16 GB' --cpu 'i5-14600KF' --out (Join-Path $dir 'fps.json') 2>&1 |
        ForEach-Object { "$_" } | Out-File -LiteralPath (Join-Path $dir 'fps-session.txt') -Encoding utf8
} else {
    Write-Host 'Nincs py.exe: az elemzés kimaradt (a nyers naplók megvannak).'
}
Write-Host ''
Write-Host "Kész. A futás mappája: $dir"
exit $rc
