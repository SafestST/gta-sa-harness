# coverage.ps1 - count entities COVERED by the notation database (per-file ids + bundle `covers:` ranges)
# Writes state/coverage.txt (sorted id list) and prints the covered count. Deterministic.
param(
  [string]$HarnessRoot = "$PSScriptRoot\.."
)
$ErrorActionPreference = "Stop"
$covered = New-Object System.Collections.Generic.HashSet[string]

function Add-Ids([string]$list) {
  foreach ($tok in ($list -split ',')) {
    $t = $tok.Trim()
    if (-not $t) { continue }
    if ($t -match '^([GS])-(\d+)\.\.([GS])-(\d+)$') {
      $p1 = $matches[1]; $a = [int]$matches[2]; $p2 = $matches[3]; $b = [int]$matches[4]
      $lo = [Math]::Min($a, $b); $hi = [Math]::Max($a, $b)
      for ($i = $lo; $i -le $hi; $i++) { [void]$covered.Add(($p1 + '-' + $i.ToString('0000'))) }
    }
    elseif ($t -match '^[GS]-\d+$') { [void]$covered.Add($t) }
    else { Write-Warning "coverage: unparsed token '$t'" }
  }
}

foreach ($dir in @("kb\game", "kb\samp")) {
  Get-ChildItem -LiteralPath (Join-Path $HarnessRoot $dir) -File -Filter *.md -ErrorAction SilentlyContinue | ForEach-Object {
    if ($_.BaseName -match '^[GS]-\d+$') { [void]$covered.Add($_.BaseName) }
  }
}
foreach ($dir in @("kb\game", "kb\samp")) {
  Get-ChildItem -LiteralPath (Join-Path $HarnessRoot $dir) -File -Filter *.md -ErrorAction SilentlyContinue | ForEach-Object {
    $m = Select-String -LiteralPath $_.FullName -Pattern '^covers:\s*(.+)$' | Select-Object -First 1
    if ($m) { Add-Ids $m.Matches[0].Groups[1].Value }
  }
}

$sorted = $covered | Sort-Object
$sorted -join "," | Set-Content (Join-Path $HarnessRoot "state\coverage.txt") -Encoding UTF8
Write-Host ("COVERED ENTITIES: " + $covered.Count)
