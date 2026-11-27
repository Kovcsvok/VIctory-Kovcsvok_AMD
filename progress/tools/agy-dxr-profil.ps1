param(
    [ValidateSet('series-x', 'series-s')]
    [string]$Console = 'series-x',
    [ValidateSet('0', '1')]
    [string]$DxrOpt = '1',
    [switch]$UnlockFps,
    [switch]$GpuTiming,
    [ValidateSet('release', 'diag')]
    [string]$Build = 'release'
)

# Minden orokolt VICTORY_* valtozo torlese, hogy az eloforditas es a futtatas 100%-ig egyezzen
Get-ChildItem -Path Env:VICTORY_* -ErrorAction SilentlyContinue | Remove-Item -ErrorAction SilentlyContinue

$AgyTree   = 'C:\Games\NOT_GTAVI\VIctory-dev\agy-dxr-fast'
$AgyState  = 'C:\Games\NOT_GTAVI\VIctory-dev\state\agy-dxr-fast'
$AgyConfig = Join-Path $AgyState 'victory.toml'
$GameDir   = 'C:\Games\NOT_GTAVI\<JATEKMAPPA>'
$TitleExe  = 'C:\Games\NOT_GTAVI\<JATEKMAPPA>\game_scarlett_master.exe'
$FfxDir    = 'C:\Games\NOT_GTAVI\VIctory-dev\FidelityFX-SDK\Kits\FidelityFX\signedbin'

$EffectiveBuild = if ($GpuTiming) { 'diag' } else { $Build }
$ReleaseExe = Join-Path $AgyTree 'target\release\victory.exe'
$DiagExe    = Join-Path $AgyTree 'target\diag\victory.exe'
if ($EffectiveBuild -eq 'diag' -and (Test-Path -LiteralPath $DiagExe)) {
    $AgyExe = $DiagExe
} else {
    $AgyExe = $ReleaseExe
}

$env:RUST_LOG = 'info'
$env:NO_COLOR = '1'

# Kulso allapot es konfig (nem nyul a repohoz)
$env:VICTORY_CONFIG    = $AgyConfig
$env:VICTORY_GAME_DIR  = $GameDir
$env:VICTORY_CACHE_DIR = Join-Path $AgyState 'cache'
$env:VICTORY_DATA_DIR  = Join-Path $AgyState 'data'

if (Test-Path -LiteralPath $FfxDir) {
    $env:VICTORY_FIDELITYFX_DIR = $FfxDir
}

# Memoria es texturak (Series X: nincs 512px texturakorlat!)
$env:VICTORY_WINDOW_BUDGET_MB = '2048'
$env:VICTORY_TEXTURE_MAX      = '0'
$env:VICTORY_FFX_FG           = '0'

# Konzol profil: Series X (FSR 4.1.2 1080p->1440p) vs Series S
if ($Console -eq 'series-x') {
    $env:VICTORY_FSR_1440P = '1'
} else {
    Remove-Item -Path Env:VICTORY_FSR_1440P -ErrorAction SilentlyContinue
    Remove-Item -Path Env:VICTORY_FSR -ErrorAction SilentlyContinue
}

# 30 FPS korlat feloldasa (1:1 jatekido)
if ($UnlockFps) {
    $env:VICTORY_FRAME_INTERVAL_MS = '0'
    $env:VICTORY_TITLE_FPS         = '60'
    $env:VICTORY_VSYNC             = '0'
}

# Nativ DXR 1.1 + caf96a3229145fa6 optimalizacio
$env:VICTORY_NATIVE_RT              = '1'
$env:VICTORY_BVH_BUILDER            = '1'
$env:VICTORY_DXR_OPT                = $DxrOpt
$env:VICTORY_NATIVE_RT_ANYHIT       = '0'
$env:VICTORY_NATIVE_RT_FBT_TWOPASS  = '0'

# Shader-cache kulcsba hash-elt RDNA 4 / Wave32 kapcsolok (shader_cache.rs)
$env:VICTORY_RDNA_WAVE32      = '2'
$env:VICTORY_SHADER_OPT       = '127'
$env:VICTORY_PORT_CBV         = '1'
$env:VICTORY_LEGACY_MUL_PLAIN = '1'
$env:VICTORY_LDS_INIT_HOIST   = '1'

# VIctory-Fast alapfutasi es szinkron kapcsolok
$env:VICTORY_PORT_CONSTANTS     = '1'
$env:VICTORY_PORT_DESCRIPTORS   = '1'
$env:VICTORY_PORT_RT            = '1'
$env:VICTORY_TWIN_MOVE          = '1'
$env:VICTORY_GPU_ONLY_COPYBACK  = '2'
$env:VICTORY_TEXTURE_NO_WAIT    = '1'
$env:VICTORY_RELAY              = '2'
$env:VICTORY_RELAY_COPY         = '1'
$env:VICTORY_WIDE_BACK          = '1'
$env:VICTORY_CARD_REHASH_RUNS   = '1'
$env:VICTORY_JOIN_COPIES        = '1'
$env:VICTORY_INDIRECT_WINDOW    = '1'
$env:VICTORY_INDIRECT_BATCH     = '2'
$env:VICTORY_CARD_STEPS         = '2'
$env:VICTORY_MAP_THREADS        = '1'
$env:VICTORY_TITLE_PRIORITIES   = '0'
$env:VICTORY_CARD_AWAKE         = '1'
$env:VICTORY_SHOW_AFTER         = '1'
$env:VICTORY_THIN               = '1'
$env:VICTORY_JOIN_PARTS         = '8'
$env:VICTORY_UPLOAD_AHEAD       = '1'
$env:VICTORY_PIPELINE_BOOK      = '1'
$env:VICTORY_SKIP_PIPELINES     = 'none'
$env:VICTORY_AMBIENT            = '1.8'
$env:VICTORY_PANEL              = '1'

# Diagnosztika / GPU idobelyeg
if ($GpuTiming) {
    $env:VICTORY_GPU_TIMING = '1'
    $env:VICTORY_D3D12_DRED = '1'
} else {
    $env:VICTORY_D3D12_DRED = 'light'
}
