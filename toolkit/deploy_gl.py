import datetime, ftplib, os, sys

import configparser, os
_CFG = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'config.ini')
HOST = 'console-ip'
PORT = 1337
if os.path.isfile(_CFG):
    _cp = configparser.ConfigParser(); _cp.read(_CFG)
    HOST = _cp.get('console', 'ftp_host', fallback=HOST)
    PORT = _cp.getint('console', 'ftp_port', fallback=PORT)
PORT = 1337
BASE = '/data/homebrew/PPSA99001'
SRC = r'C:\Users\X\GTA-SA-Harness\build\glbuild\dist\PPSA99001'

ftp = ftplib.FTP()

try:
    ftp.connect(HOST, PORT, timeout=15)
    ftp.login()
except ftplib.all_errors as e:
    print(f'CONNECT FAILED {HOST}:{PORT} - {e}')
    sys.exit(1)

print('FTP:', ftp.getwelcome())


def ensure(p):
    parts = p.strip('/').split('/')
    cur = ''
    for part in parts:
        cur += '/' + part
        try:
            ftp.mkd(cur)
        except ftplib.error_perm:
            pass


def chmod(p):
    try:
        ftp.sendcmd('SITE CHMOD 777 ' + p)
    except Exception:
        pass


def walk_delete(path):
    try:
        names = ftp.nlst(path)
    except Exception:
        return
    for n in names:
        p = n if n.startswith('/') else path.rstrip('/') + '/' + n
        try:
            ftp.delete(p)
        except Exception:
            try:
                ftp.cwd(p)
                ftp.cwd('/')
                walk_delete(p)
            except Exception:
                pass
    try:
        ftp.rmd(path)
    except Exception:
        pass


if not os.path.isdir(SRC):
    print('LOCAL PACKAGE MISSING:', SRC)
    print('build the app package first (dist/PPSA99001/)')
    ftp.quit()
    sys.exit(1)


def build_timestamp():
    eboot = os.path.join(SRC, 'eboot.bin')
    src = eboot if os.path.isfile(eboot) else SRC
    return datetime.datetime.fromtimestamp(os.path.getmtime(src)).strftime('%Y-%m-%d %H:%M:%S')


def local_file_count(path):
    n = 0
    for root, dnames, files in os.walk(path):
        n += len(files)
    return n


def remote_file_count(path):
    total = 0
    try:
        entries = list(ftp.mlsd(path, facts=['type']))
    except ftplib.all_errors as e:
        print('  remote list failed', path, e)
        return -1
    for name, facts in entries:
        if name in ('.', '..') or facts.get('type') in ('cdir', 'pdir'):
            continue
        p = path.rstrip('/') + '/' + name
        if facts.get('type') == 'dir':
            sub = remote_file_count(p)
            if sub < 0:
                return -1
            total += sub
        else:
            total += 1
    return total


BUILD_TS = build_timestamp()
expected = local_file_count(SRC)
print('build timestamp:', BUILD_TS)
print('local package files:', expected)

print('cleaning old PPSA99001...')
walk_delete(BASE)

count = 0
dirs = set()
for root, dnames, files in os.walk(SRC):
    for f in files:
        lp = os.path.join(root, f)
        rel = os.path.relpath(lp, SRC).replace(os.sep, '/')
        rp = f'{BASE}/{rel}'
        parent = rp.rsplit('/', 1)[0]
        ensure(parent)
        d = parent
        while d.startswith(BASE):
            dirs.add(d)
            if d == BASE:
                break
            d = d.rsplit('/', 1)[0]
        with open(lp, 'rb') as fh:
            ftp.storbinary('STOR ' + rp, fh)
        chmod(rp)
        print('  ok', rel, os.path.getsize(lp))
        count += 1

dirs.add(BASE)
for d in sorted(dirs, key=len):
    chmod(d)

print(f'deployed {count} files, chmod 777 on {count} files + {len(dirs)} dirs')

print('verify file count (recursive mlsd):')
uploaded = remote_file_count(BASE)
print(f'file count check: local {expected} vs remote {uploaded}')
if uploaded != expected:
    print(f'VERIFY FAILED: remote file count {uploaded} != local {expected}')
    ftp.quit()
    sys.exit(1)
print(f'VERIFY OK: {uploaded}/{expected} files on console')

print('verify listing (mlsd):')
ok = 0
for name, facts in ftp.mlsd(BASE, facts=['type', 'size']):
    print(' ', name, facts.get('type'), facts.get('size', ''))
    ok += 1
print(f'mlsd entries: {ok}')
ftp.quit()
print('build timestamp:', BUILD_TS)
print('DEPLOY OK')
