# B-ENGINE
covers: G-0001..G-0008, G-0018..G-0021
domain: game | type: bundle | path: install root (engine + libs)
format: exe + dll + config | depth: P2

## Role
The **engine boot chain** — the native binaries and libs that start the game:
`gta_sa.exe` (G-0004, 14 MB) is the engine bootstrap; `hlm-intro.exe` (G-0005)
the intro movie host; `winmm.dll` (G-0021) is a game-local audio shim (SDK
winmm facade), `bass.dll` (G-0001) audio playback, `ogg.dll` (G-0008) + `vorbis*`
(G-0019/20) streaming codecs, `eax.dll` (G-0002) environmental audio,
`stream.ini` (G-0018) streaming config, `gtaweap3.ttf` (G-0003) weapon font,
`mouse.png` (G-0007) cursor, `hoodlum.nfo` (G-0006) release metadata.

## Structure (P2 fingerprint)
- Native PE x86; sizes/hashes in inventory.json. 
- Boot: gta_sa.exe -> winmm/bass/ogg/vorbis/eax -> data loader (gta.dat G-0070)
  -> world streaming (IMGs). 
- Import/export surface and precise hook order [UNVERIFIED] without disasm.

## Relations
- SAMP depends on this chain: samp.exe (S-0012) launches gta_sa.exe + samp.dll
  (S-0011) hook. RCON/network ride the same process.

## Annotations
- Fingerprint depth (P2). The exact relationship gta_sa.exe <-> winmm.dll is a
  known modding vector but left at fingerprint level here.
