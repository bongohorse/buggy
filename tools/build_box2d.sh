#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
platform="${1:-wasm-web}"
case "$platform" in
 wasm-web)
  if [[ -z "${BUGGY_EMSDK_DIR:-}" ]];then echo 'Set BUGGY_EMSDK_DIR to an activated Emscripten 4.0.6 SDK directory.' >&2;exit 2;fi
  source "$BUGGY_EMSDK_DIR/emsdk_env.sh" >/dev/null 2>&1
  compiler=(emcc);archiver=(emar)
  emcc --version | head -1 | rg '4\.0\.6' >/dev/null || { echo 'Emscripten 4.0.6 required' >&2;exit 2; }
  ;;
 x86_64-linux) compiler=(gcc);archiver=(ar) ;;
 *) echo 'Static Box2D library target not configured' >&2;exit 2;;
esac
objdir=".build/box2d-$platform"
mkdir -p "$objdir" "box2d311/lib/$platform"
for file in box2d311/vendor_src/*.c;do
 "${compiler[@]}" -O3 -DNDEBUG -DBOX2D_DISABLE_SIMD -fPIC -Ibox2d311/include -c "$file" -o "$objdir/$(basename "${file%.c}").o"
done
"${archiver[@]}" rcs "box2d311/lib/$platform/libbuggy_box2d311.a" "$objdir"/*.o
sha256sum "box2d311/lib/$platform/libbuggy_box2d311.a"
