#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
gcc -std=gnu17 -O2 -DBOX2D_DISABLE_SIMD -Ibox2d311/include -shared -fPIC box2d311/vendor_src/*.c -lm -o /tmp/buggy-core.so
python3 tests/physics_test.py
