# MODULE M02 — PHASE 2: CATALOG NOTATIONS (LLM, ITERATIVE)

**Prereq:** Phase 1 done (taxonomy + registry exist). **Read:** HARNESS.md,
state/state.json, kb/01_TAXONOMY.md, kb/02_BUNDLES.md, kb/00_INDEX.md.

## OBJECTIVE
Turn every entity (and every bundle) into a durable **notation** under the
notation database: `kb/game/**` and `kb/samp/**`. This is where the model builds
its complete, utter understanding — not a mirror of the tree, but knowledge units.

## ITERATION LOOP (the harness "knows where it stands")
1. Read `state.json` -> `cursors.catalog` gives `done`, `total`, `next_batch`.
2. Take ONE bounded batch (recommend 8-15 entities per iteration).
3. For each entity in the batch:
   - open the file READ-ONLY (text files fully; binaries via header/string/hex
     probes — see `scripts/probe.ps1` if present, or direct Read/Grep)
   - author a notation: `kb/game/<id>.md` or `kb/samp/<id>.md` using the template
     in HARNESS.md §5. Group related entities into one bundle notation where
     they form a coherent system (note the ids covered).
   - cross-reference other ids/subsystems
4. Update the monolith: `.\scripts\invoke.ps1 -CatalogBatch -Done <d> -Total <t> -Next "G-....,S-...."`  (writes journal + increments iteration)
5. Regenerate the index: `.\scripts\invoke.ps1 -RegenIndex`
6. Repeat until `done >= total`.

## DEPTH POLICY (smart, not exhaustive-brute)
Prioritise by **understanding leverage**:
- **P0 Read fully** — text "code" files: handling.cfg, carcols.dat, cargrp.dat,
  carmods.dat, *.ide, *.ipl, *.dat, *.zon, *.ped, SAMP.ide, SAMP.ipl, *.gxt
  (keys only). These define the world and are the highest-leverage knowledge.
- **P1 Structural** — binary assets (dff/txd/col/img/ifp/saa/scm): document
  container/anchor structure, size, what it bundles, strings exposed; note where
  external specs (GTAModding, open-source reVC/RE3) would deepen analysis. Do not
  dump raw bytes.
- **P2 Fingerprint** — exe/dll/audio/video: id, size, sha256, entry-adjacent
  surface (imports/strings only at safe depth); note role in boot chain.
Record the depth used in each notation.

## RULES
- Read-only on the target. Never write into Program Files.
- A batch NEVER partially updates state: author all notations in the batch, then
  bookkeep once.
- If interrupted, resume from `cursors.catalog.next_batch` — never restart.
- Update `counters.notations` when adding notations.
