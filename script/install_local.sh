#!/bin/bash
# Install an already built app outside the source tree (and outside Desktop sync).
set -euo pipefail
cd "$(dirname "$0")/.."
SOURCE="$PWD/dist/Rightnest.app"
PARENT="$HOME/Applications"
TARGET="$PARENT/Rightnest.app"
[[ -f "$SOURCE/Contents/MacOS/Rightnest" ]] || { echo 'Build first: ./script/build_and_run.sh --build' >&2; exit 1; }
mkdir -p "$PARENT"
STAGE="$(mktemp -d "$PARENT/.starboard-install.XXXXXX")"
trap 'rm -rf "$STAGE"' EXIT
/usr/bin/ditto --norsrc --noextattr "$SOURCE" "$STAGE/Rightnest.app"
/usr/bin/xattr -cr "$STAGE/Rightnest.app"
/usr/bin/codesign --verify --strict "$STAGE/Rightnest.app"
# One-time rename of our own earlier prototype, preserving its bundle identity.
LEGACY="$PARENT/Starboard.app"
if [[ ! -e "$TARGET" && -d "$LEGACY" ]] &&
   [[ "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$LEGACY/Contents/Info.plist")" == dev.bartuercan.starboard ]]; then
    pkill -x Starboard >/dev/null 2>&1 || true
    mv "$LEGACY" "$TARGET"
fi
if [[ -e "$TARGET" ]]; then
    ID="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$TARGET/Contents/Info.plist")"
    [[ "$ID" == dev.bartuercan.starboard ]] || { echo 'Another app occupies the destination; installation stopped.' >&2; exit 1; }
    if diff -qr "$TARGET/Contents" "$STAGE/Rightnest.app/Contents" >/dev/null &&
       /usr/bin/codesign --verify --strict "$TARGET" 2>/dev/null; then
        echo "Already installed: $TARGET"
        exit 0
    fi
    pkill -x Rightnest >/dev/null 2>&1 || true
    mv "$TARGET" "$STAGE/previous.app"
fi
if ! mv "$STAGE/Rightnest.app" "$TARGET"; then
    if [[ -d "$STAGE/previous.app" ]]; then mv "$STAGE/previous.app" "$TARGET"; fi
    exit 1
fi
echo "Installed: $TARGET"
echo 'Open this installed copy and grant permission to it. Development updates can require a new grant.'
