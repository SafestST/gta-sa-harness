# MODULE M03 — PHASE 3: SYNTHESIS — THE CATALOGUE CODE-BASE (LLM)

**Prereq:** Phase 2 done (`catalog.done >= catalog.total`). **Read:** HARNESS.md,
state/state.json, the entire kb/ tree.

## OBJECTIVE
Synthesise the notation database into a **catalogue code-base** under `catalog/`.
This is the deliverable: an LLM with zero prior exposure must be able to read
`catalog/` alone and hold a complete, utter, working model of the codebase. It
must NOT mirror the raw file tree — it encodes understanding.

## REQUIRED ARTEFACTS (A-Z of the monolith's knowledge)
- `catalog/README.md` — orientation: what this is, how to read it, the two
  domains (GAME + SAMP) and how SAMP overlays the game.
- `catalog/00_SYSTEM_MAP.md` — the whole as a system: boot chain (exe -> dlls ->
  data -> models -> audio), subsystems (world, vehicles, peds/AI, mission script,
  text, audio), and where SAMP plugs in (samp.dll load, RCON, world overlay).
- `catalog/01_FORMAT_REFERENCE.md` — distilled from kb/01_TAXONOMY.md: every
  format, one crisp definition, consumer, read path.
- `catalog/02_ENTITY_REFERENCE.md` — distilled registry: every bundle + notable
  entities with their role (deep links into kb/ notations).
- `catalog/03_DOMAIN_GAME.md`, `catalog/04_DOMAIN_SAMP.md` — per-domain
  comprehension guides (world construction, vehicle/handling model, ped AI data,
  mission script model, SAMP object overlay + network client surface).
- `catalog/05_LLM_QUICKSTART.md` — the fastest path for an LLM to become fluent:
  what to read first, what maps to what, gotchas (data precedence, archive
  coupling, SAMP overrides).

## COMPLETION EVIDENCE (gate for Advance -> done)
- catalog/README.md exists (and ideally the rest of the artefacts).
Then: `.\scripts\invoke.ps1 -Advance` (-> phase 4 done).

## DISCIPLINE
Every statement must trace back to a kb/ notation. Mark knowledge limits with
`[UNVERIFIED]` + how to verify. This is the capstone; quality over speed.
