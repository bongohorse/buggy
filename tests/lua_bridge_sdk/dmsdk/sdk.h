// Test-only Lua 5.4 adapter for the unchanged production C++ bridge.
// This validates the Lua/C boundary, not the Defold SDK or engine ABI.
#pragma once
#include <stddef.h>
extern "C" {
struct lua_State;
typedef long long lua_Integer;
typedef int (*lua_CFunction)(lua_State*);
struct luaL_reg { const char* name;lua_CFunction func; };
int lua_type(lua_State*,int);size_t lua_rawlen(lua_State*,int);void* lua_newuserdatauv(lua_State*,size_t,int);
int lua_rawgeti(lua_State*,int,lua_Integer);void lua_rawseti(lua_State*,int,lua_Integer);
void luaL_checktype(lua_State*,int,int);double luaL_checknumber(lua_State*,int);double luaL_optnumber(lua_State*,int,double);
int luaL_error(lua_State*,const char*,...);void lua_settop(lua_State*,int);int lua_getfield(lua_State*,int,const char*);
void lua_setfield(lua_State*,int,const char*);void lua_pushnumber(lua_State*,double);void lua_pushboolean(lua_State*,int);
void lua_createtable(lua_State*,int,int);int lua_toboolean(lua_State*,int);const char* lua_pushfstring(lua_State*,const char*,...);
void luaL_setfuncs(lua_State*,const luaL_reg*,int);void lua_pushvalue(lua_State*,int);void lua_setglobal(lua_State*,const char*);
}
#define LUA_TTABLE 5
#define lua_istable(L,i) (lua_type(L,i)==LUA_TTABLE)
#define lua_objlen lua_rawlen
#define lua_newuserdata(L,n) lua_newuserdatauv(L,n,0)
#define lua_pop(L,n) lua_settop(L,-(n)-1)
#define lua_newtable(L) lua_createtable(L,0,0)
inline void luaL_register(lua_State* L,const char* n,const luaL_reg* r){lua_newtable(L);luaL_setfuncs(L,r,0);lua_pushvalue(L,-1);lua_setglobal(L,n);}
namespace dmExtension { enum Result { RESULT_OK };struct Params { lua_State* m_L; }; }
#define DM_DECLARE_EXTENSION(a,b,c,d,e,f,g,h) extern "C" int buggy_test_open(lua_State* L){dmExtension::Params p={L};return e(&p);}
