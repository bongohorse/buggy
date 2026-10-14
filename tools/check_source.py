from pathlib import Path
import re,json,hashlib,ctypes as C,ctypes.util
root=Path(__file__).resolve().parents[1]
errors=[]
# Validate the Defold resource graph without claiming a Bob compilation.
for p in list((root/'main').glob('*'))+list((root/'assets').glob('*.atlas'))+list((root/'assets/fonts').glob('*.font')):
 if p.suffix not in ['.script','.gui_script','.render_script','.html']:
  for path in re.findall(r'"(/[^"\n]+)"',p.read_text()):
   path=path.rstrip('\\')
   if path.startswith('/builtins/'):continue
   if not(root/path[1:]).exists():errors.append(f'{p.name}: missing {path}')
for p in list((root/'main').glob('*script'))+list((root/'modules').glob('*.lua')):
 for mod in re.findall(r"require\s*['\"]([^'\"]+)",p.read_text()):
  if not(root/(mod.replace('.','/')+'.lua')).exists():errors.append(f'{p.name}: missing module {mod}')
# Lua 5.4 parser catches syntax errors; Defold uses Lua 5.1/LuaJIT and needs its own runtime check.
libpath=ctypes.util.find_library('lua5.4')
if libpath:
 lua=C.CDLL(libpath);lua.luaL_newstate.restype=C.c_void_p;lua.luaL_loadfilex.argtypes=[C.c_void_p,C.c_char_p,C.c_char_p];lua.lua_tolstring.argtypes=[C.c_void_p,C.c_int,C.c_void_p];lua.lua_tolstring.restype=C.c_char_p;lua.lua_close.argtypes=[C.c_void_p]
 for p in list((root/'main').glob('*script'))+list((root/'modules').glob('*.lua')):
  L=lua.luaL_newstate();rc=lua.luaL_loadfilex(L,str(p).encode(),None)
  if rc:errors.append(lua.lua_tolstring(L,-1,None).decode())
  lua.lua_close(L)
else:print('Lua syntax check unavailable: liblua5.4 not installed')
streams=json.loads((root/'assets/terrain.buffer').read_text());assert len(streams[0]['data'])//3==len(streams[1]['data'])//2==len(streams[2]['data'])//4
expected=json.loads((root/'box2d311/UPSTREAM-SHA256.json').read_text())
for path,digest in expected.items():
 if hashlib.sha256((root/'box2d311'/path).read_bytes()).hexdigest()!=digest:errors.append('Upstream source changed: '+path)
if errors:raise SystemExit('\n'.join(errors))
print('PASS: resource references, Lua syntax (when available), terrain streams, pinned upstream hashes')
