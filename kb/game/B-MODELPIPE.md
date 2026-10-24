# B-MODELPIPE
covers: G-0331..G-0423
domain: game | type: bundle | path: models\** (archives + geometry + textures + collision)
format: img + dff + txd + col + fxp | depth: P1

## Role
The **model pipeline** — everything that becomes a rendered/collidable asset:
- Archives: `cutscene.img` (G-0331), `gta3.img` (G-0339, deep-notated),
  `gta_int.img` (G-0340, interiors), `player.img` (G-0345)
- Collision: `models\coll\peds.col` (G-0346), `vehicles.col` (G-0347),
  `weapons.col` (G-0348)
- Geometry: `models\generic\*.dff` + `models\grass\*.dff` (G-0349..G-0373;
  generic objects + grass meshes)
- Textures: root TXDs `effectsPC/fonts/fronten*/hud/misc/particle/pcbtns.txd`
  (G-0333..G-0344) + `models\txd\*.txd` per-region/per-set (G-0374..G-0423)
- Effects: `models\effects.fxp` (G-0332) particle preset pack

## Structure
- `.img`: IMG dir2 archives (see G-0339) holding DFF/TXD/COL entries.
- `.dff`: RenderWare geometry (frame hierarchy, geometry lists, materials).
- `.txd`: RenderWare texture dictionaries (DXT formats).
- `.col`: collision meshes (bounding boxes + face data).
- All binary; P1 structural. Full decode needs RenderWare/IMG specs (GTAModding,
  open-source reVC/RE3) - out of scope for raw byte dumping.

## Relations
- B-G01/B-G02/B-G03 world+interior+player archives; named by IDE (B-WORLD-DEFS,
  B-DATA-CONFIG); collided per B-G09.
- SAMP reuses the identical pipeline via its own IMGs (S-0432/S-0434).

## Annotations
- High-value Phase 2 task: dump IMG entry tables (name+offset+size) for each
  archive -> complete asset inventory of the game. Covered at bundle level here.
