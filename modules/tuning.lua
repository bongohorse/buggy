local M={revision=0,saved_revision=0,save_delay=0}
M.spec={
 {key='power',label='POWER',min=.6,max=1.8,step=.05,default=1.25,format='percent'},
 {key='spring',label='SPRING',min=2,max=7,step=.1,default=4.2,format='hz'},
 {key='damping',label='DAMPING',min=.3,max=1.1,step=.05,default=.65,format='ratio'},
 {key='air',label='AIR CONTROL',min=.4,max=1.8,step=.05,default=1.1,format='percent'},
 {key='zoom',label='ZOOM',min=.8,max=1.6,step=.05,default=1.2,format='percent'}
}
M.values={}
for _,spec in ipairs(M.spec) do M.values[spec.key]=spec.default end
local function set_value(spec,value)
 if type(value)~='number' or value~=value then return false end
 value=math.max(spec.min,math.min(spec.max,value))
 value=math.max(spec.min,math.min(spec.max,math.floor(value/spec.step+.5)*spec.step))
 if math.abs(M.values[spec.key]-value)<.00001 then return false end
 M.values[spec.key]=value;return true
end
function M.set(index,value)
 if set_value(M.spec[index],value) then M.revision=M.revision+1;M.save_delay=.5;return true end
 return false
end
function M.fraction(index)
 local spec=M.spec[index];return (M.values[spec.key]-spec.min)/(spec.max-spec.min)
end
function M.adjust(index,fraction)
 local spec=M.spec[index];return M.set(index,spec.min+math.max(0,math.min(1,fraction))*(spec.max-spec.min))
end
function M.reset()
 local changed=false
 for i,spec in ipairs(M.spec) do changed=M.set(i,spec.default) or changed end
 return changed
end
function M.label(index)
 local spec=M.spec[index];local value=M.values[spec.key]
 if spec.format=='percent' then return string.format('%d%%',math.floor(value*100+.5)) end
 if spec.format=='hz' then return string.format('%.1f Hz',value) end
 return string.format('%.2f',value)
end
function M.apply()
 local v=M.values;buggy_physics.tune(v.power,v.spring,v.damping,v.air)
end
function M.load()
 local ok,data=pcall(sys.load,sys.get_save_file('buggy_ridge','tuning'))
 if ok and type(data)=='table' then for _,spec in ipairs(M.spec) do set_value(spec,data[spec.key]) end end
 M.revision=M.revision+1;M.saved_revision=M.revision
end
function M.save()
 if M.saved_revision==M.revision then return end
 local ok=pcall(sys.save,sys.get_save_file('buggy_ridge','tuning'),M.values)
 if ok then M.saved_revision=M.revision end
end
function M.update(dt)
 if M.saved_revision~=M.revision then M.save_delay=M.save_delay-dt;if M.save_delay<=0 then M.save();M.save_delay=1 end end
end
return M
