# 07 PS5 EXECUTION — CONVERTING THE CATALOGUED FILES INTO A PS5-EXECUTABLE FORM

Full research notes: `../kb/research/RELAPSE-ARCHITECTURE.md` (the exploit
chain) and `../kb/research/PS5-EMULATION.md` (the landscape). This document is
the **conversion architecture**: what the PlayStation can execute, and how the
439 catalogued GAME+SAMP entities (4.74 GB) map onto it.

## 0. The execution surface (what "PS5-executable" means)
After Relapse on firmware 13.6, the console runs **plain FreeBSD/Orbis x86-64
ELF payloads**: elfldr listens on **TCP 9021** and executes whatever ELF is
pushed to it; kernel r/w + JIT shared memory also allow PROT_RWX mapping
directly. There is **no Windows PE loader and no Sony signing** involved.

Consequence, stated plainly and honestly:
- **Windows PE binaries in this catalogue cannot be run as-is.** `gta_sa.exe`
  (G-0004, x86 PE) and `samp.dll` (S-0011, x86 PE DLL) are 32-bit Windows
  images; the PS5's execution surface is FreeBSD x86-64 ELF.
- **The data files are the portable part.** IMG/DFF/TXD/COL/IDE/IPL/SCM/GXT/
  DAT are **format-compatible across the PS2/PC/Android editions** of GTA SA
  (RenderWare). These carry over to a PS5-hosted build with repackaging, not
  translation.

So the conversion is: **build a FreeBSD x86-64 ELF runtime that consumes the
catalogued data, then feed it the data.** The exploit gets the runtime on the
console; the harness's job is the runtime + data assembly.

## 1. Three candidate runtimes (and the honest feasibility)
| Runtime | What it is | How data is used | Feasibility on PS5 13.6 |
|---|---|---|---|
| **A. Native engine reimplementation** (recommended) | Recompile an open GTA-SA engine reimplementation (e.g. re3/reVC lineage, OpenSA) to a FreeBSD x86-64 ELF; add an SA-MP client reimplementation (open.mp) | Consumes the catalogue's PC data almost verbatim (same formats) | **Highest.** No Windows API needed; data formats already match. Engine + client must be built for Orbis. |
| **B. PS2 edition under an emulator** | Run the PS2 build of SA inside a PCSX2-derived homebrew (already reported running on jailbroken PS5) | Requires the **PS2-edition delta** data (not the PC files); formats shared (DFF/TXD/COL/IMG/IDE/IPL/SCM/GXT) so catalogue knowledge transfers | Medium. Runs console titles, not our PC files. No SAMP (SAMP is PC-only). |
| **C. Windows x86 PE emulation (Wine-on-Orbis)** | Run the original Windows binaries under a translation/compat layer | Would run G-0004 + S-0011 untouched | **Lowest.** No maintained Wine/PE-loader for Orbis; 32-bit x86 on 64-bit FreeBSD adds WoW64 complexity. Not a viable near-term path. |

**Recommendation: Path A** — it is the only path where *the files we have*
(PC-edition data + SAMP overlay) are the input, and it matches the format
leverage already catalogued.

## 2. What converts, and how (mapping the 439 entities)
### 2.1 Carries over as-is (data, ~95% of the catalogue by intent)
These are consumed by the engine **byte-for-byte** (or with container repack):
- **World data**: `data\maps\**\*.ide / *.ipl`, `data\gta.dat` (load-order
  list), `data\info.zon`, `map.zon` — engine reads these directly.
- **Runtime config**: `data\*.dat/cfg` (handling, carcols, ped, popcycle,
  timecyc, water, surface, weapon, carmods, cargrp, numplate, fonts, etc.).
- **Models/textures/collision**: `gta3.img`, `gta_int.img`, `player.img`,
  `cutscene.img`, `data\script\script.img`, `data\Paths\carrec.img`,
  `models\**\*.dff`, `models\*.txd`, `models\coll\*.col`, `models\effects.fxp`.
- **Scripting/text**: `data\script\main.scm`, `data\main.sc`, `text\*.gxt`.
- **Animation**: `anim\*.ifp`, `anim\*.img`, `animgrp.dat`.
- **SAMP overlay**: `SAMP\SAMP.ide/.ipl/.img`, `SAMPCOL.img`, `samaps.txd`,
  `blanktex.txd`, `CUSTOM.ide`, `custom.img` — same formats, loaded by the
  reimplemented client exactly as samp.dll loads them today.

### 2.2 Must be recompiled / rebuilt (binaries)
- **Engine**: nothing to salvage from `gta_sa.exe` — the runtime is a fresh
  FreeBSD x86-64 build of the reimplementation.
- **SAMP core**: `samp.dll` (S-0011) is a Windows x86 PE DLL. Its **protocol
  surface is what matters** (SA-MP 0.3.7 network client, RCON). Reimplemented
  by an open SAMP-client project (open.mp / reimpl); the catalogue keeps the
  overlay data (SAMP.ide/img/ipl) and UI assets (sampgui.png S-0015,
  sampaux3.ttf S-0014) which carry over.
- **Launcher/tools**: `samp.exe` (S-0012), `samp_debug.exe` (S-0017),
  `rcon.exe` (S-0009), `SAMPUninstall.exe` (S-0016), `hlm-intro.exe` (G-0005)
  — Windows-only; not needed on PS5 (replaced by the ELF launcher / in-payload
  UI). `samp.saa` (S-0013) inner layout is [UNVERIFIED]; if it is a plain
  asset archive its entries join the data pack.

### 2.3 Media that may need container work
- **Audio**: `audio\SPC_*` banks + BankSlot/TrakLkup/StrmPaks index tables are
  console-era streaming formats the engine reimplementation must decode; if the
  reimplementation uses its own audio backend, transcode to that backend's
  container. Keep the original files for provenance.
- **Video**: `movies\*.mpg` (MPEG-1/2 cutscenes) — PS5 (FreeBSD) can decode;
  may need container remux only.
- **Fonts/images**: `.ttf` (G-0003, S-0014), `.png` (mouse, sampgui),
  `data\Icons\*` — carry over.

## 3. The conversion pipeline (build, on the PC, in the harness)
```
Stage 0  TARGET DEFINITION  (this doc) — done.
Stage 1  RUNTIME BUILD       build the engine reimplementation + SAMP client
                             reimplementation for FreeBSD x86-64 -> one or more
                             Orbis ELF payloads (this is a cross-compile /
                             port job; the engine's own build system targets
                             Linux/mac/Win; FreeBSD is the new target).
Stage 2  DATA PACK           assemble a payload bundle (ELF + data dir):
                             copy GAME+SAMP data per the load-order in
                             catalog/00_SYSTEM_MAP.md (gta.dat chain, IMG set,
                             SAMP overlay last). Checksum with the SHA256s in
                             state/inventory.json to prove integrity.
Stage 3  TRANSFER            host the payload over HTTP (serve.py pattern) or
                             serve via the elfldr port.
Stage 4  EXECUTE on console  push ELF to port 9021 (or kexp-style JIT map);
                             verify boot to menu, then SAMP connect test.
Stage 5  VERIFY              run the harness coverage/ notation gates against
                             the built payload's manifest.
```
Each stage produces an artifact the harness can inventory (new entity domain
`PS5-BUILD` or a `catalog/07` annex manifest), keeping the monolith's
auditability.

## 4. SAMP-specific conversion notes
- SAMP is **client + server**. The **server** side (SA-MP server / open.mp
  server) is not in this catalogue and runs on any x86-64 host — the PS5 does
  not need it; the PS5 only needs the **client**.
- The client needs: the engine (Path A), the network client logic (reimpl),
  the overlay data (carries over), and UI assets (carries over). The SA-MP
  0.3.7 protocol surface is the main reverse/reimplementation target; the
  catalogue's SAMP notations (S-0011, S-0013, B-SAMP-CLIENT, B-SAMP-OVERLAY)
  document exactly the files that must load.
- PS5 network on jailbroken firmware works for LAN/private-server play;
  public-server/PSN access is a separate concern (ban risk — out of scope,
  see PS5-EMULATION.md).

## 5. Open items / [UNVERIFIED]
- Whether the chosen engine reimplementation compiles cleanly for FreeBSD
  x86-64 (dependent on the project's portability).
- Inner layout of `samp.saa` (S-0013) and the exact SA-MP 0.3.7 packet format
  — both [UNVERIFIED] per kb/ notations; needed to finalize the client reimpl.
- elfldr's exact ELF-upload protocol (payload framing on port 9021) — infer
  from the public elfldr binary / kexp.js calling convention when we build.
- Audio bank decoding in the reimplementation.

## 6. Relationship to the harness
This document is the Phase-3+ deliverable for the ACTIVE open item (HANDOFF
§5). It turns "convert the files into something the PlayStation can execute"
into an executable plan: **Runtime A (native reimplementation, FreeBSD x86-64
ELF) + data pack of the catalogued PC files + SAMP client reimplementation,
delivered over Relapse's elfldr on port 9021.**