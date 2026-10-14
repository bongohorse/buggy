local M={}
function M.medal(time)
 if time<=65 then return 'GOLD',3 elseif time<=90 then return 'SILVER',2 end
 return 'BRONZE',1
end
function M.finish(record,time,practice)
 if practice then return record,false end
 local changed=not record.best_time or time<record.best_time
 local _,rank=M.medal(time)
 record.medal=math.max(record.medal or 0,rank)
 if changed then record.best_time=time end
 return record,changed
end
return M
