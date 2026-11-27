# Képsor-rögzítő a játék ablakáról (Claude, 2026-11-26): videó helyett JPEG-képek
# másodpercenként -Fps darabszámmal, -Seconds ideig, a victory.exe ablakának képtartalmáról
# (keret és címsor nélkül). Mellette fut az F8-jelölő (jelolo.ps1): a hibás pillanatoknál
# nyomott F8 időpontja a jelolesek.csv-be kerül, a képek neve a helyi idő ezredmásodpercre.
# -NoMarker: F8-jelölő nélkül (ha a mérőindító sajátja már fut); -StopFile: ennek megjelenésekor leáll.
param(
    [Parameter(Mandatory = $true)][string]$Out,
    [int]$Seconds = 240,
    [int]$Fps = 4,
    [int]$Quality = 80,
    [switch]$NoMarker,
    [string]$StopFile = ''
)
$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Force -Path $Out | Out-Null
Add-Type -AssemblyName System.Drawing
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class KepsorWin {
    [StructLayout(LayoutKind.Sequential)] public struct RECT { public int L, T, R, B; }
    [StructLayout(LayoutKind.Sequential)] public struct POINT { public int X, Y; }
    [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
    [DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr h, out RECT r);
    [DllImport("user32.dll")] public static extern bool ClientToScreen(IntPtr h, ref POINT p);
    [DllImport("user32.dll")] public static extern bool IsIconic(IntPtr h);
}
'@
[void][KepsorWin]::SetProcessDPIAware()
$stop = Join-Path $Out '.leallit'
$marker = if ($NoMarker) { $null } else {
    Start-Process -FilePath powershell.exe -WindowStyle Hidden -PassThru -ArgumentList @(
        '-NoProfile', '-ExecutionPolicy', 'RemoteSigned', '-File', "`"$PSScriptRoot\jelolo.ps1`"",
        '-Out', "`"$(Join-Path $Out 'jelolesek.csv')`"", '-StopFile', "`"$stop`"")
}
$codec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object MimeType -eq 'image/jpeg'
$params = New-Object System.Drawing.Imaging.EncoderParameters 1
$params.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter ([System.Drawing.Imaging.Encoder]::Quality, [long]$Quality)
$end = (Get-Date).AddSeconds($Seconds)
$step = [int](1000 / $Fps)
$n = 0; $missed = 0
while ((Get-Date) -lt $end) {
    if ($StopFile -and (Test-Path -LiteralPath $StopFile)) { break }
    $t0 = Get-Date
    $p = Get-Process victory -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1
    if (-not $p) { Start-Sleep -Milliseconds 500; $missed++; continue }
    $h = $p.MainWindowHandle
    if ([KepsorWin]::IsIconic($h)) { Start-Sleep -Milliseconds 500; continue }
    $r = New-Object KepsorWin+RECT; [void][KepsorWin]::GetClientRect($h, [ref]$r)
    $pt = New-Object KepsorWin+POINT; [void][KepsorWin]::ClientToScreen($h, [ref]$pt)
    $w = $r.R - $r.L; $hgt = $r.B - $r.T
    if ($w -gt 0 -and $hgt -gt 0) {
        $bmp = New-Object System.Drawing.Bitmap $w, $hgt
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        $g.CopyFromScreen($pt.X, $pt.Y, 0, 0, $bmp.Size)
        $bmp.Save((Join-Path $Out ("{0}.jpg" -f $t0.ToString('HHmmss-fff'))), $codec, $params)
        $g.Dispose(); $bmp.Dispose(); $n++
    }
    $left = $step - [int]((Get-Date) - $t0).TotalMilliseconds
    if ($left -gt 0) { Start-Sleep -Milliseconds $left }
}
if ($marker) {
    New-Item -ItemType File -Path $stop -Force | Out-Null
    if (-not $marker.WaitForExit(5000)) { Stop-Process -Id $marker.Id -Force -ErrorAction SilentlyContinue }
    Remove-Item -LiteralPath $stop -ErrorAction SilentlyContinue
}
"Kész: $n kép, $Out"
