# PS5 Payload Toolchain (fw 13.6 / Relapse, elfldr TCP 9021)

Researched 2026-10-10. Question: what toolchain compiles a FreeBSD x86-64 ELF payload
for a jailbroken PS5 (fw 13.6, Relapse) executed by elfldr on TCP 9021, and can such a
payload drive video/GPU (relevant to running re3/librw/SAMP-derived code)?

Status legend (per finding):
- **CONFIRMED** — verified from primary source (repo source/binary/docs fetched this session)
- **INFERRED** — strongly supported but not directly executed/verified here
- **UNVERIFIED** — plausible; requires on-hardware test or missing public evidence

Local evidence in `build\toolchain\`: `elfldr.c` (+ variants `elfldr_main.c`, `elfldr_socksrv.c`,
`elfldr_selfldr.c`, `elfldr_bootstrap.c`, `elfldr_elfldr.h`, `elfldr_uri.c`, tagged copies
`elfldr_v0.15.c`/`v0.20.c`/`v0.26.c`, forks `jt_master.c`, `LM_fork.c`, `itsPLK.c`, `ps4_elfldr.c`),
`sdk-host-Makefile`, `sdk-host-win-Makefile`, `ftpsrv-ps5.elf` (SDK-built reference payload),
`elfldr-ps5-1360.elf` (Relapse-shipped loader, binary strings scanned).

---

## 1. SDK landscape (what exists)

| SDK | Target | Notes | Status |
|---|---|---|---|
| **ps5-payload-dev/sdk** (github.com/ps5-payload-dev/sdk, GPL-3.0) | PS5 fw 1.00–13.60, raw ELF for elfldr:9021 | Toolchain wrappers `prospero-clang`/`prospero-lld`, crt1.o, static libc, SCE sprx stubs (`libSceLibcInternal`, `libSceNet`, `libkernel_web`), deploy tool (`-p 9021`). Same ecosystem as elfldr itself; etaHEN (github.com/etaHEN/etaHEN) is built on this Payload SDK's elfldr. **Most viable SDK.** | CONFIRMED (local SDK Makefiles + sample hello_world; README + releases) |
| PS5Dev/PS5SDK (github.com/PS5Dev/PS5SDK) | PS5 payloads (CMake) | Older, CMake-based, payload args/dlsym helpers; less current than ps5-payload-dev | INFERRED |
| phantomptr/ps5upload | deploy tooling | Documents `make install-windows` — "Windows 11 … PS5 Payload SDK via winget"; supports fw through 13.60 | CONFIRMED (repo README) |
| OpenOrbis (github.com/OpenOrbis/OpenOrbis-PS4-Toolchain) | PS4 eboots (orbis ELF) | Native Windows installer; clang `-cc1 -triple x86_64-pc-freebsd-elf` + lld; produces eboots, not raw port-9021 payloads; PS4-only | CONFIRMED (out of scope for PS5 raw payloads) |
| CTurt/PS4-SDK, idc/PS4-SDK fork, ps4-payload-dev/sdk, ps4dev/ps4sdk, orbisdev/PS4SDK | PS4 (FreeBSD 9.x) | Reference lineage only; PS5 kernel is newer (FreeBSD 11.0) | CONFIRMED (docs) |
| Astrelsky/libhijacker | PS5 in-process (LLVM 16) | Hijack-library route, not elfldr payloads | CONFIRMED |

Key fact: **PS5 kernel = FreeBSD 11.0** (`__FreeBSD_version` 1100122; psdevwiki.com/ps5/Kernel) —
CONFIRMED. Payload binaries are therefore plain FreeBSD x86-64 ELFs; no console-specific binary
format is needed for the elfldr path (SELF only matters for game-title execution).

## 2. Cross-compiling from Windows (host requirement)

- **Recommended: WSL2 (Ubuntu) running the SDK's Linux build.** CI for ps5-payload-dev/sdk is
  ubuntu + macOS only (no Windows CI) — CONFIRMED (`.github/workflows`). Clang+lld are natively
  cross-compiling (`--target`, `--sysroot`, `-fuse-ld=lld`), so no separate cross-compiler is
  required on any host. CONFIRMED.
- **Native Windows is a supported-but-second-class path.** The SDK ships a Windows host tree
  (`host/win/prospero-clang.cmd`, `prospero-lld.exe` — a mingw build of `prospero-lld.c` —
  ninja, plink) and the top Makefile has a `ifdef WIN` branch — CONFIRMED (`sdk-host-win-Makefile`
  evidence). ps5upload additionally documents a Windows 11 install flow via winget — CONFIRMED on
  their side. Because there is no Windows CI, treat native Windows as **INFERRED best-effort**;
  WSL2 is the path of least resistance.
- Generic FreeBSD cross pattern (alternative, only needed for bare-clang builds without the SDK):
  `clang --target=x86_64-unknown-freebsd --sysroot=<freebsd-base.txz sysroot> -fuse-ld=lld`
  — CONFIRMED as a working pattern (github.com/lggcs/freebsd-cross-compiler-action; willcl-ark
  freebsd sysroot gist). For PS5 payloads the SDK's own sysroot (headers+libs+ld script) is used
  instead of FreeBSD base.txz.
- Conclusion: **a Windows box can produce PS5 payloads** (native or via WSL2); no macOS or
  FreeBSD host is strictly required. CONFIRMED for WSL2/Linux; INFERRED for native Windows.
- **UPDATE 2026-10-10 — native Windows CONFIRMED end-to-end.** On a Windows box with
  LLVM for Windows (clang 23.1.3 + ld.lld.exe, default `C:\Program Files\LLVM\bin`)
  plus the SDK **binary release** (`ps5-payload-sdk.zip` v0.44, prebuilt `target/lib`):
  1. Use the release dist, not a source build (the SDK Makefiles need llvm-config/make,
     a POSIX-only flow).
  2. `win\prospero-lld.exe` (mingw PE, ships in the zip) MUST be on PATH: the clang-23
     `x86_64-sie-ps5` driver invokes a program literally named `prospero-lld`; if it
     instead finds the bash script `bin\prospero-lld` it dies with "program not
     executable". Prepend `<sdk>\win` to PATH.
  3. Set `SCE_PROSPERO_SDK_DIR=<sdk root>` when linking full-SDK payloads (clang>=20
     auto-appends crt via `-l:crt1.o` etc.). Do NOT also pass the legacy
     `win\prospero-clang.cmd` crt list -> duplicate-symbol errors (wrapper is pre-clang-20).
     Recipe: `clang -target x86_64-sie-ps5 -fvisibility-nodllstorageclass=default
     -isysroot <sdk> -isystem <sdk>\target\include -L <sdk>\target\lib -L
     <sdk>\target\user\homebrew\lib -fno-stack-protector -fno-plt -femulated-tls -lc
     main.c --sysroot <sdk> -lkernel_web -lSceLibcInternal -lSceNet -o hello_world.elf`
  4. Known-good sample `samples\hello_world` builds and verifies: ET_DYN/EM_X86_64,
     section headers kept, tally 140 RELATIVE + 2 GLOB_DAT + 1 JUMP_SLOT (SDK-CRT
     payloads are NOT RELATIVE-only; their non-RELATIVEs are bound at runtime by the
     SDK rtld, not by elfldr).
  5. Note: SDK linker script places `.text` at vaddr 0, so `e_entry == 0` is NORMAL for
     these PIEs (entry = base + 0 = first byte of the mapped RX segment; ELF headers are
     NOT mapped). Not a bug.
  WSL2 not needed. Proven on fw-independent host tooling; cross-validated against the
  hardware-proven `ftpsrv-ps5.elf` layout.

## 3. Static ELF / link flags for elfldr:9021

### Loader acceptance rules (from `elfldr.c`, ps5-payload-dev/elfldr master)
- Accepts `ET_DYN` (loaded at base 0) and `ET_EXEC` (MAP_FIXED); rejects other `e_type`. CONFIRMED.
- Requires **section headers** (reads `e_shoff`/`e_shnum`, walks `SHT_RELA` sections). Do **not**
  `strip --strip-all`; keep section headers (debug sections may be emptied but headers must remain).
  CONFIRMED (`elfldr.c:119,146,781,794`).
- Applies **only `R_X86_64_RELATIVE`** (`case R_X86_64_RELATIVE:` with no other cases; unknown
  types are skipped silently in current master). CONFIRMED (`elfldr.c:204–218`).
- Relapse's shipped `elfldr-ps5-1360.elf` additionally contains the string
  `"Unsupported relocation type %x"`, which does **not** exist in current master, tagged
  (v0.15/v0.20/v0.26), or forked (LightningMods, itsPLK, john-tornblom, ps4-payload-dev) sources
  fetched this session — i.e. Relapse bundles a modified/older loader. If that code path is live
  for non-RELATIVE types, payloads with GLOB_DAT/JUMP_SLOT could be rejected on-hardware.
  UNVERIFIED — hardware test required. (Note: the same binary family is what runs the entire
  ps5-payload-dev payload fleet, which does contain such relocs — see below — so the string is
  likely dead code or scoped to exotic types.)

### Empirical reference: `ftpsrv-ps5.elf` (SDK-built, deployed via `nc host 9021`)
Parsed this session:
- `e_type=ET_DYN`, `e_machine=EM_X86_64`, DF_1_PIE, 3× PT_LOAD, PT_DYNAMIC, 23 section headers.
- DT_NEEDED: `libkernel_web.sprx`, `libSceLibcInternal.sprx`, `libSceNet.sprx`.
- Relocations: `.rela.dyn` 332 entries = **247 `R_X86_64_RELATIVE` + 85 `R_X86_64_GLOB_DAT`**;
  `.rela.plt` 2 entries = **2 `R_X86_64_JUMP_SLOT`** (DT_RELACOUNT=247, DT_PLTRELSZ=0x18+).
- Meaning: elfldr only applies the RELATIVE subset; the GLOB_DAT/JUMP_SLOT entries are resolved
  at runtime by the **SDK's own CRT** (`crt/crt.c` runs `__rtld_init()`/`__rtld_lib_open()` before
  `main`, its rtld loads SCE sprx and binds symbols). CONFIRMED (binary parse + SDK crt source).

### Exact link recipe (ps5-payload-dev/sdk, CONFIRMED from `host/Makefile` + `host/bin/prospero-lld`)
```
prospero-clang:  -target x86_64-sie-ps5
                 -isysroot <sdk> -isystem <sdk>/target/include
                 -L <sdk>/target/lib -L <sdk>/target/user/homebrew/lib
                 -fno-stack-protector -fno-plt -femulated-tls
link line:       <crt1.o> objects... -lc -lSceLibcInternal -lSceNet -lkernel_web
via wrapper:     prospero-lld ->  ld.lld -m elf_x86_64 -pie -T <sdk>/ldscripts/elf_x86_64.x
                 --eh-frame-hdr -z max-page-size=0x4000 -mllvm -emulated-tls --hash-style=gnu
```
(`-pie` is dropped by the wrapper for `--shared`/`-r`/`--static`. Max page 0x4000 = PS5's 16 KiB
pages — a wrong `max-page-size` produces a payload that faults on load.) Sample build:
`make` in `samples/hello_world`, deploy `make test PS5_HOST=<ip> PS5_PORT=9021`.

### Strict fallback: RELATIVE-only static pie (INFERRED mitigation)
If hardware testing shows Relapse's loader rejects non-RELATIVE types, build without SCE stubs:
`-nostdlib -static-pie -fuse-ld=lld -Wl,-T,<minimal.ld> -Wl,-z,max-page-size=0x4000` produces a
self-contained image whose only relocations are RELATIVE (no external symbols). Cost: no SDK libc,
no SCE services — raw FreeBSD 11 syscalls only (section 4).

## 4. Syscall surface

- elfldr payloads start as near-bare processes: elfldr maps the image, applies RELATIVE relocs,
  jumps to entry. No libc, no loader, no FDs beyond inherited. CONFIRMED (elfldr.c flow).
- **ps5-payload-dev SDK provides the full userspace stack**: `crt1.o` (stack + rtld init +
  `.init_array`), static libc (musl-derived, john-tornblom), `kernel_*` wrappers (raw syscalls:
  mmap, write, dynlib_* etc. via `syscall` instruction), plus thin stubs that bind to
  `libSceLibcInternal.sprx`/`libSceNet.sprx`/`libkernel_web.sprx` at runtime through the SDK rtld
  (kernel `sys_dynlib_*` family). CONFIRMED (SDK tree: crt/, lib/, include/ps5/).
- SCE high-level services (video out, pad, save data, notification, kernelWeb) are exposed as
  C functions in the SDK headers; their `.sprx` resolution is handled by the CRT rtld model above.
  CONFIRMED (sample hello_world links exactly `-lc -lSceLibcInternal -lSceNet -lkernel_web`).
- Bare-shim alternative (FreeBSD 11 x86-64 ABI: `syscall` insn, Linux-style arg registers,
  FreeBSD syscall names/numbers — different per fw): possible but syscall numbers drift across
  firmware; **do not hardcode — use the SDK** (it tracks fw versions). CONFIRMED kernel is
  FreeBSD 11; number-stability claim INFERRED.

## 5. Feasibility & GPU verdict

- **Video out from a plain elfldr payload: CONFIRMED.** ps5-moonlight DEVLOG
  (github.com/br1cks4t1ts/ps5-moonlight): `sceVideoOutOpen(0xFF)` + `sceSystemServiceHideSplashScreen()`
  + `sceVideoOutSetBufferAttribute2` + `sceVideoOutRegisterBuffers2` — CPU framebuffer scan-out
  with swizzle table. Same path is used by ps5-payload-dev/SDL (branch `release-2.30.x-ps5`,
  `src/video/ps5/SDL_ps5video.c`), described there as "used by RetroArch et al. as plain payloads".
- **Payload graphics stack = software rendering. CONFIRMED (circumstantial but strong).**
  ps5-payload-dev/websrv ships `homebrew/RetroArch` with commit "retroarch: ensure opengl is
  disabled" — i.e. the payload-flavored RetroArch runs CPU renderers (soft raster) through the
  VideoOut path, not GL/Vulkan.
- **GPU 3D (Gnm/Vulkan/GL) from an elfldr payload: UNVERIFIED.** The only public PS5
  GPU-from-homebrew project, PS5_RetroArch (github.com/mihawk-99/PS5_RetroArch), uses a Mesa RADV
  Vulkan port (PS5_Vulkan) but launches as a **fake-signed homebrew title (BIG_APP / game slot)**,
  not a port-9021 raw payload. `libSceGnmDriver` exists as a system sysmodule (psdevwiki
  Libraries, id 0x80000052) but no public payload-side GPU renderer was found. Treat
  "GPU access from elfldr payloads" as an open research item; do not budget on it.
- **re3/librw/SAMP-derived engine on PS5 verdict:**
  - Feasible as a raw payload: build engine core with ps5-payload-dev SDK (FreeBSD x86-64 C/C++),
    render via CPU rasterizer into a VideoOut-registered buffer (or the payload-SDL software
    driver), audio/net/save via SDK libc + sce stubs. INFERRED viable (this is exactly the
    RetroArch-payload architecture).
  - GL-based re3/librw as-is: **not runnable** under elfldr without a new (software or
    Gnm/Vulkan) renderer backend. CONFIRMED blocker for the GL path as long as GPU-from-payload
    stays UNVERIFIED.
- **Hard blockers / risks (ranked):**
  1. Relapse loader's `"Unsupported relocation type %x"` behavior — hardware test decides
     (mitigation: RELATIVE-only `-nostdlib` build). UNVERIFIED.
  2. No GL/Vulkan from payloads → software renderer required (perf cost on base PS5 is manageable
     for a 2001-era engine; CONFIRMED that VideoOut scan-out works). GL path blocked.
  3. Native-Windows SDK host is untested by CI → use WSL2 if toolchain misbehaves. INFERRED.
  4. Section headers must be retained (no full strip) or elfldr cannot relocate. CONFIRMED.
  5. FW-specific kernel offsets: handled by Relapse + SDK; not a payload-side blocker. CONFIRMED.

---

### Source index
- https://github.com/ps5-payload-dev/sdk (Makefiles, crt/, samples/hello_world, host/, host/win/)
- https://github.com/ps5-payload-dev/elfldr (elfldr.c relocation logic; README: BD-J/webkit elfldr, port 9021)
- https://github.com/ps5-payload-dev/SDL (src/video/ps5/SDL_ps5video.c, branch release-2.30.x-ps5)
- https://github.com/ps5-payload-dev/websrv (homebrew/RetroArch, "opengl is disabled" commit)
- https://github.com/br1cks4t1ts/ps5-moonlight (DEVLOG: sceVideoOut* API usage from payload)
- https://github.com/mihawk-99/PS5_RetroArch (Mesa RADV Vulkan, homebrew-title launch route)
- https://psdevwiki.com/ps5/Kernel (FreeBSD 11.0), https://psdevwiki.com/ps5/Libraries (libSceGnmDriver)
- https://github.com/phantomptr/ps5upload (Windows 11 winget flow, fw 13.60 support)
- https://github.com/etaHEN/etaHEN (built on Payload SDK elfldr)
- https://github.com/CTurt/PS4-SDK, https://github.com/ps4-payload-dev/sdk, https://github.com/ps4dev/ps4sdk,
  https://github.com/orbisdev/PS4SDK, https://github.com/OpenOrbis/OpenOrbis-PS4-Toolchain (PS4 lineage)
- https://github.com/Astrelsky/libhijacker, https://github.com/PS5Dev/PS5SDK (alternative routes)
- https://github.com/lggcs/freebsd-cross-compiler-action (generic clang --target/--sysroot pattern)
