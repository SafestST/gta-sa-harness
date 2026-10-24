# 01 TAXONOMY — CANONICAL FORMAT CATALOGUE (GAME + SAMP)

Monolith: GTA-SA-Harness · Phase 1 · Source of truth: `state/inventory.json` (439 entities).
Two domains: **GAME** (422) and **SAMP** (17). Every format below is grounded in
actual inventory categories/files. Depth codes: **P0** = fully readable text,
**P1** = binary structural, **P2** = fingerprint only.

---

## A. TEXT-CODE (118 entities) — the readable "program" of the game

These ARE the highest-leverage knowledge: they configure engine subsystems at load.

| Format id | Files (real) | What it is | Consumer subsystem | Read path |
|---|---|---|---|---|
| `handling-cfg` | data\handling.cfg | Per-vehicle physics (mass, engine, grip, suspension) | CGame::cHandlingDataMgr | P0 full text |
| `carcols-dat` | data\carcols.dat | Vehicle colour definitions & palettes | CVehicleModelInfo | P0 |
| `cargrp-dat` | data\cargrp.dat | Traffic spawn groups | Traffic | P0 |
| `carmods-dat` | data\carmods.dat | Vehicle tuning/mod kit table | Mod shop | P0 |
| `weapon-dat` | data\weapon.dat | Weapon stats (damage, range, fire rate) | CWeaponInfo | P0 |
| `ped-dat` | data\ped.dat | Ped model / behaviour definitions | CPed | P0 |
| `pedstats-dat` | data\pedstats.dat | Ped attribute stats | CPedStats | P0 |
| `pedgrp-dat` | data\pedgrp.dat | Ped population groups | Ped population | P0 |
| `popcycle-dat` | data\popcycle.dat | Zone/time population rules | CPopulation | P0 |
| `timecyc-dat`|`timecycp-dat` | data\timecyc.dat / timecycp.dat | Weather/time lighting keyframes | CTimeCycle | P0 |
| `water-dat`|`water1-dat` | data\water.dat, water1.dat | Water level/geometry data | CWater | P0 |
| `surface-dat`|`surfinfo-dat` | data\surface.dat, surfinfo.dat | Surface/ground-type table | CCollision | P0 |
| `gta-dat` | data\gta.dat | **Master data file list** (order = load order of IDE/IPL) | Loader | P0 (critical) |
| `gta-quick-dat` | data\gta_quick.dat | Quick/non-strict load list | Loader | P0 |
| `default-dat` | data\default.dat | Defaults/fallbacks | Loader | P0 |
| `clothes-dat` | data\clothes.dat | Clothing items | Clothes | P0 |
| `furnitur-dat` | data\furnitur.dat | Interior furniture defs | Interiors | P0 |
| `plants-dat` | data\plants.dat | Vegetation placement | CPlantMgr | P0 |
| `procobj-dat` | data\procobj.dat | Procedural object rules | Procedural objects | P0 |
| `polydensity-dat` | data\polydensity.dat | Per-zone model density | LOD/streaming | P0 |
| `numplate-dat` | data\numplate.dat | Number plate templates | Vehicles | P0 |
| `fonts-dat` | data\fonts.dat | Font map | Text/font | P0 |
| `melee-dat` | data\melee.dat | Melee weapon behaviour | Melee | P0 |
| `animgrp-dat` | data\animgrp.dat | Animation group table | CAnimManager | P0 |
| `animviewer-dat` | data\animviewer.dat | Anim viewer list | Debug | P0 |
| `gridref-dat` | data\gridref.dat | Grid reference | Streaming | P0 |
| `shopping-dat` | data\shopping.dat | Shops/inventory | Shopping | P0 |
| `ar-stats-dat` | data\ar_stats.dat | Arrest/ratio stats | Stats | P0 |
| `statdisp-dat` | data\statdisp.dat | Stats display order | Stats | P0 |
| `surfaud-dat` | data\surfaud.dat | Surface-audio pairing | Audio | P0 |
| `object-dat` | data\object.dat | Object default flags | CObject | P0 |
| `audio-events-txt` | data\AudioEvents.txt, data\AudioEventHistory.txt | Audio event definitions | Audio | P0 |
| `samp-license-txt` | samp-license.txt | SAMP EULA text | SAMP | P0 |

## B. WORLD-DATA (160 entities) — the level "code"

| Format id | Files (real) | What it is | Consumer | Read path |
|---|---|---|---|---|
| `ide` | peds.ide, vehicles.ide, default.ide, txdcut.ide, data\maps\*\*.ide, **SAMP\SAMP.ide (89 KB), SAMP\CUSTOM.ide** | **Item Definition**: model ID registry -> model names, txd, LOD, flags (the linker between world refs and assets) | CModelInfo | P0 |
| `ipl` | data\maps\**\*.ipl: LA/SF/vegas/country/interior/generic/leveldes/veh_mods + paths.ipl, paths2-5.ipl, cull.ipl, occlu*.ipl, tunnels.ipl, Audiozon.ipl, **SAMP\SAMP.ipl** | **Item Placement**: instantiates IDE items at coords/rot with LOD linkage | CTheZones / IPL loader | P0 |
| `zon` | data\info.zon, data\map.zon | Named zones (cities, interiors, gang turfs) | CTheZones | P0 |
| `grp` | data\Decision\*.grp (+Allowed) | Ped decision/response groups | Decision maker | P0 |

## C. BINARY ASSETS (P1 structural) — model pipeline

| Format id | Files (real) | What it is | Consumer | Read path |
|---|---|---|---|---|
| `img` | models\gta3.img (940 MB), gta_int.img, player.img, cutscene.img, data\script\script.img, **SAMP\SAMP.img (47 MB), SAMPCOL.img, SAMP\custom.img** | IMG archive container (directory of DFF/TXD/COL entries, dir2 format) | Streaming loader | P1: list entry table + sizes; entries binary |
| `dff` | models\generic\**, models\grass\**, SAMP inside .img | RenderWare geometry (frame hierarchy, geometry, material splits) | CModelInfo / RWS | P1 |
| `txd` | models\txd\** (50), models\*.txd, SAMP\samaps.txd, SAMP\blanktex.txd | RenderWare texture dictionary (DXT textures) | RWS | P1 |
| `col` | models\coll\*.col (3) | Collision mesh + level-of-collision | CCollision | P1 |
| `ifp` | anim\ped.ifp, anim\anim.img, anim\cuts.img | IFP animation archives (compressed keyframes) | CAnimManager | P1 |
| `fxp` | models\effects.fxp | Particle FX preset pack | Particle system | P1 |

## D. SCRIPTING (the mission/code layer)

| Format id | Files (real) | What it is | Consumer | Read path |
|---|---|---|---|---|
| `scm` | data\script\main.scm (3.1 MB), data\main.sc | Compiled SCM: the game's own program (missions, threads, custom scripts). Opcode stream + jump table + header (size/var counts). Full semantic decompile needs an SCM toolchain (e.g. Sanny Builder / CLEO disasm) - NOT built into harness | CTheScripts | P1: header, opcode surface, string/global tables; opcode semantics `[UNVERIFIED]` without tool |
| `saa` | samp.saa (2.7 MB) | SAMP's archive (payload loaded by samp.dll at startup) | SAMP (samp.dll) | P1: container; inner semantics `[UNVERIFIED]` |

## E. TEXT TABLES

| Format id | Files (real) | What it is | Consumer | Read path |
|---|---|---|---|---|
| `gxt` | text\american/french/german/italian/spanish.gxt | Keyed text tables (UI, subtitles) per locale | CText | P1: key+string extraction |

## F. EXECUTABLES / LIBRARIES (P2 fingerprint)

| Format id | Files (real) | What it is | Consumer | Read path |
|---|---|---|---|---|
| `exe` | gta_sa.exe (14 MB), samp.exe, samp_debug.exe, SAMPUninstall.exe, rcon.exe, hlm-intro.exe | Native PE binaries; gta_sa.exe = engine bootstrap, samp*.exe = multiplayer client launcher/core | - | P2: size/hash/imports/strings only |
| `dll` | samp.dll (1.2 MB), bass.dll, ogg.dll, vorbis.dll, vorbisFile.dll, eax.dll, winmm.dll | samp.dll = the SAMP mod core loaded into gta_sa.exe; rest = audio/effects libs | gta_sa.exe | P2 |

## G. MEDIA / MISC (P2)

| Format id | Files (real) | What it is | Read path |
|---|---|---|---|
| `audio-bank` | audio\SPC_* (radio: AA..TK), GENRL, SCRIPT (320 MB), FEET, PAIN_A, CUTSCENE, ADVERTS, AMBIENCE + BankSlot.dat/BankLkup.dat/TrakLkup.dat/StrmPaks.dat/PakFiles.dat/EventVol.dat | Streamed audio banks + their index/lookup tables | P2 |
| `font` | gtaweap3.ttf, sampaux3.ttf | Fonts | P2 |
| `image` | mouse.png, sampgui.png, data\Icons\*.ICN (3) | UI images/icons | P2 |
| `video` | movies\GTAtitles.mpg, movies\Logo.mpg | Intro/cutscene video | P2 |
| `metadata` | hoodlum.nfo, stream.ini, samp.saa? | Release/misc metadata | P2 |

---

## SAMP OVERLAY RULE (cross-domain)
SAMP does NOT replace the game's world; it **augments** it at load time:
- `SAMP\SAMP.ide` (S-0431) + `SAMP\SAMP.ipl` (S-0433) register SAMP-only world
  objects; `SAMP\SAMP.img` (S-0429) holds their DFF/TXD payload; `SAMPCOL.img`
  (S-0434) their collision; `samaps.txd` (S-0430) map textures; `CUSTOM.ide`/`custom.img`
  (S-0428/29) are the user-custom overlay.
- `samp.dll` (S-0011) is the network client that hooks the game loop; `samp.saa`
  (S-0013) is its bundled payload. RCON (`rcon.exe`, S-0009) is the server-command tool.

The full catalogue of these bundles is in `kb/02_BUNDLES.md`.
