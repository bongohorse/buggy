local track=require 'modules.track'
local tuning=require 'modules.tuning'
local M={}
local function clamp(x,a,b) return math.max(a,math.min(b,x)) end
function M.update(s,p,w,h,dt,snap)
 if s.viewport_w~=w or s.viewport_h~=h then snap=true;s.viewport_w=w;s.viewport_h=h end
 local speed=math.abs(p.speed)
 local zoom=tuning.values.zoom
 -- A small widening at speed preserves the landing view while the zoom slider stays authoritative.
 local height=math.max(640,660*h/w)/zoom*(1+clamp(speed/20,0,1)*.12)
 local shape_alpha=snap and 1 or (1-math.exp(-7*math.min(dt,.05)))
 s.view_height=s.view_height+(height-s.view_height)*shape_alpha;s.view_width=s.view_height*w/h
 local direction=p.speed< -1 and -1 or 1
 local lead=clamp(speed*8,0,s.view_width*.10)*direction
 local anchor=direction<0 and .60 or .40
 local target_x=p.body.x*60-s.view_width*anchor+lead
 -- Follow the road rather than every suspension bounce; let the buggy move within the frame in the air.
 local ground=track.height(p.body.x+direction*2)*60+210
 local air=clamp(p.body.y*60+210-ground,0,220)*.28
 local target_y=math.max(ground-s.view_height*.30+air,p.body.y*60+210-s.view_height*.78)
 local ax=snap and 1 or (1-math.exp(-6*math.min(dt,.05)))
 local ay=snap and 1 or (1-math.exp(-2.4*math.min(dt,.05)))
 s.camera_x=s.camera_x+(target_x-s.camera_x)*ax
 s.camera_y=s.camera_y+(target_y-s.camera_y)*ay
end
return M
