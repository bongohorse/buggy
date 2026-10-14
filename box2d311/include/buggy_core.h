#pragma once
#include "box2d/box2d.h"
#ifdef __cplusplus
extern "C" {
#endif
typedef struct BuggyPose { float x,y,angle; } BuggyPose;
typedef struct BuggyState { BuggyPose chassis,wheel[2]; float speed,spin; int grounded,roof_contact; } BuggyState;
typedef struct BuggyTuning { float power,spring,damping,air; } BuggyTuning;
void buggy_tune(float power,float spring,float damping,float air);
BuggyTuning buggy_tuning(void);
typedef struct BuggyGap { float start,finish; } BuggyGap;
void buggy_create_level(const b2Vec2*,int,float,float,float,const BuggyGap*,int);
void buggy_add_route(const b2Vec2*,int);
void buggy_surface(int rear,int front);
int buggy_gear(void);
float buggy_vertical_speed(void);
void buggy_destroy(void);
void buggy_create(const b2Vec2* points,int count);
void buggy_create_course(const b2Vec2* points,int count,float bridge_start,float bridge_finish,float bridge_height);
int buggy_bridge_count(void);
BuggyPose buggy_bridge_pose(int index);
float buggy_bridge_deflection(void);
void buggy_reset(float x,float y);
void buggy_step(int gas,int brake);
BuggyState buggy_state(void);
#ifdef __cplusplus
}
#endif
