# B-SAMP-CLIENT
covers: S-0009..S-0017
domain: samp | type: bundle | path: install root (SAMP artifacts)
format: exe + dll + saa + font + image | depth: P2

## Role
The **SAMP client surface** — every SAMP artifact at the install root:
- `samp.exe` (S-0012) launcher -> starts gta_sa.exe and loads the mod
- `samp.dll` (S-0011, deep-notated) the mod core hook
- `samp_debug.exe` (S-0017) debug build of the launcher
- `samp.saa` (S-0013, deep-notated) bundled payload archive
- `rcon.exe` (S-0009) remote-console admin tool
- `samp-license.txt` (S-0010) EULA; `sampaux3.ttf` (S-0014) font;
  `sampgui.png` (S-0015) UI graphic; `SAMPUninstall.exe` (S-0016) uninstaller

## Structure (P2)
- Sizes/hashes in inventory.json. Boot: samp.exe -> gta_sa.exe + samp.dll ->
  loads samp.saa -> network client (RCON surface via rcon.exe).
- Exact hook/injection mechanism [UNVERIFIED] without disassembly.

## Relations
- B-S01 client; feeds B-S02 overlay (registers SAMP.ide/img/ipl via samp.dll).
- Sits atop the game engine chain (B-ENGINE).

## Annotations
- Fingerprint depth; network protocol + hooking are the two open surfaces for
  future deep analysis (marked UNVERIFIED).
