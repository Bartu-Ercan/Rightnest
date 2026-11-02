#!/bin/bash
# Local preview packaging only. Does not publish or bypass Gatekeeper.
set -euo pipefail
cd "$(dirname "$0")/.."
./script/build_and_run.sh --release
APP="$PWD/dist/Rightnest.app"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP/Contents/Info.plist")"
STAGE="$(mktemp -d "${TMPDIR:-/tmp/}rightnest-package.XXXXXX")"
trap 'rm -rf "$STAGE"' EXIT
/usr/bin/ditto --norsrc --noextattr "$APP" "$STAGE/Rightnest.app"
codesign --verify --strict "$STAGE/Rightnest.app"
lipo "$STAGE/Rightnest.app/Contents/MacOS/Rightnest" -verify_arch arm64
if strings "$STAGE/Rightnest.app/Contents/MacOS/Rightnest" | grep -E -- '--verify-textedit|--audit-compatibility'; then
    echo 'Refusing to package developer test entrypoints.' >&2; exit 1
fi
ln -s /Applications "$STAGE/Applications"
cp docs/INSTALL.md "$STAGE/READ-ME-FIRST.md"
cp LICENSE "$STAGE/LICENSE.txt"
OUTPUT="$PWD/dist/Rightnest-$VERSION-preview-arm64.dmg"
hdiutil create -volname "Rightnest $VERSION Preview" -srcfolder "$STAGE" -ov -format UDZO "$OUTPUT"
hdiutil verify "$OUTPUT"
shasum -a 256 "$OUTPUT" > "$OUTPUT.sha256"
printf '%s\n' "$OUTPUT" 'Developer preview. Not Developer ID signed or notarized. See installation limitations.'
