# Quick start — the near one-click path

The toolkit automates everything the project had to learn the hard way:
version checking, file placement, the tuned registry, resumable uploading
and verification. You fill in three paths; it does the rest.

## What you need first

1. A console on firmware 13.60 with the homebrew environment running and its
   FTP server started (the README above covers the baseline).
2. The Wine runtime on the console, built once from `wine-build/` on any
   Linux machine (the recipes there are the exact ones this project used).
   This is the only manual step, and it is one-time.
3. Your own installed copy of GTA San Andreas (PC, US v1.0 retail) and the
   SAMP 0.3.7-R5 client from sa-mp.mp.

## The three steps

    1. copy config.example.ini to config.ini and fill in your three paths
    2. python setup.py
    3. open the title on the console

That's it. The setup:

- verifies your game is the tested version before touching anything (a
  mismatch stops the run and tells you why)
- uploads the game and the client into the console's Wine prefix,
  resumable - an interrupted run just continues where it stopped
- applies the exact registry settings the project ended with
  (d3d9 native override, video memory size, offscreen rendering mode)
- reports every file it placed, and verifies by size

## Re-running

Safe at any time. Files already on the console with a matching size are
skipped, so re-runs after a game update on your PC send only what changed.

## If something breaks

The main README's "When something breaks" table lists every error code this
project encountered, in plain words, with what fixed each one.
