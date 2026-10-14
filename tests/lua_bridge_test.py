import ctypes as C,ctypes.util,pathlib
r=pathlib.Path(__file__).resolve().parents[1]
lua=C.CDLL(ctypes.util.find_library('lua5.4'),mode=C.RTLD_GLOBAL)
lua.luaL_newstate.restype=C.c_void_p
for n in ['luaL_openlibs','lua_close']:getattr(lua,n).argtypes=[C.c_void_p]
lua.luaL_loadstring.argtypes=[C.c_void_p,C.c_char_p]
lua.lua_pcallk.argtypes=[C.c_void_p,C.c_int,C.c_int,C.c_int,C.c_longlong,C.c_void_p]
lua.lua_tolstring.argtypes=[C.c_void_p,C.c_int,C.c_void_p];lua.lua_tolstring.restype=C.c_char_p
bridge=C.CDLL('/tmp/buggy-lua-bridge.so');bridge.buggy_test_open.argtypes=[C.c_void_p]
L=lua.luaL_newstate();lua.luaL_openlibs(L);bridge.buggy_test_open(L)
code="""
package.path=ROOT..'/?.lua;'..package.path
local course=require 'modules.track'
assert(#course.points==6401)
for i=1,8 do
 buggy_physics.create(course.points,course.bridge,course.gaps)
 for _,r in ipairs(course.routes) do buggy_physics.add_route(r.points) end
 buggy_physics.surface(1,2)
 assert(#buggy_physics.state().bridge==12)
 for j=1,30 do buggy_physics.step(true,false) end
 assert(buggy_physics.state().body.x>3)
 buggy_physics.destroy()
end
buggy_physics.create({{-100,0},{100,0}})
assert(#buggy_physics.state().bridge==0)
buggy_physics.destroy()
local progress=require 'modules.progress'
assert(progress.medal(65)=='GOLD' and progress.medal(65.1)=='SILVER' and progress.medal(91)=='BRONZE')
local record={best_time=100,medal=2}
local _,changed=progress.finish(record,60,true);assert(not changed and record.best_time==100 and record.medal==2)
_,changed=progress.finish(record,60,false);assert(changed and record.best_time==60 and record.medal==3)
_,changed=progress.finish(record,120,false);assert(not changed and record.best_time==60 and record.medal==3)
""".replace('ROOT',repr(str(r)))
rc=lua.luaL_loadstring(L,code.encode()) or lua.lua_pcallk(L,0,0,0,0,None)
if rc:raise AssertionError(lua.lua_tolstring(L,-1,None).decode())
lua.lua_close(L);print('PASS: production C++ bridge / Lua 5.4 adapter, 6401 input points + gap/route, 12 plank poses, 8 world recreations, optional bridge')
