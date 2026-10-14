"""Check smooth shared samples, aligned render surfaces and a real bridge gap."""
from pathlib import Path
import json,math,re
r=Path(__file__).resolve().parents[1]
course=json.loads((r/'docs/track-profile.json').read_text());p=course['points']
assert len(p)==6401 and all(0<b[0]-a[0]<.10001 for a,b in zip(p,p[1:]))
angles=[math.atan2(b[1]-a[1],b[0]-a[0]) for a,b in zip(p,p[1:])]
gaps=[course['bridge']]+course['gaps']
def visible(a,b):return not any(a[0]>=g['start']-.001 and b[0]<=g['finish']+.001 for g in gaps)
turn=max(abs(angles[i+1]-angles[i]) for i in range(len(angles)-1) if visible(p[i],p[i+1]) and visible(p[i+1],p[i+2]))
assert turn<math.radians(6),math.degrees(turn)
expected={(round(x*60,4),round(y*60+210,4)) for x,y in p}
for name,offset in [('terrain',-.22),('road',0),('edge',.025)]:
 streams=json.loads((r/'assets'/f'{name}.buffer').read_text());s={x['name']:x for x in streams}
 pos=s['position']['data'];assert len(pos)//3==len(s['texcoord0']['data'])//2==len(s['color']['data'])//4
 for i in range(0,len(pos),18):
  x1,y1=pos[i:i+2];x2,y2=pos[i+6:i+8]
  assert not any(x1>=g['start']*60-.001 and x2<=g['finish']*60+.001 for g in [course['bridge']]+course['gaps']),'Static mesh spans bridge/gap'
  assert (round(x1,4),round(y1-offset*60,4)) in expected
  assert (round(x2,4),round(y2-offset*60,4)) in expected
print(f'PASS: {len(p)} common samples, maximum facet turn {math.degrees(turn):.2f} degrees, three aligned meshes, bridge and two open ravine gaps')

route=course['routes'][0]['points'];expected_route={(round(x*60,4),round(y*60+210,4)) for x,y in route}
streams=json.loads((r/'assets/route.buffer').read_text());pos=streams[0]['data']
for i in range(0,len(pos),18):
 assert (round(pos[i],4),round(pos[i+1],4)) in expected_route
 assert abs((pos[i+1]-pos[i+4])-27)<.001
print('PASS: raised route render profile matches one-sided collision trail')
