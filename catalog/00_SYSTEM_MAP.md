# 00 SYSTEM MAP — THE CODEBASE AS A SYSTEM

## Boot chain (GAME)
```
gta_sa.exe (G-0004)
  -> libs: winmm.dll (audio shim), bass.dll, ogg.dll, vorbis*.dll, eax.dll (G-0001..21)
  -> data loader: data\gta.dat (G-0070)  [IMG -> IDE -> IPL, in order]
     IMG: gta3.img (world), gta_int.img (interiors), player.img, cutscene.img,
          data\script\script.img, data\Paths\carrec.img
     IDE: peds/vehicles/default/txdcut + data\maps\**\.ide
     IPL: data\maps\**\.ipl (LA/SF/Vegas/country/interior/generic/leveldes + paths/occlu/cull)
  -> runtime config: data\*.dat/cfg (handling, carcols, ped, popcycle, timecyc, water, surface...)
  -> mission script: data\script\main.scm (G-0329) + data\main.sc (G-0074)
  -> streaming: IMG archives -> DFF/TXD/COL (models\**) on demand
```

## Subsystems (who consumes what)
| Subsystem | Consumes | Notes |
|---|---|---|
| World building | IDE + IPL + IMG (DFF/TXD) | gta.dat load order is law |
| Vehicles | handling.cfg, carcols.dat, carmods.dat, cargrp.dat, vehicles.ide, weapon.dat, numplate.dat | B-G05 |
| Ped / AI | ped.dat, pedstats.dat, pedgrp.dat, popcycle.dat, peds.ide, data\Decision\** | B-G06 |
| Navigation | data\Paths\NODES*.DAT, carrec.img, maps\paths*.ipl | B-PATHS |
| Weather/time | timecyc.dat, timecycp.dat, water.dat, water1.dat | B-G08 |
| Collision | surface.dat, surfinfo.dat, surfaud.dat, models\coll\*.col | B-G09 |
| Animation | anim\*.ifp/img, animgrp.dat | B-G10 |
| Text/UI | text\*.gxt, fonts.dat, fonts.txd, hud.txd, data\Icons | B-TEXT |
| Audio | audio\SPC_*/banks + BankSlot/TrakLkup/StrmPaks index tables | B-AUDIO |
| Mission/scripts | main.scm, script.img, main.sc | B-G04 |

## SAMP overlay (how the mod plugs in)
```
samp.exe (S-0012) -> launches gta_sa.exe + loads samp.dll (S-0011)
  -> samp.dll consumes samp.saa (S-0013) payload
  -> registers SAMP world overlay (NOT via gta.dat):
       SAMP.ide (S-0431) ids + SAMP.ipl (S-0433) placements
       + SAMP.img (S-0432) models + SAMPCOL.img (S-0434) collision
       + samaps.txd (S-0430) textures + blanktex.txd (S-0427) fallback
       + user layer CUSTOM.ide (S-0428) + custom.img (S-0429)
  -> network client + RCON admin surface (rcon.exe S-0009)
```
Key rule: SAMP **self-registers** at runtime; it never edits game files and
never extends the SCM. It reuses game formats verbatim.

## Cross-cutting facts an LLM must know
1. `gta.dat` references only *additional* IMGs; gta3.img/gta_int.img/player.img
   are engine auto-loads.
2. IDE = model-id registry (the linker); IPL = placement; IMG = geometry. The
   three must agree for a model to render.
3. SAMP.ide ids are the object ids used by SA-MP server scripts.
4. World data precedence: game base first, SAMP overlay on top, per-bundle
   (see kb/02_BUNDLES.md).
