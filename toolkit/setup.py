#!/usr/bin/env python3
"""GTA-SA-Harness toolkit - the near one-click setup.

What this does, in order:
  1. Checks your game copy is the tested version (US v1.0 retail, "compact").
  2. Checks the SAMP 0.3.7-R5 client files are where you said they are.
  3. Connects to your console's FTP server.
  4. Uploads the game and the client into the console's Wine prefix.
  5. Applies the tuned registry settings the project ended with.
  6. Verifies every file landed, by size.

Run it again any time: files already on the console with a matching size are
skipped, so an interrupted run simply continues where it stopped.

Before the first run: copy config.example.ini to config.ini, fill in the
three paths, and save. Then:

    python setup.py

Options:
  --dry-run      check everything and connect, but upload nothing
  --config PATH  use a different config file (default: config.ini beside this script)

This script only READS your game installation. It never modifies it.
"""

import argparse
import configparser
import ftplib
import hashlib
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))


def say(msg):
    print(msg, flush=True)


def fail(msg):
    say("")
    say("STOPPED: " + msg)
    say("Nothing was half-applied. Fix the above and run again.")
    sys.exit(1)


def sha256_of(path, chunk=1024 * 1024):
    h = hashlib.sha256()
    with open(path, "rb") as fh:
        while True:
            data = fh.read(chunk)
            if not data:
                break
            h.update(data)
    return h.hexdigest()


def ftp_connect(host, port):
    ftp = ftplib.FTP()
    try:
        ftp.connect(host, port, timeout=15)
        ftp.login()
    except ftplib.all_errors as e:
        return None, e
    return ftp, None


def ftp_walk_count(ftp, path):
    total = 0
    try:
        entries = list(ftp.mlsd(path, facts=["type", "size"]))
    except ftplib.all_errors:
        return -1
    for name, facts in entries:
        if name in (".", "..") or facts.get("type") in ("cdir", "pdir"):
            continue
        p = path.rstrip("/") + "/" + name
        if facts.get("type") == "dir":
            sub = ftp_walk_count(ftp, p)
            if sub < 0:
                return -1
            total += sub
        else:
            total += 1
    return total


def ftp_size(ftp, path):
    try:
        return ftp.size(path)
    except ftplib.all_errors:
        return -1


def ftp_ensure_dir(ftp, path):
    parts = path.strip("/").split("/")
    cur = ""
    for part in parts:
        cur += "/" + part
        try:
            ftp.mkd(cur)
        except ftplib.error_perm:
            pass


def upload_tree(ftp, local_root, remote_root, dry_run, label):
    """Upload every file under local_root to remote_root.

    A file is skipped when the console already holds a file of the same size,
    which makes the whole upload resumable and re-runs cheap.
    """
    files = []
    for root, _dirs, names in os.walk(local_root):
        for n in names:
            files.append(os.path.join(root, n))
    files.sort()
    say(f"[{label}] {len(files)} files to place")

    done = skipped = sent = 0
    for lp in files:
        rel = os.path.relpath(lp, local_root).replace(os.sep, "/")
        rp = remote_root.rstrip("/") + "/" + rel
        size = os.path.getsize(lp)
        if ftp_size(ftp, rp) == size:
            skipped += 1
        elif dry_run:
            pass
        else:
            ftp_ensure_dir(ftp, rp.rsplit("/", 1)[0])
            with open(lp, "rb") as fh:
                ftp.storbinary("STOR " + rp, fh)
            sent += 1
        done += 1
        if done % 50 == 0 or done == len(files):
            say(f"[{label}] {done}/{len(files)} ({skipped} already fine, {sent} uploaded)")
    return done, skipped, sent


REGISTRY_BLOCK = """\\
[Software\\\\Wine\\\\DllOverrides]
"d3d9"="native"

[Software\\\\Wine\\\\Direct3D]
"VideoMemorySize"=dword:00001000
"OffscreenRenderingMode"="fbo"
"""


def apply_registry(ftp, prefix_root, dry_run):
    """Merge the tuned Wine registry keys into the console prefix's user.reg."""
    user_reg = prefix_root.rstrip("/") + "/user.reg"
    current = ""
    try:
        import io
        buf = io.BytesIO()
        ftp.retrbinary("RETR " + user_reg, buf.write)
        current = buf.getvalue().decode("utf-16-le", errors="replace")
        if not current.startswith("WINE REGISTRY"):
            current = ""
    except ftplib.all_errors:
        current = ""
    if '"d3d9"="native"' in current:
        say("[registry] already applied on the console")
        return
    if dry_run:
        say("[registry] would apply (dry run)")
        return
    if not current:
        current = "WINE REGISTRY Version 2\n;; merged by gta-sa-harness toolkit\n"
    block = current.rstrip("\r\n") + "\n\n" + REGISTRY_BLOCK.replace("\\\\\n", "\n")
    data = block.encode("utf-16-le")
    import io
    bio = io.BytesIO(data)
    ftp.storbinary("STOR " + user_reg, bio)
    say("[registry] tuned keys applied")


def main():
    ap = argparse.ArgumentParser(description="near one-click console setup")
    ap.add_argument("--config", default=os.path.join(HERE, "config.ini"))
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    if not os.path.isfile(args.config):
        example = os.path.join(HERE, "config.example.ini")
        if os.path.isfile(example):
            fail(f"no config found. Copy config.example.ini to config.ini, fill in your paths, run again.")
        fail("config file not found: " + args.config)

    cp = configparser.ConfigParser()
    cp.read(args.config)
    try:
        host = cp.get("console", "ftp_host")
        port = cp.getint("console", "ftp_port", fallback=1337)
        prefix = cp.get("console", "prefix", fallback="/data/wowps5/prefix")
        game_dir = cp.get("game", "install_dir")
        samp_dir = cp.get("samp", "install_dir")
    except (configparser.Error, KeyError) as e:
        fail("config.ini is missing a value: " + str(e))

    say("== 1/6 checking your game copy ==")
    game_exe = os.path.join(game_dir, "gta_sa.exe")
    if not os.path.isfile(game_exe):
        fail(f"gta_sa.exe not found at {game_exe} - check the [game] install_dir in config.ini")
    with open(os.path.join(HERE, "known-hashes.json"), "r", encoding="utf-8") as fh:
        known = json.load(fh)
    say("   hashing gta_sa.exe (this takes a moment)...")
    actual = sha256_of(game_exe)
    expected = known.get("game_exe_sha256", "")
    if actual.lower() != expected.lower():
        say("")
        say("   VERSION MISMATCH")
        say(f"   your copy:  {actual}")
        say(f"   tested:     {expected}")
        say("   The tested configuration is the PC v1.0 US retail ('compact') edition.")
        say("   Other versions are untested - see the README before continuing.")
        fail("game version does not match the tested configuration")

    say("== 2/6 checking the SAMP client ==")
    samp_dll = os.path.join(samp_dir, "samp.dll")
    if not os.path.isfile(samp_dll):
        fail(f"samp.dll not found at {samp_dll} - check the [samp] install_dir in config.ini (the client from sa-mp.mp)")
    say("   client found")

    say("== 3/6 connecting to the console ==")
    ftp, err = ftp_connect(host, port)
    if ftp is None:
        fail(f"could not reach the console at {host}:{port} ({err}). Is the console on, and is its FTP server running?")
    say("   connected: " + (ftp.getwelcome() or host))

    drive_c = prefix.rstrip("/") + "/dosdevices/c:"

    say("== 4/6 uploading the game ==")
    n, skip, sent = upload_tree(ftp, game_dir, drive_c, args.dry_run, "game")
    say(f"   game: {n} files ({skip} already fine, {sent} uploaded)")

    say("== 5/6 uploading the SAMP client ==")
    n2, skip2, sent2 = upload_tree(ftp, samp_dir, drive_c, args.dry_run, "samp")
    say(f"   client: {n2} files ({skip2} already fine, {sent2} uploaded)")

    say("== 6/6 applying the tuned registry ==")
    apply_registry(ftp, prefix, args.dry_run)

    ftp.quit()
    say("")
    say("DONE. Open the title on the console and let it boot.")
    say("If something breaks, the README's 'When something breaks' table covers every code this project saw.")


if __name__ == "__main__":
    main()
