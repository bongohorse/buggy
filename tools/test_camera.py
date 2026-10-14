import ctypes as C,ctypes.util
path=ctypes.util.find_library('lua5.4')
if not path:raise SystemExit('liblua5.4 required for camera test')
lua=C.CDLL(path);lua.luaL_newstate.restype=C.c_void_p;lua.luaL_openlibs.argtypes=[C.c_void_p];lua.luaL_loadfilex.argtypes=[C.c_void_p,C.c_char_p,C.c_char_p];lua.lua_pcallk.argtypes=[C.c_void_p,C.c_int,C.c_int,C.c_int,C.c_longlong,C.c_void_p];lua.lua_tolstring.argtypes=[C.c_void_p,C.c_int,C.c_void_p];lua.lua_tolstring.restype=C.c_char_p;lua.lua_close.argtypes=[C.c_void_p]
L=lua.luaL_newstate();lua.luaL_openlibs(L)
rc=lua.luaL_loadfilex(L,b'tests/camera_test.lua',None)
if not rc:rc=lua.lua_pcallk(L,0,0,0,0,None)
if rc:raise SystemExit(lua.lua_tolstring(L,-1,None).decode())
lua.lua_close(L)
