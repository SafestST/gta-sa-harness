# MODULE M01 — PHASE 1: TAXONOMY + REGISTRATION (LLM)

**Prereq:** Phase 0 done (state/inventory.json exists). **Read:** HARNESS.md,
state/state.json, state/inventory.json summary.

## OBJECTIVE
Produce the canonical understanding layer of the notation database:
1. `kb/01_TAXONOMY.md` — canonical format catalogue covering BOTH domains
   (GAME + SAMP), grounded in the actual inventory categories.
2. `kb/02_BUNDLES.md` — the logical bundles of the codebase (e.g. "world model
   archive gta3.img + its .ide/.ipl", "SAMP world overlay", "mission script
   main.scm + script.img"), i.e. how files cohere into systems.
3. Regenerate `kb/00_INDEX.md` via `scripts/gen-index.ps1` (deterministic registry).

## WHAT THE TAXONOMY MUST CONTAIN
For every category present in inventory (`by_category`), define:
- **format id** (e.g. `handling-cfg`, `carcols-dat`, `ide`, `ipl`, `dff`, `txd`,
  `col`, `img`, `ifp`, `scm`, `gxt`, `saa`, `dll`, `exe`)
- **what it is** — the artifact and its role in the engine
- **who consumes it** — which subsystem loads it (e.g. handling.cfg -> CGame::cHandlingDataMgr)
- **how an LLM reads it** — text parseable vs binary; structure notes; where
  depth is limited without third-party tools (say so explicitly)
- **cross-domain** — which formats are shared / overridden by SAMP
  (SAMP.ide/SAMP.ipl override/augment the world; SAMP.img adds models)

## REGISTRATION
Run `.\scripts\invoke.ps1 -RegenIndex`. Every entity id (G-#### / S-####) must
appear in kb/00_INDEX.md. Do NOT hand-edit that table; regenerate it.

## COMPLETION EVIDENCE (gate for Advance)
- kb/01_TAXONOMY.md exists
- kb/00_INDEX.md exists (regenerated)
Then: `.\scripts\invoke.ps1 -Advance`

## DISCIPLINE
Every claim written to the KB must be reproducible from the target files or
publicly documented GTA SA / SAMP formats. Where knowledge is uncertain, mark
`[UNVERIFIED]` and say what would verify it. Do not fabricate offsets or IDs.
