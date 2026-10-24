# GTA-SA-Harness — San Andreas Multiplayer on a PlayStation 5

Everything needed to understand and replicate the project documented at
**https://safest.st/insights/samp-gta-sa-on-ps5/** — running Grand Theft Auto:
San Andreas and the SAMP 0.3.7-R5 multiplayer client on a jailbroken
PlayStation 5, through a custom Wine build.

Written for non-experts. If you can follow a recipe, you can follow this.

---

## Read this first: the HZGaming part

The configuration shipped in this pack is set up for **one specific server:
Horizon Roleplay (HZGaming)** — `samp.hzgaming.net:7777`.

That is not a limitation of the method; it is a fact of how SAMP servers
work. Every server runs its own scripts, its own rules, and its own setup.
Connecting to a **different** server will need completely different
configuration, and working that out is on you. The good news: the code-base
in this repository contains everything you will need to make it happen —
every setting, every file reference, every decision — recorded and explained.

## What this is, in one paragraph

A jailbroken PS5 can run homemade programs. This project used that ability to
do something the console was never built for: run the PC version of GTA San
Andreas, plus the SAMP multiplayer client that its community servers use. The
trick was a piece of software called Wine — a translator that lets Windows
programs run on non-Windows systems — rebuilt by hand for the PS5. This
repository is the toolbox and instruction manual: the analysis notes, the
file inventories, the build knowledge, and the guide you are reading now.

## What this is NOT

- It contains **no game files**. GTA San Andreas is a commercial product;
  sharing it is illegal. You must use a copy you legally own.
- It contains **no console firmware or exploit tooling**. The jailbreak
  itself is public knowledge elsewhere; this pack points to it, it does not
  carry it.
- It is **not a one-click installer**. It is a documented path.

## What you need before you start

| You need | In plain words |
|---|---|
| A PS5 on firmware 13.60, jailbroken | The console's defences unlocked with public tools, so it can run homemade software |
| A legally owned copy of GTA San Andreas (PC) | The US v1.0 retail edition, "compact" version — 439 files, 4.74 GB when installed |
| The SAMP 0.3.7-R5 client | Free download from sa-mp.mp — this is the multiplayer add-on |
| A second computer running Linux | Used once, to rebuild Wine for the console ("the build server") |
| A USB stick and some patience | For moving files to the console |

Zone variant: **US v1.0** is the tested configuration. Other regions and
executable versions are untested.

## The words, explained

- **Jailbreak** — removing the console's restrictions so it can run programs
  Sony did not sign off on.
- **Payload** — a homemade program loaded onto the console over your home
  network.
- **Wine** — a translator. Windows programs speak "Windows"; Wine translates
  that into the console's native language in real time.
- **WoW64** — the part of Wine that lets a modern 64-bit system run old
  32-bit programs. SAMP is an old 32-bit program.
- **Prefix** — the fake mini-Windows that Wine keeps its files in. The game
  lives inside one.

## The steps, in order

1. **Set up the console.** Follow the public jailbreak instructions for
   firmware 13.60 (start with the Relapse-Exploit project, below). You will
   end up with etaHEN running and a payload manager on the home screen.
2. **Learn to send a payload.** Practice with something harmless — a splash
   screen. If a box with a moving rectangle appears on your TV, your
   pipeline works.
3. **Do NOT write your own renderer.** The first strategy in this project was
   rebuilding the game's graphics from scratch. It produced something that
   looked like an off-brand clone. Weeks were spent learning this lesson so
   you do not have to — the notes in `state/journal.md` (10–13 October) are
   the receipt.
4. **Rebuild Wine for the console.** On your Linux machine, follow the
   prospero-win project (below) as the foundation and build Wine with WoW64
   support (`--enable-archs=i386,x86_64`). This is the one genuinely
   technical step; the prospero-win repository documents it.
5. **Validate before you load anything.** Run the Vulkan probe and the CPU
   test first. Both should say PASS. Only then put your game copy into the
   Wine prefix.
6. **Boot the game.** Expect crashes at first — the error codes carry
   addresses, which makes them fixable. The journal records every crash this
   project hit and what fixed it.
7. **Add SAMP.** Install the 0.3.7-R5 client into the same prefix. The known
   startup fault lands inside Wine itself, not the game — see "When something
   breaks" below. Set your own username in the client settings.
8. **Wire up input.** The console has no keyboard, so the project connected
   the PS5's own on-screen keyboard into Wine. The controller mapping used:
   left stick moves the cursor, X is left-click, the touchpad summons the
   keyboard, L1 + Triangle opens chat.

## When something breaks

| What you see | What it means | What to do |
|---|---|---|
| CE-100008-9 / CE-107750-0 | The program did not load | Check how the payload was packaged, not the code inside it |
| CE-108255-1 | The program crashed with a memory-protection fault | Note the faulting address in the error, find it in the journal, work backwards |
| SAMP crash at 0x7BCB15AA | A fault inside Wine's translator, not the game or client | Fix the compatibility layer; the journal records the diagnosis path |
| Typed characters appear as ▢ squares | A **display-side** encoding mismatch — the underlying string is correct and executes | **Not game-breaking.** Login, chat and commands all work through it; a future fix is queued |

## Is this legal?

Running software you own on hardware you own is, in general, lawful. The
console-side tooling referenced is publicly documented. What is **not** lawful
is distributing the game's files — and nothing in this repository does. EU
Directive 2001/29/EC and 17 U.S.C. §106 apply. This project operated on a
legitimately owned retail copy throughout.

## Roadmap: what this does not do yet

- **Server restart support.** The current build does not survive a server-side
  restart: when Horizon Roleplay cycles its scripts and sessions, rejoining
  means starting the client again from the console. Closing that gap is the
  next functional work.
- **Stability under long play.** Random crashes are still present. The journal
  records every crash signature collected so far — the build needs hours of
  runtime against them, not new architecture.
- **Display-side text.** Characters typed through the on-screen keyboard
  render as squares in the client's fields — even though the underlying string
  is correct and executes. Not game-breaking; queued for a future fix.
## What is inside this repository

- `HARNESS.md` — the constitution: how the whole analysis was run
- `modules/` — the phases, in order
- `scripts/` — the deterministic tooling
- `kb/` — 22 notation files: the distilled knowledge of the game and the
  SAMP client, including the research notes
- `catalog/` — the assembled catalogue code-base
- `state/` — the inventory manifest (439 files, SHA-256 hashes) and the full
  journal: every decision, every failure, every fix

## The projects this stands on

| Project | What it gave this work |
|---|---|
| [Relapse-Exploit](https://github.com/ntfargo/Relapse-Exploit) | The firmware 13.60 entry point |
| [elfldr](https://github.com/ps5-payload-dev/elfldr) · [PS5 payload SDK](https://github.com/ps5-payload-dev/sdk) | Payload loading and the toolchain |
| [prospero-win](https://github.com/mpereiraesaa/prospero-win) | The Windows compatibility foundation |
| [gta-reversed](https://github.com/gta-reversed/gta-reversed) | The community reverse-engineering of the game |
| [librw](https://github.com/aap/librw) | The open RenderWare-compatible renderer |
| [gtasa_vita](https://github.com/TheOfficialFloW/gtasa_vita) | The precedent that a port was possible at all |
| [sa-mp.mp](https://sa-mp.mp) | The multiplayer client |

---

SAFEST Security Limited — [safest.st](https://safest.st) — dev@safest.st
