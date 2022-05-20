#!/bin/bash
export APP_NAME='install-aws-vpn'
export BUILD=$APP_NAME
export APP=$APP_NAME".app"
export APP_PATH=/Applications/"$APP"
export VERSION=0.0.1
export BUILD_PATH=$(pwd)
export RESOURCE_DIR="$APP_PATH"/Contents/Resources
export ICON="$RESOURCE_DIR"/beam.icns

# Update submodules
echo -e "Updating submodules..."
git submodule update --remote
echo -e " Done.\n"

# Create the stub application
mkdir -p "$APP_PATH"/Contents/Scripts
mkdir -p "$APP_PATH"/Contents/MacOS
mkdir -p "$RESOURCE_DIR"

cat <<EOF > "$APP_PATH"/Contents/Info.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIconFile</key>
  <string>beam</string>
  <key>CFBundleIconName</key>
  <string>beam</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>dental.beam.$APP_NAME</string>
  <key>CFBundleVersion</key>
  <string>"$VERSION"</string>
  <key>CFBundleShortVersionString</key>
  <string>$VERSION</string>
  <key>CFBundleSupportedPlatforms</key>
  <array>
    <string>MacOSX</string>
  </array>
</dict>
</plist>
EOF

cat <<EOF > "$APP_PATH"/Contents/PkgInfo
APPLZERO
EOF

# Create the build directory located in ~/pkgbuild/$BUILD
cd ~/
mkdir pkgbuild
cd pkgbuild
mkdir $BUILD
cd $BUILD

sudo xattr -d -r com.apple.quarantine "$APP_PATH"

cp $BUILD_PATH/resources/beam-icon/beam.icns $ICON
echo "#!/bin/bash" > "$APP_PATH"/Contents/MacOS/"$APP_NAME"
echo "" >> "$APP_PATH"/Contents/MacOS/"$APP_NAME"
echo "echo 'Opening log for $APP_PATH'" >> "$APP_PATH"/Contents/MacOS/"$APP_NAME"
chmod +x "$APP_PATH"/Contents/MacOS/"$APP_NAME"

# Copy resources (.pkg, .json, etc.)
cp -R $BUILD_PATH/resources/openvpn $RESOURCE_DIR/

cat <<EOF >"$APP_PATH"/Contents/Scripts/preinstall
#!/bin/bash
cp -R \$S1\\$APP /Applications
exit 0
EOF
chmod +x "$APP_PATH"/Contents/Scripts/preinstall

cat <<EOF >"$APP_PATH"/Contents/Scripts/postinstall
#!/bin/bash
export FILENAME="$APP_NAME.dmg"
export TMP_FOLDER="/tmp/$APP_NAME"
export FILEPATH=\$TMP_FOLDER/\$FILENAME
export DATETIME=\$(date +%m-%d-%y_%H%M%S)
export RESOURCE_DIR=$APP_PATH"/Contents/Resources"
export ICON=$ICON
export TOTALTIME=$TOTALTIME
export LOGFILE=/Users/Shared/log-$APP_NAME-\$DATETIME.log
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>/Users/Shared/log-$APP_NAME-\$DATETIME.log 2>&1
mkdir \$TMP_FOLDER
echo "open \$LOGFILE" >> "$APP_PATH"/Contents/MacOS/"$APP_NAME"
chmod +x "$APP_PATH"/Contents/MacOS/"$APP_NAME"
EOF
cat $BUILD_PATH/lib/MDM-Shell-Functions/functions.sh >>"$APP_PATH"/Contents/Scripts/postinstall
cat $BUILD_PATH/postinstall.sh >>"$APP_PATH"/Contents/Scripts/postinstall
cat <<EOF >>"$APP_PATH"/Contents/Scripts/postinstall
echo "removing $APP"
rm -rf $APP_PATH
pkgutil --forget dental.beam.$APP_NAME
exit 0
EOF
chmod +x "$APP_PATH"/Contents/Scripts/postinstall 

echo "Buidling package"
pkgbuild --scripts "$APP_PATH"/Contents/Scripts --install-location /Applications  --component "$APP_PATH" ./${BUILD}.pkg
productbuild --synthesize --package ${BUILD}.pkg /Applications --version $VERSION ./dist.xml
productbuild --distribution dist.xml --version $VERSION --package-path ./${BUILD}.pkg ./${BUILD}-final.pkg
echo "Signing package"
signing_cert="$( security find-identity -p macappstore -v | awk '/Developer ID Installer/ { print $2 }' )"
productsign --sign "$signing_cert" ./${BUILD}-final.pkg ./${BUILD}-final-signed.pkg 
