param(
    [int]$Jobs = 6,
    [switch]$Verify
)

$ErrorActionPreference = 'Stop'

$profil = Join-Path $PSScriptRoot 'agy-v2-profil.ps1'
if (-not (Test-Path -LiteralPath $profil)) {
    Write-Error "Nem talalhato a profil: $profil"
    exit 1
}
. $profil -Port1 'be'

if (-not (Test-Path -LiteralPath $AgyExe)) {
    Write-Error "Nem talalhato a victory.exe: $AgyExe"
    exit 1
}
if (-not (Test-Path -LiteralPath $GameDir)) {
    Write-Error "Nem talalhato a jatek konyvtara: $GameDir"
    exit 1
}
if (Get-Process -Name 'victory' -ErrorAction SilentlyContinue) {
    Write-Error 'A victory.exe mar fut! Allitsd le eloforditas elott.'
    exit 1
}

Write-Host '=== AGY-9070-v2 Eloforditas ===' -ForegroundColor Cyan
Write-Host ("Exe   : {0}" -f $AgyExe)
Write-Host ("State : {0}" -f $AgyState)
Write-Host ("Jatek : {0}" -f $GameDir)
Write-Host ("Jobs  : {0}" -f $Jobs)

$totalSw = [System.Diagnostics.Stopwatch]::StartNew()
$stage1Sec = 0.0
$stage2Sec = 0.0
$stage3Sec = 0.0

Push-Location $AgyTree
try {
    # 1. szakasz: DXBC -> VSH2 shaderek
    Write-Host ''
    Write-Host '[1/3] Shaderek forditasa (shaders)...' -ForegroundColor Yellow
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $shaderArgs = @('shaders', '--jobs', "$Jobs")
    if ($Verify) { $shaderArgs += '--verify' }
    $shaderArgs += $GameDir
    & $AgyExe @shaderArgs
    $rc1 = $LASTEXITCODE
    $sw.Stop()
    $stage1Sec = [math]::Round($sw.Elapsed.TotalSeconds, 2)
    if ($rc1 -ne 0) {
        Write-Error ("1. szakasz (shaders) sikertelen, exit={0}" -f $rc1)
        exit $rc1
    }
    Write-Host ("1. szakasz kesz: {0} mp" -f $stage1Sec) -ForegroundColor Green

    # 2. szakasz: Compute PSO eloforditas
    Write-Host ''
    Write-Host '[2/3] Compute pipeline-ok eloforditasa (translate --pipelines --only-compute)...' -ForegroundColor Yellow
    $sw.Restart()
    & $AgyExe translate --pipelines --only-compute --jobs $Jobs $GameDir
    $rc2 = $LASTEXITCODE
    $sw.Stop()
    $stage2Sec = [math]::Round($sw.Elapsed.TotalSeconds, 2)
    if ($rc2 -ne 0) {
        Write-Error ("2. szakasz (translate --pipelines --only-compute) sikertelen, exit={0}" -f $rc2)
        exit $rc2
    }
    Write-Host ("2. szakasz kesz: {0} mp" -f $stage2Sec) -ForegroundColor Green

    # 3. szakasz: Hasznalt pipeline-ok bemelegitese (ha mar van known-pipelines.bin)
    $knownBin = Join-Path $AgyState 'cache\pipelines\known-pipelines.bin'
    Write-Host ''
    if (Test-Path -LiteralPath $knownBin) {
        Write-Host '[3/3] Hasznalt pipeline-ok bemelegitese (warm --used)...' -ForegroundColor Yellow
        $sw.Restart()
        & $AgyExe warm --used --jobs $Jobs
        $rc3 = $LASTEXITCODE
        $sw.Stop()
        $stage3Sec = [math]::Round($sw.Elapsed.TotalSeconds, 2)
        if ($rc3 -ne 0) {
            Write-Error ("3. szakasz (warm --used) sikertelen, exit={0}" -f $rc3)
            exit $rc3
        }
        Write-Host ("3. szakasz kesz: {0} mp" -f $stage3Sec) -ForegroundColor Green
    } else {
        Write-Host '[3/3] warm --used kihagyva (meg nincs known-pipelines.bin — elso jatekinditas utan lesz).' -ForegroundColor DarkGray
    }
} finally {
    Pop-Location
}

$totalSw.Stop()
$totalSec = [math]::Round($totalSw.Elapsed.TotalSeconds, 2)

# Cache statisztikak
$shaderDir = Join-Path $AgyState 'cache\shaders'
$shaderFiles = 0
if (Test-Path -LiteralPath $shaderDir) {
    $shaderFiles = @(Get-ChildItem -LiteralPath $shaderDir -File -ErrorAction SilentlyContinue).Count
}
$hostPipelines = Join-Path $AgyState 'cache\pipelines\host-pipelines.bin'
$hostMb = 0.0
if (Test-Path -LiteralPath $hostPipelines) {
    $hostMb = [math]::Round(((Get-Item -LiteralPath $hostPipelines).Length / 1MB), 2)
}
$warmBad = Join-Path $AgyState 'cache\pipelines\warm-bad.txt'
$warmBadLines = 0
if (Test-Path -LiteralPath $warmBad) {
    $warmBadLines = @(Get-Content -LiteralPath $warmBad -ErrorAction SilentlyContinue | Where-Object { $_.Trim() -ne '' }).Count
}

Write-Host ''
Write-Host '=== Osszegzes ===' -ForegroundColor Cyan
Write-Host ("1. szakasz (shaders)      : {0} mp" -f $stage1Sec)
Write-Host ("2. szakasz (compute PSO)  : {0} mp" -f $stage2Sec)
Write-Host ("3. szakasz (warm --used)  : {0} mp" -f $stage3Sec)
Write-Host ("Osszes ido                : {0} mp" -f $totalSec)
Write-Host ("Shader cache fajlok       : {0} db ({1})" -f $shaderFiles, $shaderDir)
Write-Host ("host-pipelines.bin        : {0} MB" -f $hostMb)
Write-Host ("warm-bad.txt sorok        : {0} db" -f $warmBadLines)
