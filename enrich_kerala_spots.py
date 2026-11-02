import json
import re
import urllib.request
import urllib.parse
import os
import time

print("Starting Kerala Spots Real Photo Enrichment...")

with open('apps/web/kerala_spots.js', 'r', encoding='utf-8') as f:
    text = f.read()
    m = re.search(r'const KERALA_SPOTS = (\[[\s\S]*?\]);', text)
    kl_spots = json.loads(m.group(1))

# Load existing cache
cache = {}
if os.path.exists('data/place_real_photos_cache.json'):
    with open('data/place_real_photos_cache.json', 'r', encoding='utf-8') as f:
        cache = json.load(f)

def clean_query(name, dist_name):
    clean = re.sub(r'\s*\([^)]*\)', '', name)
    clean = re.sub(r'\s+(Ancient|Historic|Sacred|Perennial|Clifftop|Panoramic|Lakeside|Catchment|High-Altitude)\s+', ' ', clean)
    return f"{clean} {dist_name} Kerala"

def search_wikipedia_photo(query):
    url = f"https://en.wikipedia.org/w/api.php?action=query&generator=search&gsrsearch={urllib.parse.quote(query)}&gsrlimit=3&prop=pageimages&piprop=thumbnail|original&pithumbsize=1280&format=json"
    req = urllib.request.Request(url, headers={'User-Agent': 'SafarTravelApp/2.0 (travel@safar.in)'})
    try:
        with urllib.request.urlopen(req, timeout=6) as res:
            data = json.loads(res.read().decode('utf-8'))
            pages = data.get('query', {}).get('pages', {})
            for pid, page in sorted(pages.items(), key=lambda x: x[1].get('index', 99)):
                thumb = page.get('thumbnail', {}).get('source', '')
                title = page.get('title', '')
                if thumb:
                    lower = thumb.lower()
                    if any(bad in lower for bad in ['.svg', 'locator', 'flag', 'coat_of_arms', 'icon', 'seal', 'diagram', 'in-tn', 'in-kl']):
                        continue
                    clean_url = thumb.split('?')[0].replace('https://thumb.wikimedia.org/', 'https://upload.wikimedia.org/')
                    return title, clean_url
    except Exception:
        pass
    return None, None

updated_count = 0
for idx, s in enumerate(kl_spots):
    cur_img = s.get('imageUrl', '')
    is_unsplash = 'unsplash' in cur_img.lower()
    is_svg = '.svg' in cur_img.lower()
    
    if s['name'] in cache and not is_svg:
        s['imageUrl'] = cache[s['name']]
        continue
        
    if is_unsplash or is_svg or s['name'] not in cache:
        q1 = clean_query(s['name'], s.get('districtName', ''))
        title, img = search_wikipedia_photo(q1)
        if not img:
            q2 = re.sub(r'\s*\([^)]*\)', '', s['name'])
            title, img = search_wikipedia_photo(q2)
        if not img:
            q3 = f"{s.get('districtName', '')} district tourism Kerala"
            title, img = search_wikipedia_photo(q3)
            
        if img:
            s['imageUrl'] = img
            cache[s['name']] = img
            updated_count += 1
            print(f"[{idx+1}/{len(kl_spots)}] UPDATED: {s['name']} -> {img[:65]}...")
        else:
            print(f"[{idx+1}/{len(kl_spots)}] NOT FOUND: {s['name']}")
        time.sleep(0.1)

print(f"\nFinished Kerala enrichment. Updated {updated_count} spots.")

# Save updated cache
with open('data/place_real_photos_cache.json', 'w', encoding='utf-8') as f:
    json.dump(cache, f, indent=2, ensure_ascii=False)

# Write updated kerala_spots.js
with open('apps/web/kerala_spots.js', 'w', encoding='utf-8') as f:
    f.write(f"// SAFAR TRAVEL APP - KERALA TOURIST ATTRACTIONS CATALOG\n// 14 Districts x 10 Verified Spots = 140 Authentic Landmarks\n\nconst KERALA_SPOTS = {json.dumps(kl_spots, indent=2, ensure_ascii=False)};\n\nif (typeof module !== 'undefined') module.exports = {{ KERALA_SPOTS }};\n")

print("Saved updated apps/web/kerala_spots.js!")
