"""Rebuild metadata/atlases and smooth track; never overwrite painted source art."""
from pathlib import Path
import json,subprocess,sys
from PIL import Image
r=Path(__file__).resolve().parents[1];a=r/'assets'
main=['chassis','wheel-painted','tree-pine-painted','tree-birch-painted','grass-painted','rocks-painted','wood-painted','ui-panel-painted','ui-pedal-painted','spring','pixel','dot','flag']
bg=['background','parallax-hills','parallax-forest']
for name,names in [('game',main)]+[('parallax-'+str(i),[n]) for i,n in enumerate(bg,1)]:
 (a/(name+'.atlas')).write_text('\n'.join('images { image: "/assets/'+n+'.png" }' for n in names)+'\nextrude_borders: 2\nmargin: 0\ninner_padding: 2\n')
sizes={n:list(Image.open(a/(n+'.png')).size) for n in main+bg}
(r/'modules/art_sizes.lua').write_text('return {\n'+''.join('["%s"]={%d,%d},\n'%(n,*s) for n,s in sizes.items())+'}\n')
subprocess.run([sys.executable,str(r/'tools/build_track.py')],check=True)
print('Painted atlases and sprite metadata ready')
