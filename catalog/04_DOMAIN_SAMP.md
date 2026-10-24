# 04 DOMAIN SAMP — COMPREHENSION GUIDE

## Identity
San Andreas Multiplayer (SA-MP) — a client/server mod that turns the single-
player engine into a multiplayer world. Version surface observed: **SA:MP 0.3.7**
(per SAMP.ide header + wiki reference).

## Client boot
```
samp.exe (S-0012) -> launches gta_sa.exe and loads samp.dll (S-0011)
  samp.dll = the mod core: hooks the engine loop, runs the network client,
  draws SAMP UI (sampgui.png S-0015), loads payload samp.saa (S-0013),
  applies the world overlay, exposes admin via rcon.exe (S-0009).
```

## World overlay (the "codebase" part)
SAMP adds its own world objects WITHOUT touching game files (self-registration):
- `SAMP.ide` (S-0431): registers model ids (the object catalogue used by
  SA-MP server scripts, e.g. SetObjectModel).
- `SAMP.ipl` (S-0433): placements + cull zones for enterable buildings.
- `SAMP.img` (S-0432): DFF/TXD payload behind those ids.
- `SAMPCOL.img` (S-0434): collision for those objects.
- `samaps.txd` (S-0430): map textures; `blanktex.txd` (S-0427): fallback.
- User layer: `CUSTOM.ide` (S-0428) + `custom.img` (S-0429).
All reuse the game's exact formats (ide/ipl/img/txd) — see 01_FORMAT_REFERENCE.

## Network / payload surfaces (P2, [UNVERIFIED])
- Network protocol and packet layout: not documented here (would need packet
  capture/disassembly). Marked UNVERIFIED.
- `samp.saa` (S-0013): bundled payload archive consumed at startup; inner
  container layout UNVERIFIED.
- Hook/load mechanism of samp.dll into gta_sa.exe: UNVERIFIED at this depth.

## Data precedence
Game base first, SAMP overlay on top; SAMP never edits game files and never
extends the SCM (main.scm). Scripts are server-side; the client's "scripts"
surface is the payload (samp.saa) + UI.
