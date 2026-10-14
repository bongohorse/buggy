local data=require 'modules.track_data'
local M=data
M.length=M.finish-3
M.revision="ridge600-v1"
function M.height(x)
 local p=M.points
 if x<=p[1][1] then return p[1][2] end
 if x>=p[#p][1] then return p[#p][2] end
 local lo,hi=1,#p
 while hi-lo>1 do local mid=math.floor((lo+hi)/2);if p[mid][1]<=x then lo=mid else hi=mid end end
 local a,b=p[lo],p[hi];return a[2]+(b[2]-a[2])*(x-a[1])/(b[1]-a[1])
end
function M.is_bridge(x) return x>=M.bridge.start and x<=M.bridge.finish end
function M.section(x)
 for _,section in ipairs(M.sections) do if x<section.finish then return section.name end end
 return M.sections[#M.sections].name
end
function M.is_gap(x)
 if M.is_bridge(x) then return true end
 for _,g in ipairs(M.gaps) do if x>g.start and x<g.finish then return true end end
 return false
end
function M.surface(x,y)
 if y and x>=268 and x<=302 and y>M.height(x)+1.5 then return 2 end
 for _,v in ipairs(M.surfaces) do if x>=v.start and x<v.finish then return v.kind end end
 return 0
end
function M.is_rock(x) return M.surface(x)==2 end
function M.warning(x)
 for _,v in ipairs(M.warnings) do if x>=v.x and x<v.x+17 then return v.text end end
 return ''
end
function M.slope(x)
 return math.atan2(M.height(x+.5)-M.height(x-.5),1)
end
return M
