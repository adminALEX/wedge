#!/bin/bash
# Writes Sparkle's appcast.xml (one item: this release) to stdout.
#
#   SIGN_UPDATE=<path to Sparkle's sign_update> scripts/appcast.sh <app> <dmg> <download-base-url> < private-key
#
# The EdDSA private key comes in on stdin (CI: the SPARKLE_PRIVATE_KEY secret).
# The DMG is expected at <download-base-url>/<dmg file name>.
set -euo pipefail

APP="$1" DMG="$2" BASE_URL="$3"
INFO="$APP/Contents/Info.plist"
VERSION="$(plutil -extract CFBundleShortVersionString raw "$INFO")"
BUILD="$(plutil -extract CFBundleVersion raw "$INFO")"
MIN_OS="$(plutil -extract LSMinimumSystemVersion raw "$INFO")"
# Prints: sparkle:edSignature="…" length="…"
SIGNATURE="$("$SIGN_UPDATE" --ed-key-file - "$DMG")"

cat <<EOF
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>Wedge</title>
    <item>
      <title>Wedge $VERSION</title>
      <pubDate>$(LC_ALL=C date -u "+%a, %d %b %Y %H:%M:%S +0000")</pubDate>
      <sparkle:version>$BUILD</sparkle:version>
      <sparkle:shortVersionString>$VERSION</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>$MIN_OS</sparkle:minimumSystemVersion>
      <enclosure url="$BASE_URL/$(basename "$DMG")" $SIGNATURE type="application/octet-stream"/>
    </item>
  </channel>
</rss>
EOF
