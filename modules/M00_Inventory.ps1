# M00_Inventory.ps1 - PHASE 0: deterministic full-manifest walker (GAME + SAMP)
# Idempotent. Writes state/inventory.json. Never writes to the target dir.
param(
  [string]$TargetRoot = "C:\Program Files (x86)\Rockstar Games\GTA San Andreas",
  [string]$StateDir = "$PSScriptRoot\..\state",
  [switch]$SkipHashes
)

$ErrorActionPreference = "Stop"
$invPath = Join-Path $StateDir "inventory.json"

function Get-Domain([string]$Rel, [string]$Name) {
  if ($Rel -like "SAMP\*" -or $Name -like "samp*" -or $Name -ieq "rcon.exe") { return "samp" }
  return "game"
}

function Get-Category([string]$Ext) {
  switch ($Ext.ToLowerInvariant()) {
    ".dat"  { "text-config" }
    ".cfg"  { "text-config" }
    ".ini"  { "text-config" }
    ".txt"  { "text-config" }
    ".zon"  { "world-data" }
    ".ped"  { "world-data" }
    ".ide"  { "world-data" }
    ".ipl"  { "world-data" }
    ".grp"  { "world-data" }
    ".img"  { "archive-img" }
    ".dff"  { "model-dff" }
    ".txd"  { "texture-txd" }
    ".col"  { "collision-col" }
    ".ifp"  { "anim-ifp" }
    ".scm"  { "script-scm" }
    ".sc"   { "script-scm" }
    ".saa"  { "archive-saa" }
    ".gxt"  { "text-gxt" }
    ".ttf"  { "font" }
    ".png"  { "image" }
    ".ico"  { "image" }
    ".ICN"  { "image" }
    ".mpg"  { "video" }
    ".exe"  { "executable" }
    ".dll"  { "library-dll" }
    ".nfo"  { "metadata" }
    ".fxp"  { "metadata" }
    default { "other" }
  }
}

Write-Host "PHASE 0 INVENTORY | target: $TargetRoot"
$files = Get-ChildItem -LiteralPath $TargetRoot -Recurse -File -Force -ErrorAction SilentlyContinue
$entries = @()
$n = 0
foreach ($f in $files) {
  $n++
  $rel = $f.FullName.Substring($TargetRoot.Length).TrimStart('\')
  $name = $f.Name
  $ext = [System.IO.Path]::GetExtension($name)
  $hash = $null
  if (-not $SkipHashes) {
    try { $hash = (Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256 -ErrorAction Stop).Hash.ToLowerInvariant() }
    catch { $hash = "HASH-ERROR" }
  }
  $entries += [ordered]@{
    id       = "$(if ($rel -like "SAMP\*" -or $name -like "samp*" -or $name -ieq "rcon.exe"){"S"}else{"G"})-{0:D4}" -f $n
    domain   = Get-Domain $rel $name
    category = Get-Category $ext
    path     = $rel
    name     = $name
    ext      = $ext
    size     = $f.Length
    sha256   = $hash
  }
  if ($n % 100 -eq 0) { Write-Host "  ...$n files" }
}

$summary = [ordered]@{
  generated_at = (Get-Date).ToString("o")
  target_root  = $TargetRoot
  file_count   = $entries.Count
  total_bytes  = ($entries | ForEach-Object { [int64]$_.size } | Measure-Object -Sum).Sum
  by_domain    = $entries | Group-Object { $_.domain } | ForEach-Object { [ordered]@{ domain=$_.Name; count=$_.Count } }
  by_category  = $entries | Group-Object { $_.category } | Sort-Object { $_.Count } -Descending | ForEach-Object { [ordered]@{ category=$_.Name; count=$_.Count } }
}
$out = [ordered]@{ summary = $summary; files = $entries }
$out | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $invPath -Encoding UTF8
Write-Host ("DONE: {0} files -> {1}" -f $entries.Count, $invPath)
