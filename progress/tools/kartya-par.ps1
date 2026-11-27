# Felügyelet nélküli páros mérés egy induláskor rögzített beállításra (élő A/B nem lehet):
# A = a csomag alapja, B = VICTORY_CARD_BUFFERS_MIN_MB=<MinMb> (a kártyán tartott másolatok már
# <MinMb> MiB-tól, nem 4 MiB-tól). ABBA sorrend (-Parok 2), hogy a gép melegedése és a mentés
# eltérése kiessen. Minden menet a meres-csomag.ps1-gyel, a mentés magától töltve, <Perc> perc után
# bezárva. A végén futas-osszevetes.py: futásonként és rajzolásszám szerint párosítva.
# Claude-40, 2026-11-28. A gépet a menetek alatt ne használd (kb. Parok x 2 x (Perc + 1) perc).
#   -Parok   hány A-B pár (1: AB, 2: ABBA, 3: ABBAAB)
#   -Perc    egy menet hossza percben
#   -MinMb   a B menetek VICTORY_CARD_BUFFERS_MIN_MB értéke
#   -Probe   csak kiírja, mit futtatna, a játékot nem indítja
param(
    [ValidateRange(1, 4)][int]$Parok = 2,
    [ValidateRange(4, 30)][int]$Perc = 12,
    [ValidateRange(1, 64)][int]$MinMb = 1,
    [switch]$Probe
)
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$meresek = Split-Path -Parent $here
$csomag = Join-Path $here 'meres-csomag.ps1'
$elemzo = Join-Path $here 'futas-osszevetes.py'
$sorrend = @('A', 'B', 'B', 'A', 'A', 'B', 'B', 'A')[0..(2 * $Parok - 1)]
$volt = $env:VICTORY_CARD_BUFFERS_MIN_MB
$futasok = @()
$jel = Get-Date -Format 'HHmm'
try {
    for ($i = 0; $i -lt $sorrend.Count; $i++) {
        $l = $sorrend[$i]
        $nev = "kartya$MinMb-$jel-$($i + 1)$l"
        if ($l -eq 'B') { $env:VICTORY_CARD_BUFFERS_MIN_MB = "$MinMb" }
        else { Remove-Item Env:VICTORY_CARD_BUFFERS_MIN_MB -ErrorAction SilentlyContinue }
        Write-Host ("[{0}/{1}] {2}: {3}" -f ($i + 1), $sorrend.Count, $nev, $(if ($l -eq 'B') { "VICTORY_CARD_BUFFERS_MIN_MB=$MinMb" } else { 'a csomag alapja' }))
        $args1 = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $csomag, '-Nev', $nev, '-TexMax', '512',
            '-LookMs', '250', '-AutoA', '25,100,5', '-Perc', "$Perc")
        if ($Probe) { Write-Host ('   powershell ' + ($args1 -join ' ')); continue }
        $kezd = Get-Date
        & powershell @args1
        $kod = $LASTEXITCODE
        $dir = Get-ChildItem -Path $meresek -Directory -Filter "*-$nev" | Sort-Object LastWriteTime | Select-Object -Last 1
        if (-not $dir -or $dir.CreationTime -lt $kezd.AddSeconds(-5)) { Write-Host "   nincs futásmappa (kilépési kód $($kod)): megállok"; break }
        Set-Content -Path (Join-Path $dir.FullName 'kartya-par.txt') -Encoding utf8 -Value @(
            "Pár-mérés: $l", "VICTORY_CARD_BUFFERS_MIN_MB=$(if ($l -eq 'B') { $MinMb } else { '(nincs, a csomag alapja: 4 MiB)' })",
            "Kilépési kód: $kod")
        $futasok += "$l=$($dir.FullName)"
        if ($kod -eq 2) { Write-Host "   a menet nem indult (kilépési kód 2): megállok"; break }
        Start-Sleep -Seconds 20
    }
} finally {
    if ($null -eq $volt) { Remove-Item Env:VICTORY_CARD_BUFFERS_MIN_MB -ErrorAction SilentlyContinue }
    else { $env:VICTORY_CARD_BUFFERS_MIN_MB = $volt }
}
if ($futasok.Count -ge 2) {
    $ki = Join-Path $meresek "kartya-par-$jel.txt"
    & python -I $elemzo @futasok | Tee-Object -FilePath $ki
    Write-Host "Összevetés: $ki"
}
