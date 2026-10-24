# B-DATA-CONFIG
covers: G-0057..G-0098
domain: game | type: bundle | path: data\ (root data definitions)
format: multi (text-config + ide + zon)

## Role
The engine's **boot-time configuration corpus** — 42 files at the data root.
Everything the engine needs before the world streams: vehicle physics
(handling.cfg G-0072, deep-notated separately), vehicle/weapon/ped tables,
weather/timecycle, water, surfaces, zones, and the item-definition tables
(vehicles.ide G-0095, peds.ide G-0081, default.ide G-0066, txdcut.ide G-0094).
Master loader `gta.dat` (G-0070, deep-notated separately) orders the world loads.

## Structure
- `.dat` records: line-oriented key=value or CSV-typed tables, `;` comments.
- `.ide` item definitions (vehicles/peds/objects) at data root.
- `.zon` zone records: `zone <name>, <type>, <x1,y1,z1>, <x2,y2,z2>, <level>, <gxtname>` (verified in info.zon G-0073).
- Key subsystems represented: B-G05 vehicles (handling/carcols/cargrp/carmods/
  weapon/numplate/melee/vehicles.ide), B-G06 peds (ped/pedgrp/pedstats/popcycle/
  peds.ide), B-G08 weather/water (timecyc/timecycp/water/water1),
  B-G09 surfaces (surface/surfinfo/surfaud), B-G11 loader (gta/gta_quick/default),
  B-G12 fonts/clothes, and misc (ar_stats/statdisp/shopping/plants/procobj/
  polydensity/gridref/furnitur/animgrp/animviewer/AudioEvents/object).

## Relations
- Feeds every runtime subsystem named in kb/01_TAXONOMY.md section A.
- G-0070 gta.dat and G-0072 handling.cfg have individual deep notations.

## Annotations
- G-0074 `data\main.sc` (script stub) sits in this range — mission-script
  companion to main.scm (G-0329).
- Zone names (SUNMA/SUNNN/BATTP/PARA/CIVI...) are the canonical city names used
  by SAMP server scripts too.
