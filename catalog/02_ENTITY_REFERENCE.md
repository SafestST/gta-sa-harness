# 02 ENTITY REFERENCE — BUNDLES + NOTABLE ENTITIES

Full registry: `../kb/00_INDEX.md` (439 ids, paths, sizes, categories).
Deep notations: `../kb/game/*.md`, `../kb/samp/*.md`. Bundles below.

## GAME bundles
| Bundle | Covers | System |
|---|---|---|
| B-ENGINE | G-0001..0008, G-0018..0021 | gta_sa.exe + libs + boot chain |
| B-ANIM | G-0022..0024 | anim.img/cuts.img/ped.ifp |
| B-AUDIO | G-0025..0056 | radio + speech banks + index tables |
| B-DATA-CONFIG | G-0057..0098 | data-root config corpus (+ zones, vehicles.ide, main.sc) |
| B-DECISION | G-0099..0142 | ped decision-maker |
| B-MEDIA | G-0143..0147, G-0424..0426 | icons, movies, ReadMe |
| B-WORLD-DEFS | G-0148..0255 | data\maps IDE+IPL (LA/SF/Vegas/country/interior/generic + paths/cull/occlu) |
| B-PATHS | G-0256..0328 | node network NODES*.DAT + carrec.img |
| B-SCRIPT | G-0074, G-0329, G-0330 | main.scm + script.img + main.sc (mission system) |
| B-MODELPIPE | G-0331..0423 | gta3/gta_int/player/cutscene IMGs, DFF, TXD, COL, effects.fxp |
| B-TEXT | G-0435..0439 | 5 localized .gxt |

## Notable GAME entities (deep-notated)
| Id | Path | What it is |
|---|---|---|
| G-0070 | data\gta.dat | Master data loader (IMG/IDE/IPL order) |
| G-0072 | data\handling.cfg | Vehicle physics |
| G-0329 | data\script\main.scm | Mission script (3.1 MB, SCM) |
| G-0339 | models\gta3.img | World model archive (940 MB) |

## SAMP bundles
| Bundle | Covers | System |
|---|---|---|
| B-SAMP-CLIENT | S-0009..0017 | samp.exe/samp.dll/samp_debug/samp.saa/rcon/license/font/gui/uninstaller |
| B-SAMP-OVERLAY | S-0427..0434 | SAMP.ide/ipl/img/SAMPCOL.img/samaps.txd/blanktex + CUSTOM.ide/custom.img |

## Notable SAMP entities (deep-notated)
| Id | Path | What it is |
|---|---|---|
| S-0011 | samp.dll | The mod core (network client hook) |
| S-0013 | samp.saa | SAMP payload archive (2.7 MB) |
| S-0431 | SAMP\SAMP.ide | SAMP object registry (SA:MP 0.3.7, 2069 lines) |
| S-0432 | SAMP\SAMP.img | SAMP world model archive (47 MB) |
| S-0433 | SAMP\SAMP.ipl | SAMP placements + cull zones |

## Research
- kb/research/PS5-EMULATION.md — emulation on PS5 / applicable stack (see catalog/06_PS5_STACK.md).
