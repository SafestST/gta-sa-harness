# B-WORLD-DEFS
covers: G-0148..G-0255
domain: game | type: bundle | path: data\maps\** (.ide + .ipl)
format: ide + ipl | depth: P0

## Role
The **world definition set** — 55 IDE + 53 IPL files that register and place
every object in the game world, per region:
LA (LAn/LAs/LAe/LAn2/LAs2/LAe2), SF, vegas, country, interior, generic,
leveldes (level design extras), veh_mods. Plus the special IPLs at the maps root:
`paths.ipl`/`paths2-5.ipl` (road/path markers), `cull.ipl`, `occlu*.ipl`
(occlusion boxes), `tunnels.ipl`, `Audiozon.ipl`, `txd.ide`.

## Structure
- `.ide`: `objs`/`tobj`/`peds`/`cars`/`hier` sections; `<id> <modelname>
  <txdname> <drawdist> <flags>`. Binds model ids to DFF/TXD names.
- `.ipl`: `inst` records `<id> <modelname> <ix,iy,iz> <sx,sy,sz> <rotation>` and
  `cull`/`occ`/`path` sections. Loaded in gta.dat order (G-0070).
- Region dirs mirror the streaming sectors the engine uses for paging.

## Relations
- B-G01 world archive (gta3.img G-0339) supplies the DFF/TXD each IDE/IPL names.
- Zone names (info.zon G-0073) are referenced by IPL `zone` semantics.
- SAMP mirrors this exact grammar for its overlay (S-0431/S-0433).

## Annotations
- P0: full parse of these 108 files yields the authoritative object catalogue
  of the game world (model id -> asset -> placement). Highest-value Phase 2 task
  remaining; gta.dat load order must be respected when reasoning.
