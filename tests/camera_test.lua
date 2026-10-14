package.path='./?.lua;'..package.path
local tuning=require 'modules.tuning'
local camera=require 'modules.camera'
local function state() return {view_height=720,view_width=1280,camera_x=0,camera_y=0} end
local pose={speed=0,body={x=5,y=1}}
local s=state();tuning.values.zoom=1.2;camera.update(s,pose,390,844,1/60,true)
local close=s.view_height;tuning.values.zoom=.8;camera.update(s,pose,390,844,1/60,true)
assert(s.view_height>close*1.4,'Zoom did not change the view')
tuning.values.zoom=1.6;pose.speed=18;camera.update(s,pose,390,844,1/60,true)
local car_x=pose.body.x*60-s.camera_x
assert(car_x>114 and car_x+114<s.view_width,'Buggy cropped at maximum portrait zoom/speed')
pose.speed=0;pose.body.y=1;tuning.values.zoom=1.2;camera.update(s,pose,1280,720,1/60,true)
local y=s.camera_y;pose.body.y=1.15;camera.update(s,pose,1280,720,1/60,false)
assert(math.abs(s.camera_y-y)<.2,'Suspension bounce caused excessive camera movement')
camera.update(s,pose,390,844,1/60,false)
assert(math.abs(s.view_width-660/1.2)<.01,'Orientation change did not reframe immediately')
pose.speed=-10;pose.body.y=1;camera.update(s,pose,390,844,1/60,true)
assert(pose.body.x*60-s.camera_x>s.view_width*.60,'Reverse view does not reveal the road behind')
pose.speed=7;pose.body.x=493;pose.body.y=21;camera.update(s,pose,390,844,1/60,true)
assert(pose.body.y*60+210-s.camera_y<s.view_height*.90,'Summit jump crops the airborne buggy')
print('PASS: reverse view, summit jump framing, camera zoom, portrait framing, bounce damping, orientation')
