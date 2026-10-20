#!/bin/sh
# Builds mbedTLS for the app (armv7, iOS 5.0, one build for iOS 5 and 6) from the verified release tarball into out/ios.
# Works on Debian/Ubuntu with the ios5 toolchain; no Xcode/xcrun needed.
set -eu
HERE="$(cd "$(dirname "$0")" && pwd)"
VER=3.6.7
"$HERE/fetch.sh" --verify-only
TARBALL="$HERE/download/mbedtls-$VER.tar.bz2"
TOOLCHAIN="${TOOLCHAIN:-$HOME/ios-toolchain}"
CC="${CC:-$TOOLCHAIN/bin/ios5-clang}"
AR="${AR:-$TOOLCHAIN/bin/arm-apple-darwin11-ar}"
RANLIB="${RANLIB:-$TOOLCHAIN/bin/arm-apple-darwin11-ranlib}"
SDK="${SDK:-$TOOLCHAIN/SDKs/iPhoneOS5.0.sdk}"
J="$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 4)"

[ -x "$CC" ] || { echo "missing compiler: $CC" >&2; exit 1; }
[ -d "$SDK" ] || { echo "missing SDK: $SDK" >&2; exit 1; }

WORK="$HERE/build/ios"
SRC="$WORK/mbedtls-$VER"
rm -rf "$WORK" && mkdir -p "$WORK"
tar -xjf "$TARBALL" -C "$WORK"
CFLAGS="-Os -I$SRC/include -I$HERE -include $HERE/mbedtls_ios6_predef.h -Wno-deprecated-module-dot-map"
make -C "$SRC/library" -j"$J" CC="$CC" AR="$AR" RANLIB="$RANLIB" CFLAGS="$CFLAGS" \
     libmbedcrypto.a libmbedx509.a libmbedtls.a
"$CC" $CFLAGS -c "$HERE/mbedtls_ios6_alt.c" -o "$WORK/mbedtls_ios6_alt.o"
OUT="$HERE/out/ios"
rm -rf "$OUT" && mkdir -p "$OUT/lib"
cp "$SRC/library/libmbedtls.a" "$SRC/library/libmbedx509.a" "$SRC/library/libmbedcrypto.a" "$OUT/lib/"
"$AR" rcs "$OUT/lib/libmbedcrypto.a" "$WORK/mbedtls_ios6_alt.o"
cp -R "$SRC/include" "$OUT/include"
cp "$HERE/mbedtls_ios6_config.h" "$HERE/mbedtls_ios6_predef.h" "$OUT/include/"
echo "built $OUT"
