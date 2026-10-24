# RELAPSE-ARCHITECTURE — RESEARCH: RELAPSE PS5 JAILBREAK, ARCHITECTURE + FIRMWARE 13.6 RUN CHAIN
covers: (research domain - no inventory entity)
domain: research | type: external-platform | path: n/a (external)

## Executive summary
Relapse (github.com/ntfargo/Relapse-Exploit, published 2026-09-29, MIT) is a
**3-stage WebKit+FreeBSD kernel exploit chain** for PS5 + PS5 Pro on firmware
**7.00–13.60**. Stage 1 corrupts a typedarray in WebKit to get userland
arbitrary read/write (ARW); stage 2 runs a ROP chain through a parked worker
thread to gain a syscall primitive; stage 3 races `aio_multi_wait` to get
kernel r/w, escalates privileges, and drops a **JIT-shared-memory ELF loader
listening on TCP port 9021** (`elfldr-ps5-1360.elf`). Any x86-64 ELF payload
can then be pushed to that port and executed on the Orbis (FreeBSD) kernel.

## 1. Repo anatomy (the codebase, as of 2026-10-10)
```
Relapse-Exploit/
├── index.html            entry page; loads src/firmware.js, main.js, rop.js,
│                         utils/syscalls.js, then module src/site.js
├── serve.py              local HTTP host (port 8000) that serves the page;
│                         prints http://<192.168.x>:8000/ for the PS5 browser
├── offsets/<fw>.js       34 firmware-specific offset tables (7.00 .. 13.60)
├── src/
│   ├── firmware.js       UA parse "PlayStation 5/<fw>"; whitelist check
│   ├── webkit.js         STAGE 1: JSC leaks + structured-clone pool mismatch
│   │                     -> corrupt typedarray -> installWindowP ARW object
│   ├── site.js           run(): getPrimitive() -> log, resolve WebKit base
│   ├── main.js           STAGE 2: find worker stack (pthread walk),
│   │                     setjmp/longjmp ROP launch, syscall map, kexp handoff
│   ├── rop.js            worker_rop chain builder (add_syscall etc.)
│   ├── relapse_exploit.js STAGE 3: kernel base leak (routing socket),
│   │                     aio_multi_wait UAF, oid-window sysctl r/w, pipe
│   │                     cross fast r/w, privilege escalation, cleanup
│   ├── kexp.js           load shellcode + elfldr into JIT shm, spawn thread,
│   │                     return elfldr result
│   └── utils/            int64.js, mem.js, rop_slave.js (parked worker),
│                         syscalls.js (FreeBSD syscall table + tramp offsets)
└── payloads/
    ├── elfldr-ps5-1360.elf   397 KB ELF loader -> listens on TCP 9021
    └── kexp_2026_05_25.bin   18,912 B kernel shellcode blob (patched at
                              runtime with resolved symbol addresses)
```

## 2. Stage-by-stage architecture
### Stage 1 — WebKit ARW (userland, JS only)
- JSC info leaks + a structured-clone object-pool mismatch corrupt a typedarray
  backing store -> get an `installWindowP()` primitive object exposing
  read8/read4/read2/read1 + write8/write4/write2/write1 + leakval.
- WebKit base recovered from `__ps5NativeCtor` minus host-constructor
  candidates (candidates per-fw in `offsets/<fw>.js`).

### Stage 2 — ROP + syscall primitive (still userland)
- A Web Worker (`rop_slave.js`) parks in libkernel; the exploit walks the
  libkernel thread list (`lk__thread_list`) for a plausible 0x80000 stack whose
  return slot matches `lk_worker_wait_return` fingerprint.
- Gadget map + syscall-map offsets (per-fw) are resolved against the real
  bases: libSceNKWebKit (from host ctor), libSceLibcInternal (via the memset
  import), libkernel (via the __stack_chk_guard import).
- A setjmp/longjmp context is planted so the worker's return resumes the ROP
  chain; the chain can call real FreeBSD syscalls (SYS_* in utils/syscalls.js).

### Stage 3 — kernel exploit + payload load
- **KASLR leak**: raw routing socket (AF_ROUTE/RTM_GET with RTA_AUTHOR) returns
  a kernel return address -> kbase.
- **Slow r/w**: `aio_multi_wait` UAF race against parked AIO worker threads;
  reclaim waiter arrays, flip oid kinds on `kern.smp.cpus` / `kern.smp.maxcpus`
  sysctl nodes -> slow 32-bit kernel read/write via sysctl window steering.
- **Fast r/w**: two pipes, cross the master pipe's buffer pointer to the victim
  pipe -> pipe-backed kernel r/w at speed.
- **Escalation**: curproc -> ucred (uid/ruid/svuid/gid=0, root vnode cdir/rdir,
  sysCoreAuthId, all caps, syscall start/end widened) -> sandbox escape.
- **Cleanup**: defuse armed AIO groups, restore oids/pipes, release workers.
- **Payload load (kexp.js)**: fetch `payloads/*.elf` over HTTP, mmap
  PROT_RW/MAP_PRIVATE_ANON, copy in; `SYS_JITSHM_CREATE` + executable mmap
  (PROT_RWX, MAP_SHARED) -> write shellcode + elfldr, pthread_create the
  shellcode, elfldr begins listening on **TCP 9021**.

## 3. How it runs on firmware 13.6 (the run chain in practice)
1. Console on 13.60, offline (recommended; PSN ban risk). Browser opens
   `http://<host>:8000/` (serve.py on the PC).
2. `firmware.js` sees UA `PlayStation 5/13.60` -> whitelisted -> loads
   `offsets/13.60.js` (gadget map, syscall map, oid/aio/pipe offsets).
3. Stage 1..3 run in the browser process. WebKit may need several reloads;
   kernel panic/hang -> reboot and retry (README stability notes).
4. Success => `elfldr` listening on **port 9021** of the console's IP.
5. Push any **x86-64 ELF payload** to 9021 to execute it on Orbis kernel
   (root, sandbox escaped, dynlib syscall whitelist open).

## 4. Execution surface (what the PS5 can now run)
- Payloads are **plain FreeBSD/Orbis x86-64 ELF executables** (no Sony signing,
  no eboot.pkg requirement). The elfldr listens on 9021 and execs what it
  receives.
- JIT shared memory means the same payload can also be mapped PROT_RWX
  directly from kernel (as kexp.js does) — no file needed on disk.
- Homebrew that runs on top (reported in press, see PS5-EMULATION.md): PS2
  (PCSX2-derived), PSP (PPSSPP-derived), Switch, 360, WiiU, RetroArch builds.

## 5. Sources
- github.com/ntfargo/Relapse-Exploit (MIT; tree, README, src/, offsets/,
  payloads/ read 2026-10-10 via GitHub API/raw).
- Firmware offset files 7.00..13.60 read (13.60 detailed).
- Cross-ref: kb/research/PS5-EMULATION.md (landscape + applicability).
- All behavioural claims above from reading the code; firmware-specific
  offset semantics [UNVERIFIED] beyond what the code shows.