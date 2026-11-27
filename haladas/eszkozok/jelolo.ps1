# Jelölőgomb a méréshez (Claude, 2026-11-26).
# Az F8 billentyű minden lenyomására egy sort ír a megadott CSV-be (UTC és helyi idő, sorszám),
# és lejátssza a Windows figyelmeztető hangját. A billentyű a játék ablakában is működik,
# nem kell hozzá ablakot váltani. A játék csak a kontrollert figyeli, az F8-at nem.
# Leáll, ha megjelenik a stop-fájl, vagy legkésőbb MaxSeconds után.
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Out,
    [Parameter(Mandatory = $true)][string]$StopFile,
    [int]$MaxSeconds = 3600
)
$ErrorActionPreference = 'Stop'
Add-Type -TypeDefinition @'
using System;
using System.IO;
using System.Runtime.InteropServices;
using System.Threading;
public static class KlbfJelolo {
    [DllImport("user32.dll", SetLastError = true)] static extern bool RegisterHotKey(IntPtr hWnd, int id, uint mods, uint vk);
    [DllImport("user32.dll")] static extern bool UnregisterHotKey(IntPtr hWnd, int id);
    [DllImport("user32.dll")] static extern bool PeekMessage(out MSG msg, IntPtr hWnd, uint min, uint max, uint remove);
    [StructLayout(LayoutKind.Sequential)]
    public struct MSG { public IntPtr hwnd; public uint message; public UIntPtr wParam; public IntPtr lParam; public uint time; public int x; public int y; }
    const uint MOD_NOREPEAT = 0x4000, VK_F8 = 0x77, WM_HOTKEY = 0x0312;
    public static int Run(string outFile, string stopFile, int maxSeconds) {
        if (!RegisterHotKey(IntPtr.Zero, 1, MOD_NOREPEAT, VK_F8)) return Marshal.GetLastWin32Error();
        try {
            File.WriteAllText(outFile, "utc,local,n\r\n");
            int n = 0;
            DateTime until = DateTime.UtcNow.AddSeconds(maxSeconds);
            while (!File.Exists(stopFile) && DateTime.UtcNow < until) {
                MSG m;
                while (PeekMessage(out m, IntPtr.Zero, 0, 0, 1)) {
                    if (m.message == WM_HOTKEY) {
                        n++;
                        DateTime now = DateTime.Now;
                        File.AppendAllText(outFile, now.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ") + "," + now.ToString("HH:mm:ss") + "," + n + "\r\n");
                        System.Media.SystemSounds.Exclamation.Play();
                    }
                }
                Thread.Sleep(30);
            }
            return 0;
        } finally {
            UnregisterHotKey(IntPtr.Zero, 1);
        }
    }
}
'@
$rc = [KlbfJelolo]::Run($Out, $StopFile, $MaxSeconds)
if ($rc -ne 0) { Set-Content -LiteralPath $Out -Value "Az F8 nem foglalható le (Windows-hibakód $rc)." -Encoding UTF8 }
exit $rc
