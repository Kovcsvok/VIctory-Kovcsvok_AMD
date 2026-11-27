param(
    [Parameter(Mandatory)]
    [string]$RunDir,
    [double]$WarmupSeconds = 150.0
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $RunDir)) {
    Write-Error "Nem talalhato a futasi mappa: $RunDir"
    exit 1
}

$logPath = Join-Path $RunDir 'victory.log'
if (-not (Test-Path -LiteralPath $logPath)) {
    Write-Error "Nem talalhato a victory.log: $logPath"
    exit 1
}

$ansiRx  = [regex]'\x1b\[[0-9;]*m'
$tsRx    = [regex]'^(\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d(?:\.\d+)?)Z'
$fpsRx   = [regex]'([0-9.]+) fps,\s*([0-9.]+) ms/frame \(([^)]+)\)'
$memRx   = [regex]'memory summary: RAM private ([0-9.]+) MB, working set ([0-9.]+) MB; VRAM local ([0-9.]+)/([0-9.]+) MB, SHR ([0-9.]+)/([0-9.]+) MB'
$dxrRx   = [regex]'native DXR per frame: dyn_blas=([0-9.]+) refits=([0-9.]+) static_blas=([0-9.]+) upgraded_static=([0-9.]+) compacted=([0-9.]+) tlas=([0-9.]+)'
$gpuRx   = [regex]"the card's time by command \(timing run\): ([0-9.]+) ms a frame in ([0-9.]+) commands a frame, the longest ([0-9.]+) ms: (.+)$"

$winSamples = New-Object System.Collections.Generic.List[object]
$memSamples = New-Object System.Collections.Generic.List[object]
$dxrSamples = New-Object System.Collections.Generic.List[object]
$gpuShaders = @{}

$firstTs = $null
$lastTs  = $null

$reader = [System.IO.StreamReader]::new($logPath, [System.Text.Encoding]::UTF8)
try {
    while ($null -ne ($raw = $reader.ReadLine())) {
        $line = $ansiRx.Replace($raw, '')
        $mTs = $tsRx.Match($line)
        if (-not $mTs.Success) { continue }
        $t = [DateTime]::Parse($mTs.Groups[1].Value, [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::AssumeUniversal).ToUniversalTime()
        if ($null -eq $firstTs) { $firstTs = $t }
        $lastTs = $t
        $relSec = ($t - $firstTs).TotalSeconds

        $mFps = $fpsRx.Match($line)
        if ($mFps.Success) {
            $winSamples.Add([pscustomobject]@{
                Time   = $t
                RelSec = $relSec
                Fps    = [double]$mFps.Groups[1].Value
                Ms     = [double]$mFps.Groups[2].Value
            })
            continue
        }

        $mMem = $memRx.Match($line)
        if ($mMem.Success) {
            $memSamples.Add([pscustomobject]@{
                RelSec    = $relSec
                PrivateMb = [double]$mMem.Groups[1].Value
                WsMb      = [double]$mMem.Groups[2].Value
                VramMb    = [double]$mMem.Groups[3].Value
                BudgetMb  = [double]$mMem.Groups[4].Value
                ShrMb     = [double]$mMem.Groups[5].Value
            })
            continue
        }

        $mDxr = $dxrRx.Match($line)
        if ($mDxr.Success) {
            $dxrSamples.Add([pscustomobject]@{
                RelSec     = $relSec
                DynBlas    = [double]$mDxr.Groups[1].Value
                Refits     = [double]$mDxr.Groups[2].Value
                StaticBlas = [double]$mDxr.Groups[3].Value
                Tlas       = [double]$mDxr.Groups[6].Value
            })
            continue
        }

        $mGpu = $gpuRx.Match($line)
        if ($mGpu.Success) {
            $key = $mGpu.Groups[4].Value.Trim()
            if (-not $gpuShaders.ContainsKey($key)) {
                $gpuShaders[$key] = New-Object System.Collections.Generic.List[double]
            }
            $gpuShaders[$key].Add([double]$mGpu.Groups[1].Value)
        }
    }
} finally {
    $reader.Dispose()
}

$totalSec = if ($firstTs -and $lastTs) { ($lastTs - $firstTs).TotalSeconds } else { 0.0 }
$effectiveWarmup = if ($totalSec -gt ($WarmupSeconds + 15.0)) { $WarmupSeconds } else { 0.0 }

$steadyWins = @($winSamples | Where-Object { $_.RelSec -ge $effectiveWarmup })
if ($steadyWins.Count -eq 0) { $steadyWins = @($winSamples) }

$avgFps = 0.0
$avgMs  = 0.0
$p95Ms  = 0.0
$over100Pct = 0.0
$estFrames = 0.0
$elapsedSteady = 0.0

if ($steadyWins.Count -gt 0) {
    $sortedMs = @($steadyWins | ForEach-Object { $_.Ms } | Sort-Object)
    $p95Idx = [math]::Min($sortedMs.Count - 1, [int][math]::Floor(0.95 * $sortedMs.Count))
    $p95Ms = $sortedMs[$p95Idx]
    $over100Count = @($steadyWins | Where-Object { $_.Ms -gt 100.0 }).Count
    $over100Pct = 100.0 * $over100Count / $steadyWins.Count

    if ($steadyWins.Count -ge 2) {
        for ($i = 1; $i -lt $steadyWins.Count; $i++) {
            $dt = ($steadyWins[$i].Time - $steadyWins[$i - 1].Time).TotalSeconds
            if ($dt -gt 0 -and $dt -lt 30.0) {
                $elapsedSteady += $dt
                $estFrames += $steadyWins[$i].Fps * $dt
            }
        }
    }
    if ($elapsedSteady -gt 0) {
        $avgFps = $estFrames / $elapsedSteady
        $avgMs  = 1000.0 / [math]::Max($avgFps, 0.001)
    } else {
        $avgFps = ($steadyWins | Measure-Object -Property Fps -Average).Average
        $avgMs  = ($steadyWins | Measure-Object -Property Ms -Average).Average
    }
}

$peakWsGiB  = if ($memSamples.Count -gt 0) { (($memSamples | Measure-Object -Property WsMb -Maximum).Maximum) / 1024.0 } else { 0.0 }
$peakPrvGiB = if ($memSamples.Count -gt 0) { (($memSamples | Measure-Object -Property PrivateMb -Maximum).Maximum) / 1024.0 } else { 0.0 }
$peakVramGiB = if ($memSamples.Count -gt 0) { (($memSamples | Measure-Object -Property VramMb -Maximum).Maximum) / 1024.0 } else { 0.0 }
$peakShrGiB  = if ($memSamples.Count -gt 0) { (($memSamples | Measure-Object -Property ShrMb -Maximum).Maximum) / 1024.0 } else { 0.0 }

$avgDynBlas = if ($dxrSamples.Count -gt 0) { ($dxrSamples | Measure-Object -Property DynBlas -Average).Average } else { 0.0 }
$avgRefits  = if ($dxrSamples.Count -gt 0) { ($dxrSamples | Measure-Object -Property Refits -Average).Average } else { 0.0 }
$avgTlas    = if ($dxrSamples.Count -gt 0) { ($dxrSamples | Measure-Object -Property Tlas -Average).Average } else { 0.0 }

$outLines = New-Object System.Collections.Generic.List[string]
$outLines.Add("# AGY-DXR-Fast Futasi Osszegzes")
$outLines.Add("")
$outLines.Add("- **Mappa**: ``$RunDir``")
$outLines.Add(("- **Teljes naplozott ido**: {0:N1} s (bemelegitesi levagas: {1:N0} s)" -f $totalSec, $effectiveWarmup))
$outLines.Add(("- **Renderelt FPS (atl. / ablakokbol)**: **{0:N2} FPS** ({1:N1} ms/frame)" -f $avgFps, $avgMs))
$outLines.Add(("- **p95 ablak-kepkockaido**: **{0:N1} ms**" -f $p95Ms))
$outLines.Add(("- **>100 ms ablakok aranya**: **{0:N1}%**" -f $over100Pct))
$outLines.Add(("- **Csucs RAM (Working Set / Private)**: **{0:N2} GiB** / {1:N2} GiB" -f $peakWsGiB, $peakPrvGiB))
$outLines.Add(("- **Csucs VRAM (Local / Shared)**: **{0:N2} GiB** / {1:N2} GiB" -f $peakVramGiB, $peakShrGiB))
if ($dxrSamples.Count -gt 0) {
    $outLines.Add(("- **Nativ DXR / kepkocka**: dyn_blas={0:N1}, refits={1:N1}, tlas={2:N1}" -f $avgDynBlas, $avgRefits, $avgTlas))
}

$targetHashes = @('caf96a3229145fa6', '3592426e3e9142d8', '36f04a4ed0ad1d9b', 'f607780aa8e502d0')
if ($gpuShaders.Count -gt 0) {
    $outLines.Add("")
    $outLines.Add("## GPU Idozites (VICTORY_GPU_TIMING=1)")
    $outLines.Add("")
    $outLines.Add("| Parancs / Shader | Atlag ms/frame | Mintak |")
    $outLines.Add("|---|---:|---:|")

    $ranked = $gpuShaders.GetEnumerator() | ForEach-Object {
        $avg = ($_.Value | Measure-Object -Average).Average
        [pscustomobject]@{ Key = $_.Key; AvgMs = $avg; Count = $_.Value.Count }
    } | Sort-Object -Property AvgMs -Descending

    foreach ($r in ($ranked | Select-Object -First 20)) {
        $outLines.Add(("| ``{0}`` | {1:N2} | {2} |" -f $r.Key, $r.AvgMs, $r.Count))
    }

    $outLines.Add("")
    $outLines.Add("### Kiemelt RT shaderek es BLAS")
    foreach ($h in $targetHashes) {
        $hits = @($ranked | Where-Object { $_.Key -match $h })
        if ($hits.Count -gt 0) {
            $sum = ($hits | Measure-Object -Property AvgMs -Sum).Sum
            $outLines.Add(("- ``{0}``: **{1:N2} ms/frame**" -f $h, $sum))
        }
    }
    $blasHits = @($ranked | Where-Object { $_.Key -match 'blas|raytracing|tlas|refit' })
    if ($blasHits.Count -gt 0) {
        $blasSum = ($blasHits | Measure-Object -Property AvgMs -Sum).Sum
        $outLines.Add(("- **BLAS / TLAS parancsok osszesen**: **{0:N2} ms/frame**" -f $blasSum))
    }
}

$summaryPath = Join-Path $RunDir 'osszegzes.md'
$outLines | Set-Content -LiteralPath $summaryPath -Encoding UTF8

Write-Host ""
Write-Host "=== AGY-DXR Elemzes ($RunDir) ===" -ForegroundColor Cyan
$outLines | ForEach-Object { Write-Host $_ }
