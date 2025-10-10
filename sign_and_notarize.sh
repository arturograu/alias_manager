#!/bin/bash

# Load environment variables
if [ -f .env ]; then
    source .env
fi

# Set variables
APP="build/macos/Build/Products/Release/Alias Manager.app"
SIGN_ID=$(security find-identity -v -p codesigning | grep "Developer ID Application" | head -n1 | awk '{print $2}')

# Sign the app
echo "Signing application..."
codesign -f --options runtime --timestamp -s "$SIGN_ID" "$APP"

# Verify signing
echo "Verifying signature..."
codesign --verify --deep --strict --verbose=2 "$APP"

# Create zip for notarization
echo "Creating zip for notarization..."
ditto -c -k --keepParent "$APP" "$APP.zip"

# Submit for notarization using environment variables
echo "Submitting for notarization..."
xcrun notarytool submit "$APP.zip" \
    --apple-id "$APPLE_ID" \
    --password "$APPLE_APP_SPECIFIC_PASSWORD" \
    --team-id "$APPLE_TEAM_ID" \
    --wait

# Staple the notarization
echo "Stapling notarization..."
xcrun stapler staple "$APP"

echo "Process complete!"
