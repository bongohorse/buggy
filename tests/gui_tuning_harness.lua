-- Appended to the production GUI script only in the headless test collection.
local normal_init,normal_update,normal_input=init,update,on_input
local function mouse(self,x,y,pressed,released)
 normal_input(self,hash('pointer'),{x=x,y=y,pressed=pressed,released=released})
end
local function tap(self,node)
 local p=gui.get_position(node);mouse(self,p.x,p.y,true,false);mouse(self,p.x,p.y,false,true)
end
local function touch(self,id,x,y,pressed,released)
 normal_input(self,hash('multitouch'),{touch={{id=id,x=x,y=y,pressed=pressed,released=released}}})
end
function init(self) normal_init(self);self.probe_frames=0 end
function update(self,dt)
 normal_update(self,dt)
 if s.mode~='running' then return end
 if self.last_tick==s.tick then return end;self.last_tick=s.tick
 self.probe_frames=self.probe_frames+1;local n=self.probe_frames
 if n==12 then tap(self,self.tune.node);assert(self.expanded)
 elseif n==14 then
  local before=buggy_physics.state().body
  local row=self.rows[1];mouse(self,row.x+row.width,row.y,true,false)
  assert(math.abs(tuning.values.power-1.8)<.001)
  local after=buggy_physics.state().body;assert(before.x==after.x and before.y==after.y,'Slider reset or moved the buggy')
  assert(self.drags.mouse==1 and s.input.touches.mouse==nil)
 elseif n==16 then
  local row=self.rows[1];mouse(self,row.x-200,row.y-100,false,false)
  assert(math.abs(tuning.values.power-.6)<.001,'Captured drag did not clamp outside the rail')
 elseif n==17 then
  local row=self.rows[1];mouse(self,row.x,row.y,false,true);assert(self.drags.mouse==nil)
 elseif n==20 then
  local row=self.rows[3];mouse(self,row.x,row.y,true,false);mouse(self,row.x,row.y,false,true)
  assert(math.abs(tuning.values.damping-.3)<.001)
 elseif n==24 then
  local row=self.rows[5];touch(self,42,row.x+row.width,row.y,true,false)
  local pedal=gui.get_position(self.gas.node);touch(self,43,pedal.x,pedal.y,true,false)
  assert(math.abs(tuning.values.zoom-1.6)<.001 and self.drags[42]==5)
  assert(s.input.touches[42]==nil and s.input.touches[43]=='gas','Slider capture interfered with the pedal')
 elseif n==26 then
  local row=self.rows[5];touch(self,42,row.x+row.width+80,row.y,false,true)
  local pedal=gui.get_position(self.gas.node);touch(self,43,pedal.x,pedal.y,false,true)
  assert(self.drags[42]==nil and s.input.touches[43]==nil)
 elseif n==30 then
  local p=gui.get_position(self.defaults.node);touch(self,44,p.x,p.y,true,false);touch(self,44,p.x,p.y,false,true)
  for _,spec in ipairs(tuning.spec) do assert(math.abs(tuning.values[spec.key]-spec.default)<.001) end
 elseif n==34 then
  local p=gui.get_position(self.tune.node);touch(self,45,p.x,p.y,true,false);touch(self,45,p.x,p.y,false,true)
  assert(not self.expanded)
  local w,h=window.get_size();local expected=sys.get_config_int('buggy.expected_width',0)
  if expected>0 then assert(w==expected,'Unexpected viewport width '..w) end
  print(string.format('BUGGY_GUI_TUNING_PASS viewport=%dx%d mouse, captured drag, touch + gas, defaults, no reset',w,h))
 elseif n==40 then
  local p=gui.get_position(self.sound.node);local old=s.sound_on;touch(self,51,p.x,p.y,true,false);touch(self,51,p.x,p.y,false,true);assert(s.sound_on~=old);self.original_sound=old
 elseif n==42 then
  local p=gui.get_position(self.practice.node);touch(self,52,p.x,p.y,true,false);touch(self,52,p.x,p.y,false,true);assert(s.practice and s.restart=='full')
 elseif n==44 then buggy_physics.reset(120,track.height(120)+1.8)
 elseif n==76 then assert(s.checkpoint==120,'Practice checkpoint did not activate')
 elseif n==78 then
  s.mode='crashed';local p=gui.get_position(self.gas.node);touch(self,53,p.x,p.y,true,false);touch(self,53,p.x,p.y,false,true);assert(s.restart==true,'Gas did not request instant retry')
 elseif n==82 then assert(s.practice and buggy_physics.state().body.x>118,'Checkpoint retry returned to start')
 elseif n==84 then
  local p=gui.get_position(self.practice.node);touch(self,54,p.x,p.y,true,false);touch(self,54,p.x,p.y,false,true);assert(not s.practice and s.restart=='full')
 elseif n==88 then
  assert(s.checkpoint==3 and buggy_physics.state().body.x<10,'Full run did not reset practice checkpoint')
  s.sound_on=self.original_sound;s.audio_dirty=true
  print('BUGGY_GAMEPLAY_UI_PASS sound toggle, practice checkpoint, gas retry, full run')
 end
end
