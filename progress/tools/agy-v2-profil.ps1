param(
    [ValidateSet('be', 'ki')]
    [string]$Port1 = 'be'
)

# Clear every inherited VICTORY_* variable first so precompile and launch always match
Get-ChildItem -Path Env:VICTORY_* -ErrorAction SilentlyContinue | Remove-Item -ErrorAction SilentlyContinue

$AgyTree  = 'C:\Games\NOT_GTAVI\VIctory-dev\agy-9070-v2'
$AgyExe   = 'C:\Games\NOT_GTAVI\VIctory-dev\agy-9070-v2\target\diag\victory.exe'
$AgyState = 'C:\Games\NOT_GTAVI\VIctory-dev\state\agy-9070-v2'
$GameDir  = 'C:\Games\NOT_GTAVI\<JATEKMAPPA>'
$TitleExe = 'C:\Games\NOT_GTAVI\<JATEKMAPPA>\game_scarlett_master.exe'
$FfxDir   = 'C:\Games\NOT_GTAVI\VIctory-dev\FidelityFX-SDK\Kits\FidelityFX\signedbin'

$env:RUST_LOG = 'info'
$env:NO_COLOR = '1'
if (Test-Path -LiteralPath $FfxDir) {
    $env:VICTORY_FIDELITYFX_DIR = $FfxDir
}
$env:VICTORY_D3D12_DRED = 'light'

# Port switches (1, 2, 5, 6, 7) — Port 1 toggleable via -Port1 ki
$env:VICTORY_PORT_CONSTANTS   = $(if ($Port1 -eq 'ki') { '0' } else { '1' })
$env:VICTORY_PORT_DESCRIPTORS = '1'
$env:VICTORY_PORT_CBV         = '1'
$env:VICTORY_PORT_GUARD       = '1'
$env:VICTORY_PORT_JOURNAL     = '1'

# Visuals, sync, and RT correctness
$env:VICTORY_SLOT_COUNTS      = '1'
$env:VICTORY_TWIN_MOVE        = '1'
$env:VICTORY_TWIN_EXACT       = '0'
$env:VICTORY_PORT_CBV_WRITTEN = '2'
$env:VICTORY_CARD_STEPS       = '2'
$env:VICTORY_CARD_STEPS_LEARN = '0'
$env:VICTORY_LATE_WAIT        = '2'
$env:VICTORY_BVH_NO_HIT       = '1'

# Copy / indirect / presentation (keep AMD default VICTORY_RELAY=0 — never set RELAY or RELAY_COPY)
$env:VICTORY_JOIN_COPIES      = '1'
$env:VICTORY_INDIRECT_WINDOW  = '1'
$env:VICTORY_INDIRECT_BATCH   = '2'
$env:VICTORY_SHOW_AFTER       = '1'
$env:VICTORY_JOIN_PARTS       = '8'
$env:VICTORY_UPLOAD_AHEAD     = '1'
$env:VICTORY_WIDE_BACK        = '1'
$env:VICTORY_CARD_REHASH_RUNS = '1'
$env:VICTORY_TEXTURE_NO_WAIT  = '1'

# Memory, I/O, and CPU scheduling (Intel Core Ultra + 32 GB RAM)
$env:VICTORY_RESIDENCY        = '1'
$env:VICTORY_QUIET_WINDOWS    = '1'
$env:VICTORY_DSTORAGE_IO      = 'direct'
$env:VICTORY_LANE_CORE        = '1'
$env:VICTORY_FAST_CORES       = '3'
$env:VICTORY_THIN             = '1'
$env:VICTORY_THIN_THREADS     = '12'
$env:VICTORY_MAP_THREADS      = '1'
$env:VICTORY_TITLE_PRIORITIES = '0'
$env:VICTORY_CARD_AWAKE       = '1'

# Pipeline library & compilation responsiveness
$env:VICTORY_PIPELINE_BOOK          = '1'
$env:VICTORY_LIBRARY_STORE_LATER    = '1'
$env:VICTORY_PIPELINE_WAIT_AGAIN_MS = '8'

# Appearance & diagnostics HUD
$env:VICTORY_AMBIENT         = '0.8'
$env:VICTORY_AMBIENT_REFLECT = '0.5'
$env:VICTORY_AMBIENT_MOST    = '2.0'
$env:VICTORY_TEXTURE_LOOK_MS = '250'
$env:VICTORY_PANEL           = '1'
$env:VICTORY_PANEL_ALPHA     = '0.45'
