# B-SAMP-OVERLAY
covers: S-0427..S-0434
domain: samp | type: bundle | path: SAMP\**
format: ide + ipl + img + txd | depth: P0/P1

## Role
The **SAMP world overlay** — the 8 files that give the multiplayer mod its own
world objects on top of the retail game:
- `SAMP.ide` (S-0431, deep-notated) object registry (SA:MP 0.3.7)
- `SAMP.ipl` (S-0433, deep-notated) placements + cull zones
- `SAMP.img` (S-0432, deep-notated) model payload (47 MB)
- `SAMPCOL.img` (S-0434) collision payload (3.3 MB)
- `samaps.txd` (S-0430) map textures (656 KB)
- `blanktex.txd` (S-0427) fallback texture
- User layer: `CUSTOM.ide` (S-0428) + `custom.img` (S-0429)

## Structure
- Identical grammar to the game: ide/ipl/img/txd (see kb/01_TAXONOMY.md). No
  private format - SAMP reuses the engine streaming pipeline verbatim.

## Relations
- B-S02 overlay; loaded/registered by samp.dll (S-0011) at runtime; overlays
  B-WORLD-DEFS/B-MODELPIPE (does not modify them - self-registers, see
  cross-domain rules in kb/02_BUNDLES.md).

## Annotations
- P0 for the ide/ipl (full read trivial -> complete SAMP object + cull list);
  P1 for the imgs (entry-table dump = SAMP asset inventory). Covered at bundle
  level here; individual deep notations exist for S-0431/32/33.
