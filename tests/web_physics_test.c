#include "buggy_core.h"
#include "track_test.h"
#include <assert.h>
#include <math.h>
#include <stdio.h>
static float height(float x){
 int lo=0,hi=sizeof(track_test)/sizeof(track_test[0])-1;
 while(hi-lo>1){int m=(lo+hi)/2;if(track_test[m].x<=x)lo=m;else hi=m;}
 b2Vec2 a=track_test[lo],b=track_test[hi];return a.y+(b.y-a.y)*(x-a.x)/(b.x-a.x);
}
static int surface(BuggyPose p){
 if(p.x>=268&&p.x<=302&&p.y>height(p.x)+1.5f)return 2;
 for(unsigned i=0;i<sizeof(surfaces)/sizeof(surfaces[0]);i++)if(p.x>=surfaces[i].start&&p.x<surfaces[i].finish)return surfaces[i].kind;
 return 0;
}
int main(void){
 b2Version v=b2GetVersion();assert(v.major==3&&v.minor==1&&v.revision==1);
 b2Vec2 flat[]={{-100,0},{2000,0}};buggy_create(flat,2);
 for(int i=0;i<180;i++)buggy_step(0,0);
 BuggyState s=buggy_state();assert(s.grounded&&fabsf(s.chassis.x-3)<.1f);
 for(int i=0;i<180;i++)buggy_step(1,0);
 s=buggy_state();assert(s.speed>7&&s.chassis.x>15);
 for(int i=0;i<180;i++){buggy_step(0,1);if(fabsf(buggy_state().speed)<.2f)break;}
 s=buggy_state();assert(fabsf(s.speed)<.2f&&buggy_gear()==0);
 for(int i=0;i<150;i++)buggy_step(0,1);assert(buggy_state().speed< -1&&buggy_gear()==-1);
 for(int i=0;i<180;i++)buggy_step(1,0);assert(buggy_state().speed>5);
 buggy_reset(3,12);for(int i=0;i<20;i++)buggy_step(1,0);assert(buggy_state().chassis.angle>.05f);
 buggy_reset(3,12);for(int i=0;i<20;i++)buggy_step(0,1);assert(buggy_state().chassis.angle<-.05f);
 buggy_create_level(track_test,sizeof(track_test)/sizeof(track_test[0]),98,112,1.3f,track_gaps,sizeof(track_gaps)/sizeof(track_gaps[0]));
 buggy_add_route(route_test,sizeof(route_test)/sizeof(route_test[0]));
 assert(buggy_bridge_count()==12);
 buggy_reset(105,2.8f);for(int i=0;i<180;i++)buggy_step(0,0);assert(buggy_bridge_deflection()>.32f);
 buggy_reset(3,1.8f);
 int frame=0;
 for(;frame<7200;frame++){
  s=buggy_state();buggy_surface(surface(s.wheel[0]),surface(s.wheel[1]));
  float cap=(s.chassis.x>409&&s.chassis.x<429)||(s.chassis.x>482&&s.chassis.x<501)?8:14;
  int gas=s.speed<=cap,brake=s.speed>cap;
  if(!s.grounded){float target=(s.chassis.x>417&&s.chassis.x<447)||(s.chassis.x>495&&s.chassis.x<521)?-.25f:-.05f;float err=target-s.chassis.angle-s.spin*.35f;gas=err>.08f;brake=err<-.08f;}
  buggy_step(gas,brake);s=buggy_state();assert(isfinite(s.chassis.x)&&isfinite(s.chassis.y));
  if(s.chassis.x>=TRACK_FINISH)break;
 }
 assert(s.chassis.x>=TRACK_FINISH);
 buggy_reset(3,1.8f);int roof=0,crashed=0;
 for(int i=0;i<7200;i++){
  s=buggy_state();buggy_surface(surface(s.wheel[0]),surface(s.wheel[1]));buggy_step(1,0);s=buggy_state();roof=s.roof_contact?roof+1:0;
  if(roof>=33||s.chassis.y< -9){crashed=1;break;}
  if(s.chassis.x>=TRACK_FINISH)break;
 }
 assert(crashed);
 for(int n=0;n<100;n++){buggy_reset(3,1.8f);for(int i=0;i<180;i++)buggy_step(0,0);assert(buggy_state().grounded);}
 BuggyPose before=buggy_state().chassis;buggy_tune(.6f,2,.3f,.4f);
 BuggyPose after=buggy_state().chassis;assert(before.x==after.x&&before.y==after.y&&before.angle==after.angle);
 buggy_reset(3,1.8f);assert(fabsf(buggy_tuning().power-.6f)<.001f);
 float speeds[2];
 for(int n=0;n<2;n++){
  buggy_create(flat,2);buggy_tune(n?1.8f:.6f,4.2f,.65f,1.1f);
  for(int i=0;i<180;i++)buggy_step(0,0);for(int i=0;i<60;i++)buggy_step(1,0);speeds[n]=buggy_state().speed;
 }
 assert(speeds[1]>speeds[0]*1.3f);
 buggy_tune(1.25f,4.2f,.65f,1.1f);
 buggy_destroy();assert(b2GetByteCount()==0);
 printf("PASS: Box2D %d.%d.%d WASM, acceleration, brake/reverse/forward, air controls, complete 597m track with surfaces, shortcut and gap (%d frames), gas-only crash, 100 resets, live tuning + pose preservation, zero leaked bytes\n",v.major,v.minor,v.revision,frame+1);
 return 0;
}
