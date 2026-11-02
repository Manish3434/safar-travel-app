import re

with open('apps/web/districts.js', 'r', encoding='utf-8') as f:
    text = f.read()

matches = re.findall(r"d\('([^']+)',\s*'([^']+)',\s*'([^']+)'", text)
print(f"Total district entries in districts.js: {len(matches)}")
states = {}
for state, dist_id, name in matches:
    states.setdefault(state, []).append((dist_id, name))

print(f"Total states/UTs in districts.js: {len(states)}")
for st, dists in sorted(states.items()):
    print(f"  {st}: {len(dists)} districts")
