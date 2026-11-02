#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
MODE="${1:-run}"
case "$MODE" in run|--verify|--build|--debug|--logs|--telemetry|--release) ;; *) echo "Usage: $0 [--build|--release|--verify|--debug|--logs|--telemetry]" >&2; exit 2;; esac
CONFIG=debug
if [[ "$MODE" == "--release" ]]; then CONFIG=release; fi
swift build -c "$CONFIG" --arch arm64 --product Rightnest
BIN="$(swift build -c "$CONFIG" --arch arm64 --show-bin-path)/Rightnest"
DIST_BUNDLE="$PWD/dist/Rightnest.app"
BUILD_STAGE="$(mktemp -d "${TMPDIR:-/tmp/}starboard-build.XXXXXX")"
trap 'rm -rf "$BUILD_STAGE"' EXIT
BUNDLE="$BUILD_STAGE/Rightnest.app"
if [[ "$MODE" != "--build" && "$MODE" != "--release" ]]; then
    pkill -x Rightnest >/dev/null 2>&1 || true
fi
mkdir -p "$BUNDLE/Contents/MacOS"
cp "$BIN" "$BUNDLE/Contents/MacOS/Rightnest.next"
mv -f "$BUNDLE/Contents/MacOS/Rightnest.next" "$BUNDLE/Contents/MacOS/Rightnest"
cat > "$BUNDLE/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>Rightnest</string>
<key>CFBundleIdentifier</key><string>dev.bartuercan.starboard</string>
<key>CFBundleName</key><string>Rightnest</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>0.1.0</string>
<key>CFBundleVersion</key><string>2</string>
<key>RightnestReleasesURL</key><string>https://github.com/Bartu-Ercan/Rightnest/releases</string>
<key>CFBundleDevelopmentRegion</key><string>en</string>
<key>CFBundleLocalizations</key><array><string>en</string><string>tr</string></array>
<key>LSMinimumSystemVersion</key><string>13.0</string>
<key>LSUIElement</key><true/>
<key>NSPrincipalClass</key><string>NSApplication</string>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
if [[ -f "$PWD/Assets/AppIcon.icns" ]]; then
    mkdir -p "$BUNDLE/Contents/Resources"
    cp "$PWD/Assets/AppIcon.icns" "$BUNDLE/Contents/Resources/AppIcon.icns"
    /usr/libexec/PlistBuddy -c 'Add :CFBundleIconFile string AppIcon' "$BUNDLE/Contents/Info.plist"
fi
/usr/bin/xattr -cr "$BUNDLE"
STARBOARD_SIGNING_IDENTITY="${RIGHTNEST_SIGNING_IDENTITY:-${STARBOARD_SIGNING_IDENTITY:-}}"
LOCAL_SIGNING_DIR="$HOME/.local/share/starboard-signing"
if [[ -z "${STARBOARD_SIGNING_IDENTITY:-}" && -f "$LOCAL_SIGNING_DIR/development.keychain-db" ]]; then
    security unlock-keychain -p "$(cat "$LOCAL_SIGNING_DIR/keychain-password")" "$LOCAL_SIGNING_DIR/development.keychain-db"
    codesign --force --timestamp=none --keychain "$LOCAL_SIGNING_DIR/development.keychain-db" \
        --sign 'Starboard Local Development' "$BUNDLE"
    echo "Signed with stable local development identity (not a public distribution signature)." >&2
elif [[ -n "${STARBOARD_SIGNING_IDENTITY:-}" ]]; then
    codesign --force --options runtime --timestamp --sign "$STARBOARD_SIGNING_IDENTITY" "$BUNDLE"
else
    codesign --force --sign - "$BUNDLE" >/dev/null
    echo "Ad-hoc build: run python3 script/setup_local_signing.py for a stable local development identity." >&2
fi
codesign --verify --strict "$BUNDLE"
# Sign on a local temporary volume first: Desktop metadata can be added while signing.
mkdir -p "$PWD/dist"
if [[ -d "$DIST_BUNDLE" ]]; then rm -rf "$DIST_BUNDLE"; fi
/usr/bin/ditto --norsrc --noextattr "$BUNDLE" "$DIST_BUNDLE"
BUNDLE="$DIST_BUNDLE"
if [[ "$MODE" != "--build" && "$MODE" != "--release" ]]; then
    ./script/install_local.sh
    BUNDLE="$HOME/Applications/Rightnest.app"
fi
case "$MODE" in
 --build|--release) echo "$BUNDLE";;
 --debug) lldb -- "$BUNDLE/Contents/MacOS/Rightnest";;
 --logs|--telemetry|--release) open -n "$BUNDLE"; /usr/bin/log stream --info --style compact --predicate 'process == "Rightnest"';;
 --verify) open -n "$BUNDLE"; sleep 2; pgrep -x Rightnest >/dev/null; echo "Rightnest process is running";;
 run) open -n "$BUNDLE";;
esac
