#!/bin/sh
# Builds the release IPA and installs it over USB as a user app (needs AppSync on the phone).
set -eu
cd "$(dirname "$0")/.."
[ -f vendor/mbedtls/out/ios/lib/libmbedtls.a ] || { echo "build mbedTLS first: vendor/mbedtls/build.sh" >&2; exit 1; }
make ipa
echo "installing Spofity.ipa"
ideviceinstaller install Spofity.ipa
