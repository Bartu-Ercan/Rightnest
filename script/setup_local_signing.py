#!/usr/bin/env python3
"""Create an isolated, local-only signing identity. Does not change system trust.
Private material stays outside the source checkout; never publish this keychain.
"""
import os
from pathlib import Path
import secrets
import subprocess
import tempfile

root = Path.home() / '.local/share/starboard-signing'
root.mkdir(parents=True, exist_ok=True, mode=0o700)
os.chmod(root, 0o700)
keychain = root / 'development.keychain-db'
password_file = root / 'keychain-password'

def run(args):
    result = subprocess.run(args, capture_output=True, text=True)
    if result.returncode:
        # Never print full command arguments (they may contain a generated keychain password).
        raise SystemExit(f'{args[0]} failed: {result.stderr.strip()}')
    return result.stdout

if not keychain.exists():
    password_file.write_text(secrets.token_urlsafe(40))
    os.chmod(password_file, 0o600)
    password = password_file.read_text()
    run(['security', 'create-keychain', '-p', password, str(keychain)])
    run(['security', 'set-keychain-settings', '-lut', '21600', str(keychain)])
    run(['security', 'unlock-keychain', '-p', password, str(keychain)])
    with tempfile.TemporaryDirectory(dir=root) as directory:
        temporary = Path(directory)
        key, cert, bundle = [temporary / name for name in ['key.pem', 'cert.pem', 'identity.p12']]
        run(['openssl', 'req', '-new', '-x509', '-newkey', 'rsa:3072', '-nodes', '-days', '3650',
             '-subj', '/CN=Starboard Local Development', '-keyout', str(key), '-out', str(cert),
             '-addext', 'basicConstraints=critical,CA:FALSE',
             '-addext', 'keyUsage=critical,digitalSignature', '-addext', 'extendedKeyUsage=codeSigning'])
        os.chmod(key, 0o600)
        run(['openssl', 'pkcs12', '-export', '-legacy', '-inkey', str(key), '-in', str(cert),
             '-out', str(bundle), '-passout', f'file:{password_file}'])
        run(['security', 'import', str(bundle), '-k', str(keychain), '-P', password, '-T', '/usr/bin/codesign'])
        (root / 'certificate.pem').write_bytes(cert.read_bytes())
else:
    run(['security', 'unlock-keychain', '-p', password_file.read_text(), str(keychain)])
run(['security', 'find-certificate', '-c', 'Starboard Local Development', str(keychain)])
print('Local keychain ready. No global trust or permission change performed.')
print(keychain)
