# B-TEXT
covers: G-0435..G-0439
domain: game | type: bundle | path: text\*.gxt
format: gxt | depth: P1

## Role
**Localized text tables** — 5 files (american, french, german, italian,
spanish), ~740-815 KB each. Supply every UI string, mission subtitle and
message key in the game. The `american.gxt` is the canonical/English base;
SAMP and CLEO scripts reference the same keys.

## Structure
- `.gxt`: keyed table (16-bit key index -> string block), two-block layout
  (table of keys + data of strings). Exact record layout [UNVERIFIED] without
  gxt spec; extraction of keys+strings is straightforward (P1).

## Relations
- Consumed by CText at runtime; keys referenced by main.scm (G-0329), UI, and
  SAMP client strings.
- fonts.dat G-0067 / fonts.txd G-0334 render these strings.

## Annotations
- High-value P1 task: dump american.gxt key list = the game's entire text
  surface (usable by mods/SAMP localisation).
