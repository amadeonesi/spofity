#!/bin/sh
# Builds the release IPA and installs it over USB as a user app (needs AppSync on the phone). Same as IG6's.
set -eu
cd "$(dirname "$0")/.."
export THEOS="${THEOS:-$HOME/theos}"
[ -f vendor/mbedtls/out/ios/lib/libmbedtls.a ] || { echo "build mbedTLS first: vendor/mbedtls/build.sh"; exit 1; }
gmake package FINALPACKAGE=1 "$@"
IPA="$(ls -t packages/*.ipa | head -n 1)"
echo "installing $IPA"
ideviceinstaller install "$IPA"
