param(
    [int]$Jobs = 4,
    [switch]$CpuOnly
)

$ErrorActionPreference = 'Stop'

$profil = Join-Path $PSScriptRoot 'agy-dxr-profil.ps1'
if (-not (Test-Path -LiteralPath $profil)) {
    Write-Error "Nem talalhato a profil: $profil"
    exit 1
}
. $profil -Console 'series-x' -DxrOpt '1' -Build 'release'

if (-not (Test-Path -LiteralPath $AgyExe)) {
    Write-Error "Nem talalhato a victory.exe: $AgyExe"
    exit 1
}
if (-not (Test-Path -LiteralPath $GameDir)) {
    Write-Error "Nem talalhato a jatek konyvtara: $GameDir"
    exit 1
}

$runningVictory = Get-Process -Name 'victory' -ErrorAction SilentlyContinue
if ($runningVictory -and -not $CpuOnly) {
    Write-Host 'FIGYELEM: Egy victory.exe folyamat jelenleg is fut! GPU PSO bemelegites nem futtathato kozben.' -ForegroundColor Yellow
    Write-Host 'Hasznald a -CpuOnly kapcsolot a csak-CPU shader-cache bemelegiteshez, vagy vard meg a futo teszt veget.' -ForegroundColor Yellow
    exit 2
}

Write-Host '=== AGY-DXR-Fast Shader Eloforditas ===' -ForegroundColor Cyan
Write-Host ("Exe   : {0}" -f $AgyExe)
Write-Host ("State : {0}" -f $AgyState)
Write-Host ("Jatek : {0}" -f $GameDir)
Write-Host ("Jobs  : {0} (CpuOnly={1})" -f $Jobs, ([bool]$CpuOnly))

$totalSw = [System.Diagnostics.Stopwatch]::StartNew()
Push-Location $AgyTree
try {
    Write-Host '[1/2] DXBC/RDNA -> DXIL shaderek forditasa (shaders)...' -ForegroundColor Yellow
    & $AgyExe shaders --jobs $Jobs $GameDir
    if ($LASTEXITCODE -ne 0) {
        Write-Error ("shaders parancs sikertelen, exit={0}" -f $LASTEXITCODE)
        exit $LASTEXITCODE
    }

    if (-not $CpuOnly) {
        $knownBin = Join-Path $AgyState 'cache\pipelines\known-pipelines.bin'
        if (Test-Path -LiteralPath $knownBin) {
            Write-Host '[2/2] Hasznalt pipeline-ok GPU bemelegitese (warm --used)...' -ForegroundColor Yellow
            & $AgyExe warm --used --jobs $Jobs
            if ($LASTEXITCODE -ne 0) {
                Write-Error ("warm --used sikertelen, exit={0}" -f $LASTEXITCODE)
                exit $LASTEXITCODE
            }
        } else {
            Write-Host '[2/2] warm --used kihagyva (meg nincs known-pipelines.bin — elso jatekinditas utan lesz).' -ForegroundColor DarkGray
        }
    } else {
        Write-Host '[2/2] GPU warm --used kihagyva (-CpuOnly).' -ForegroundColor DarkGray
    }
} finally {
    Pop-Location
}
$totalSw.Stop()

$shaderDir = Join-Path $AgyState 'cache\shaders'
$shaderFiles = if (Test-Path -LiteralPath $shaderDir) { @(Get-ChildItem -LiteralPath $shaderDir -File -Recurse -ErrorAction SilentlyContinue).Count } else { 0 }
Write-Host ("Kesz ({0:N1} mp). Shader cache fajlok: {1} db ({2})" -f $totalSw.Elapsed.TotalSeconds, $shaderFiles, $shaderDir) -ForegroundColor Green
