#!/bin/bash
# Build, bundle, ad-hoc sign, install, and (by default) enable start-at-login.
# Usage:
#   ./build.sh              build + install to /Applications + start at login + launch
#   ./build.sh --no-login   build + install only (no LaunchAgent, no auto-launch)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
EXEC_NAME="JudeGaoRoutine"
APP_DISPLAY="Jude Gao Routine"
APP_DIR="/Applications/$APP_DISPLAY.app"
BUILD="$ROOT/build"
LABEL="com.judegao.routine"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"

NO_LOGIN=0
[ "${1:-}" = "--no-login" ] && NO_LOGIN=1

echo "==> Compiling"
rm -rf "$BUILD"; mkdir -p "$BUILD"
xcrun swiftc \
  -O \
  -target arm64-apple-macos13.0 \
  -framework AppKit \
  -o "$BUILD/$EXEC_NAME" \
  "$ROOT/Sources/"*.swift

echo "==> Assembling $APP_DIR"
# Stop any running copy / LaunchAgent so we can overwrite the binary cleanly.
launchctl unload -w "$PLIST" 2>/dev/null || true
pkill -x "$EXEC_NAME" 2>/dev/null || true
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
cp "$BUILD/$EXEC_NAME" "$APP_DIR/Contents/MacOS/$EXEC_NAME"
cp "$ROOT/Info.plist" "$APP_DIR/Contents/Info.plist"

echo "==> Ad-hoc signing"
codesign --force --sign - "$APP_DIR" || echo "    (codesign skipped — app still runs)"

if [ "$NO_LOGIN" -eq 1 ]; then
  echo "==> Done. Launch with: open \"$APP_DIR\""
  exit 0
fi

echo "==> Enabling start-at-login + launching"
mkdir -p "$(dirname "$PLIST")"
cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>$LABEL</string>
  <key>ProgramArguments</key>
  <array><string>$APP_DIR/Contents/MacOS/$EXEC_NAME</string></array>
  <key>RunAtLoad</key><true/>
  <key>ProcessType</key><string>Interactive</string>
</dict>
</plist>
EOF
launchctl load -w "$PLIST"

echo "==> Done. Jude Gao Routine is running in your menu bar (💻 45:00)."
echo "    Disable auto-start from the menu, or: launchctl unload -w \"$PLIST\""
