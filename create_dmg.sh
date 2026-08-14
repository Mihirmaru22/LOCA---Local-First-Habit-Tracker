#!/bin/bash
set -e

# ==============================================================================
# Pluto DMG Package Builder
# ==============================================================================

echo "🪐 Building Pluto DMG Package..."

# Path to the exported .app (default or passed argument)
APP_PATH="${1:-}"

if [ -z "$APP_PATH" ]; then
    # Look for exported Pluto.app or Loca_Mac.app in common build directories
    if [ -d "$HOME/Desktop/Pluto.app" ]; then
        APP_PATH="$HOME/Desktop/Pluto.app"
    elif [ -d "$HOME/Desktop/Loca_Mac.app" ]; then
        APP_PATH="$HOME/Desktop/Loca_Mac.app"
    elif [ -d "$HOME/Downloads/Pluto.app" ]; then
        APP_PATH="$HOME/Downloads/Pluto.app"
    elif [ -d "$HOME/Downloads/Loca_Mac.app" ]; then
        APP_PATH="$HOME/Downloads/Loca_Mac.app"
    else
        # Find in Xcode DerivedData
        FOUND_APP=$(find ~/Library/Developer/Xcode/DerivedData -name "Loca_Mac.app" -type d 2>/dev/null | head -n 1 || true)
        if [ -n "$FOUND_APP" ] && [ -d "$FOUND_APP" ]; then
            APP_PATH="$FOUND_APP"
        fi
    fi
fi

if [ -z "$APP_PATH" ] || [ ! -d "$APP_PATH" ]; then
    echo "❌ Error: Could not locate Pluto.app or Loca_Mac.app."
    echo "Usage: ./create_dmg.sh /path/to/Pluto.app"
    exit 1
fi

echo "📦 Using App Bundle: $APP_PATH"

# Create a staging directory
STAGING_DIR="$(mktemp -d)/Pluto_DMG_Staging"
mkdir -p "$STAGING_DIR"

echo "📂 Staging application and Applications symlink..."
cp -R "$APP_PATH" "$STAGING_DIR/Pluto.app"
ln -s /Applications "$STAGING_DIR/Applications"

# Output DMG Path
OUTPUT_DMG="$HOME/Desktop/Pluto.dmg"
rm -f "$OUTPUT_DMG"

echo "💿 Creating DMG at: $OUTPUT_DMG..."
hdiutil create -volname "Pluto" -srcfolder "$STAGING_DIR" -ov -format UDZO "$OUTPUT_DMG"

# Clean up staging directory
rm -rf "$STAGING_DIR"

echo "✅ Success! Pluto DMG created at: $OUTPUT_DMG"
echo ""
echo "💡 Note for Testers:"
echo "If macOS says 'App is damaged / Move to Bin' due to Gatekeeper quarantine, have the tester run:"
echo "   xattr -cr /Applications/Pluto.app"
echo "Or Right-Click ➔ Open ➔ Open Anyway in System Settings."
