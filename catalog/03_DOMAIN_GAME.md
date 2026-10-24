# 03 DOMAIN GAME — COMPREHENSION GUIDE

## World construction (how a city is built)
1. `gta.dat` (G-0070) lists IMGs then IDEs then IPLs in load order.
2. Each region dir under `data\maps\` (LA/SF/vegas/country/interior/generic/
   leveldes/veh_mods) has matching `.ide` (register model ids) + `.ipl`
   (place them). Streaming loads geometry from the matching IMG (`gta3.img`
   for the main world, `gta_int.img` interiors, `player.img` player).
3. Zoning: `info.zon`/`map.zon` define named city zones; `paths*.ipl` +
   `data\Paths\NODES*.DAT` provide the AI nav mesh; `cull.ipl`/`occlu*.ipl`
   control occlusion.

## Vehicle & handling model
- `vehicles.ide` maps vehicle ids -> DFF/TXD; `handling.cfg` gives physics per
  id; `carcols.dat` colours; `carmods.dat` mod kits; `cargrp.dat` traffic
  groups; `weapon.dat`/`melee.dat` weapon behaviour; `numplate.dat` plates.

## Ped & AI model
- `peds.ide` ped ids; `ped.dat`/`pedstats.dat`/`pedgrp.dat` attributes;
  `popcycle.dat` who spawns where/when; `data\Decision\**` decision-maker
  response tables (MISSION/RANDOM .grp + per-author variants).

## Mission script model
- `main.scm` (G-0329) is the game's program: opcode stream + variable tables +
  mission threads; `script.img` holds scripted assets it streams; `main.sc` is
  its companion. Script commands surface into world/vehicle/ped/audio/text
  subsystems via opcodes.

## Animation, audio, text
- Animation: `anim\*.ifp/img` + `animgrp.dat`. Audio: banks (`SPC_*`, `GENRL`,
  `SCRIPT`, `FEET`, `PAIN_A`, `CUTSCENE`, ...) indexed by BankSlot/TrakLkup/
  StrmPaks. Text: `.gxt` keyed tables per locale, rendered via fonts.dat/txd.

## Binary pipeline (RenderWare)
- IMG archives -> DFF (geometry) + TXD (textures) + COL (collision). This
  pipeline is shared with the PS2/Android editions (see 06_PS5_STACK).
