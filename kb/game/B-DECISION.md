# B-DECISION
covers: G-0099..G-0142
domain: game | type: bundle | path: data\Decision\**
format: decision (text) + grp | depth: P0/P1

## Role
The **ped decision-maker data** — 44 files controlling NPC behavioural
responses (flee/fight/random behaviour). Root files (e.g. `MISSION.grp`,
`RANDOM.grp`, `RANDOM2.grp` under `Allowed\`) are per-context response tables;
`data values:` CSV records pair a ped/event id with weighted response params
(verified: `36,4,1502,100.0,...`). Named subdirs (andyd, chris, ChrisM, Craig,
david, Imran) are per-author/variant response sets.

## Structure
- `.grp`: `data values:` header + CSV rows: `<model/event>,<type>,<id>,<w1..w4>,<flags>...`
- `.dat` under Allowed\ = permitted response sets per context.
- Per-ped response files under author dirs.

## Relations
- Feeds CPed decision/AI (with popcycle.dat G-0085, ped.dat G-0079).
- SAMP runs on the same ped decision machinery for NPCs.

## Annotations
- P0 for the .grp value semantics at row level; exact field meaning [UNVERIFIED]
  without ped-AI docs. Structural record complete.
