import csv
import json
import os
import re
import urllib.request
import urllib.parse
from concurrent.futures import ThreadPoolExecutor, as_completed

print("Starting All-India Real District Photo Harvest...")

# Load cache
cache = {}
if os.path.exists('data/place_real_photos_cache.json'):
    with open('data/place_real_photos_cache.json', 'r', encoding='utf-8') as f:
        cache = json.load(f)
print(f"Loaded existing cache with {len(cache)} entries.")

def is_valid_real_photo(url):
    if not url:
        return False
    lower = url.lower()
    bad_keywords = [
        '.svg', 'locator', 'map', 'flag', 'coat_of_arms', 'icon', 
        'seal', 'diagram', 'chart', 'symbol', 'plan', 'emblem',
        'location', 'districts', 'boundary', 'in-tn', 'in-kl'
    ]
    if any(bad in lower for bad in bad_keywords):
        return False
    return True

def clean_wiki_url(url):
    clean = url.split('?')[0].replace('https://thumb.wikimedia.org/', 'https://upload.wikimedia.org/')
    return clean

def search_wikipedia(query):
    url = f"https://en.wikipedia.org/w/api.php?action=query&generator=search&gsrsearch={urllib.parse.quote(query)}&gsrlimit=3&prop=pageimages&piprop=thumbnail|original&pithumbsize=1280&format=json"
    req = urllib.request.Request(url, headers={'User-Agent': 'SafarTravelApp/2.0 (travel@safar.in)'})
    try:
        with urllib.request.urlopen(req, timeout=7) as res:
            data = json.loads(res.read().decode('utf-8'))
            pages = data.get('query', {}).get('pages', {})
            for pid, page in sorted(pages.items(), key=lambda x: x[1].get('index', 99)):
                thumb = page.get('thumbnail', {}).get('source', '')
                title = page.get('title', '')
                if thumb and is_valid_real_photo(thumb):
                    return title, clean_wiki_url(thumb)
    except Exception:
        pass
    return None, None

# Load districts
districts = []
with open('data/districts.csv', 'r', encoding='utf-8') as f:
    for row in csv.DictReader(f):
        districts.append(row)

print(f"Loaded {len(districts)} districts.")

def fetch_for_district(d):
    name = d['name'].strip()
    st_code = d['state_code'].strip()
    hq = d.get('hq_name', '').strip()
    
    # Check if already cached
    cache_key = f"DISTRICT_{st_code}_{name}"
    if cache_key in cache and is_valid_real_photo(cache[cache_key]):
        return cache_key, cache[cache_key], False
        
    # Query 1: "{District} district"
    title, img = search_wikipedia(f"{name} district")
    if not img:
        # Query 2: "{District} tourism"
        title, img = search_wikipedia(f"{name} tourism")
    if not img and hq and hq != name:
        # Query 3: "{Headquarters}"
        title, img = search_wikipedia(f"{hq}")
    if not img:
        # Query 4: "{District}"
        title, img = search_wikipedia(f"{name}")
        
    if img:
        return cache_key, img, True
    return cache_key, None, False

# Run multi-threaded harvest
new_found = 0
with ThreadPoolExecutor(max_workers=12) as executor:
    futures = {executor.submit(fetch_for_district, d): d for d in districts}
    for idx, future in enumerate(as_completed(futures), 1):
        key, img_url, is_new = future.result()
        if img_url:
            cache[key] = img_url
            if is_new:
                new_found += 1
                if new_found % 25 == 0 or new_found == 1:
                    print(f"[{idx}/{len(districts)}] Found: {key} -> {img_url[:65]}...")

print(f"\nHarvest finished! New real district photos found: {new_found}")
print(f"Total cache size: {len(cache)}")

# Save updated cache
with open('data/place_real_photos_cache.json', 'w', encoding='utf-8') as f:
    json.dump(cache, f, indent=2, ensure_ascii=False)

print("Saved data/place_real_photos_cache.json!")
