#!/bin/sh
# Builds and runs the ASan/UBSan ownership harness against a source tree.
# Usage: tests/ownership/run.sh [source-root]   (default: this checkout)
set -eu
HERE=$(cd "$(dirname "$0")" && pwd)
SRC=$(cd "${1:-$HERE/../..}" && pwd)
OUT=$(mktemp -d /tmp/zip-ownership-build-XXXXXX)
trap 'rm -rf "$OUT"' EXIT

SAN="-fsanitize=address,undefined -fno-sanitize-recover=all -fno-omit-frame-pointer -g -O1"
FW="-framework Foundation -framework CoreFoundation -framework CoreServices -framework CoreGraphics"

compile() { # lang file object [extra...]
    lang=$1; file=$2; obj=$3; shift 3
    # shellcheck disable=SC2086
    clang++ -x "$lang" $SAN -std=gnu++17 -w -I"$SRC" -I"$SRC/4D Plugin API" -I"$SRC/4D Plugin API/Classes" \
        -I"$SRC/include" -I"$SRC/include/mz" "$@" -c "$file" -o "$OUT/$obj"
}

clang -x objective-c $SAN -w -Wno-int-conversion -I"$SRC/4D Plugin API" -c "$SRC/4D Plugin API/4DPluginAPI.c" -o "$OUT/api.o"
compile objective-c++ "$SRC/4D Plugin API/Classes/C_TEXT.cpp" ctext.o
compile objective-c++ "$SRC/4D Plugin API/Classes/C_LONGINT.cpp" clong.o
compile objective-c++ "$SRC/codepage/cpmap.cpp" cpmap.o
compile objective-c++ "$SRC/4DPlugin-Zip.cpp" plugin.o -include "$HERE/fake_time.h"
compile objective-c++ "$HERE/harness.mm" harness.o

# shellcheck disable=SC2086
clang++ $SAN "$OUT"/*.o "$SRC/a/libjsoncpp_static.a" $FW -o "$OUT/harness"
ASAN_OPTIONS=detect_leaks=0:abort_on_error=0 UBSAN_OPTIONS=print_stacktrace=1 "$OUT/harness"
