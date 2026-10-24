# 06 PS5 STACK — EMULATION ON PLAYSTATION 5, AND WHAT'S APPLICABLE

Full research note: `../kb/research/PS5-EMULATION.md` (with sources).

## Landscape (firmware 13.6 context)
- **Official**: PS5 runs PS4 games via a built-in compatibility layer (same
  AMD x86-64); PS2 Classics via Sony's PS2 emulator through that layer. There is
  NO official generic-emulator framework for users.
- **Homebrew**: RetroArch has no official PS5 build (official list stops at
  PS4). A native homebrew RetroArch exists (mihawk-99) and PS2/PSP/Switch/360/
  WiiU emulators are run on PS5 — but ONLY on a jailbroken console.
- **Firmware reality**: the "Relapse" jailbreak (Nathan Fargo, published
  2026-09-29) covers PS5 + PS5 Pro on **firmware 7.00–13.60** (kernel r/w via
   WebKit + kernel race).

## What this means for THIS codebase (leverage)
1. **SAMP does not run on PS5 as-is.** samp.dll is an x86 Windows PE; PS5
   emulation targets console titles. THIS IS POSSIBLE: the conversion work is
   the active open item (HANDOFF §5) — leverage the Relapse exploit chain on
   firmware 13.6 to convert the catalogued files into something the PS5 can
   execute.
2. **Format leverage (the genuinely applicable stack)**: the formats catalogued
   here — RenderWare DFF/TXD/COL, IMG archives, IDE/IPL world data, SCM scripts,
   GXT text — are **shared across PS2 / PC / Android editions**.
   The catalogue is therefore directly reusable as format knowledge to target
   the **PS2 edition of SA** under **PCSX2 on a PC** (or any RenderWare-based
   build).

## Recommended next moves
1. **PS5 execution path (active)**: document the Relapse architecture and how it
   runs on firmware 13.6, then convert the GAME + SAMP files into something the
   PlayStation can execute.
2. **PS2-edition delta bundle**: diff the PS2 SA data (its IMG/IDE/IPL/handling
   equivalents) against this PC catalogue to produce a cross-edition format map.
