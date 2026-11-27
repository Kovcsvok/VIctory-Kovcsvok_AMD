# A csomag shadereinek előfordítása a játék saját beállításaival (a gyorsítótár kulcsa ezeken múlik).
param([string]$List, [int]$Jobs = 4, [string]$Log)
$tree = 'C:\Games\NOT_GTAVI\VIctory-dev\belobug-9070'
Get-ChildItem Env:VICTORY_* -ErrorAction SilentlyContinue | Remove-Item
$s = @{ VICTORY_TEXTURE_NO_WAIT='1'; VICTORY_RELAY='2'; VICTORY_WIDE_BACK='1'; VICTORY_CARD_REHASH_RUNS='1'; VICTORY_JOIN_COPIES='1'
  VICTORY_INDIRECT_WINDOW='1'; VICTORY_RELAY_COPY='1'; VICTORY_CARD_STEPS='2'; VICTORY_INDIRECT_BATCH='2'; VICTORY_MAP_THREADS='1'
  VICTORY_TITLE_PRIORITIES='0'; VICTORY_CARD_AWAKE='1'; VICTORY_SHOW_AFTER='1'; VICTORY_AMBIENT='0.8'; VICTORY_D3D12_DRED='light'
  VICTORY_THIN='1'; VICTORY_JOIN_PARTS='8'; VICTORY_UPLOAD_AHEAD='1'; VICTORY_PORT_CONSTANTS='1'; VICTORY_PORT_DESCRIPTORS='1'
  VICTORY_PORT_CBV='1'; VICTORY_PORT_GUARD='1'; VICTORY_PORT_JOURNAL='1'; VICTORY_TEXTURE_MAX='512'; VICTORY_TEXTURE_LOOK_MS='250'
  VICTORY_PORT_CONSTANTS_ORDER='0' }
foreach ($k in $s.Keys) { Set-Item "Env:$k" $s[$k] }
$env:RUST_LOG = 'info'; $env:NO_COLOR = '1'
Set-Location $tree
$t = [Diagnostics.Stopwatch]::StartNew()
& "$tree\target\diag\victory.exe" translate --warm $List --jobs $Jobs 'C:\Games\NOT_GTAVI\<JATEKMAPPA>' > $Log 2> "$Log.err"
"kilépési kód $LASTEXITCODE, $([math]::Round($t.Elapsed.TotalMinutes,1)) perc"
