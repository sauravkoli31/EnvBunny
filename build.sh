#!/bin/bash
set -euo pipefail

APP_NAME="EnvBunny"
DISPLAY_NAME="EnvBunny"
BUNDLE_ID="com.sauravkoli.environment-manager"
MIN_MACOS="14.0"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
VERSION_FILE="$SCRIPT_DIR/.version"

# Auto-bump major version
if [ -f "$VERSION_FILE" ]; then
    CURRENT=$(cat "$VERSION_FILE")
    MAJOR=$(echo "$CURRENT" | cut -d. -f1)
    MINOR=$(echo "$CURRENT" | cut -d. -f2)
    MINOR=$((MINOR + 1))
    VERSION="$MAJOR.$MINOR.0"
else
    VERSION="1.0.0"
fi
SHORT_VERSION=$(echo "$VERSION" | cut -d. -f1-2)
echo "$VERSION" > "$VERSION_FILE"

DMG_PATH="$BUILD_DIR/${APP_NAME}-${VERSION}.dmg"

echo "Version: $VERSION"

# Clean previous build
echo "Cleaning previous build..."
rm -rf "$APP_BUNDLE" "$DMG_PATH"
mkdir -p "$BUILD_DIR"

# Build release binary
echo "Building release binary..."
cd "$SCRIPT_DIR"
swift build -c release

BINARY="$SCRIPT_DIR/.build/release/$APP_NAME"
if [ ! -f "$BINARY" ]; then
    echo "Error: Binary not found at $BINARY"
    exit 1
fi

# Create .app bundle structure
echo "Creating .app bundle..."
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy binary
cp "$BINARY" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

# Copy logo into Resources (loaded via Bundle.main at runtime)
LOGO_SRC="$SCRIPT_DIR/Assets/envBunny-logo.png"
if [ -f "$LOGO_SRC" ]; then
    cp "$LOGO_SRC" "$APP_BUNDLE/Contents/Resources/envBunny-logo.png"
    echo "Logo copied."
fi

# Copy app icon
ICON_SRC="$SCRIPT_DIR/Assets/AppIcon.icns"
if [ -f "$ICON_SRC" ]; then
    cp "$ICON_SRC" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
    echo "App icon copied."
fi

# Create Info.plist
cat > "$APP_BUNDLE/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleIdentifier</key>
	<string>$BUNDLE_ID</string>
	<key>CFBundleName</key>
	<string>$DISPLAY_NAME</string>
	<key>CFBundleDisplayName</key>
	<string>$DISPLAY_NAME</string>
	<key>CFBundleExecutable</key>
	<string>$APP_NAME</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleVersion</key>
	<string>$VERSION</string>
	<key>CFBundleShortVersionString</key>
	<string>$SHORT_VERSION</string>
	<key>LSMinimumSystemVersion</key>
	<string>$MIN_MACOS</string>
	<key>LSUIElement</key>
	<false/>
	<key>NSHighResolutionCapable</key>
	<true/>
	<key>CFBundleIconFile</key>
	<string>AppIcon</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
</dict>
</plist>
EOF

# Create DMG
echo "Creating DMG..."
DMG_STAGING="$BUILD_DIR/dmg-staging"
rm -rf "$DMG_STAGING"
mkdir -p "$DMG_STAGING"

cp -R "$APP_BUNDLE" "$DMG_STAGING/"
ln -s /Applications "$DMG_STAGING/Applications"

hdiutil create -volname "$DISPLAY_NAME" \
    -srcfolder "$DMG_STAGING" \
    -ov -format UDZO \
    "$DMG_PATH"

rm -rf "$DMG_STAGING"

echo ""
echo "Build complete!"
echo "  Version: $VERSION"
echo "  App: $APP_BUNDLE"
echo "  DMG: $DMG_PATH"
echo "  Size: $(du -h "$DMG_PATH" | cut -f1)"
