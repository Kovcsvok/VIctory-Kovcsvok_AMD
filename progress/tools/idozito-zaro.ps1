# Felügyelet nélküli menethez (meres-csomag.ps1 -Perc): -Perc perc után bezárja a játék ablakát úgy, mint
# a felhasználó X gombja (WM_SYSCOMMAND SC_CLOSE), így a videó és a napló rendesen lezárul. Ha a játék
# addig magától kilép, vagy a stopfájl megjelenik, nem tesz semmit. (Claude, 2026-11-27, Claude-30)
param([int]$Perc = 10, [string]$StopFile = '')
$ErrorActionPreference = 'Stop'
Add-Type -Namespace W -Name U -MemberDefinition '[DllImport("user32.dll")] public static extern bool PostMessageW(IntPtr h, uint m, IntPtr w, IntPtr l);'
$deadline = (Get-Date).AddMinutes($Perc)
while ((Get-Date) -lt $deadline) {
    if ($StopFile -and (Test-Path -LiteralPath $StopFile)) { return }
    Start-Sleep -Seconds 2
}
$game = Get-Process -Name victory -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne [IntPtr]::Zero } | Select-Object -First 1
if (-not $game) { return }
[W.U]::PostMessageW($game.MainWindowHandle, 0x0112, [IntPtr]0xF060, [IntPtr]::Zero) | Out-Null
