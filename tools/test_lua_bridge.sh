#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
# Lua 5.4 test adapter; actual Defold 5.1/SDK validation remains a separate step.
g++ -std=c++17 -shared -fPIC -Itests/lua_bridge_sdk -Ibox2d311/include box2d311/src/bridge.cpp box2d311/lib/x86_64-linux/libbuggy_box2d311.a -l:liblua5.4.so.0 -lm -o /tmp/buggy-lua-bridge.so
python3 tests/lua_bridge_test.py
