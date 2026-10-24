# B-ANIM
covers: G-0022..G-0024
domain: game | type: bundle | path: anim\**
format: ifp + img | depth: P1

## Role
**Animation store** — 3 files: `ped.ifp` (1.4 MB, the main ped animation set),
`anim.img` (10.9 MB, additional anim archive), `cuts.img` (270 MB, cutscene
animation archive). Driven by `animgrp.dat` (G-0057) which maps anim groups.

## Structure
- `.ifp`: RenderWare animation sections (bone/keyframe tracks); IFP container
  anatomy documented publicly; P1 structural.
- `anim.img`/`cuts.img`: standard IMG archives (see G-0339) of IFP entries.

## Relations
- B-G10 animation subsystem with animgrp.dat (G-0057) + animviewer.dat (G-0058).
- Used by main.scm (G-0329) scripted animation commands and cutscene playback.

## Annotations
- P1 structural; keyframe decode out of scope (needs anim tools). Names/sizes
  recorded in inventory.
