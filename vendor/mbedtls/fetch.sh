#!/bin/sh
# Puts the official mbedTLS 3.6.7 release tarball into ./download and verifies its SHA-256.
#   ./fetch.sh                    download it from GitHub
#   ./fetch.sh /path/to/tarball   copy a tarball you already have
#   ./fetch.sh --verify-only      only check the file that is already there
set -eu
HERE="$(cd "$(dirname "$0")" && pwd)"
VER=3.6.7
SHA=a7e8bcbec0e6f761b4af24f25677626b35f762f68eef79c08677a363212d11f6
URL="https://github.com/Mbed-TLS/mbedtls/releases/download/mbedtls-$VER/mbedtls-$VER.tar.bz2"
DEST="$HERE/download/mbedtls-$VER.tar.bz2"
mkdir -p "$HERE/download"
case "${1:-}" in
  --verify-only) [ -f "$DEST" ] || { echo "missing $DEST"; exit 1; } ;;
  "") curl -fL --proto '=https' -o "$DEST.tmp" "$URL" && mv "$DEST.tmp" "$DEST" ;;
  *) cp "$1" "$DEST" ;;
esac
if command -v sha256sum >/dev/null 2>&1; then
  GOT="$(sha256sum "$DEST" | cut -d' ' -f1)"
else
  GOT="$(shasum -a 256 "$DEST" | cut -d' ' -f1)"
fi
if [ "$GOT" != "$SHA" ]; then
  echo "checksum mismatch for $DEST: $GOT"
  rm -f "$DEST"
  exit 1
fi
echo "verified mbedtls-$VER"
