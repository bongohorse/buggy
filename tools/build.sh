#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
source tools/defold-version.env
platform="${1:-wasm-web}"
case "$platform" in wasm-web|arm64-android|x86_64-linux) ;; *) echo "Unsupported platform" >&2;exit 2;; esac
if [[ ! -f "box2d311/lib/$platform/libbuggy_box2d311.a" ]];then bash tools/build_box2d.sh "$platform";fi
cache="${BUGGY_TOOLCHAIN_DIR:-$PWD/.cache/toolchain}"
mkdir -p "$cache"
bob="$cache/bob-$DEFOLD_VERSION.jar"
if [[ ! -f "$bob" ]];then
 curl --fail --location --connect-timeout 15 --max-time 240 --retry 2 "https://github.com/defold/defold/releases/download/$DEFOLD_VERSION/bob.jar" -o "$bob.part"
 printf '%s  %s\n' "$BOB_SHA256" "$bob.part" | sha256sum --check --status
 mv "$bob.part" "$bob"
fi
printf '%s  %s\n' "$BOB_SHA256" "$bob" | sha256sum --check --status
command=("${BUGGY_JAVA_BIN:-java}" -jar "$bob")
if [[ -n "${HTTPS_PROXY:-}" ]]; then command=(python3 tools/with_build_proxy.py "${command[@]}"); fi
"${command[@]}" --platform "$platform" --architectures "$platform" --variant release --archive --max-cpu-threads 3 --bundle-output .build/bundle resolve build bundle
if [[ "$platform" == wasm-web ]];then
 python3 tools/stage_web.py
fi
