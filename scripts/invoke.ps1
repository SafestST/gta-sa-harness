# invoke.ps1 - MONOLITH ENTRY. Gated state-machine transitions + journal.
# Usage:
#   invoke.ps1                     # status + next action (same as inspect -Status)
#   invoke.ps1 -RunInventory       # Phase 0 (must be in phase 0)
#   invoke.ps1 -RegenIndex         # rebuild kb/00_INDEX.md from inventory (phase >=1)
#   invoke.ps1 -Advance            # complete current phase (evidence-checked), move to next
#   invoke.ps1 -CatalogBatch -Done 12 -Total 439 -Next "G-0123,G-0124"   # Phase 2 batch bookkeeping
#   invoke.ps1 -SetStatus -Phase 1 -Status running   # LLM announces a phase start
param(
  [string]$HarnessRoot = "$PSScriptRoot\..",
  [switch]$RunInventory,
  [switch]$RegenIndex,
  [switch]$Advance,
  [switch]$CatalogBatch,
  [switch]$SetStatus,
  [int]$Phase = -1,
  [string]$Status = "",
  [int]$Done = -1,
  [int]$Total = -1,
  [string]$Next = ""
)
$ErrorActionPreference = "Stop"
$statePath = Join-Path $HarnessRoot "state\state.json"
$journalPath = Join-Path $HarnessRoot "state\journal.md"

$PHASES = @("inventory","taxonomy","catalog","synthesis","done")

function Get-State {
  if (Test-Path $statePath) { return Get-Content -Raw $statePath | ConvertFrom-Json }
  return [pscustomobject]@{
    monolith="GTA-SA-Harness"
    target=@{ root="C:\Program Files (x86)\Rockstar Games\GTA San Andreas"; scope=@("GAME","SAMP"); read_only=$true }
    phase=0; phase_name="inventory"; iteration=0
    cursors=@{ inventory=@{status="pending"}; taxonomy=@{status="pending";registered=0}
               catalog=@{status="pending";done=0;total=0;next_batch=@()}
               synthesis=@{status="pending"} }
    counters=@{ notations=0; journal_entries=0; kb_files=0 }
    updated_at=(Get-Date).ToString("o")
  }
}
function Save-State($s) { $s.updated_at=(Get-Date).ToString("o"); $s | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $statePath -Encoding UTF8 }
function Journal($s,[string]$msg) {
  $entry = "### {0} - {1}" -f (Get-Date).ToString("s"), $msg
  if (Test-Path $journalPath) { Add-Content -LiteralPath $journalPath -Value ("`n" + $entry) } else { Set-Content -LiteralPath $journalPath -Value $entry -Encoding UTF8 }
  $s.counters.journal_entries += 1
}
function Evidence($s) {
  switch ($s.phase) {
    0 { return (Test-Path (Join-Path $HarnessRoot "state\inventory.json")) }
    1 { return ((Test-Path (Join-Path $HarnessRoot "kb\01_TAXONOMY.md")) -and (Test-Path (Join-Path $HarnessRoot "kb\00_INDEX.md"))) }
    2 { return ($s.cursors.catalog.total -gt 0 -and $s.cursors.catalog.done -ge $s.cursors.catalog.total) }
    3 { return (Test-Path (Join-Path $HarnessRoot "catalog\README.md")) }
    default { return $false }
  }
}

$s = Get-State

if ($SetStatus) {
  if ($Status -eq "") { throw "SetStatus requires -Status running|pending|done" }
  $p = $s.phase
  if ($Phase -ge 0) { $p = $Phase }
  switch ($p) {
    0 { $s.cursors.inventory.status = $Status }
    1 { $s.cursors.taxonomy.status = $Status }
    2 { $s.cursors.catalog.status = $Status }
    3 { $s.cursors.synthesis.status = $Status }
  }
  Journal $s ("STATUS: phase '" + $PHASES[$p] + "' -> " + $Status)
  Save-State $s; Write-Host "state updated."; exit 0
}

if ($RunInventory) {
  if ($s.phase -ne 0) { throw "GATE: Phase 0 inventory can only run in phase 0 (current: $($s.phase_name))" }
  Journal $s "PHASE 0 START: inventory walk (GAME+SAMP)"
  & (Join-Path $HarnessRoot "modules\M00_Inventory.ps1") -StateDir (Join-Path $HarnessRoot "state")
  $s.cursors.inventory.status = "done"
  Journal $s "PHASE 0 DONE: inventory.json written"
  Save-State $s; Write-Host "NEXT: Phase 1 taxonomy -> run: .\scripts\invoke.ps1 -SetStatus -Phase 1 -Status running ; then author kb/01_TAXONOMY.md"; exit 0
}

if ($RegenIndex) {
  & (Join-Path $HarnessRoot "scripts\gen-index.ps1")
  Journal $s "INDEX regenerated (registry synced)"
  Save-State $s; Write-Host "index synced."; exit 0
}

if ($CatalogBatch) {
  if ($s.phase -ne 2) { throw "GATE: CatalogBatch only valid in phase 2 (current: $($s.phase_name))" }
  if ($Done -ge 0) { $s.cursors.catalog.done = $Done }
  if ($Total -ge 0) { $s.cursors.catalog.total = $Total }
  if ($Next -ne "") { $s.cursors.catalog.next_batch = @($Next -split "," | ForEach-Object { $_.Trim() } | Where-Object { $_ }) }
  $s.iteration += 1
  $kb = Get-ChildItem -LiteralPath (Join-Path $HarnessRoot "kb") -Recurse -File | Where-Object { $_.Extension -eq ".md" }
  $s.counters.kb_files = $kb.Count
  $notations = @(Get-ChildItem -LiteralPath (Join-Path $HarnessRoot "kb\game") -File -Filter *.md -ErrorAction SilentlyContinue) + @(Get-ChildItem -LiteralPath (Join-Path $HarnessRoot "kb\samp") -File -Filter *.md -ErrorAction SilentlyContinue)
  $s.counters.notations = $notations.Count
  Journal $s "PHASE 2 ITERATION $($s.iteration): batch done=$($s.cursors.catalog.done)/$($s.cursors.catalog.total) kb_files=$($s.counters.kb_files)"
  Save-State $s; Write-Host "catalog cursor updated (iteration $($s.iteration))"; exit 0
}

if ($Advance) {
  if (-not (Evidence $s)) {
    if ($s.phase -eq 0) { throw "GATE FAIL: run -RunInventory first (no inventory.json)" }
    if ($s.phase -eq 1) { throw "GATE FAIL: kb/01_TAXONOMY.md and kb/00_INDEX.md required before advance" }
    if ($s.phase -eq 2) { throw "GATE FAIL: catalog done ($($s.cursors.catalog.done)) is less than total ($($s.cursors.catalog.total))" }
    if ($s.phase -eq 3) { throw "GATE FAIL: catalog/README.md required" }
    throw "GATE FAIL: current phase incomplete"
  }
  $from = $PHASES[$s.phase]
  switch ($s.phase) {
    0 { $s.cursors.inventory.status = "done" }
    1 { $s.cursors.taxonomy.status = "done" }
    2 { $s.cursors.catalog.status = "done" }
    3 { $s.cursors.synthesis.status = "done" }
  }
  $s.phase += 1
  if ($s.phase -ge $PHASES.Count) { $s.phase = $PHASES.Count - 1 }
  $s.phase_name = $PHASES[$s.phase]
  Journal $s "ADVANCE: phase '$from' COMPLETE -> '$($s.phase_name)'"
  Save-State $s; Write-Host "ADVANCED -> phase $($s.phase) ($($s.phase_name))"; exit 0
}

# default: status
Write-Host ("MONOLITH: {0} | phase={1} ({2}) | iteration={3}" -f $s.monolith, $s.phase, $s.phase_name, $s.iteration)
Write-Host ("  cursors: inv={0} tax={1} cat={2} done={3}/{4} synth={5}" -f $s.cursors.inventory.status,$s.cursors.taxonomy.status,$s.cursors.catalog.status,$s.cursors.catalog.done,$s.cursors.catalog.total,$s.cursors.synthesis.status)
Write-Host ("  counters: notations={0} journal_entries={1} kb_files={2}" -f $s.counters.notations,$s.counters.journal_entries,$s.counters.kb_files)
switch ($s.phase) {
  0 { Write-Host "NEXT ACTION: .\scripts\invoke.ps1 -RunInventory" }
  1 { Write-Host "NEXT ACTION: author kb/01_TAXONOMY.md + kb/02_BUNDLES.md, then .\scripts\invoke.ps1 -Advance" }
  2 { Write-Host "NEXT ACTION: author KB notations in kb/game + kb/samp, then .\scripts\invoke.ps1 -CatalogBatch ..." }
  3 { Write-Host "NEXT ACTION: assemble catalog\ (catalogue code-base), then .\scripts\invoke.ps1 -Advance" }
}
