# GTA-SA-HARNESS — MONOLITH CONSTITUTION

Version: 1.1
Status: **COMPLETE — Phases 0-3 done (catalogue code-base delivered); research domain added**

This document is the single constitution of the monolith. Any LLM operating this
harness MUST read this file first, then read `state/state.json` to learn where the
monolith stands. You may never skip a phase, never write to the target directory,
and never advance state without appending a journal entry.

---

## 1. MISSION

Analyse the target directory

    C:\Program Files (x86)\Rockstar Games\GTA San Andreas

comprising TWO co-equal domains:

- **GAME** — GTA San Andreas (v1.0 retail-style install, 4.74 GB / 439 files): the
  compiled engine, readable data "code" (handling.cfg, carcols.dat, *.ide, *.ipl,
  *.dat, *.zon, *.ped), the mission script (data\script\main.scm), maps, models,
  anims, text tables, audio.
- **SAMP** — San Andreas Multiplayer (samp.exe / samp.dll / samp_debug.exe /
  samp.saa / rcon.exe + SAMP\*.ide|ipl|img): the multiplayer mod core layered on the
  game.

The target is **READ-ONLY**. The monolith never modifies it.

Deliverable: a **CATALOGUE CODE-BASE** — a fully cross-referenced, notation-backed
catalog of the entire target such that an LLM with no prior exposure can hold a
complete and utter model of the codebase. It must NOT mirror the raw file tree; it
must be an understanding, encoded as notations.

## 2. MONOLITH LAYOUT (A-Z)

    GTA-SA-Harness\
    ├── HARNESS.md          <- THIS FILE (constitution; read first, always)
    ├── modules\            <- PHASES (the "Modular" axis; run strictly in order)
    │     M00_Inventory.ps1     deterministic walker (script)
    │     M01_Taxonomy.md       format taxonomy + entity registration (LLM)
    │     M02_Catalog.md        deep per-entity notation (LLM, iterative)
    │     M03_Synthesis.md      assemble catalogue code-base (LLM)
    ├── scripts\            <- deterministic tooling (reproducible, idempotent)
    │     invoke.ps1            monolith entry: gate-check -> run phase -> advance
    │     inspect.ps1           EXTERNAL MONITOR: human-readable state + journal + KB
    ├── state\              <- THE SOURCE OF TRUTH (monolith position, never hand-edited by the LLM)
    │     state.json            schema below
    │     inventory.json        Phase 0 output (439-file manifest w/ hashes)
    │     journal.md            append-only run log (external monitoring trail)
    ├── kb\                 <- NOTATION DATABASE (the model's long-term memory)
    │     00_INDEX.md           master index (regenerated each phase)
    │     01_TAXONOMY.md        canonical format taxonomy + capability map
    │     game\...              notations per GAME entity/bundle
    │     samp\...              notations per SAMP entity/bundle
    └── catalog\            <- FINAL CATALOGUE CODE-BASE (Phase 3 output)

## 3. STATE MACHINE (WHERE THE MONOLITH STANDS)

`state/state.json` is the ONLY authority on position. Schema:

    {
      "monolith": "GTA-SA-Harness",
      "target": { "root": "...", "scope": ["GAME","SAMP"], "read_only": true },
      "phase": 0..4,
      "phase_name": "inventory"|"taxonomy"|"catalog"|"synthesis"|"done",
      "iteration": int,                  // increments every LLM batch in Phase 2
      "cursors": {
        "inventory": { "status": "pending|running|done" },
        "taxonomy":  { "status": "...", "registered": int },
        "catalog":   { "status": "...", "done": int, "total": int, "next_batch": [...] },
        "synthesis": { "status": "..." }
      },
      "counters": { "notations": int, "journal_entries": int, "kb_files": int },
      "updated_at": "ISO-8601"
    }

Phase gates (never run a phase whose predecessor is not `done`):

    0 inventory (script)  -> inventory.json        [COMPLETE]
    1 taxonomy   (LLM)    -> kb/01_TAXONOMY.md + kb/00_INDEX.md + entity registration  [COMPLETE]
    2 catalog    (LLM)    -> kb/game/**, kb/samp/**  (batched iterations)
    3 synthesis  (LLM)    -> catalog/**            (final catalogue code-base)
    4 done

## 4. OPERATING RULES (BINDING)

1. READ FIRST: `HARNESS.md`, then `state/state.json`, then `state/journal.md` (tail).
2. ONE PHASE AT A TIME. In Phase 2, one bounded batch per iteration; update
   `cursors.catalog.done/total/next_batch` and `iteration` after each batch.
3. NOTATIONS ARE MEMORY. Every durable finding is a notation file under `kb/`.
   A notation is a concise, cross-referenced knowledge unit (see template below).
   Update `kb/00_INDEX.md` and `counters` when you add notations.
4. JOURNAL EVERY MOVE. Append a dated entry to `state/journal.md` for every
   phase completion, every batch, and every notable decision. This is the external
   monitoring trail.
5. NEVER write into the target directory. NEVER hand-edit state.json (use the
   `advance` helper in `scripts/invoke.ps1` or the documented transition rules).
6. DETERMINISM: scripts in `scripts/` must be idempotent and reproducible.
   LLM phases are reproducible from state + journal alone.
7. If a phase is interrupted, resume from state.json — never restart.

## 5. NOTATION TEMPLATE (KB UNITS)

    # <ENTITY_ID or BUNDLE_ID>
    covers: <ids covered - single id, comma list, or range e.g. G-0057..G-0098>
    domain: game|samp | type: <type> | path: <relative path>
    format: <canonical format id>
    ## Role (what it is / what it does in the codebase)
    ## Structure (format anatomy; offsets/records only when known)
    ## Relations (links to other entity_ids / notations / game subsystems)
    ## Annotations (LLM notes, gotchas, provenance)

Every notation MUST carry a `covers:` line. Per-entity notations use their own
id; bundle notations list every id they cover (ranges allowed). Phase 2 progress
(`cursors.catalog.done`) = number of DISTINCT entities covered, computed by
`scripts/coverage.ps1`. Entity IDs: `G-<NNNN>` for game, `S-<NNNN>` for SAMP.
Registry lives in `kb/00_INDEX.md`.

## 6. EXTERNAL MONITORING

    powershell -File scripts\inspect.ps1          # state + next action + KB stats
    powershell -File scripts\inspect.ps1 -Journal # + tail of journal.md

Any operator (human or LLM) may run inspect at any time to see exactly where the
monolith stands and what it is processing.
