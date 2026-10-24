# 05 LLM QUICKSTART — FASTEST PATH TO FLUENCY

## Read in this order (≈5 min)
1. `README.md` — what the catalogue is, trust levels (P0/P1/P2).
2. `00_SYSTEM_MAP.md` — boot chain + subsystems + SAMP hook (the mental model).
3. `01_FORMAT_REFERENCE.md` — the format lexicon (29 formats).
4. `04_DOMAIN_SAMP.md` — SAMP is a thin overlay on the game; don't over-model it.
5. `03_DOMAIN_GAME.md` — world/vehicle/ped/script/audio/text subsystems.

## The three laws of this codebase
1. **gta.dat is law.** It fixes IMG->IDE->IPL load order. Reason about any
   world fact from it.
2. **IDE + IPL + IMG must agree.** IDE registers the id, IPL places it, IMG
   holds the geometry. All three named the same model or it won't render.
3. **SAMP self-registers.** It never edits game files, never extends SCM; it
   overlays via its own SAMP.ide/ipl/img and its payload samp.saa.

## Gotchas
- SAMP.ide ids = the object ids in SA-MP server scripts (SetObjectModel etc.).
- `gta.dat` lists only *additional* IMGs; the big three (gta3/gta_int/player)
  are engine auto-loads.
- Binary formats (DFF/TXD/COL/IMG/IFP/SAA/SCM/GXT): we hold structure, not byte
  dumps. Anything byte-level is [UNVERIFIED] — verify vs RenderWare/GTAModding/
  SCM specs before acting.
- Audio banks and the node network (NODES*.DAT) are binary; treat at fingerprint
  depth unless deep-decode is authorised.
- `main.scm` is compiled SCM — semantic opcode meaning needs an SCM toolchain.

## Where things live
- Registry: `../kb/00_INDEX.md` (id -> path/size/category; SHA256 in ../state/inventory.json)
- Deep notations: `../kb/game/` + `../kb/samp/`
- Bundles: `../kb/02_BUNDLES.md`
- Emulation/PS5 research: `06_PS5_STACK.md` + `../kb/research/PS5-EMULATION.md`
