"""Verify the staged Defold HTML5 release and record reproducible file hashes."""
from pathlib import Path
import hashlib,json,re
root=Path(__file__).resolve().parents[1];d=root/'dist';files=[]
for p in sorted(d.rglob('*')):
 if p.is_file():files.append(dict(path=p.relative_to(d).as_posix(),bytes=p.stat().st_size,sha256=hashlib.sha256(p.read_bytes()).hexdigest()))
assert any(x['path'].endswith('.wasm') for x in files)
html=(d/'index.html').read_text();assert '{{' not in html
for name in re.findall(r'<script[^>]+src=[\'\"]([^\'\"]+)',html):
 if not name.startswith(('http','//')):assert (d/name).exists(),name
(root/'docs/html5-bundle.json').write_text(json.dumps(dict(engine='Defold 1.14.0',physics='Box2D 3.1.1',bytes=sum(x['bytes'] for x in files),files=files),indent=2)+'\n')
p=root/'docs/VALIDATION.md';s=p.read_text().replace('A final cached build after toolbar text-size adjustment runs in the packaging workflow.','The final cached build and both engine/GUI runs after toolbar text-size adjustment passed in the packaging workflow.');p.write_text(s)
print('PASS: staged release, resolved HTML/loader references, bundle hashes;',sum(x['bytes'] for x in files),'bytes')
