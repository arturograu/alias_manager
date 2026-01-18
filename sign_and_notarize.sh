#!/bin/bash

# Load environment variables
if [ -f .env ]; then
    source .env
fi

# Set variables
APP="build/macos/Build/Products/Release/Alias Manager.app"
DMG="build/macos/Build/Products/Release/Alias Manager.dmg"
SIGN_ID=$(security find-identity -v -p codesigning | grep "Developer ID Application" | head -n1 | awk '{print $2}')

echo "Using signing identity: $SIGN_ID"

# Sign all frameworks and dylibs first
echo "Signing embedded frameworks and libraries..."
find "$APP" -name "*.framework" -type d | while read framework; do
    echo "Signing framework: $framework"
    codesign -f --options runtime --timestamp -s "$SIGN_ID" "$framework"
done

find "$APP" -name "*.dylib" -type f | while read dylib; do
    echo "Signing dylib: $dylib"
    codesign -f --options runtime --timestamp -s "$SIGN_ID" "$dylib"
done

# Sign the main app bundle
echo "Signing main application..."
codesign -f --options runtime --timestamp -s "$SIGN_ID" "$APP"

# Verify signing
echo "Verifying signature..."
codesign --verify --deep --strict --verbose=2 "$APP"

# Create DMG with drag & drop installer
echo "Creating DMG with drag & drop installer..."

# Remove old DMG if exists
rm -f "$DMG"

# Check if create-dmg is installed
if command -v create-dmg &> /dev/null; then
    create-dmg \
        --volname "Alias Manager" \
        --volicon "macos/AppIcon.icns" \
        --window-pos 200 120 \
        --window-size 600 400 \
        --icon-size 100 \
        --icon "Alias Manager.app" 150 185 \
        --hide-extension "Alias Manager.app" \
        --app-drop-link 450 185 \
        --no-internet-enable \
        "$DMG" \
        "$APP"
else
    echo "create-dmg not found, using fallback method..."
    # Fallback: Create a simple DMG with Applications symlink
    TEMP_DIR=$(mktemp -d)
    cp -R "$APP" "$TEMP_DIR/"
    ln -s /Applications "$TEMP_DIR/Applications"
    hdiutil create -volname "Alias Manager" -srcfolder "$TEMP_DIR" -ov -format UDZO "$DMG"
    rm -rf "$TEMP_DIR"
fi

# Submit DMG for notarization
echo "Submitting DMG for notarization..."
xcrun notarytool submit "$DMG" \
    --apple-id "$APPLE_ID" \
    --password "$APPLE_APP_SPECIFIC_PASSWORD" \
    --team-id "$APPLE_TEAM_ID" \
    --wait

# Staple the notarization to the DMG
echo "Stapling notarization to DMG..."
xcrun stapler staple "$DMG"

echo "Process complete!"
