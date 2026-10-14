from pathlib import Path
import shutil
root=Path(__file__).resolve().parents[1]
html=list((root/'.build/bundle').glob('*/index.html'))
if len(html)!=1:raise SystemExit('Expected exactly one Defold HTML5 bundle')
bundle=html[0].parent
if not list(bundle.glob('*.wasm')):raise SystemExit('No compiled Defold WASM engine in bundle')
dist=root/'dist'
if dist.exists():shutil.rmtree(dist)
shutil.copytree(bundle,dist)
print('Compiled HTML5 game staged in dist/')
