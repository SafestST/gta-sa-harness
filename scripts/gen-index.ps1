# gen-index.ps1 - regenerate kb/00_INDEX.md (entity registry) from state/inventory.json
# Deterministic + idempotent. Used by Phase 1/2/3 to keep the notation DB registry in sync.
param(
  [string]$HarnessRoot = "$PSScriptRoot\.."
)
$ErrorActionPreference = "Stop"
$inv = Join-Path $HarnessRoot "state\inventory.json"
$idx = Join-Path $HarnessRoot "kb\00_INDEX.md"
if (-not (Test-Path $inv)) { throw "inventory.json missing - run Phase 0 first" }

$data = Get-Content -Raw $inv | ConvertFrom-Json

$L = New-Object System.Collections.Generic.List[string]
$L.Add("# NOTATION DATABASE - MASTER INDEX")
$L.Add("")
$totGb = ('{0:N2}' -f ($data.summary.total_bytes / 1GB))
$L.Add("Generated: " + (Get-Date).ToString('s') + " | Entities: " + $data.summary.file_count + " | Total: " + $totGb + " GB")
$L.Add("")
$L.Add("Format: <ENTITY_ID> <domain> <category> <format> <size> - <path>")
$L.Add("")
$L.Add("| ID | Domain | Category | Format | Size | Path |")
$L.Add("|----|--------|----------|--------|------|------|")
foreach ($f in $data.files) {
  $fmt = "none"
  if ($f.ext) { $fmt = $f.ext.TrimStart('.') }
  $row = "| " + $f.id + " | " + $f.domain + " | " + $f.category + " | " + $fmt + " | " + $f.size + " | " + $f.path + " |"
  $L.Add($row)
}
$L.Add("")
$L.Add("See 01_TAXONOMY.md for the canonical format catalogue and kb/game, kb/samp for notations.")
$L -join "`n" | Set-Content -LiteralPath $idx -Encoding UTF8
Write-Host "INDEX REGENERATED: $idx"
