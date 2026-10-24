# RUNTIME-BUILD-PLAN — STAGE 1: BUILDING THE PS5-EXECUTABLE RUNTIME
covers: (research domain - no inventory entity)
domain: research | type: build-plan | path: n/a

## Status: HARD CONSTRAINTS RESOLVED (2026-10-10)
Two findings from the toolchain + payload-SDK research materially change the
conversion plan in catalog/07_PS5_EXECUTION.md. Recorded here as governing
constraints.

## Governing constraints (from kb/research/PS5-PAYLOAD-TOOLCHAIN.md)
1. **elfldr relocation whitelist (HARD).** Relapse's elfldr appears to reject
   non-RELATIVE relocations (it ships an "Unsupported relocation type %x"
   string). SDK-built ELF payloads contain GLOB_DAT/JUMP_SLOT relocs. => The
   runtime MUST be built **`-nostdlib -static-pie`, RELATIVE-only**, no dynamic
   link. Do NOT strip section headers.
   - Flag template (CONFIRMED from ps5-payload-dev/sdk):
     `-target x86_64-sie-ps5 -fno-stack-protector -fno-plt -femulated-tls`
     `ld.lld -m elf_x86_64 -pie -T ldscripts/elf_x86_64.x --eh-frame-hdr -z max-page-size=0x4000 --hash-style=gnu`
2. **3D GPU from an elfldr payload is UNVERIFIED.** Public PS5 Vulkan/GL
   (RetroArch/Mesa RADV) runs as a **fake-signed homebrew title**, NOT a 9021
   payload. What IS confirmed from payloads: **CPU framebuffer scan-out via
   `sceVideoOut*`** (ps5-moonlight DEVLOG, ps5-payload-dev/SDL). => Assume a
   **software rasterizer writing to a VideoOut framebuffer**; do not assume a
   GL/Vulkan context is available to a payload.
3. **Build host:** ps5-payload-dev/sdk is CI-supported on **Linux/macOS**;
   Windows via **WSL2 (recommended)**. Native-Windows is best-effort only.

## Engine base reality check (from re3 assessment)
- **re3 = GTA III only** (master=III, miami branch=VC). No SA.
- **Reusable as-is:** librw's RW binary data layer (DFF/TXD/COL/IMG/IFP are
  game-agnostic). aap/librw builds; FreeBSD is a *named premake target*.
- **NOT reusable (III/VC-specific, must be written for SA):** gta.dat `IMG`
  directive, .ide `txdp`/`anim` sections, .ipl `grge`/`enex`/`occl` sections,
  handling.cfg 36-column layout, all SCM opcodes, GXT layout, all SA
  gameplay systems.

## Consequence for Path A
Path A (native SA engine -> FreeBSD ELF) is **feasible but is a large porting
project**, not a build: the RW data layer is ready, everything SA-specific
(game logic, loaders, SCM VM, SAMP client) must be built on top. The graphics
output path is a **software renderer + VideoOut**, not OpenGL.

## Recommended de-risking step (NEXT)
Before committing to the full SA port, prove the **delivery pipeline** with a
minimal PoC: build a tiny static-pie RELATIVE-only ELF with ps5-payload-dev/sdk
(WSL2) that writes a splash to the VideoOut framebuffer, push it to port 9021,
and confirm it renders on the console. This validates toolchain -> elfldr ->
screen independent of the engine, and de-risks constraint (1) and (2).

## Build artifacts so far
- Toolchain: cmake 4.4.4, clang 23.1.3, ninja 1.13.2 (provisioned).
- build\src\re3\ (III), build\src\librw\ (aap/librw), build\src\re3-build\
  (configure green, host build blocked on missing Win SDK).
- build\data\ (439-file verified data pack), build\elfldr-ps5-1360.elf.
