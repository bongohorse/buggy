#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ ! -f box2d311/lib/x86_64-linux/libbuggy_box2d311.a ]];then bash tools/build_box2d.sh x86_64-linux;fi
mkdir -p .build
python3 tools/prepare_runtime_test.py
cat > .build/smoke.project <<'CONFIG'
[bootstrap]
main_collection = /tests/generated/smoke.collectionc
[engine]
run_while_iconified = 1
CONFIG
command=("${BUGGY_JAVA_BIN:-java}" -jar .cache/toolchain/bob-1.14.0.jar)
if [[ -n "${HTTPS_PROXY:-}" ]];then command=(python3 tools/with_build_proxy.py "${command[@]}");fi
"${command[@]}" --platform x86_64-linux --architectures x86_64-linux --variant headless --settings .build/smoke.project --archive --max-cpu-threads 3 --bundle-output .build/headless resolve build bundle
for shape in desktop portrait;do
 if [[ "$shape" == portrait ]];then options=(--config=display.width=390 --config=display.height=844 --config=buggy.expected_width=390);else options=(--config=buggy.expected_width=1280);fi
 (cd '.build/headless/Buggy Ridge' && timeout 15 ./BuggyRidge.x86_64 "${options[@]}") > ".build/runtime-$shape.log" 2>&1
 python3 - "$shape" <<'PYTEST'
from pathlib import Path
import sys
s=Path('.build/runtime-'+sys.argv[1]+'.log').read_text()
assert 'BUGGY_RUNTIME_SMOKE_PASS' in s,s[-3000:]
assert 'BUGGY_GUI_TUNING_PASS' in s,s[-3000:]
assert 'BUGGY_GAMEPLAY_UI_PASS' in s,s[-3000:]
assert not any(x in s for x in ['ERROR:SCRIPT','ERROR:GAMESYS','ERROR:GAMEOBJECT','ERROR:GUI','ERROR:RESOURCE']),s[-3000:]
print('\n'.join(x for x in s.splitlines() if '_PASS' in x))
PYTEST
done
