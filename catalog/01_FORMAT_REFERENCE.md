# 01 FORMAT REFERENCE — EVERY FORMAT, ONE CRISP DEFINITION

Source: kb/01_TAXONOMY.md (P0/P1/P2 = read depth). Both GAME + SAMP use these.

## Text-code (P0 — fully readable)
| Format | File(s) | What it is |
|---|---|---|
| handling-cfg | data\handling.cfg | Vehicle physics table |
| carcols-dat | data\carcols.dat | Vehicle colours |
| cargrp-dat | data\cargrp.dat | Traffic spawn groups |
| carmods-dat | data\carmods.dat | Vehicle mod/tuning table |
| weapon-dat | data\weapon.dat | Weapon stats |
| ped-dat / pedstats-dat / pedgrp-dat | data\ped*.dat | Ped defs/stats/groups |
| popcycle-dat | data\popcycle.dat | Zone/time population |
| timecyc-dat | data\timecyc.dat, timecycp.dat | Weather/time lighting keyframes |
| water-dat | data\water.dat, water1.dat | Water levels |
| surface-dat | data\surface.dat, surfinfo.dat, surfaud.dat | Surface/ground types |
| gta-dat | data\gta.dat | MASTER data-file list (load order) |
| *.dat misc | clothes/furnitur/plants/procobj/polydensity/numplate/fonts/melee/animgrp/animviewer/gridref/shopping/ar_stats/statdisp/object/audio-events | subsystem config |
| ide | *.ide (vehicles/peds/default/txdcut + data\maps + SAMP) | Item-Definition: model-id registry |
| ipl | *.ipl (data\maps + SAMP) | Item-Placement: world instances |
| zon | data\info.zon, map.zon | Named zones |
| grp | data\Decision\*.grp | Ped decision groups |

## Binary assets (P1 — structural)
| Format | File(s) | What it is |
|---|---|---|
| img | gta3.img (940MB), gta_int.img, player.img, cutscene.img, script.img, SAMP.img, SAMPCOL.img, custom.img | IMG dir2 archive (DFF/TXD/COL entries) |
| dff | models\generic, models\grass | RenderWare geometry |
| txd | models\txd, models\*.txd, SAMP\samaps.txd | RenderWare texture dictionary |
| col | models\coll\*.col | Collision mesh |
| ifp | anim\ped.ifp | Animation keyframes |
| fxp | models\effects.fxp | Particle FX presets |

## Scripting / data containers (P1)
| Format | File(s) | What it is |
|---|---|---|
| scm | data\script\main.scm, data\main.sc | Compiled mission script (opcode stream) |
| saa | samp.saa | SAMP payload archive |
| gxt | text\american/french/german/italian/spanish.gxt | Localized text tables |

## Executables / libraries (P2 — fingerprint)
| Format | File(s) | What it is |
|---|---|---|
| exe | gta_sa.exe, samp.exe, samp_debug.exe, SAMPUninstall.exe, rcon.exe, hlm-intro.exe | Native PE (engine / SAMP client / tools) |
| dll | samp.dll, bass.dll, ogg.dll, vorbis*.dll, eax.dll, winmm.dll | Mod core + audio/effects libs |

## Media / misc (P2)
| Format | File(s) | What it is |
|---|---|---|
| audio-bank | audio\SPC_*, GENRL, SCRIPT, FEET, PAIN_A, CUTSCENE, ADVERTS, AMBIENCE + index .dat | Streamed audio banks + lookup tables |
| font | gtaweap3.ttf, sampaux3.ttf | Fonts |
| image | mouse.png, sampgui.png, data\Icons\*.ICN/ico | UI images/icons |
| video | movies\GTAtitles.mpg, Logo.mpg | Cutscene video |
| metadata | hoodlum.nfo, ReadMe, stream.ini | Release/config metadata |

## Trust note
Binary inner record layouts (DFF/TXD/COL/IFP/IMG/SAA/SCM/GXT) are documented
structurally; exact byte-level anatomy marked [UNVERIFIED] — verify against
RenderWare / GTAModding / SCM specs before deep byte work.
