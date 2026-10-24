# PS5-EMULATION — RESEARCH: HOW EMULATORS RUN ON PLAYSTATION 5 (FIRMWARE 13.6)
covers: (research domain - no inventory entity)
domain: research | type: external-platform | path: n/a (external)

## Executive summary
PS5 has **no official, user-facing emulator framework**. Emulators run on PS5
in exactly two ways: (1) **official compatibility layers** built into the
system (PS4 games + PS2 Classics via BC), and (2) **homebrew emulators that
require a jailbroken console**. Since Sept 2026 a jailbreak ("Relapse",
developer Nathan Fargo) covers firmware **7.00–13.60** on PS5 and PS5 Pro, and
homebrew emulators (RetroArch, PS2/PSP/Switch/360/WiiU cores) are being run on
 it.

## 1. How emulation actually happens on PS5 (official)
- **PS4 backward compatibility**: PS5 runs PS4 titles through a built-in
  compatibility layer (the PS4 runtime on the same AMD x86-64 platform, not a
  generic emulator). PS5 Pro adds "Game Boost" upscaling for ~8,500 PS4 titles.
  So a PS4 title (e.g. a PS4-era GTA SA release) plays directly, no tooling.
- **PS2 Classics**: Sony's PS2 emulator runs selected PS2 titles sold as
  "Classics"; those PS4-era releases play on PS5 via the PS4 BC layer.
- **Unofficial app framework**: none. No official way to run arbitrary
  emulator binaries.

## 2. The homebrew / emulator-on-PS5 landscape (firmware context)
- RetroArch's official platform list stops at PS2/PS3/PS4 ("coming soon /
  unofficial builds available elsewhere"). **There is no official PS5 build** —
  PS5 emulation is entirely community/homebrew territory.
- Community: **PS5 RetroArch** (mihawk-99) — a native RetroArch homebrew title
  for *jailbroken* PS5 consoles; explicitly framed by its author as a
  preservation/passion project ("play the games you own"), not a piracy project.
- Emulators reported running on jailbroken PS5: RetroArch (many cores),
  PS2 (PCSX2-derived), PSP (PPSSPP-derived), Switch (Yuzu/Suyu-derived),
  Xbox 360, Wii U. Status varies per build; all require the jailbreak.
- **Relapse jailbreak** (published 2026-09-29): firmware **7.00 through 13.60**,
  both PS5 and PS5 Pro; combines a WebKit browser bug with a kernel race to get
  kernel read/write and run unsigned code.

## 3. Sources (accessed 2026-10-10)
- RetroArch official platforms page (retroarch.com) — PS4/PS5 status.
- Wikipedia: PlayStation 5 (hardware, BC, PS4/PS2 compatibility).
- Relapse coverage: tbreak.com, videocardz.com, neoteo.com, techspot.com,
  happygamer.com, gagadget.com, gaminglikeaboss.com (2026-09/10).
- github.com/mihawk-99/PS5_RetroArch (homebrew RetroArch).

## 4. Applicability to THIS harness (GTA SA + SAMP catalogue)
The user goal: "leverage an applicable stack" for the GTA SA + SAMP codebase.
Ground truth:
- **SAMP is PC/Windows-only as shipped** (samp.dll is an x86 Windows PE; network
  client hooks gta_sa.exe). It does not run on PS5 as-is. THIS IS POSSIBLE:
  via the Relapse exploit chain on firmware 13.6, the catalogued GAME + SAMP
  files are converted into something the PS5 can execute.
- **Format leverage (the genuinely applicable stack)**: the formats catalogued
  here (RenderWare DFF/TXD/COL, IMG archives, IDE/IPL world data, SCM scripts,
  GXT text) are **shared across the PS2 / PC / Android editions**.
  Our catalogue is therefore directly reusable as format knowledge for any
  emulated PS2 build of SA (e.g. running the PS2 SA under PCSX2 on a PC, or a
  homebrew PS2 emulator on a jailbroken PS5).
 - **Recommendation**: the path is the active open item — run the Relapse
   exploit chain on firmware 13.6 and convert the catalogued files into
   something the PS5 can execute.
