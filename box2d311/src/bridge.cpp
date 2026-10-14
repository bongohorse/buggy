#include <dmsdk/sdk.h>
#include "buggy_core.h"
static int Create(lua_State* L){
    bool has_bridge=lua_istable(L,2),has_gaps=lua_istable(L,3);luaL_checktype(L,1,LUA_TTABLE);int n=(int)lua_objlen(L,1);
    if(n<2||n>8192)return luaL_error(L,"Track requires 2..8192 points");
    b2Vec2* points=(b2Vec2*)lua_newuserdata(L,n*sizeof(b2Vec2));
    for(int i=0;i<n;i++){
        lua_rawgeti(L,1,i+1);luaL_checktype(L,-1,LUA_TTABLE);
        lua_rawgeti(L,-1,1);points[i].x=(float)luaL_checknumber(L,-1);lua_pop(L,1);
        lua_rawgeti(L,-1,2);points[i].y=(float)luaL_checknumber(L,-1);lua_pop(L,2);
        if(!b2IsValidVec2(points[i])||(i>0&&points[i].x<=points[i-1].x))return luaL_error(L,"Track must be finite and increasing");
    }
    if(has_bridge){
        lua_getfield(L,2,"start");float from=(float)luaL_checknumber(L,-1);lua_pop(L,1);
        lua_getfield(L,2,"finish");float to=(float)luaL_checknumber(L,-1);lua_pop(L,1);
        lua_getfield(L,2,"height");float y=(float)luaL_checknumber(L,-1);lua_pop(L,1);
        int ng=has_gaps?(int)lua_objlen(L,3):0;if(ng>8)return luaL_error(L,"At most 8 gaps");
        BuggyGap gaps[8];
        for(int i=0;i<ng;i++){
            lua_rawgeti(L,3,i+1);lua_getfield(L,-1,"start");gaps[i].start=(float)luaL_checknumber(L,-1);lua_pop(L,1);
            lua_getfield(L,-1,"finish");gaps[i].finish=(float)luaL_checknumber(L,-1);lua_pop(L,2);
        }
        buggy_create_level(points,n,from,to,y,gaps,ng);
    }else buggy_create(points,n);return 0;
}
static int Surface(lua_State* L){buggy_surface((int)luaL_checknumber(L,1),(int)luaL_checknumber(L,2));return 0;}
static int AddRoute(lua_State* L){
    luaL_checktype(L,1,LUA_TTABLE);int n=(int)lua_objlen(L,1);if(n<2||n>4096)return luaL_error(L,"Invalid route size");
    b2Vec2* p=(b2Vec2*)lua_newuserdata(L,n*sizeof(b2Vec2));
    for(int i=0;i<n;i++){
        lua_rawgeti(L,1,i+1);lua_rawgeti(L,-1,1);p[i].x=(float)luaL_checknumber(L,-1);lua_pop(L,1);
        lua_rawgeti(L,-1,2);p[i].y=(float)luaL_checknumber(L,-1);lua_pop(L,2);
        if(!b2IsValidVec2(p[i])||(i&&p[i].x<=p[i-1].x))return luaL_error(L,"Invalid route points");
    }
    buggy_add_route(p,n);return 0;
}
static int Reset(lua_State* L){buggy_reset((float)luaL_optnumber(L,1,3),(float)luaL_optnumber(L,2,1.8));return 0;}
static int Step(lua_State* L){buggy_step(lua_toboolean(L,1),lua_toboolean(L,2));return 0;}
static void Num(lua_State* L,const char* key,float v){lua_pushnumber(L,v);lua_setfield(L,-2,key);}
static void Pose(lua_State* L,BuggyPose p){lua_newtable(L);Num(L,"x",p.x);Num(L,"y",p.y);Num(L,"angle",p.angle);}
static int State(lua_State* L){
    BuggyState s=buggy_state();lua_newtable(L);Pose(L,s.chassis);lua_setfield(L,-2,"body");
    Pose(L,s.wheel[0]);lua_setfield(L,-2,"rear");Pose(L,s.wheel[1]);lua_setfield(L,-2,"front");
    Num(L,"gear",buggy_gear());Num(L,"vy",buggy_vertical_speed());Num(L,"speed",s.speed);Num(L,"spin",s.spin);
    lua_newtable(L);for(int i=0;i<buggy_bridge_count();i++){Pose(L,buggy_bridge_pose(i));lua_rawseti(L,-2,i+1);}lua_setfield(L,-2,"bridge");
    Num(L,"bridge_sag",buggy_bridge_deflection());
    lua_pushboolean(L,s.grounded);lua_setfield(L,-2,"grounded");lua_pushboolean(L,s.roof_contact);lua_setfield(L,-2,"roof_contact");return 1;
}
static int Version(lua_State* L){b2Version v=b2GetVersion();lua_pushfstring(L,"%d.%d.%d",v.major,v.minor,v.revision);return 1;}
static int Destroy(lua_State* L){buggy_destroy();return 0;}
static int Tune(lua_State* L){
    buggy_tune((float)luaL_checknumber(L,1),(float)luaL_checknumber(L,2),(float)luaL_checknumber(L,3),(float)luaL_checknumber(L,4));return 0;
}
static int Tuning(lua_State* L){
    BuggyTuning t=buggy_tuning();lua_newtable(L);Num(L,"power",t.power);Num(L,"spring",t.spring);Num(L,"damping",t.damping);Num(L,"air",t.air);return 1;
}
static const luaL_reg Methods[]={{"create",Create},{"surface",Surface},{"add_route",AddRoute},{"reset",Reset},{"step",Step},{"state",State},{"version",Version},{"destroy",Destroy},{"tune",Tune},{"tuning",Tuning},{0,0}};
static dmExtension::Result Initialize(dmExtension::Params* p){luaL_register(p->m_L,"buggy_physics",Methods);lua_pop(p->m_L,1);return dmExtension::RESULT_OK;}
static dmExtension::Result Finalize(dmExtension::Params*){buggy_destroy();return dmExtension::RESULT_OK;}
DM_DECLARE_EXTENSION(BuggyBox2D311,"BuggyBox2D311",0,0,Initialize,0,0,Finalize)
