import glob
from pathlib import Path

names = glob.glob(r'C:\work\Hinggan_League\ems_simulate\www\assets\index-*.js')
assert names, 'no index js'
js_name = Path(names[0]).name
targets = [
    Path(names[0]),
    Path(r'C:\work\Hinggan_League\ems_simulate\dist\ems_simulate_backend\_internal\www\assets') / js_name,
]
old = ',{key:"contact",icon:Cn,label:t("settings.contact")}'
for f in targets:
    s = f.read_text(encoding='utf-8')
    if old not in s:
        print(f, 'PATTERN NOT FOUND, skip')
        continue
    f.write_text(s.replace(old, ''), encoding='utf-8')
    print(f, 'patched; residual =', f.read_text(encoding='utf-8').count(old))
