from pathlib import Path
import json
root=Path(__file__).resolve().parents[1]
d=root/'tests/generated';d.mkdir(exist_ok=True)
(d/'hud_tuning.gui_script').write_text((root/'main/hud.gui_script').read_text()+'\n'+(root/'tests/gui_tuning_harness.lua').read_text())
(d/'hud_tuning.gui').write_text((root/'main/hud.gui').read_text().replace('/main/hud.gui_script','/tests/generated/hud_tuning.gui_script'))
collection=(root/'tests/smoke.collection').read_text()
collection+='\nembedded_instances { id: "gui_test" data: '+json.dumps('components { id: "gui" component: "/tests/generated/hud_tuning.gui" }\n')+' }\n'
(d/'smoke.collection').write_text(collection)
