# Memória-mintavevő a KLBF-méréshez (Claude, 2026-11-26).
# Másodpercenként egy CSV-sor: Windows-commit, szabad RAM, lapozófájl, lapbeolvasás,
# a victory.exe privát és munkakészlet-mérete, a victory.exe és az egész GPU dedikált és
# megosztott memóriája. A tools\memwatch.ps1 nvidia-smi-t hív, ezért Radeonon ezt használjuk.
# A WMI-osztályok nevei nem lokalizáltak, ezért magyar Windowson is működnek.
param(
    [Parameter(Mandatory = $true)][string]$Out,
    [string]$StopFile = '',
    [int]$IntervalMs = 1000,
    [int]$WaitStartS = 900
)
$ErrorActionPreference = 'Continue'
$inv = [Globalization.CultureInfo]::InvariantCulture
'utc,local,commit_used_gb,commit_limit_gb,commit_free_gb,avail_ram_gb,pagefile_used_gb,pages_input_per_s,victory_pid,victory_private_gb,victory_ws_gb,victory_gpu_dedicated_gb,victory_gpu_shared_gb,adapter_dedicated_gb,adapter_shared_gb,sample_ms' |
    Set-Content -LiteralPath $Out -Encoding ASCII
$deadline = (Get-Date).AddSeconds($WaitStartS)
$seen = $false
$goneAt = $null
while ($true) {
    if ($StopFile -and (Test-Path -LiteralPath $StopFile)) { break }
    $sw = [Diagnostics.Stopwatch]::StartNew()
    $now = Get-Date
    $p = Get-Process victory -ErrorAction SilentlyContinue | Sort-Object WorkingSet64 -Descending | Select-Object -First 1
    if ($p) {
        $seen = $true
        $goneAt = $null
    } elseif ($seen) {
        if (-not $goneAt) { $goneAt = $now }
        if (($now - $goneAt).TotalSeconds -gt 5) { break }
    } elseif ($now -gt $deadline) {
        break
    }
    try {
        $m  = Get-CimInstance Win32_PerfFormattedData_PerfOS_Memory
        $pf = (Get-CimInstance Win32_PageFileUsage | Measure-Object CurrentUsage -Sum).Sum / 1024
        $ad = Get-CimInstance Win32_PerfFormattedData_GPUPerformanceCounters_GPUAdapterMemory |
              Sort-Object TotalCommitted -Descending | Select-Object -First 1
        $vid = ''; $vpriv = ''; $vws = ''; $gd = ''; $gs = ''
        if ($p) {
            $vid = $p.Id
            $vpriv = [string]::Format($inv, '{0:F3}', $p.PrivateMemorySize64 / 1GB)
            $vws = [string]::Format($inv, '{0:F3}', $p.WorkingSet64 / 1GB)
            $g = @(Get-CimInstance Win32_PerfFormattedData_GPUPerformanceCounters_GPUProcessMemory -Filter "Name LIKE 'pid_$($p.Id)_%'")
            if ($g.Count -gt 0) {
                $gd = [string]::Format($inv, '{0:F3}', ($g | Measure-Object DedicatedUsage -Sum).Sum / 1GB)
                $gs = [string]::Format($inv, '{0:F3}', ($g | Measure-Object SharedUsage -Sum).Sum / 1GB)
            }
        }
        $line = [string]::Format($inv, '{0},{1},{2:F3},{3:F3},{4:F3},{5:F3},{6:F3},{7},{8},{9},{10},{11},{12},{13:F3},{14:F3},{15}',
            $now.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.fffZ'), $now.ToString('HH:mm:ss'),
            $m.CommittedBytes / 1GB, $m.CommitLimit / 1GB, ($m.CommitLimit - $m.CommittedBytes) / 1GB,
            $m.AvailableMBytes / 1024, $pf, $m.PagesInputPersec,
            $vid, $vpriv, $vws, $gd, $gs, $ad.DedicatedUsage / 1GB, $ad.SharedUsage / 1GB, $sw.ElapsedMilliseconds)
        Add-Content -LiteralPath $Out -Value $line -Encoding ASCII
    } catch {
        Add-Content -LiteralPath $Out -Value ("# hiba: " + $_.Exception.Message) -Encoding ASCII
    }
    $left = $IntervalMs - [int]$sw.ElapsedMilliseconds
    if ($left -gt 0) { Start-Sleep -Milliseconds $left }
}
