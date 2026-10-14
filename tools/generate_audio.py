"""Small original procedural mono effects; deterministic synthesis, no external recordings."""
from pathlib import Path
import wave,math,random,struct
r=Path(__file__).resolve().parents[1];out=r/'assets/audio';out.mkdir(exist_ok=True);rate=22050
rng=random.Random(318)
def save(name,seconds,fn,loop=False):
 samples=[];last=0
 for i in range(round(seconds*rate)):
  t=i/rate;last=last*.83+rng.uniform(-1,1)*.17;x=fn(t,last)
  if not loop:x*=min(1,t/.005)*min(1,(seconds-t)/.025)
  samples.append(max(-.94,min(.94,x)))
 with wave.open(str(out/(name+'.wav')),'wb') as w:
  w.setparams((1,2,rate,len(samples),'NONE','not compressed'));w.writeframes(b''.join(struct.pack('<h',round(x*30000)) for x in samples))
 (out/(name+'.sound')).write_text('sound: "/assets/audio/'+name+'.wav"\nlooping: '+('1' if loop else '0')+'\ngain: 1\nspeed: 1\n')
save('engine',2,lambda t,n:(.32*math.sin(math.tau*55*t)+.17*math.sin(math.tau*110*t)+.11*math.sin(math.tau*165*t))*(.78+.22*math.sin(math.tau*13*t)),True)
save('dirt',2,lambda t,n:n*.7*(.6+.4*math.sin(math.tau*11*t)),True)
save('grass',2,lambda t,n:n*.35+.04*math.sin(math.tau*87*t),True)
save('stone',2,lambda t,n:n*(.4+.5*math.sin(math.tau*27*t)**8)+.08*math.sin(math.tau*180*t)*math.sin(math.tau*19*t)**12,True)
save('wood',2,lambda t,n:.14*math.sin(math.tau*95*t)*math.sin(math.tau*9*t)**6+n*.15,True)
save('landing',.35,lambda t,n:(math.sin(math.tau*(88*t-70*t*t))*.55+n*.5)*math.exp(-t*14))
save('creak',.6,lambda t,n:(.22*math.sin(math.tau*(210*t+25*t*t))+.08*math.sin(math.tau*420*t)+n*.10)*math.sin(math.pi*t/.6))
save('pickup',.24,lambda t,n:.28*math.sin(math.tau*(660*t+550*t*t))*math.exp(-t*7))
save('checkpoint',.4,lambda t,n:.22*math.sin(math.tau*(440 if t<.18 else 660)*t)*math.exp(-t*3))
print('Nine original sound assets generated, mono 22.05kHz')
