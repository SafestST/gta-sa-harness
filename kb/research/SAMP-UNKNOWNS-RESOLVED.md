# SAMP-UNKNOWNS-RESOLVED — RESEARCH: PINNED [UNVERIFIED] ITEMS FROM THE PS5 EXECUTION HANDOFF
covers: S-0011, S-0013, B-SAMP-CLIENT, B-AUDIO, G-0025..G-0056, (research domain)
domain: research | type: unknowns-resolution | path: n/a (target read-only; external sources cited)
status: 2026-10-10 — items 1-5 of catalog/07 open items pinned (CONFIRMED/INFERRED/STILL UNVERIFIED per item)

Cross-refs: catalog/07_PS5_EXECUTION.md, kb/research/RELAPSE-ARCHITECTURE.md,
kb/research/PS5-EMULATION.md, kb/samp/S-0013.md, kb/samp/S-0011.md,
kb/samp/B-SAMP-CLIENT.md, kb/game/B-AUDIO.md, catalog/01_FORMAT_REFERENCE.md.

----------------------------------------------------------------------
## ITEM 1 — samp.saa inner layout (S-0013)
VERDICT: CONFIRMED — SAMP-PRIVATE ENCRYPTED ARCHIVE "SAA2". NOT ZIP, NOT IMG, NOT DFF-bag.
It is a signed, doubly-TEA-encrypted container whose reader lives inside samp.dll.

### What was found
Actual file C:\Program Files (x86)\Rockstar Games\GTA San Andreas\samp.saa, 2,689,408 B.
Header dump (first 256 B, annotated):
- 0x00-0x03  `53 41 41 32` = "SAA2"  -> headerV1.dwSAAV = 0x32414153
- 0x04-0x07  `16 00 00 00` = 0x16 = 22 -> headerV1.dwFileCount (deliberately fake)
- 0x08-0xF7  240 B of random-looking data -> wFakeData[SAA_MAX_FAKEDATA=120]
- 0xF8-0xFB  `99 83 DC 2B` = 0x2BDC8399 (stored dwCompleteID, XOR-obfuscated)
- 0xFC-0xFF  `AA B7 F4 6B` = 0x6BF4B7AA (stored dwXORKey)
- Whole-file Shannon entropy = 7.9999 bits/byte -> payload is encrypted (not compressible text).

HeaderV2 bitfield decode (per ArchiveCommon.h unions):
  CompleteID = 0x2BDC8399 ^ 0x6BF4B7AA = 0x40283433
    dwSAMPID  = bits 0-19  = 0x83433  == SAA_FILE_ID (0x83433)  [CONFIRMED match]
    dwVersion = bits 20-22 = 2        == SAA_FILE_VERSION      [CONFIRMED match]
    dwSignSize= bits 23-30 = 0x80 = 128
    dwInvalidIndex = (0x6BF4B7AA >> 5) & 0xFF = 245
File-size arithmetic checks exactly: 256 (header) + 1312*2048 (data) + 256*8 (entry table) + 128 (signature) = 2,689,408.

Format (from the open 0.3.7 client source, primary ground truth):
  [0x000-0x0FF] SAA_FILE_HEADER (256 B; fake V1 block + XOR'd V2 id/key)
  [0x100 ...]   file data, each file padded to SAA_BLOCK_SIZE=2048, encrypted per-file with
                TinyEncrypt (TEA variant, 16-byte key) under a key located inside the
                (decrypted) entry-table memory at (JenkinsHash(name) % (2048-TEA_KEY_SIZE))
  [...]         entry table: 256 x SAA_ENTRY{8 B}, TEA-encrypted with embedded TEA_KEY
  [...]         128 B RSA signature over data (hash excludes header+signature)
Lookup: Jenkins hash of LOWERCASED filename (init 0x9E3779B9 obfuscated 0xC103D3E7);
256 slots include fake/decoy entries; entries linked via 8-bit dwPrevEntry chain ending at
dwInvalidIndex; GetFileData walks the chain to compute the data offset.
Signature verified with an RSA public key embedded in samp.dll; if verification fails the
reader zeroes its obfuscation mask and decrypted data is garbage.

### Evidence
- Local file bytes (header, tail, entropy) — this session.
- Zellcore/SA-MP (open SA-MP 0.3.7 client reimplementation, master):
  arctool2/ArchiveBuilder.cpp (build/sign/encrypt logic), client/archive/ArchiveFS.cpp
  (reader), client/archive/ArchiveCommon.h (structs/constants), TinyEncrypt.h,
  Obfuscator.h (key 0xC103D3E7). The observed header decodes bit-for-bit against this.
- Community tools that only work by loading the real samp.dll confirm the container is
  not trivially parseable: "samp-saa2-extract" (blast.hk/threads/186840, requires
  samp.dll+bass.dll+d3dx9_25.dll) and "Custom SAA2" (ugbase.eu resources 1108 / threads
  4627; DSOUND.dll shim + unpacked CustomSAA2 folder replaces archive reads).
- "OpenSaa" (libertycity.net 236672) patches samp.dll to load plain files instead.

### CONFIRMED vs INFERRED vs STILL UNVERIFIED
- CONFIRMED: container is SAMP-private "SAA2"; header magic/fake-count/fake-data layout;
  data+entry-table+sig layout; TEA block cipher; Jenkins-hash keying; per-port/embedded
  keys; RSA signature gate. Format is fully documented and reproducible from the open
  source.
- STILL UNVERIFIED: the actual TEA_KEY (entry-table key) and RSA public key byte values
  embedded in the shipped samp.dll (they are XOR-obfuscated inside the binary; a future
  extractor must pull them from samp.dll or use a disassembler). Consequence: without
  those keys the shipped samp.saa cannot be decoded offline yet — the fastest path is
  running samp.dll once (samp-saa2-extract style) or locating the keys in the PE.
- Note: filext.com's generic "SAA" magic (DA BC 85 74 ...) is a DIFFERENT format; ignore.

----------------------------------------------------------------------
## ITEM 2 — SA-MP 0.3.7 network protocol / packet layout
VERDICT: CONFIRMED — transport, packet-ID ranges and reliable/unreliable split are fully
documented in the open 0.3.7 source (the authoritative ground truth).

### What was found
Transport: UDP on RakNet (heavily modified RakNet fork by the SA-MP team). Server default
port 7777; client connects and calls SetXorKey(serverPort) which keys the SA-MP datagram
XOR cipher (SAMPCipher: EncryptData/DecryptData, key derived from port). The whole UDP
payload is passed through the cipher at the socket layer.

Framing: RakNet datagram; first byte = MessageID (packet ID). GetPacketID() handles
ID_TIMESTAMP (26): if byte 0 == ID_TIMESTAMP skip the 4-byte timestamp, read ID at byte 5.
SA-MP user packets are appended AFTER ID_USER_PACKET_ENUM in PacketEnumerations.h:
  ID_PLAYER_SYNC, ID_VEHICLE_SYNC, ID_PASSENGER_SYNC, ID_AIM_SYNC, ID_RCON_COMMAND,
  ID_RCON_RESPONCE, ID_STATS_UPDATE, ID_WEAPONS_UPDATE, ID_SPECTATOR_SYNC, ID_TRAILER_SYNC
(Note: numeric values = enum position in that header; a reimplementation must mirror the
enum order, not the names.)
RPCs travel inside ID_RPC (12); RPC id is a single byte (UniqueID 0-255) enumerated in
sdk/raknet/SAMPRPC.h: RPC_ServerJoin..RPC_ScrDisableVehicleCollision (~150 entries;
script/function RPCs start at RPC_ScrSetSpawnInfo = 100).

Reliable/unreliable split (from client send sites in netgame.cpp / localplayer.cpp):
- SYNC packets (player/vehicle/passenger/aim/trailer/spectator) = HIGH_PRIORITY +
  UNRELIABLE_SEQUENCED, adaptive 15-100 Hz (NETMODE_*_SENDRATE, scaled by players in
  range; LAN 15-30 Hz).
- ID_STATS_UPDATE, ID_WEAPONS_UPDATE = HIGH_PRIORITY + UNRELIABLE.
- All game-critical RPCs = HIGH_PRIORITY + RELIABLE or RELIABLE_SEQUENCED (RPC_Chat,
  RPC_Death, RPC_Spawn, RPC_ClientJoin, RPC_EnterVehicle/ExitVehicle, RPC_SetInteriorId,
  RPC_RequestClass, RPC_VehicleDamage, RPC_ActorDamage, ...).

Connect handshake: RakNet connection -> ID_CONNECTION_REQUEST_ACCEPTED -> client skips
72 bits, reads server challenge (u32), challenge ^= NETGAME_VERSION (4242 for 0.3.7) ->
sends RPC_ClientJoin { iVersion(4242), byteMod(MOD_VERSION), name len+name,
  uiChallenge, GPCI hardware ID (GenerateComputerID, GPCI_KEY=1001), SAMP_VERSION str }.
Sync structs (ONFOOT_SYNC_DATA, INCAR_SYNC_DATA, PASSENGER_SYNC_DATA, AIM_SYNC_DATA,
TRAILER_SYNC_DATA, SPECTATOR_SYNC_DATA) and constants (MAX_PLAYERS 200, etc.) are in
sdk/shared.h; bit-compression details (health/armour nibble*7, C_VECTOR1 24-bit normals,
optional move-speed/surf bits) are visible in netgame.cpp handlers.

### Best public source to use as ground truth
PRIMARY: the open 0.3.7 client+server source (github.com/Zellcore/SA-MP; itself a fork of
teredokot/SAMPC) — sdk/raknet (PacketEnumerations.h, PacketPriority.h, SAMPRPC.h,
SAMPCipher.h, BitStream.h, RakClient/RakPeer), client/net/*, sdk/shared.h. This is a
reverse-engineered REBUILD of 0.3.7, not the official closed binary, but it is the most
complete public spec and matches the real protocol constants.
SECONDARY: gitlab.com/ziggi/RakSAMP (working 0.3.7/0.3.DL fake client/server reimpl);
github.com/katursis/Pawn.RakNet (packet/RPC capture plugin for 0.3.7);
vp817.github.io/RakNetProtocolDoc (RakNet layer); github.com/Brunoo16/samp-packet-list
(community packet list); blast.hk Pawn.RakNet tutorials; open.mp docs (www.open.mp) for
the modern reimplementation's view.

### Version drift (0.3.7 vs open.mp)
- open.mp reimplements the SERVER+client with 0.3.7-compatible networking; for exact 0.3.7
  byte-level ground truth prefer the Zellcore/SA-MP source (same constants as shipped
  0.3.7: NETGAME_VERSION 4242, SAMP_VERSION "0.3.7" in release binaries). open.mp's own
  client may drift its private RPC/packet numbering; treat open.mp as a compat reference,
  not the 0.3.7 spec.
- CONFIRMED: transport/framing/RPC model/sync-vs-reliable split.
- INFERRED: nothing material; exact datagram byte scope of the SAMPCipher XOR (whole
  datagram vs RakNet payload) is confirmed at API level (SetXorKey(port) + EncryptData)
  but the precise wrap point in RakPeer.cpp was not re-verified this session.

----------------------------------------------------------------------
## ITEM 3 — elfldr upload protocol on port 9021
VERDICT: CONFIRMED (protocol), CONFIRMED (ELF identity). INFERRED only the exact source
revision of the Relapse binary.

### What was found
Downloaded https://raw.githubusercontent.com/ntfargo/Relapse-Exploit/main/payloads/elfldr-ps5-1360.elf
-> C:\Users\X\GTA-SA-Harness\build\elfldr-ps5-1360.elf (397,024 B). Parsed locally:
- ELF magic 7F 45 4C 46; class 2 = ELF64; little-endian; EI_OSABI=0 (System V; FreeBSD
  builds often carry 0 — the FreeBSD/Orbis nature is proven by runtime strings instead).
- e_machine = 62 = EM_X86_64  [CONFIRMED x86-64]
- e_type = 3 = ET_DYN (position-independent); e_entry = 0x46B8; 4 program headers
  (PH0 PT_LOAD RWE at 0x4000; PH1/PH2 PT_LOAD; PH3 PT_DYNAMIC); NO PT_INTERP
  (self-contained payload — no dynamic interpreter).
- Dynamic section DT_NEEDED resolves to libkernel.sprx / libSceHttp.sprx etc. which the
  payload loads at runtime via sceKernelLoadStartModule + sceKernelDlsym (strings seen).
- String evidence: "Socket server was compiled at %s %s", "elfldr_read", "elfldr_load",
  "elfldr_spawn", "payload_readuri", "payload_readhttp", "http_get", "/user/temp/payload_%d.self",
  "Serving ELF loader on", "[elfldr.elf] Unknown payload format", "[elfldr.elf] Error
  reading ELF/HTTP/URI/SELF payload", "kernel_overlap_sockets", "kernel_set_proc_jaildir",
  "rfork_thread", "execve", "pt_socket", "Bootstrapping elfldr.elf...", "elfldr.c",
  "selfldr.c".

Upload protocol (raw TCP, port 9021, INADDR_ANY, SO_REUSEADDR, listen backlog 5):
1. Accept one connection, setsockopt SO_NOSIGPIPE.
2. recv(first 4 bytes, MSG_PEEK|MSG_WAITALL) and dispatch on little-endian magic:
    0x464C457F ("\x7FELF")      -> RAW ELF -> elfldr_read()+elfldr_spawn()
    0x656C6966 ("file")         -> file:// URI line -> download via uri_get_content
    0x70747468 ("http")         -> http(s):// URI line -> download
    0x20544547 ("GET ")         -> HTTP GET request (payload_readhttp; ?uri= / ?args= / ?pipe=)
    0x1D3D154F / 0xEEF51454     -> PS4/PS5 SELF -> selfldr_read()+selfldr_spawn()
    else                         -> "[elfldr.elf] Unknown payload format"
3. The connection is closed after one payload (one payload per TCP connection).
4. elfldr_read(): reads the 64-byte ELF header, validates magic, computes total =
   e_shoff + e_shnum*sizeof(Elf64_Ehdr), then MSG_WAITALL reads the remainder (plus any
   section extents). => NO length prefix, NO handshake: the sender just pushes the raw
   ELF bytes and keeps the connection open until the loader has consumed them.
5. elfldr_spawn(): rfork_thread -> child ptrace(PT_TRACE_ME) -> execve(
   /system/vsh/app/NPXS40112/eboot.bin) -> loader maps the pushed ELF into the child
   (pt_mmap), copies PT_LOAD segments, applies ONLY R_X86_64_RELATIVE relocations,
   mprotects per PF_*, sets RIP=entry / RDI=args, escalates (rootdir/jaildir/ucred) and
   runs it. stdio may be piped back to the TCP client (args pipe=).

Payload build constraints implied by the loader (elfldr.c):
- Must be ELF64 (Elf64_Ehdr) x86-64; e_type ET_DYN (PIE) or ET_EXEC (fixed).
- Only R_X86_64_RELATIVE relocations supported ("Unsupported relocation type %x") =>
  build STATIC, -fPIE, no dynamic symbol relocations (raw syscalls / hardcoded imports).

### Evidence
- Local ELF header/program-header/dynamic parse + string scan (this session).
- Source match: github.com/ps5-payload-dev/elfldr (socksrv.c, elfldr.c, elfldr.h) —
  socksrv.c/elfldr.c behavior above is quoted from that repo; every observed error string
  in the Relapse binary matches this codebase byte-for-byte, so Relapse ships this loader.
- RELAPSE-ARCHITECTURE.md (kexp.js loads elfldr via JIT shm; elfldr then serves 9021).
- INFERRED: the exact git revision/toolchain of Relapse's build; that the runtime use-case
  (curl/nc raw-ELF push) matches the elfldr_read path exactly as documented. (Protocol
  itself CONFIRMED by source.)

----------------------------------------------------------------------
## ITEM 4 — SAMP client hook mechanism
VERDICT: CONFIRMED (fingerprint-level: PE identity + imports + mechanism from open source).
INFERRED: exact engine symbol list/addresses patched at runtime (not statically visible).

### What was found (actual samp.dll, 1,204,224 B)
- PE: DOS MZ; e_lfanew=0x118; PE\0\0; machine = 0x014C = x86 (32-bit)  [CONFIRMED]
  optional magic 0x10B (PE32); image base 0x10000000; entry RVA 0x0CBC90;
  timestamp 0x6372C39E; 5 sections .text/.rdata/.data/.rsrc/.reloc (reloc table present);
  NO export table; import dir RVA 0x0FC298 (0xF0 = 11 import descriptors).
- Imports: d3dx9_25.dll, USER32.dll, COMCTL32.dll, ADVAPI32.dll, KERNEL32.dll, GDI32.dll,
  WSOCK32.dll, WINMM.dll, PSAPI.DLL, BASS.dll, SHELL32.dll. gta_sa.exe is NOT imported —
  engine symbols are resolved at runtime.
- Telltale strings: "GTA:SA:MP" (window title), "samp.saa", "sampgui.png", "sampaux3.ttf",
  "Software\SAMP", "Game Version: %s", "I can't determine your GTA version.",
  "CONNECTION REJECTED: Bad mod version.", "CONNECTION REJECTED: Incorrect Version.",
  "team.sa-mp.com/report_037.php?addr=0x%X&gta=sa", ".detour", "CallNextHookEx",
  "GetProcAddress", "LoadLibraryA", "VirtualProtect", "PED:CAR_HOOKERTALK",
  "SAMP:FISHINGIDLE", SAMP000..SAMP111 pairs, "c:\sampcvs037r4\sampcvs\main\saco\Release\samp.pdb"
  (build path => 0.3.7 R4), "SAMPRW1/2", "SAMPHED", "SAMP/0.2.0".

Hook mechanism (CONFIRMED via the open 0.3.7 launcher+client source):
1. samp.exe (S-0012) launches gta_sa.exe with command line "-c -h <host> -p <port> -n <nick>"
   (or "-d" debug) using CREATE_SUSPENDED (launch3/launch3Dlg.cpp LaunchMod +
   CreateProcessAndInjectDll + InjectDLL). Injection = manual stub on the suspended
   thread's stack: push path, call LoadLibraryA("samp.dll") via a small x86 stub, restore
   all registers, jmp back to original EIP (VirtualProtectEx PAGE_EXECUTE_READWRITE +
   WriteProcessMemory + SetThreadContext). GetStartAddress() = LoadLibraryA address
   resolved locally (kernel32 base is shared).  [CONFIRMED from source]
2. samp.dll DllMain runs in the game process: detects GTA version (US 1.0 vs EU),
   installs engine hooks via Detours-style trampolines (".detour" section, VirtualProtect,
   CallNextHookEx for keyboard), resolves engine functions from gta_sa.exe's module base
   via GetProcAddress (import-free), hooks Direct3D9 (d3dx9_25.dll) for rendering, renames
   the window "GTA:SA:MP", opens samp.saa via CArchiveFS, starts the RakNet client.
   [CONFIRMED mechanism; engine symbol table itself INFERRED — runtime-resolved]
- samp.exe itself: 412,672 B; strings include "LoadLibraryA", "VirtualAlloc" — consistent
  with the above injection; the remote-write API names are not string-visible (obfuscated /
  resolved dynamically) — [UNVERIFIED detail, not material].

### CONFIRMED vs INFERRED vs STILL UNVERIFIED
- CONFIRMED: x86 PE32 identity; no gta_sa.exe import (runtime symbol resolution);
  detours/GetProcAddress/VirtualProtect hook toolkit; sample launcher's
  CREATE_SUSPENDED + LoadLibraryA stub injection (from source, matching strings).
- INFERRED: the precise set of engine entry points hooked (address/symbol table built at
  runtime); exact IAT/reloc hook list. Full verification needs a disassembler — beyond
  fingerprint scope, and NOT needed for the reimplementation path (Path A rebuilds the
  client against open.mp instead of reusing samp.dll).

----------------------------------------------------------------------
## ITEM 5 — Audio bank decoding (reimplementation constraint)
VERDICT: CONFIRMED (formats, codecs, encryption), with a CATALOGUE CORRECTION (B-AUDIO.md).
STILL UNVERIFIED: one byte-level detail (sfx offset semantics) that is already handled by
open tools.

### Catalogue correction (B-AUDIO / 01_FORMAT_REFERENCE)
Actual layout of this install (target read-only; sizes from filesystem):
- audio\streams\  = 16 STREAM BANKS: AA, ADVERTS, AMBIENCE, BEATS, CH, CO, CR, CUTSCENE,
  DS, HC, MH, MR, NJ, RE, RG, TK (radio stations/cutscene/ambience/adverts).
- audio\SFX\      = 9 SFX ARCHIVES: FEET, GENRL, PAIN_A, SCRIPT, SPC_EA, SPC_FA, SPC_GA,
  SPC_NA, SPC_PA. (The catalogue's "SPC_* = radio per locale" is WRONG; the SPC_* files
  are sound-effect archives, not radio stations.)
- audio\CONFIG\   = index tables: BankSlot.dat (216,902 B), BankLkup.dat (8,520 B),
  TrakLkup.dat (23,064 B), StrmPaks.dat (272 B), PakFiles.dat (468 B), EventVol.dat
  (45,402 B). StrmPaks.dat = stream package-name list ("AA\0ADVERTS\0..."); PakFiles.dat =
  sfx archive-name list ("FEET\0..."). Observed directly.
Lookup indices (SAAT manual, verified against table byte patterns): streams
  0=AA 1=ADVERTS 2=unused 3=AMBIENCE 4=BEATS 5=CH 6=CO 7=CR 8=CUTSCENE 9=DS 10=HC
  11=MH 12=MR 13=NJ 14=RE 15=RG 16=TK; sfx 0=FEET 1=GENRL 2=PAIN_A 3=SCRIPT 4=SPC_EA
  5=SPC_FA 6=SPC_GA 7=SPC_NA 8=SPC_PA.

### Stream banks (audio\streams\*): "GTA SA stream (SPC) format" — OGG VORBIS, XOR-obfuscated
- Each stream file = one or more tracks. Per track: track_header (8068 B) then Ogg data.
  track_header = beats[1000] x {s32 timing, s32 control} + lengths[8] x {u32 length,
  u32 extra} + u32 trailer. (beat data used by dance/lowrider minigames; lengths[] holds
  the Ogg length; length_index 0 or 1, extra ~48000 / 24000 for ambience.)
- The WHOLE track region (header + Ogg) is obfuscated by XOR with a rotating 16-byte key:
  {0xea,0x3a,0xc4,0xa1,0x9a,0xa8,0x14,0xf3,0x48,0xb0,0xd7,0x23,0x9d,0xe8,0xff,0xf1}.
  VERIFIED locally: CH decodes to default beats FF FF FF FF / 00 00 00 00 repeating; the
  AA fill bytes `15 C5 3B 5E 9A A8 14 F3 ...` = key ^ (FF FF FF FF 00 00 00 00 ...), and
  `27 F7 09 6C 57 65 D9 3E` = key ^ 0xCD (TH_LENGTH_DEFAULT). No literal "OggS" occurs in
  any stream file (confirmed by full-file binary scan) => encrypted on disk, as the
  community states ("streams on disk are encoded").
- Decoded payload = Ogg Vorbis (must be STEREO; mono plays at double speed per SAAT note).
  libogg/libvorbis handles decode after XOR.

### SFX archives (audio\SFX\*): "GTA SA SFX archive" — raw mono 16-bit PCM
- Archive = sequence of banks. Each bank = bank_header (4804 B) + that bank's sound data.
  bank_header = u32 num_sounds + 400 x sound_entry; sound_entry = {u32 offset, s32
  unknown_32 (-1), u16 sample_rate, u16 unknown_16}.
- sound_entry.offset is relative to the START of the bank's data (import code writes
  offset = running bank-local byte count after the header; export reads lengths from
  entry[i+1].offset - entry[i].offset, and the last sound's end from the BankLkup next
  bank offset or file end).
- Sound data = headerless MONO 16-bit little-endian PCM at the entry's sample_rate.
  VERIFIED locally on SPC_GA (1,103,880,528 B): num_sounds=0x4C=76; entries
  {0,-1,0x2EE0=12000Hz,...}, {0x6F1C,...}, {0xD4B6,...}, {0x14C56,...}, {0x1AD9E,...};
  the byte at offset 0x12C4 (bank data start, right after the 4804-B header) and the file
  tail are quiet 16-bit LE PCM samples. BankLkup.dat supplies per-bank {offset,length}.
- libsndfile / plain PCM handles decode (no codec work).

### Key constraint for a reimplementation (Runtime A, FreeBSD x86-64)
- Streams: implement (or pre-apply) the 16-byte XOR, then Vorbis-decode; tracks must stay
  stereo. Simplest data-pack action: pre-transcode every stream to plain .ogg during the
  Stage-2 assembly (catalog/07_PS5_EXECUTION.md) and ship the transcoded banks; keep
  originals for provenance.
- SFX: raw PCM, trivial; keep per-sound sample_rate from the entry tables; mono only.
- Recommended open stack on FreeBSD: libogg/libvorbis + libsndfile (all portable).
- STILL UNVERIFIED (byte level): none blocking; the offset-vs-absolute question is resolved
  as bank-relative by SAAT's import code; a reimplementation should follow SAAT/saat_sfx.cpp
  exactly. Sources: gtamods.com/wiki/Audio_stream; bedro0/San-Andreas-Audio-Toolkit
  (SAAT, GPL; saat_stream.h/.cpp, saat_sfx.h/.cpp, MANUAL.txt); MadGamerHD/GTA-SA-Audio-Editor
  (Python, same decryption approach); RFSA lineage (Radio Free San Andreas).

----------------------------------------------------------------------
## SOURCE URLS (all fetched/verified 2026-10-10)
- github.com/Zellcore/SA-MP (tree master; arctool2/, client/archive/, client/net/,
  sdk/raknet/, sdk/shared.h, launch3/) — Items 1, 2, 4 ground truth.
- github.com/ntfargo/Relapse-Exploit (payloads/elfldr-ps5-1360.elf; README) — Item 3.
- github.com/ps5-payload-dev/elfldr (socksrv.c, elfldr.c) — Item 3 protocol source.
- github.com/katursis/Pawn.RakNet; gitlab.com/ziggi/RakSAMP; vp817.github.io/RakNetProtocolDoc;
  github.com/Brunoo16/samp-packet-list; www.open.mp — Item 2 secondary sources.
- blast.hk/threads/186840 (samp-saa2-extract); ugbase.eu/threads/4627 + resources/1108
  (CustomSAA2); libertycity.net/files/gta-san-andreas/236672 (OpenSaa) — Item 1 corroboration.
- gtamods.com/wiki/Audio_stream; github.com/bedro0/San-Andreas-Audio-Toolkit (MANUAL.txt,
  src/saat_stream.h/.cpp, src/saat_sfx.h/.cpp); github.com/MadGamerHD/GTA-SA-Audio-Editor — Item 5.

## IMPLICATIONS FOR THE CONVERSION (catalog/07)
- samp.saa: do NOT ship the encrypted archive to the console unless the client reimpl can
  read SAA2; either (a) extract at build time with a SAAT-style SAA2 extractor once the
  embedded TEA/RSA keys are recovered, or (b) let the reimplementation read plain files
  (CustomSAA2/OpenSaa approach) — format fully documented, extraction is tractable.
- Network: implement the 0.3.7 protocol exactly as in Zellcore/SA-MP (XOR cipher keyed by
  port, PacketEnumerations enum order, SAMPRPC ids, UNRELIABLE sync / RELIABLE RPC split);
  open.mp is the compat baseline.
- Payload: build the runtime as a static ET_DYN x86-64 ELF with only R_X86_64_RELATIVE
  relocations, push raw over TCP 9021, keep the connection open; loader does the rest.
- Audio: pre-transcode streams to plain Ogg Vorbis (apply the 16-byte XOR), keep sfx as
  headerless mono PCM with a small index; link libogg/libvorbis/libsndfile.