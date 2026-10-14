local M={}
local loops={'engine','dirt','grass','stone','wood'}
function M.stop(a)
 if a.playing then for _,n in ipairs(loops) do sound.stop('#audio_'..n) end;for _,n in ipairs({'landing','creak','pickup','checkpoint'}) do sound.stop('#audio_'..n) end;a.playing=false end
end
function M.update(a,s,p,gas,dt)
 if not s.sound_on or s.mode~='running' then M.stop(a);return end
 if not a.playing then for _,n in ipairs(loops) do sound.play('#audio_'..n,{gain=0}) end;a.playing=true end
 local speed=math.abs(p.speed)
 a.pitch=(a.pitch or .8)+((.75+math.min(1,speed/17)*.9+(gas and .20 or 0))-(a.pitch or .8))*math.min(1,dt*8)
 go.set('#audio_engine','speed',a.pitch);sound.set_gain('#audio_engine',(gas or p.gear==-1) and .22 or .11)
 for i=0,3 do
  local n=loops[i+2];local gain=p.grounded and s.surface==i and math.min(.30,speed*.018) or 0
  sound.set_gain('#audio_'..n,gain);go.set('#audio_'..n,'speed',.75+math.min(speed/18,.7))
 end
 a.creak=(a.creak or 0)-dt
 if p.bridge_sag and math.abs(p.body.x-105)<10 and p.bridge_sag>.6 and a.creak<=0 then
  sound.play('#audio_creak',{gain=.26});a.creak=1.1
 end
end
function M.effect(s,name,gain)
 if s.sound_on and s.mode=='running' then sound.play('#audio_'..name,{gain=gain or .4}) end
end
return M
