param(
    [string]$Nev = 'agy-dxr-sx-30fps',
    [ValidateSet('series-x', 'series-s')]
    [string]$Console = 'series-x',
    [ValidateSet('0', '1')]
    [string]$DxrOpt = '1',
    [switch]$UnlockFps,
    [switch]$GpuTiming,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

$profil = Join-Path $PSScriptRoot 'agy-dxr-profil.ps1'
if (-not (Test-Path -LiteralPath $profil)) {
    Write-Error "Nem talalhato a profil: $profil"
    exit 1
}

$buildMode = if ($GpuTiming) { 'diag' } else { 'release' }
. $profil -Console $Console -DxrOpt $DxrOpt -UnlockFps:$UnlockFps -GpuTiming:$GpuTiming -Build $buildMode

if (-not (Test-Path -LiteralPath $AgyExe)) {
    Write-Error "Nem talalhato a victory.exe: $AgyExe"
    exit 1
}
if (-not (Test-Path -LiteralPath $TitleExe)) {
    Write-Error "Nem talalhato a jatek exe: $TitleExe"
    exit 1
}
if (-not $DryRun -and (Get-Process -Name 'victory' -ErrorAction SilentlyContinue)) {
    Write-Error 'A victory.exe mar fut! Zard be elotte.'
    exit 1
}

$safeNev = ($Nev -replace '[^a-zA-Z0-9_-]', '-').Trim('-')
if ([string]::IsNullOrWhiteSpace($safeNev)) { $safeNev = 'agy-dxr' }
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
    Write-Host '=== AGY-DXR DRY RUN ===' -ForegroundColor Cyan
    Write-Host ("Mappa      : {0}" -f $dir)
    Write-Host ("Exe        : {0}" -f $AgyExe)
    Write-Host ("Console    : {0}" -f $Console)
    Write-Host ("DXR_OPT    : {0}" -f $DxrOpt)
    Write-Host ("UnlockFps  : {0}" -f ([bool]$UnlockFps))
    Write-Host ("GpuTiming  : {0}" -f ([bool]$GpuTiming))
    Write-Host ("SHA-256    : {0}" -f $exeHash)
    Write-Host ("VICTORY_*  : {0}" -f $victoryEnvSummary)
    exit 0
}

New-Item -ItemType Directory -Path $dir -Force | Out-Null
$log   = Join-Path $dir 'victory.log'
$memo  = Join-Path $dir 'memoria.csv'
$futas = Join-Path $dir 'futas.txt'
$stop  = Join-Path $dir '.stop'

$helpers = @()
$memoScript = Join-Path $PSScriptRoot 'memoria-mintavevo.ps1'
if (Test-Path -LiteralPath $memoScript) {
    $helpers += Start-Process powershell.exe -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'RemoteSigned', '-File', $memoScript, '-Out', $memo, '-StopFile', $stop) -WindowStyle Minimized -PassThru
}

$started = Get-Date
$startedUtc = [DateTime]::UtcNow
Write-Host ("Inditas: {0}" -f $dir) -ForegroundColor Cyan
Write-Host ("Profil : Nev={0}, Console={1}, DxrOpt={2}, UnlockFps={3}, GpuTiming={4}" -f $safeNev, $Console, $DxrOpt, ([bool]$UnlockFps), ([bool]$GpuTiming))

$rc = 1
Push-Location $AgyTree
try {
    $cmdLine = "`"$AgyExe`" run `"$TitleExe`" --execute --console $Console > `"$log`" 2>&1"
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

$summaryLines = @(
    "Profil        : $safeNev",
    "Inditas helyi : $($started.ToString('yyyy-MM-dd HH:mm:ss'))",
    "Inditas UTC   : $($startedUtc.ToString('yyyy-MM-ddTHH:mm:ssZ'))",
    "Vege helyi    : $($ended.ToString('yyyy-MM-dd HH:mm:ss'))",
    "Vege UTC      : $($endedUtc.ToString('yyyy-MM-ddTHH:mm:ssZ'))",
    "Idotartam     : $durationMin perc",
    "Exit kod      : $rc",
    "Console       : $Console",
    "Branch        : $gitBranch",
    "Git HEAD      : $gitHead",
    "Exe           : $AgyExe",
    "Exe SHA-256   : $exeHash",
    "State mappa   : $AgyState",
    "Opciok        : DxrOpt=$DxrOpt, UnlockFps=$([bool]$UnlockFps), GpuTiming=$([bool]$GpuTiming)",
    "VICTORY env   : $victoryEnvSummary"
)
$summaryLines | Set-Content -LiteralPath $futas -Encoding UTF8

$elemzes = Join-Path $PSScriptRoot 'elemzes-agy-dxr.ps1'
if ((Test-Path -LiteralPath $elemzes) -and (Test-Path -LiteralPath $log)) {
    & powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File $elemzes -RunDir $dir
}

Write-Host ("Befejezve (exit={0}, {1} perc). Naplo: {2}" -f $rc, $durationMin, $dir) -ForegroundColor Green
exit $rc
