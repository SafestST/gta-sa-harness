# inspect.ps1 - EXTERNAL MONITOR. See exactly where the monolith stands and how it's processing.
#   .\scripts\inspect.ps1            # state + next action + KB stats
#   .\scripts\inspect.ps1 -Journal   # + tail of journal.md
#   .\scripts\inspect.ps1 -Inventory # + inventory summary (domains/categories)
param(
  [string]$HarnessRoot = "$PSScriptRoot\..",
  [switch]$Journal,
  [switch]$Inventory
)
$ErrorActionPreference = "Stop"
$statePath = Join-Path $HarnessRoot "state\state.json"
if (-not (Test-Path $statePath)) { Write-Host "NO STATE - monolith not started. Run: .\scripts\invoke.ps1 -RunInventory"; exit 0 }

$s = Get-Content -Raw $statePath | ConvertFrom-Json
Write-Host "=========================================================="
Write-Host ("MONOLITH        : {0}" -f $s.monolith)
Write-Host ("TARGET (RO)     : {0}" -f $s.target.root)
Write-Host ("SCOPE           : {0}" -f ($s.target.scope -join " + "))
Write-Host "----------------------------------------------------------"
Write-Host ("PHASE           : {0}  ({1})" -f $s.phase, $s.phase_name.ToUpperInvariant())
Write-Host ("ITERATION       : {0}" -f $s.iteration)
Write-Host "--- cursors -------------------------------------------------"
Write-Host ("  inventory     : {0}" -f $s.cursors.inventory.status)
Write-Host ("  taxonomy      : {0}  registered={1}" -f $s.cursors.taxonomy.status, $s.cursors.taxonomy.registered)
Write-Host ("  catalog       : {0}  done={1} total={2}" -f $s.cursors.catalog.status, $s.cursors.catalog.done, $s.cursors.catalog.total)
if ($s.cursors.catalog.next_batch.Count -gt 0) { Write-Host ("    next_batch   : {0}" -f ($s.cursors.catalog.next_batch -join ", ")) }
Write-Host ("  synthesis     : {0}" -f $s.cursors.synthesis.status)
Write-Host "--- counters ------------------------------------------------"
Write-Host ("  notations     : {0}" -f $s.counters.notations)
Write-Host ("  journal_entries: {0}" -f $s.counters.journal_entries)
Write-Host ("  kb_files      : {0}" -f $s.counters.kb_files)
Write-Host "----------------------------------------------------------"
if ($Inventory -and (Test-Path (Join-Path $HarnessRoot "state\inventory.json"))) {
  $inv = Get-Content -Raw (Join-Path $HarnessRoot "state\inventory.json") | ConvertFrom-Json
  Write-Host ("INVENTORY       : {0} files, {1:N2} GB" -f $inv.summary.file_count, ($inv.summary.total_bytes/1GB))
  Write-Host "  by domain:"; $inv.summary.by_domain | ForEach-Object { Write-Host ("    {0,-6} {1}" -f $_.domain, $_.count) }
  Write-Host "  top categories:"; $inv.summary.by_category | Select-Object -First 12 | ForEach-Object { Write-Host ("    {0,-16} {1}" -f $_.category, $_.count) }
}
if ($Journal -and (Test-Path (Join-Path $HarnessRoot "state\journal.md"))) {
  Write-Host "=== JOURNAL TAIL ==="; Get-Content (Join-Path $HarnessRoot "state\journal.md") -Tail 25
}
Write-Host "=========================================================="
