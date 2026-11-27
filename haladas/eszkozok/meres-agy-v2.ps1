param(
    [string]$Nev = 'agyv2-stabil-30',
    [int]$TexMax = 512,
    [double]$Sharp = 0.5,
    [string]$MaxFps = 'alap',
    [ValidateSet('be', 'ki')]
    [string]$Port1 = 'be',
    [switch]$Kepsor,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

$profil = Join-Path $PSScriptRoot 'agy-v2-profil.ps1'
if (-not (Test-Path -LiteralPath $profil)) {
    Write-Error "Nem talalhato a profil: $profil"
    exit 1
}
. $profil -Port1 $Port1

# Per-futtatasi felulirasok a profil betoltese utan
$env:VICTORY_TEXTURE_MAX   = "$TexMax"
$env:VICTORY_FSR           = '1'
$env:VICTORY_FSR_SHARPNESS = $Sharp.ToString([System.Globalization.CultureInfo]::InvariantCulture)
if ($MaxFps -eq 'alap' -or [string]::IsNullOrWhiteSpace($MaxFps)) {
    Remove-Item -Path Env:VICTORY_MAX_FPS -ErrorAction SilentlyContinue
} else {
    $env:VICTORY_MAX_FPS = $MaxFps
}

if (-not (Test-Path -LiteralPath $AgyExe)) {
    Write-Error "Nem talalhato a victory.exe: $AgyExe"
    exit 1
}
if (-not (Test-Path -LiteralPath $TitleExe)) {
    Write-Error "Nem talalhato a jatek exe: $TitleExe"
    exit 1
}
if (Get-Process -Name 'victory' -ErrorAction SilentlyContinue) {
    Write-Error 'A victory.exe mar fut! Zard be elotte.'
    exit 1
}

# Memoria pre-flight
$osMem = Get-CimInstance Win32_PerfFormattedData_PerfOS_Memory -ErrorAction SilentlyContinue
$availMb = if ($osMem) { [int]$osMem.AvailableMBytes } else { 0 }
$commitFreeGb = 0.0
if ($osMem -and $osMem.CommitLimit -gt 0) {
    $commitFreeGb = [math]::Round((($osMem.CommitLimit - $osMem.CommittedBytes) / 1GB), 2)
}
$heavy = @(Get-Process -ErrorAction SilentlyContinue | Where-Object {
    $_.PrivateMemorySize64 -gt 2GB -or $_.Name -match 'llama|ollama|lmstudio|koboldcpp'
})
if (($heavy.Count -gt 0 -or $commitFreeGb -lt 20) -and -not $DryRun) {
    Write-Host ("FIGYELEM: Szabad commit={0} GB, Elerheto RAM={1} MB, nehez folyamatok={2}" -f $commitFreeGb, $availMb, $heavy.Count) -ForegroundColor Yellow
    if ($heavy.Count -gt 0) {
        $heavy | ForEach-Object { Write-Host ("  - {0} ({1:N1} GB)" -f $_.Name, ($_.PrivateMemorySize64 / 1GB)) -ForegroundColor Yellow }
    }
    $ans = Read-Host 'Folytatod igy is? (i/n)'
    if ($ans -notmatch '^(i|igen|y|yes)$') {
        exit 2
    }
}

$safeNev = ($Nev -replace '[^a-zA-Z0-9_-]', '-').Trim('-')
if ([string]::IsNullOrWhiteSpace($safeNev)) { $safeNev = 'agyv2' }
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$meresRoot = Split-Path -Parent $PSScriptRoot
$dir = Join-Path $meresRoot ("{0}-{1}" -f $stamp, $safeNev)

$gitBranch = (git -C $AgyTree rev-parse --abbrev-ref HEAD 2>$null)
$gitHead   = (git -C $AgyTree rev-parse --short HEAD 2>$null)
$exeHash   = (Get-FileHash -LiteralPath $AgyExe -Algorithm SHA256).Hash

$victoryEnvSummary = (
    Get-ChildItem -Path Env:VICTORY_* |
    Sort-Object Name |
    ForEach-Object { "{0}={1}" -f $_.Name, $_.Value }
) -join '; '

if ($DryRun) {
    Write-Host '=== AGY-9070-v2 DRY RUN ===' -ForegroundColor Cyan
    Write-Host ("Mappa      : {0}" -f $dir)
    Write-Host ("Exe        : {0}" -f $AgyExe)
    Write-Host ("Branch/HEAD: {0} @ {1}" -f $gitBranch, $gitHead)
    Write-Host ("SHA-256    : {0}" -f $exeHash)
    Write-Host ("Kepsor     : {0}" -f ([bool]$Kepsor))
    Write-Host ("RAM/Commit : {0} MB RAM / {1} GB szabad commit" -f $availMb, $commitFreeGb)
    Write-Host ("VICTORY_*  : {0}" -f $victoryEnvSummary)
    exit 0
}

New-Item -ItemType Directory -Path $dir -Force | Out-Null
$env:VICTORY_RECORD_DIR = $dir

$log   = Join-Path $dir 'victory.log'
$memo  = Join-Path $dir 'memoria.csv'
$marks = Join-Path $dir 'jelolesek.csv'
$futas = Join-Path $dir 'futas.txt'
$stop  = Join-Path $dir '.stop'

$crashes = Join-Path $AgyState 'data\7952987A\crashes.log'
$crashLen = if (Test-Path -LiteralPath $crashes) { (Get-Item -LiteralPath $crashes).Length } else { 0 }

$helpers = @()
$memoScript   = Join-Path $PSScriptRoot 'memoria-mintavevo.ps1'
$jeloloScript = Join-Path $PSScriptRoot 'jelolo.ps1'
$kepsorScript = Join-Path $PSScriptRoot 'kepsor.ps1'

if (Test-Path -LiteralPath $memoScript) {
    $helpers += Start-Process powershell.exe -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'RemoteSigned', '-File', $memoScript, '-Out', $memo, '-StopFile', $stop) -WindowStyle Minimized -PassThru
}
if (Test-Path -LiteralPath $jeloloScript) {
    $helpers += Start-Process powershell.exe -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'RemoteSigned', '-File', $jeloloScript, '-Out', $marks, '-StopFile', $stop) -WindowStyle Normal -PassThru
}
if ($Kepsor -and (Test-Path -LiteralPath $kepsorScript)) {
    $kepsorDir = Join-Path $dir 'kepsor'
    $helpers += Start-Process powershell.exe -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'RemoteSigned', '-File', $kepsorScript, '-Out', $kepsorDir, '-Seconds', '3600', '-Fps', '3', '-Quality', '75', '-NoMarker', '-StopFile', $stop) -WindowStyle Minimized -PassThru
}

$started = Get-Date
$startedUtc = [DateTime]::UtcNow
Write-Host ("Inditas: {0}" -f $dir) -ForegroundColor Cyan
Write-Host ("Profil : Nev={0}, TexMax={1}, Sharp={2}, MaxFps={3}, Port1={4}, Kepsor={5}" -f $safeNev, $TexMax, $Sharp, $MaxFps, $Port1, ([bool]$Kepsor))

$rc = 1
Push-Location $AgyTree
try {
    $cmdLine = "`"$AgyExe`" run `"$TitleExe`" --execute --console series-s > `"$log`" 2>&1"
    cmd.exe /c $cmdLine
    $rc = $LASTEXITCODE
} finally {
    Pop-Location
    New-Item -ItemType File -Path $stop -Force | Out-Null
    Start-Sleep -Milliseconds 700
    foreach ($h in $helpers) {
        if ($h -and -not $h.HasExited) {
            try { $h.WaitForExit(3000) | Out-Null } catch {}
            if (-not $h.HasExited) {
                try { Stop-Process -Id $h.Id -Force -ErrorAction SilentlyContinue } catch {}
            }
        }
    }
    Remove-Item -LiteralPath $stop -Force -ErrorAction SilentlyContinue
}

$ended = Get-Date
$endedUtc = [DateTime]::UtcNow
$durationMin = [math]::Round(($ended - $started).TotalMinutes, 2)

# crashes.log delta mentese ha novekedett
if (Test-Path -LiteralPath $crashes) {
    $crashInfo = Get-Item -LiteralPath $crashes
    if ($crashInfo.LastWriteTime -ge $started -and $crashInfo.Length -gt $crashLen) {
        $fs = [System.IO.File]::OpenRead($crashes)
        try {
            $fs.Seek($crashLen, [System.IO.SeekOrigin]::Begin) | Out-Null
            $buf = New-Object byte[] ($crashInfo.Length - $crashLen)
            $read = $fs.Read($buf, 0, $buf.Length)
            if ($read -gt 0) {
                $outCrash = Join-Path $dir 'crashes.log'
                [System.IO.File]::WriteAllBytes($outCrash, $buf[0..($read - 1)])
            }
        } finally {
            $fs.Dispose()
        }
    }
}

$summaryLines = @(
    "Profil        : $safeNev",
    "Inditas helyi : $($started.ToString('yyyy-MM-dd HH:mm:ss'))",
    "Inditas UTC   : $($startedUtc.ToString('yyyy-MM-ddTHH:mm:ssZ'))",
    "Vege helyi    : $($ended.ToString('yyyy-MM-dd HH:mm:ss'))",
    "Vege UTC      : $($endedUtc.ToString('yyyy-MM-ddTHH:mm:ssZ'))",
    "Idotartam     : $durationMin perc",
    "Exit kod      : $rc",
    "Branch        : $gitBranch",
    "Git HEAD      : $gitHead",
    "Exe           : $AgyExe",
    "Exe SHA-256   : $exeHash",
    "State mappa   : $AgyState",
    "Opciok        : TexMax=$TexMax, Sharp=$Sharp, MaxFps=$MaxFps, Port1=$Port1, Kepsor=$([bool]$Kepsor)",
    "Pre-flight RAM: $availMb MB szabad RAM, $commitFreeGb GB szabad commit",
    "VICTORY env   : $victoryEnvSummary"
)
$summaryLines | Set-Content -LiteralPath $futas -Encoding UTF8

Write-Host ("Befejezve (exit={0}, {1} perc). Naplo: {2}" -f $rc, $durationMin, $dir) -ForegroundColor Green
exit $rc
