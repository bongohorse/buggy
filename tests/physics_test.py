import ctypes as C, math, pathlib, re, time, json,bisect
class Vec(C.Structure):_fields_=[('x',C.c_float),('y',C.c_float)]
class Pose(C.Structure):_fields_=[('x',C.c_float),('y',C.c_float),('angle',C.c_float)]
class State(C.Structure):_fields_=[('body',Pose),('wheel',Pose*2),('speed',C.c_float),('spin',C.c_float),('grounded',C.c_int),('roof',C.c_int)]
class Tuning(C.Structure):_fields_=[('power',C.c_float),('spring',C.c_float),('damping',C.c_float),('air',C.c_float)]
class Version(C.Structure):_fields_=[('major',C.c_int),('minor',C.c_int),('revision',C.c_int)]
lib=C.CDLL('/tmp/buggy-core.so');lib.buggy_state.restype=State;lib.buggy_create.argtypes=[C.POINTER(Vec),C.c_int];lib.buggy_reset.argtypes=[C.c_float,C.c_float];lib.buggy_step.argtypes=[C.c_int,C.c_int];lib.b2GetVersion.restype=Version
lib.buggy_tune.argtypes=[C.c_float]*4;lib.buggy_tuning.restype=Tuning
v=lib.b2GetVersion();assert(v.major,v.minor,v.revision)==(3,1,1)
root=pathlib.Path(__file__).resolve().parents[1]
course=json.loads((root/'docs/track-profile.json').read_text());track=course['points']
def create(points):lib.buggy_create((Vec*len(points))(*(Vec(*p) for p in points)),len(points))
def step(g=0,b=0,n=1):
 for _ in range(n):lib.buggy_step(g,b)
 s=lib.buggy_state();assert all(math.isfinite(x) for x in [s.body.x,s.body.y,s.body.angle,s.speed,s.spin]);return s
results={}
create([(-100,0),(2000,0)]);s=step(n=180)
assert s.grounded and .7<s.body.y<1.3,(s.grounded,s.body.y)
assert abs(s.body.x-3)<.1
s=step(1,0,180);assert s.speed>7 and s.body.x>15,(s.speed,s.body.x)
results['acceleration_speed_m_s']=round(s.speed,3)
for _ in range(180):
 s=step(0,1)
 if abs(s.speed)<.2:break
assert abs(s.speed)<.2 and lib.buggy_gear()==0,s.speed
results['brake_speed_m_s']=round(s.speed,4)
s=step(0,1,150);assert s.speed< -1 and lib.buggy_gear()==-1,(s.speed,lib.buggy_gear())
results['reverse_speed_m_s']=round(s.speed,3)
s=step(1,0,180);assert s.speed>5,s.speed
# Real wheel joints remain within configured travel after a drop.
lib.buggy_reset(3,7)
min_travel,max_travel=100,-100
for _ in range(360):
 s=step()
 for wheel in s.wheel:
  local_y=-math.sin(s.body.angle)*(wheel.x-s.body.x)+math.cos(s.body.angle)*(wheel.y-s.body.y)
  travel=local_y+.58;min_travel=min(min_travel,travel);max_travel=max(max_travel,travel)
assert min_travel>-.26 and max_travel<.26,(min_travel,max_travel)
assert s.grounded
results['suspension_travel_m']=[round(min_travel,4),round(max_travel,4)]
lib.buggy_reset(3,12);s=step(1,0,20);assert s.body.angle>.05,s.body.angle
lib.buggy_reset(3,12);s=step(0,1,20);assert s.body.angle<-.05,s.body.angle
results['air_control']='both directions verified'
# Track completion using a simple automated pilot; not a substitute for human feel testing.
lib.buggy_create_course.argtypes=[C.POINTER(Vec),C.c_int,C.c_float,C.c_float,C.c_float]
lib.buggy_bridge_pose.argtypes=[C.c_int];lib.buggy_bridge_pose.restype=Pose
lib.buggy_bridge_deflection.restype=C.c_float
class Gap(C.Structure):_fields_=[('start',C.c_float),('finish',C.c_float)]
lib.buggy_create_level.argtypes=[C.POINTER(Vec),C.c_int,C.c_float,C.c_float,C.c_float,C.POINTER(Gap),C.c_int]
lib.buggy_add_route.argtypes=[C.POINTER(Vec),C.c_int]
lib.buggy_create_level((Vec*len(track))(*(Vec(*p) for p in track)),len(track),98,112,1.3,(Gap*len(course['gaps']))(*(Gap(g['start'],g['finish']) for g in course['gaps'])),len(course['gaps']))
for r in course['routes']:lib.buggy_add_route((Vec*len(r['points']))(*(Vec(*p) for p in r['points'])),len(r['points']))
assert lib.buggy_bridge_count()==12
lib.buggy_reset(105,2.8);step(n=180);loaded_sag=lib.buggy_bridge_deflection();assert loaded_sag>.32 and loaded_sag<2,loaded_sag
lib.buggy_reset(3,1.8);assert lib.buggy_bridge_deflection()<.33
results["dynamic_bridge"]={"planks":12,"loaded_sag_m":round(loaded_sag,3),"reset_verified":True}
# Same surface decisions as gameplay, updated per wheel.
xs=[p[0] for p in track]
def height(x):
 i=max(0,min(len(track)-2,bisect.bisect_right(xs,x)-1));a,b=track[i:i+2];return a[1]+(b[1]-a[1])*(x-a[0])/(b[0]-a[0])
def surface(x,y):
 if 268<=x<=302 and y>height(x)+1.5:return 2
 return next((v['kind'] for v in course['surfaces'] if v['start']<=x<v['finish']),0)
max_x=0;upper_frames=0;air=0;landings=0;was_ground=True;roof_frames=0;started=time.perf_counter()
for frame in range(7200):
 s=lib.buggy_state()
 lib.buggy_surface(*(surface(w.x,w.y) for w in s.wheel))
 if s.grounded:
  cap=8 if (409<s.body.x<429 or 482<s.body.x<501) else 14
  g,b=(0,1) if s.speed>cap else (1,0)
 else:
  target=-.25 if (417<s.body.x<447 or 495<s.body.x<521) else -.05
  err=target-s.body.angle-s.spin*.35
  g,b=(1,0) if err>.08 else ((0,1) if err<-.08 else (0,0))
 s=step(g,b);upper_frames+=272<s.body.x<300 and s.body.y>height(s.body.x)+2;max_x=max(max_x,s.body.x);air+=not s.grounded
 if s.grounded and not was_ground:landings+=1
 was_ground=bool(s.grounded);roof_frames+=s.roof
 if s.body.x>=600:break
assert max_x>=600,('incomplete',max_x,s.body.y,s.body.angle)
results.update(track_completed=True,track_time_s=round((frame+1)/60,2),air_frames=air,landings=landings,roof_frames=roof_frames,native_step_mean_ms=round((time.perf_counter()-started)*1000/(frame+1),4))
assert upper_frames>30,'Upper shortcut was not actually reached'
results['upper_route_frames']=upper_frames
# The lower valley remains traversable beneath the optional elevated trail.
lib.buggy_reset(273,height(273)+1.8)
for _ in range(1200):
 s=lib.buggy_state();lib.buggy_surface(*(surface(w.x,w.y) for w in s.wheel));s=step(1,0)
 if s.body.x>306:break
assert s.body.x>306,('Valley path blocked',s.body.x,s.body.y)
results['lower_route_verified']=True
# Holding gas alone must require a retry: orientation/speed decisions have a purpose.
lib.buggy_reset(3,1.8);roof=0;gas_only_crash=False
for frame in range(7200):
 s=lib.buggy_state();lib.buggy_surface(*(surface(w.x,w.y) for w in s.wheel));s=step(1,0)
 roof=roof+1 if s.roof else 0
 if roof>=33 or s.body.y< -9:gas_only_crash=True;break
 if s.body.x>=600:break
assert gas_only_crash,('Gas-only unexpectedly completed',s.body.x)
results['gas_only']={'crashed':gas_only_crash,'distance_m':round(s.body.x-3,1)}
# All four surfaces change real rolling response, not just the HUD label.
ratios=[]
for material in range(4):
 create([(-100,0),(2000,0)]);step(n=180);lib.buggy_surface(material,material);v=step(1,0,180).speed
 coast=step(0,0,120).speed;ratios.append(coast/v)
assert ratios[1]<ratios[0]-.12,ratios
assert len(set(round(v,3) for v in ratios))==4,ratios
results['surface_coast_retention']=dict(zip(['dirt','grass','stone','wood'],[round(v,3) for v in ratios]))
# Repeated resets do not retain old bodies/worlds, and reproduce the same start.
for i in range(100):
 lib.buggy_reset(3,1.8);s=step(n=180);assert abs(s.body.x-3)<.1 and s.grounded
# Live tuning preserves the pose and survives a vehicle restart.
before=lib.buggy_state().body
lib.buggy_tune(.6,2,.3,.4)
after=lib.buggy_state().body
assert before.x==after.x and before.y==after.y and before.angle==after.angle
lib.buggy_reset(3,1.8);t=lib.buggy_tuning();assert abs(t.power-.6)<.001 and abs(t.spring-2)<.001
# Compare genuine response, rather than merely reading stored settings.
speeds=[]
for power in [.6,1.8]:
 create([(-100,0),(2000,0)]);lib.buggy_tune(power,4.2,.65,1.1);step(n=180);speeds.append(step(1,0,60).speed)
assert speeds[1]>speeds[0]*1.3,speeds
angles=[]
for air in [.4,1.8]:
 lib.buggy_tune(1.25,4.2,.65,air);lib.buggy_reset(3,12);angles.append(step(1,0,20).body.angle)
assert angles[1]>angles[0]*1.5,angles
# All user-facing extreme settings can be changed repeatedly while moving.
create([(-100,0),(2000,0)])
for i in range(900):
 if i%30==0:lib.buggy_tune(.6 if i%60 else 1.8,2 if i%60 else 7,.3 if i%60 else 1.1,.4 if i%60 else 1.8)
 step(1,0)
lib.buggy_tune(float('nan'),-100,100,float('inf'));t=lib.buggy_tuning()
assert abs(t.power-1.25)<.001 and t.spring==2 and abs(t.damping-1.1)<.001 and abs(t.air-1.1)<.001
lib.buggy_tune(1.25,4.2,.65,1.1)
results['live_tuning']={'pose_preserved':True,'power_speed_after_1s_m_s':[round(x,3) for x in speeds],'air_angle_rad':[round(x,3) for x in angles],'changing_extremes_steps':900,'invalid_values_clamped':True}
lib.buggy_destroy();assert lib.b2GetByteCount()==0,lib.b2GetByteCount()
results['reset_cycles']=100;results['box2d_bytes_after_destroy']=0
print(json.dumps(results,indent=2))
(root/'docs/physics-results.json').write_text(json.dumps(results,indent=2)+'\n')
