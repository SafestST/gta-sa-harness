import ftplib, io, json, os, struct, sys

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
SELF_MAGIC = 0x1D3D154F

CORE = [
    'eboot.bin',
    'sce_module/libc.prx',
    'sce_sys/param.json',
]

ftp = ftplib.FTP()

try:
    ftp.connect(HOST, PORT, timeout=15)
    ftp.login()
except ftplib.all_errors as e:
    print(f'CONNECT FAILED {HOST}:{PORT} - {e}')
    sys.exit(1)

print('FTP:', ftp.getwelcome())
fail = 0


def walk_list(path, prefix=''):
    out = []
    try:
        entries = list(ftp.mlsd(path, facts=['type']))
    except Exception as e:
        print(f'  mlsd failed {path}: {e}')
        return out
    for name, facts in entries:
        if name in ('.', '..'):
            continue
        rel = (prefix + '/' + name) if prefix else name
        if facts.get('type') == 'dir':
            out.extend(walk_list(path.rstrip('/') + '/' + name, rel))
        else:
            out.append(rel)
    return out


print(f'listing {BASE} ...')
try:
    remote = walk_list(BASE)
except Exception as e:
    print(f'LIST FAILED: {e}')
    ftp.quit()
    sys.exit(1)

remote_set = set(remote)
print(f'remote files: {len(remote)}')
for r in sorted(remote_set):
    print('  ', r)

expected = list(CORE)
if os.path.isdir(SRC):
    for root, dnames, files in os.walk(SRC):
        for f in files:
            rel = os.path.relpath(os.path.join(root, f), SRC).replace(os.sep, '/')
            if rel not in expected:
                expected.append(rel)
    print(f'(expected set from local package: {len(expected)} files)')
else:
    print('(local package missing - checking core files only)')

for e in expected:
    if e not in remote_set:
        print(f'MISSING: {e}')
        fail += 1

print('downloading eboot.bin for SELF check...')
buf = io.BytesIO()
try:
    ftp.retrbinary('RETR ' + BASE + '/eboot.bin', buf.write)
except Exception as e:
    print(f'EBOOT DOWNLOAD FAILED: {e}')
    fail += 1
else:
    data = buf.getvalue()
    if len(data) < 4:
        print(f'EBOOT TOO SMALL: {len(data)} bytes')
        fail += 1
    else:
        magic = struct.unpack('<I', data[:4])[0]
        print(f'eboot.bin size={len(data)} magic=0x{magic:08X}')
        if magic != SELF_MAGIC:
            print(f'BAD SELF MAGIC (expected 0x{SELF_MAGIC:08X})')
            fail += 1
        else:
            print('SELF magic OK')

print('downloading sce_sys/param.json...')
buf = io.BytesIO()
try:
    ftp.retrbinary('RETR ' + BASE + '/sce_sys/param.json', buf.write)
    param = json.loads(buf.getvalue().decode('utf-8'))
    print('param.json:')
    print(json.dumps(param, indent=2))
    tid = param.get('titleId')
    if tid != 'PPSA99001':
        print(f'WARN: titleId is {tid!r}, expected PPSA99001')
except Exception as e:
    print(f'PARAM READ FAILED: {e}')
    fail += 1

ftp.quit()
if fail:
    print(f'VERIFY FAILED ({fail} problem(s))')
    sys.exit(1)
print('VERIFY OK')
