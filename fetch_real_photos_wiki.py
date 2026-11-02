import urllib.request
import urllib.parse
import json
import time
import os
import re
from concurrent.futures import ThreadPoolExecutor, as_completed

CACHE_FILE = 'data/place_real_photos_cache.json'

# Load existing cache if any
cache = {}
if os.path.exists(CACHE_FILE):
    try:
        with open(CACHE_FILE, 'r', encoding='utf-8') as f:
            cache = json.load(f)
        print(f"Loaded {len(cache)} existing photos from {CACHE_FILE}")
    except Exception as e:
        print(f"Error loading cache: {e}")

def clean_query(name):
    # Remove subtitles like "(Mahabalipuram)" or "& Bastion" or "& Tank" or "Pushkarani"
    # Keep the real geographical core name
    cleaned = re.sub(r'\s*\(.*?\)', '', name)
    cleaned = re.sub(r'\s*•.*', '', cleaned)
    # Simplify compound descriptions to prime searchable landmark
    # e.g. "Kovalam Crescent Beach & Lighthouse" -> "Kovalam Beach"
    if 'Kovalam' in cleaned: return 'Kovalam Beach'
    if 'Padmanabhaswamy' in cleaned: return 'Padmanabhaswamy Temple'
    if 'Varkala' in cleaned: return 'Varkala Beach'
    if 'Courtallam' in cleaned or 'Kutralam' in cleaned: return 'Courtallam'
    if 'Brihadisvara' in cleaned: return 'Brihadisvara Temple'
    if 'Meenakshi' in cleaned: return 'Meenakshi Temple'
    if 'Vivekananda Rock' in cleaned: return 'Vivekananda Rock Memorial'
    if 'Thiruvalluvar' in cleaned: return 'Thiruvalluvar Statue'
    if 'Marina Beach' in cleaned: return 'Marina Beach'
    if 'Shore Temple' in cleaned: return 'Shore Temple'
    if 'Doddabetta' in cleaned: return 'Doddabetta'
    if 'Pykara' in cleaned: return 'Pykara Falls'
    if 'Hogenakkal' in cleaned: return 'Hogenakkal Falls'
    if 'Dhanushkodi' in cleaned: return 'Dhanushkodi'
    if 'Pamban' in cleaned: return 'Pamban Bridge'
    if 'Ramanathaswamy' in cleaned or 'Rameswaram Temple' in cleaned: return 'Ramanathaswamy Temple'
    if 'Bekal Fort' in cleaned: return 'Bekal Fort'
    if 'Athirappilly' in cleaned: return 'Athirappilly Falls'
    if 'Silent Valley' in cleaned: return 'Silent Valley National Park'
    if 'Munnar' in cleaned: return 'Munnar'
    if 'Mattupetty' in cleaned: return 'Mattupetty Dam'
    if 'Periyar' in cleaned: return 'Periyar National Park'
    if 'Taj Mahal' in cleaned: return 'Taj Mahal'
    if 'Amer Fort' in cleaned: return 'Amber Fort'
    if 'Hawa Mahal' in cleaned: return 'Hawa Mahal'
    if 'Mehrangarh' in cleaned: return 'Mehrangarh'
    if 'Mysore Palace' in cleaned: return 'Mysore Palace'
    if 'Virupaksha' in cleaned or 'Hampi' in cleaned: return 'Hampi'
    if 'Gateway of India' in cleaned: return 'Gateway of India'
    if 'Marine Drive' in cleaned: return 'Marine Drive, Mumbai'
    if 'Ajanta' in cleaned: return 'Ajanta Caves'
    if 'Ellora' in cleaned: return 'Ellora Caves'
    if 'Qutub Minar' in cleaned: return 'Qutb Minar'
    if 'Red Fort' in cleaned: return 'Red Fort'
    if 'India Gate' in cleaned: return 'India Gate'
    if 'Golden Temple' in cleaned: return 'Golden Temple'
    if 'Victoria Memorial' in cleaned: return 'Victoria Memorial, Kolkata'
    if 'Charminar' in cleaned: return 'Charminar'
    if 'Golconda' in cleaned: return 'Golconda Fort'
    if 'Jagannath' in cleaned or 'Puri' in cleaned and 'Temple' in cleaned: return 'Jagannath Temple, Puri'
    if 'Konark' in cleaned: return 'Konark Sun Temple'
    if 'Kashi Vishwanath' in cleaned: return 'Kashi Vishwanath Temple'
    if 'Dashashwamedh' in cleaned: return 'Dashashwamedh Ghat'
    if 'Dudhsagar' in cleaned: return 'Dudhsagar Falls'
    if 'Calangute' in cleaned: return 'Calangute'
    if 'Fort Aguada' in cleaned: return 'Fort Aguada'
    if 'Basilica of Bom Jesus' in cleaned: return 'Basilica of Bom Jesus'
    
    # Generic strip
    cleaned = re.sub(r'\s+&\s+.*', '', cleaned)
    return cleaned.strip()

def fetch_wiki_photo(name, district_name='', state_name=''):
    if name in cache and cache[name]:
        return name, cache[name]
        
    search_terms = [
        clean_query(name),
        f"{name} {district_name}",
        f"{name} {state_name}",
        name
    ]
    
    for term in search_terms:
        encoded = urllib.parse.quote(term)
        url = f"https://en.wikipedia.org/w/api.php?action=query&generator=search&gsrsearch={encoded}&gsrlimit=3&prop=pageimages&pithumbsize=1200&format=json"
        req = urllib.request.Request(url, headers={'User-Agent': 'SafarTravelApp/1.0 (contact@safar.travel)'})
        try:
            with urllib.request.urlopen(req, timeout=4) as resp:
                data = json.loads(resp.read().decode('utf-8'))
                pages = data.get('query', {}).get('pages', {})
                sorted_pages = sorted(pages.values(), key=lambda x: x.get('index', 99))
                for page in sorted_pages:
                    if 'thumbnail' in page and 'source' in page['thumbnail']:
                        img_url = page['thumbnail']['source']
                        # Exclude icons, maps, or coat of arms if possible
                        if not any(bad in img_url.lower() for bad in ['flag', 'locator', 'map', 'icon', 'seal', 'emblem']):
                            return name, img_url
        except Exception:
            continue
            
    return name, None

# Test on 5 places
sample_spots = [
    ('Five Falls Courtallam', 'Tenkasi', 'Tamil Nadu'),
    ('Kasi Viswanathar Temple Tenkasi', 'Tenkasi', 'Tamil Nadu'),
    ('Gundar Dam', 'Tenkasi', 'Tamil Nadu'),
    ('Karuppanathi Dam', 'Tenkasi', 'Tamil Nadu'),
    ('Thirumalai Kovil Panpoli', 'Tenkasi', 'Tamil Nadu')
]

for s, d, st in sample_spots:
    n, u = fetch_wiki_photo(s, d, st)
    print(f"Sample: '{s}' -> {u}")
