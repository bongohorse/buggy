local M={}
function M.clear(s) s.keys={};s.touches={} end
function M.pedals(s)
 local gas,brake=s.keys.gas or false,s.keys.brake or false
 for _,v in pairs(s.touches) do gas=gas or v=='gas';brake=brake or v=='brake' end
 return gas and not brake,brake
end
return M
