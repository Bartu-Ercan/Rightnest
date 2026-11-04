#!/bin/bash
# Build and validate the custom distribution image. Publication is separate.
set -euo pipefail
cd "$(dirname "$0")/.."
DMGBUILD="$PWD/.build/dmg-tools/bin/dmgbuild"
[[ -x "$DMGBUILD" ]] || { echo 'Prepare tools: python3 -m venv .build/dmg-tools && .build/dmg-tools/bin/pip install -r script/packaging-requirements.txt' >&2; exit 1; }
./script/build_and_run.sh --release
APP="$PWD/dist/Rightnest.app"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP/Contents/Info.plist")"
STAGE="$(mktemp -d "${TMPDIR:-/tmp/}rightnest-package.XXXXXX")"
MOUNT="$STAGE/verify"
MOUNTED=0
cleanup() {
    if [[ "$MOUNTED" == 1 ]]; then hdiutil detach "$MOUNT" >/dev/null || return; fi
    rm -rf "$STAGE"
}
trap cleanup EXIT
/usr/bin/ditto --norsrc --noextattr "$APP" "$STAGE/Rightnest.app"
codesign --verify --strict "$STAGE/Rightnest.app"
lipo "$STAGE/Rightnest.app/Contents/MacOS/Rightnest" -verify_arch arm64
if strings "$STAGE/Rightnest.app/Contents/MacOS/Rightnest" | grep -E -- '--verify-textedit|--verify-safari|--verify-finder|--verify-app|--audit-compatibility|--stability-seconds|--measure-idle'; then
    echo 'Refusing to package developer test entrypoints.' >&2; exit 1
fi
OUTPUT="$PWD/dist/Rightnest-$VERSION-arm64.dmg"
"$DMGBUILD" -s "$PWD/script/dmg_settings.py" -D "app=$STAGE/Rightnest.app" \
    -D "background=$PWD/Assets/installer-background.tiff" "Rightnest $VERSION" "$OUTPUT"
hdiutil verify "$OUTPUT"
mkdir -p "$MOUNT"
hdiutil attach -readonly -nobrowse -mountpoint "$MOUNT" "$OUTPUT" >/dev/null
MOUNTED=1
codesign --verify --strict "$MOUNT/Rightnest.app"
lipo "$MOUNT/Rightnest.app/Contents/MacOS/Rightnest" -verify_arch arm64
test -s "$MOUNT/Rightnest.app/Contents/Resources/LICENSE.txt"
"$PWD/.build/dmg-tools/bin/python" - "$MOUNT" <<'PY_CHECK'
import sys
from pathlib import Path
from ds_store import DSStore
root = Path(sys.argv[1])
assert sorted(p.name for p in root.iterdir() if not p.name.startswith('.')) == ['Applications', 'Rightnest.app']
assert (root/'Applications').is_symlink() and (root/'Applications').readlink() == Path('/Applications')
with DSStore.open(str(root/'.DS_Store'), 'r') as store:
    entries = {(e.filename, e.code): e.value for e in store}
assert entries['Rightnest.app', b'Iloc'] == (210, 274)
assert entries['Applications', b'Iloc'] == (590, 274)
assert entries['.', b'bwsp']['ShowToolbar'] is False
assert entries['.', b'bwsp']['ShowSidebar'] is False
assert entries['.', b'icvp']['backgroundType'] == 2
assert (root/'.background.tiff').is_file()
print('Installer: two visible items, Applications target, icon positions and background verified')
PY_CHECK
hdiutil detach "$MOUNT" >/dev/null
MOUNTED=0
(cd "$PWD/dist" && shasum -a 256 "$(basename "$OUTPUT")") > "$OUTPUT.sha256"
printf '%s\n' "$OUTPUT" 'Early access. Locally signed, not Developer ID signed or notarized. See installation limitations.'
