"""Build shared smooth collision/render profiles for the main and optional upper trail."""
from pathlib import Path
import json,math
ROOT=Path(__file__).resolve().parents[1];data=json.loads((ROOT/'assets/track-design.json').read_text())
def samples(control):
 n=len(control);dx=[control[i+1][0]-control[i][0] for i in range(n-1)];d=[(control[i+1][1]-control[i][1])/dx[i] for i in range(n-1)];m=[0.0]*n
 for i in range(1,n-1):
  if d[i-1]*d[i]>0:
   w1=2*dx[i]+dx[i-1];w2=dx[i]+2*dx[i-1];m[i]=(w1+w2)/(w1/d[i-1]+w2/d[i])
 def height(x):
  i=next((j for j in range(n-1) if x<=control[j+1][0]),n-2);a,b=control[i],control[i+1];t=(x-a[0])/dx[i]
  return (2*t**3-3*t*t+1)*a[1]+(t**3-2*t*t+t)*dx[i]*m[i]+(-2*t**3+3*t*t)*b[1]+(t**3-t*t)*dx[i]*m[i+1]
 xs={round(control[0][0]+i*data['spacing'],6) for i in range(round((control[-1][0]-control[0][0])/data['spacing'])+1)};xs.update(x for x,y in control)
 return [[x,round(height(x),6)] for x in sorted(xs)]
def smooth(x):x=max(0,min(1,x));return x*x*(3-2*x)
def rock_weight(x):return max([0]+[smooth((x-s['start'])/4)*smooth((s['finish']-x)/4) for s in data['surfaces'] if s['kind']==2])
points=samples(data['control'])
for p in points:p[1]=round(p[1]+rock_weight(p[0])*(.045*math.sin(p[0]*math.tau/1.8)+.018*math.sin(p[0]*math.tau/3.1)),6)
routes=[dict(name=r['name'],points=samples(r['control']),thickness=r['thickness']) for r in data['routes']]
def lua(v):
 if isinstance(v,str):return json.dumps(v)
 if isinstance(v,(int,float)):return format(v,'.6f')
 if isinstance(v,list):return '{'+','.join(lua(x) for x in v)+'}'
 return '{'+','.join(k+'='+lua(x) for k,x in v.items())+'}'
export={k:data[k] for k in ['finish','bridge','gaps','sections','surfaces','checkpoints','warnings','tokens']};export.update(points=points,routes=routes)
(ROOT/'modules/track_data.lua').write_text('return '+lua(export)+'\n')
all_gaps=[data['bridge']]+data['gaps']
def mesh(name,top,bottom,kind,paths):
 pos=[];uv=[];color=[]
 for path,is_route in paths:
  for a,c in zip(path,path[1:]):
   if not is_route and any(a[0]>=g['start']-.001 and c[0]<=g['finish']+.001 for g in all_gaps):continue
   for x,y in [(a[0],a[1]+top),(a[0],a[1]+bottom if kind!='body' or is_route else -20),(c[0],c[1]+top),(c[0],c[1]+top),(a[0],a[1]+bottom if kind!='body' or is_route else -20),(c[0],c[1]+bottom if kind!='body' or is_route else -20)]:
    pos.extend([x*60,y*60+210,{'body':-.24,'road':-.16,'edge':-.12}[kind]]);uv.extend([x*60/192,y*60/192]);w=rock_weight(x)
    base={'body':(.71,.61,.53),'road':(1,.93,.80),'edge':(.84,.77,.52)}[kind];stone={'body':(.64,.70,.76),'road':(.70,.86,1),'edge':(.62,.79,.90)}[kind]
    color.extend([base[k]*(1-w)+stone[k]*w for k in range(3)]+[1])
 streams=[{'name':'position','type':'float32','count':3,'data':pos},{'name':'texcoord0','type':'float32','count':2,'data':uv},{'name':'color','type':'float32','count':4,'data':color}]
 (ROOT/'assets'/name).write_text(json.dumps(streams,separators=(',',':')))
paths=[(points,False)];mesh('terrain.buffer',-.22,-20,'body',paths);mesh('road.buffer',0,-.25,'road',paths);mesh('edge.buffer',.025,-.045,'edge',paths)
# Raised shortcut is drawn as a 0.45m ribbon; one-sided top collision leaves the valley open.
mesh('route.buffer',0,-.45,'road',[(r['points'],True) for r in routes])
(ROOT/'docs/track-profile.json').write_text(json.dumps(dict(points=points,samples=len(points),spacing_m=data['spacing'],finish=data['finish'],surfaces=data['surfaces'],bridge=data['bridge'],gaps=data['gaps'],routes=routes,sections=data['sections']),indent=2)+'\n')
print('Smooth challenge:',len(points),'samples;',data['finish']-3,'metres; shortcut and jump gap')
