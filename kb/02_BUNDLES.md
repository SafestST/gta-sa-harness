# 02 BUNDLES — LOGICAL SYSTEMS OF THE CODEBASE

Monolith: GTA-SA-Harness · Phase 1 · Bundles group the 439 entities into the
coherent systems an LLM must model. Entity ids live in `kb/00_INDEX.md`
(regenerated); bundles reference paths (G-####/S-#### ids resolvable via index).

---

## GAME DOMAIN

### B-G01 WORLD MODEL ARCHIVE (the city)
- `models\gta3.img` (940 MB, the single largest entity) + the .ide/.ipl under
  `data\maps\LA`, `data\maps\SF`, `data\maps\vegas`, `data\maps\country`
- Rule: IDE registers model ids; IPL instantiates them; IMG stores the geometry.
  `data\gta.dat` (B-G11) dictates load order.

### B-G02 INTERIORS
- `models\gta_int.img` + `data\maps\interior\*.ipl/.ide` + `data\furnitur.dat`

### B-G03 PLAYER / CUTSCENE
- `models\player.img`, `models\cutscene.img`, `anim\cuts.img`,
  `movies\GTAtitles.mpg`, `movies\Logo.mpg`

### B-G04 MISSION SCRIPT SYSTEM
- `data\script\main.scm` (3.1 MB, compiled SCM), `data\script\script.img`,
  `data\main.sc` (secondary/script stub)

### B-G05 VEHICLE SYSTEM
- `data\handling.cfg`, `carcols.dat`, `carmods.dat`, `cargrp.dat`,
  `vehicles.ide`, `numplate.dat`, `melee.dat`, `weapon.dat`

### B-G06 PED / AI SYSTEM
- `data\ped.dat`, `pedgrp.dat`, `pedstats.dat`, `popcycle.dat`, `peds.ide`,
  `data\Decision\**` (incl. Allowed\*, *.grp)

### B-G07 WORLD META (zones / paths / occlusion)
- `data\info.zon`, `data\map.zon`, `data\maps\paths*.ipl` (node network),
  `data\Paths\NODES*.DAT` + `carrec.img`, `cull.ipl`, `occlu*.ipl`,
  `Audiozon.ipl`, `tunnels.ipl`

### B-G08 WEATHER / TIME / WATER
- `data\timecyc.dat`, `timecycp.dat`, `water.dat`, `water1.dat`

### B-G09 SURFACE / COLLISION
- `data\surface.dat`, `surfinfo.dat`, `surfaud.dat`, `models\coll\*.col`

### B-G10 ANIMATION
- `anim\anim.img`, `anim\ped.ifp`, `data\animgrp.dat`, `animviewer.dat`

### B-G11 DATA LOADER (master list)
- `data\gta.dat`, `gta_quick.dat`, `default.dat` — the ordered list of IDE/IPL
  loads; the spine of the whole data pipeline.

### B-G12 TEXTURE / UI
- `models\txd\**`, `models\*.txd`, `fonts.txd`, `hud.txd`, `misc.txd`,
  `particle.txd`, `pcbtns.txd`, `fronten*.txd`, `data\fonts.dat`,
  `data\Icons\*.ICN`

### B-G13 AUDIO SYSTEM
- `audio\SPC_*` radio banks + `GENRL`, `SCRIPT`, `FEET`, `PAIN_A`, `CUTSCENE`,
  `ADVERTS`, `AMBIENCE` + index tables `BankSlot.dat`, `BankLkup.dat`,
  `TrakLkup.dat`, `StrmPaks.dat`, `PakFiles.dat`, `EventVol.dat`,
  `data\AudioEvents.txt`

### B-G14 LOCALIZATION
- `text\american.gxt` (+ fr/de/it/es)

### B-G15 ENGINE / BOOT CHAIN
- `gta_sa.exe` -> loads `winmm.dll`, `bass.dll`, `ogg.dll`, `vorbis*.dll`,
  `eax.dll` -> data loader (gta.dat) -> world streaming (IMGs)

### B-G16 EFFECTS
- `models\effects.fxp`, `particle.txd`

---

## SAMP DOMAIN

### B-S01 SAMP CLIENT (launcher + core)
- `samp.exe` (launcher), `samp.dll` (the mod core hooked into gta_sa.exe),
  `samp_debug.exe`, `samp-license.txt`, `sampaux3.ttf`, `sampgui.png`,
  `SAMPUninstall.exe`
- Chain: `samp.exe` launches `gta_sa.exe` + injects/hooks `samp.dll`.

### B-S02 SAMP WORLD OVERLAY
- `SAMP\SAMP.ide` + `SAMP\SAMP.ipl` register/place SAMP objects;
  `SAMP\SAMP.img` (47 MB) holds their DFF/TXD; `SAMP\SAMPCOL.img` their
  collision; `SAMP\samaps.txd` map textures; `SAMP\blanktex.txd` fallback.
- User custom layer: `SAMP\CUSTOM.ide` + `SAMP\custom.img`.

### B-S03 SAMP PAYLOAD / ADMIN
- `samp.saa` (2.7 MB, bundled payload consumed by samp.dll), `rcon.exe`
  (remote console client for server administration).

---

## CROSS-DOMAIN COUPLING (the "how it fits" rules an LLM must know)
1. `data\gta.dat` does NOT reference SAMP files — SAMP self-registers at
   runtime via samp.dll + its own IDE/IPL/IMG set. World data precedence:
   game base first, SAMP overlay on top.
2. SAMP reuses game formats (`ide`, `ipl`, `img`, `txd`) — the taxonomy in
   `kb/01_TAXONOMY.md` covers both domains identically.
3. The mission script (`main.scm`) is orthogonal to SAMP: SAMP does not extend
   SCM; it hooks the engine (samp.dll) and runs its own payload (samp.saa).
