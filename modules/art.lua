local track=require 'modules.track'
local sizes=require 'modules.art_sizes'
local M={}
local bg_factory={background='#parallax1',['parallax-hills']='#parallax2',['parallax-forest']='#parallax3'}
local function image(name,x,y,z,w,h,color,bg)
 local id=factory.create(bg and bg_factory[name] or '#pixel',vmath.vector3(x,y,z));sprite.play_flipbook(msg.url(nil,id,'sprite'),name)
 local sz=sizes[name];go.set_scale(vmath.vector3(w/sz[1],h/sz[2],1),id)
 if color then go.set(msg.url(nil,id,'sprite'),'tint',color) end
 return id
end
local function line(x,y,xx,yy,width,z,color)
 local dx,dy=xx-x,yy-y
 local id=image('pixel',(x+xx)/2,(y+yy)/2,z,math.sqrt(dx*dx+dy*dy)+1,width,color)
 go.set_rotation(vmath.quat_rotation_z(math.atan2(dy,dx)),id);return id
end
local function plant(name,x,h,z,below)
 local sz=sizes[name];return image(name,x*60,track.height(x)*60+210+h*.5-(below or 0),z,h*sz[1]/sz[2],h)
end
function M.create()
 local a={bg={},dust={},springs={},wheel={},deck={},ropes={},foreground={},tokens={},clock=0}
 local layers={{'background',.055,-.95},{'parallax-hills',.20,-.84},{'parallax-forest',.46,-.68}}
 for _,l in ipairs(layers) do
  local layer={speed=l[2],z=l[3],name=l[1],ids={}}
  for i=1,3 do layer.ids[i]=image(l[1],0,0,l[3],1020,680,nil,true) end
  a.bg[#a.bg+1]=layer
 end
 -- Mature trees are 3-5 times the height of the buggy; overlap into dense groves.
 for i=1,math.floor((track.finish+36)/2.92) do
  local x=-16+i*2.92+math.sin(i*3.1)*.9
  if not track.is_gap(x) then
   local name=i%3==0 and 'tree-birch-painted' or 'tree-pine-painted'
   local h=300+(i*71)%220
   plant(name,x,h,-.48-(i%3)*.012,15+(i%4)*8)
  end
 end
 for i=1,math.floor((track.finish+36)/1.66) do
  local x=-16+i*1.66+math.sin(i*2.5)*.35
  if not track.is_gap(x) then
   local rock=track.is_rock(x)
   if not rock or i%3==0 then
    local h=22+(i*17)%29;local id=plant('grass-painted',x,h,i%3==0 and .30 or -.09,9)
    go.set_rotation(vmath.quat_rotation_z(math.atan2(track.height(x+.25)-track.height(x-.25),.5)*.6),id)
   end
   if rock or i%9==0 then local h=rock and (20+i%4*8) or 35;plant('rocks-painted',x,h,i%2==0 and .31 or -.08,h-6) end
  end
 end
 -- Near-camera plants and rocks move faster and sit below the driving line.
 for i=1,math.ceil((track.finish+36)/7.1) do
  local x=-6+i*7.1;local h=70+(i*13)%55
  local id=plant(i%3==0 and 'rocks-painted' or 'grass-painted',x,h,.42,145)
  a.foreground[#a.foreground+1]={id=id,x=x*60,h=h}
 end
 local b=track.bridge
 image('pixel',(b.start+b.finish)*30,106,-.38,(b.finish-b.start)*60,34,vmath.vector4(.18,.44,.44,1))
 for _,x in ipairs({b.start,b.finish}) do
  local id=image('wood-painted',x*60,b.height*60+190,-.04,145,18);go.set_rotation(vmath.quat_rotation_z(math.pi/2),id)
  line(x*60,b.height*60+260,x*60+(x==b.start and -48 or 48),b.height*60+170,5,-.05,vmath.vector4(.44,.30,.17,1))
 end
 for i=1,12 do
  a.deck[i]=image('wood-painted',0,0,-.025,(b.finish-b.start)*5+2,15)
  a.ropes[i]=image('pixel',0,0,-.03,72,3,vmath.vector4(.66,.50,.29,1))
 end
 for _,x in ipairs(track.checkpoints) do plant('flag',x,85,-.035,0) end
 for _,w in ipairs(track.warnings) do
  local y=track.height(w.x)*60+210
  local post=image('wood-painted',w.x*60,y+45,-.06,90,12);go.set_rotation(vmath.quat_rotation_z(math.pi/2),post)
  image('ui-panel-painted',w.x*60,y+91,-.05,96,36)
  line(w.x*60-12,y+92,w.x*60+12,y+92,4,-.04,vmath.vector4(1,.7,.22,1))
 end
 for i,t in ipairs(track.tokens) do a.tokens[i]=image('wheel-painted',t.x*60,t.y*60+210,.05,38,38,vmath.vector4(1,.85,.45,1)) end
 image('flag',track.finish*60+25,track.height(track.finish)*60+290,0,96,160)
 a.body=image('chassis',0,0,.1,228,112)
 for i=1,2 do a.springs[i]=image('spring',0,0,.15,13,55);a.wheel[i]=image('wheel-painted',0,0,.2,60,60) end
 for i=1,22 do a.dust[i]={id=image('dot',0,-2000,.05,12,12),life=0} end
 a.next_dust=1;a.dust_clock=0;return a
end
local function place(id,p,z,offset)
 local x,y=p.x*60,p.y*60+210
 if offset then x=x-math.sin(p.angle)*offset;y=y+math.cos(p.angle)*offset end
 go.set_position(vmath.vector3(x,y,z),id);go.set_rotation(vmath.quat_rotation_z(p.angle),id)
end
function M.update(a,s,p,dt)
 a.clock=a.clock+dt
 for i,t in ipairs(track.tokens) do
  local y=s.collected[i] and -4000 or t.y*60+210+math.sin(a.clock*3+i)*5
  go.set_position(vmath.vector3(t.x*60,y,.05),a.tokens[i]);go.set_rotation(vmath.quat_rotation_z(a.clock*.5),a.tokens[i])
 end
 for n,l in ipairs(a.bg) do
  local bh=n==1 and math.max(s.view_height*1.35,900) or (n==2 and 570 or 430)
  local sz=sizes[l.name];local bw=math.max(bh*sz[1]/sz[2],s.view_width);bh=bw*sz[2]/sz[1]
  local base=n==1 and (s.camera_y+(s.view_height-bh)*.5) or (185+s.camera_y*(n==2 and .75 or .50))
  for i,id in ipairs(l.ids) do
   local x=s.camera_x+((i-1)*bw-s.camera_x*l.speed)%(3*bw)-bw
   go.set_position(vmath.vector3(x,base+bh*.5,l.z),id);go.set_scale(vmath.vector3(bw/sz[1],bh/sz[2],1),id)
  end
 end
 for _,o in ipairs(a.foreground) do local x=o.x-s.camera_x*.10;local y=track.is_gap(x/60) and -4000 or track.height(x/60)*60+210+o.h/2-145;go.set_position(vmath.vector3(x,y,.42),o.id) end
 for i,d in ipairs(p.bridge or {}) do
  place(a.deck[i],d,-.025)
  go.set_position(vmath.vector3(d.x*60,d.y*60+258,-.03),a.ropes[i]);go.set_rotation(vmath.quat_rotation_z(d.angle),a.ropes[i])
 end
 place(a.body,p.body,.1,19)
 for i,wp in ipairs({p.rear,p.front}) do
  place(a.wheel[i],wp,.2)
  local ax=i==1 and -.75 or .75
  local x=p.body.x+math.cos(p.body.angle)*ax;local y=p.body.y+math.sin(p.body.angle)*ax
  local dx,dy=(x-wp.x)*60,(y-wp.y)*60
  go.set_position(vmath.vector3((x+wp.x)*30,(y+wp.y)*30+210,.15),a.springs[i])
  go.set_rotation(vmath.quat_rotation_z(math.atan2(dy,dx)-math.pi/2),a.springs[i]);go.set_scale(vmath.vector3(.65,math.sqrt(dx*dx+dy*dy)/96,1),a.springs[i])
 end
 a.dust_clock=a.dust_clock+dt
 if s.mode=='running' and p.grounded and math.abs(p.speed)>2 and a.dust_clock>.055 then
  a.dust_clock=0;local d=a.dust[a.next_dust];a.next_dust=a.next_dust%#a.dust+1
  d.x=p.rear.x*60;d.y=p.rear.y*60+190;d.maxlife=s.surface==2 and .32 or .6;d.life=d.maxlife;d.surface=s.surface;d.vx=-p.speed*(s.surface==2 and 17 or 12);d.vy=20+math.random()*(s.surface==2 and 70 or 35)
 end
 for _,d in ipairs(a.dust) do
  d.life=math.max(0,d.life-dt)
  if d.life>0 then d.x=d.x+d.vx*dt;d.y=d.y+d.vy*dt;go.set_position(vmath.vector3(d.x,d.y,.05),d.id);local size=d.surface==2 and 6 or (10+(1-d.life/d.maxlife)*22);go.set_scale(vmath.vector3(size/32,(d.surface==1 and size*.3 or size)/32,1),d.id) end
  local colors={{.86,.74,.52},{.45,.62,.22},{.64,.68,.71},{.66,.45,.26}};local c=colors[(d.surface or 0)+1];go.set(msg.url(nil,d.id,'sprite'),'tint',vmath.vector4(c[1],c[2],c[3],d.life/(d.maxlife or .6)*.6))
 end
end
return M
