#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
source "$BUGGY_EMSDK_DIR/emsdk_env.sh" >/dev/null 2>&1
mkdir -p .build
python3 - <<'PY'
from pathlib import Path
import json
c=json.loads(Path('docs/track-profile.json').read_text())
def vec(name,p):return 'static const b2Vec2 '+name+'[]={'+','.join('{'+str(x)+','+str(y)+'}' for x,y in p)+'};\n'
s=vec('track_test',c['points'])+'#define TRACK_FINISH 600\n'
s+='static const BuggyGap track_gaps[]={'+','.join('{'+str(g['start'])+','+str(g['finish'])+'}' for g in c['gaps'])+'};\n'
s+=vec('route_test',c['routes'][0]['points'])
s+='static const struct {float start,finish;int kind;} surfaces[]={'+','.join('{'+str(v['start'])+','+str(v['finish'])+','+str(v['kind'])+'}' for v in c['surfaces'])+'};\n'
Path('.build/track_test.h').write_text(s)
PY
emcc -O2 -Ibox2d311/include -I.build tests/web_physics_test.c box2d311/lib/wasm-web/libbuggy_box2d311.a -s ASSERTIONS=1 -s ENVIRONMENT=node -o .build/physics-test.js
node .build/physics-test.js
