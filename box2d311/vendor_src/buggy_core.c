#include "buggy_core.h"
#include <math.h>
#include <stdlib.h>
static b2WorldId world;
static b2BodyId car,wheels[2];
static b2JointId joints[2];
static int active=0,car_active=0;
enum { DECK_COUNT=12 };
static b2BodyId deck[DECK_COUNT];
static BuggyPose deck_rest[DECK_COUNT];
static int deck_count=0;
static float deck_height=0;
static float reverse_wait=0,drive=0;
static int gear=1,surfaces[2]={0,0};
static b2BodyId level_ground;
static BuggyTuning tuning={1.25f,4.2f,0.65f,1.1f};
static float bounded(float value,float low,float high,float fallback){
    return !isfinite(value)?fallback:fminf(high,fmaxf(low,value));
}
BuggyTuning buggy_tuning(void){return tuning;}
void buggy_tune(float power,float spring,float damping,float air){
    tuning=(BuggyTuning){bounded(power,.6f,1.8f,1.25f),bounded(spring,2,7,4.2f),
        bounded(damping,.3f,1.1f,.65f),bounded(air,.4f,1.8f,1.1f)};
    if(car_active){
        for(int i=0;i<2;i++){
            b2WheelJoint_SetSpringHertz(joints[i],tuning.spring);
            b2WheelJoint_SetSpringDampingRatio(joints[i],tuning.damping);
            b2Body_SetAwake(wheels[i],true);
        }
        b2Body_SetAwake(car,true);
    }
}
static int touching(b2BodyId body){
    b2ContactData contacts[12];
    int n=b2Body_GetContactData(body,contacts,12);
    for(int i=0;i<n;i++)for(int j=0;j<contacts[i].manifold.pointCount;j++)
        if(contacts[i].manifold.points[j].separation<0.025f)return 1;
    return 0;
}
void buggy_destroy(void){if(active)b2DestroyWorld(world);active=car_active=deck_count=0;}
void buggy_reset(float x,float y){
    if(!active)return;
    reverse_wait=drive=0;gear=1;surfaces[0]=surfaces[1]=-1;
    for(int i=0;i<deck_count;i++){
        b2Body_SetTransform(deck[i],(b2Vec2){deck_rest[i].x,deck_rest[i].y},b2MakeRot(deck_rest[i].angle));
        b2Body_SetLinearVelocity(deck[i],(b2Vec2){0,0});b2Body_SetAngularVelocity(deck[i],0);b2Body_SetAwake(deck[i],true);
    }
    if(car_active){b2DestroyBody(car);b2DestroyBody(wheels[0]);b2DestroyBody(wheels[1]);}
    b2BodyDef bd=b2DefaultBodyDef();bd.type=b2_dynamicBody;bd.position=(b2Vec2){x,y};
    bd.angularDamping=0.65f;bd.linearDamping=0.04f;bd.isBullet=true;
    car=b2CreateBody(world,&bd);
    b2ShapeDef sd=b2DefaultShapeDef();sd.density=20;sd.material.friction=0.5f;
    sd.filter.groupIndex=-1;
    b2Polygon box=b2MakeBox(1.45f,0.25f);b2CreatePolygonShape(car,&sd,&box);
    sd.density=2;
    box=b2MakeOffsetBox(0.72f,0.42f,(b2Vec2){-0.1f,0.55f},b2Rot_identity);
    b2CreatePolygonShape(car,&sd,&box);
    for(int i=0;i<2;i++){
        float ax=i==0?-1.18f:1.18f;
        bd.position=(b2Vec2){x+ax,y-0.58f};bd.angularDamping=0.05f;bd.isBullet=false;
        wheels[i]=b2CreateBody(world,&bd);
        sd.density=3.5f;sd.material.friction=1.45f;
        b2Circle circle={{0,0},0.48f};b2CreateCircleShape(wheels[i],&sd,&circle);
        b2WheelJointDef jd=b2DefaultWheelJointDef();jd.bodyIdA=car;jd.bodyIdB=wheels[i];
        jd.localAnchorA=(b2Vec2){ax,-0.58f};jd.localAxisA=(b2Vec2){0,1};
        jd.enableSpring=true;jd.hertz=tuning.spring;jd.dampingRatio=tuning.damping;
        jd.enableLimit=true;jd.lowerTranslation=-0.22f;jd.upperTranslation=0.22f;
        jd.enableMotor=true;jd.maxMotorTorque=48.0f*tuning.power;
        joints[i]=b2CreateWheelJoint(world,&jd);
    }
    car_active=1;
}
static void terrain_chain(b2BodyId ground,const b2Vec2* points,int count){
    if(count<2)return;
    b2Vec2* loop=malloc((count+2)*sizeof(b2Vec2));
    loop[0]=(b2Vec2){points[0].x,-20};loop[1]=(b2Vec2){points[count-1].x,-20};
    for(int i=0;i<count;i++)loop[i+2]=points[count-1-i];
    b2SurfaceMaterial material=b2DefaultSurfaceMaterial();material.friction=1.25f;
    b2ChainDef cd=b2DefaultChainDef();cd.points=loop;cd.count=count+2;cd.isLoop=true;
    cd.materials=&material;cd.materialCount=1;b2CreateChain(ground,&cd);free(loop);
}
static void bridge_create(b2BodyId ground,float from,float to,float y){
    b2Vec2 p[DECK_COUNT+1];deck_count=DECK_COUNT;deck_height=y;
    for(int i=0;i<=DECK_COUNT;i++){float t=(float)i/DECK_COUNT;p[i]=(b2Vec2){from+(to-from)*t,y-.08f-.32f*sinf(3.14159265f*t)};}
    for(int i=0;i<DECK_COUNT;i++){
        float dx=p[i+1].x-p[i].x,dy=p[i+1].y-p[i].y;
        float length=sqrtf(dx*dx+dy*dy),angle=atan2f(dy,dx);
        b2BodyDef bd=b2DefaultBodyDef();bd.type=b2_dynamicBody;
        bd.position=(b2Vec2){(p[i].x+p[i+1].x)*.5f,(p[i].y+p[i+1].y)*.5f};bd.rotation=b2MakeRot(angle);bd.angularDamping=.8f;
        deck[i]=b2CreateBody(world,&bd);deck_rest[i]=(BuggyPose){bd.position.x,bd.position.y,angle};
        b2ShapeDef sd=b2DefaultShapeDef();sd.density=5;sd.material.friction=1.3f;sd.filter.groupIndex=-2;
        b2Polygon box=b2MakeBox(length*.5f+.008f,.08f);b2CreatePolygonShape(deck[i],&sd,&box);
    }
    for(int i=0;i<=DECK_COUNT;i++){
        b2BodyId a=i==0?ground:deck[i-1],b=i==DECK_COUNT?ground:deck[i];
        b2RevoluteJointDef jd=b2DefaultRevoluteJointDef();jd.bodyIdA=a;jd.bodyIdB=b;
        jd.localAnchorA=b2Body_GetLocalPoint(a,p[i]);jd.localAnchorB=b2Body_GetLocalPoint(b,p[i]);
        jd.referenceAngle=b2Rot_GetAngle(b2Body_GetRotation(b))-b2Rot_GetAngle(b2Body_GetRotation(a));
        jd.enableLimit=true;jd.lowerAngle=-.25f;jd.upperAngle=.25f;
        jd.enableSpring=true;jd.hertz=3;jd.dampingRatio=.8f;jd.targetAngle=0;
        b2CreateRevoluteJoint(world,&jd);
    }
}
void buggy_add_route(const b2Vec2* points,int count){
    if(!active||count<2)return;
    // One-sided upper trail: approaching from the valley cannot hit an artificial ceiling.
    b2Vec2* loop=malloc((count+2)*sizeof(b2Vec2));
    loop[0]=(b2Vec2){2*points[count-1].x-points[count-2].x,2*points[count-1].y-points[count-2].y};
    for(int i=0;i<count;i++)loop[i+1]=points[count-1-i];
    loop[count+1]=(b2Vec2){2*points[0].x-points[1].x,2*points[0].y-points[1].y};
    b2SurfaceMaterial material=b2DefaultSurfaceMaterial();material.friction=1.25f;
    b2ChainDef cd=b2DefaultChainDef();cd.points=loop;cd.count=count+2;cd.isLoop=false;
    cd.materials=&material;cd.materialCount=1;b2CreateChain(level_ground,&cd);free(loop);
}
void buggy_create_level(const b2Vec2* points,int count,float from,float to,float y,const BuggyGap* gaps,int gap_count){
    buggy_destroy();b2WorldDef wd=b2DefaultWorldDef();wd.gravity=(b2Vec2){0,-14};wd.workerCount=0;
    world=b2CreateWorld(&wd);active=1;
    b2BodyDef bd=b2DefaultBodyDef();level_ground=b2CreateBody(world,&bd);
    int start=0;
    for(int i=0;i<count-1;i++){
        float x=(points[i].x+points[i+1].x)*.5f;
        int skip=to>from&&x>from&&x<to;
        for(int j=0;j<gap_count;j++)skip=skip||(x>gaps[j].start&&x<gaps[j].finish);
        if(skip){if(i-start+1>=2)terrain_chain(level_ground,points+start,i-start+1);start=i+1;}
    }
    if(count-start>=2)terrain_chain(level_ground,points+start,count-start);
    if(to>from&&from>points[0].x&&to<points[count-1].x)bridge_create(level_ground,from,to,y);
    buggy_reset(3,1.8f);buggy_surface(0,0);
}
void buggy_create_course(const b2Vec2* p,int n,float a,float b,float y){buggy_create_level(p,n,a,b,y,NULL,0);}
void buggy_create(const b2Vec2* points,int count){buggy_create_course(points,count,0,0,0);}
void buggy_surface(int rear,int front){
    int next[2]={rear,front};float friction[4]={1.45f,.75f,1.05f,1.30f};
    float resistance[4]={.04f,.22f,.12f,.065f};
    if(!car_active)return;
    for(int i=0;i<2;i++){
        int t=next[i]<0||next[i]>3?0:next[i];
        if(surfaces[i]!=t){
            b2ShapeId shape;if(b2Body_GetShapes(wheels[i],&shape,1))b2Shape_SetFriction(shape,friction[t]);
            b2Body_SetAngularDamping(wheels[i],.05f+resistance[t]*2);surfaces[i]=t;
        }
    }
    b2Body_SetLinearDamping(car,(resistance[surfaces[0]]+resistance[surfaces[1]])*.5f);
}
int buggy_gear(void){return gear;}
float buggy_vertical_speed(void){return car_active?b2Body_GetLinearVelocity(car).y:0;}
void buggy_step(int gas,int brake){
    if(!active||!car_active)return;
    gas=gas&&!brake;
    if(gas||brake){b2Body_SetAwake(car,true);b2Body_SetAwake(wheels[0],true);b2Body_SetAwake(wheels[1],true);}
    int ground=touching(wheels[0])||touching(wheels[1]);
    float rolling[4]={.04f,.22f,.12f,.065f};
    b2Body_SetLinearDamping(car,ground?(rolling[surfaces[0]<0?0:surfaces[0]]+rolling[surfaces[1]<0?0:surfaces[1]])*.5f:.04f);
    float vx=b2Body_GetLinearVelocity(car).x;
    if(!brake)reverse_wait=0;
    else if(ground&&fabsf(vx)<.4f)reverse_wait+=1.0f/60.0f;
    else if(vx>.4f)reverse_wait=0;
    int reverse=brake&&(reverse_wait>.45f||gear==-1)&&vx<.5f;
    int braking=(brake&&!reverse)||(gas&&vx<-.4f);
    gear=reverse?-1:(braking?0:1);
    float target=(gas&&!braking)?1.0f:0;
    drive+=(target-drive)*.14f;
    for(int i=0;i<2;i++){
        b2WheelJoint_EnableMotor(joints[i],gas||brake);
        b2WheelJoint_SetMotorSpeed(joints[i],reverse?9.0f:(braking?0:-32.0f));
        b2WheelJoint_SetMaxMotorTorque(joints[i],braking?80.0f:(reverse?30.0f:48.0f*tuning.power*drive));
    }
    if(!ground){
        float spin=b2Body_GetAngularVelocity(car);
        float torque=(gas?72.0f:(brake?-72.0f:0))*tuning.air-spin*10.0f;
        if(fabsf(spin)<3.5f||torque*spin<0)b2Body_ApplyTorque(car,torque,true);
    }
    b2World_Step(world,1.0f/60.0f,4);
}
static BuggyPose pose(b2BodyId body){b2Vec2 p=b2Body_GetPosition(body);return(BuggyPose){p.x,p.y,b2Rot_GetAngle(b2Body_GetRotation(body))};}
int buggy_bridge_count(void){return deck_count;}
BuggyPose buggy_bridge_pose(int index){return index>=0&&index<deck_count?pose(deck[index]):(BuggyPose){0};}
float buggy_bridge_deflection(void){
    float sag=0;for(int i=0;i<deck_count;i++)sag=fmaxf(sag,deck_height-(b2Body_GetPosition(deck[i]).y+.08f));return sag;
}
BuggyState buggy_state(void){
    BuggyState s={0};if(!car_active)return s;
    s.chassis=pose(car);s.wheel[0]=pose(wheels[0]);s.wheel[1]=pose(wheels[1]);
    s.speed=b2Body_GetLinearVelocity(car).x;s.spin=b2Body_GetAngularVelocity(car);
    s.grounded=touching(wheels[0])||touching(wheels[1]);
    s.roof_contact=cosf(s.chassis.angle)<0.2f&&touching(car);return s;
}
