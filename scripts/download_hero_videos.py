import os
import urllib.request
import json

VIDEOS_DIR = os.path.join(os.path.dirname(__file__), '..', 'apps', 'web', 'videos')
os.makedirs(VIDEOS_DIR, exist_ok=True)

# Wikimedia Commons video searches
SEARCHES = {
    'beach': 'ocean waves beach filetype:video',
    'wildlife': 'birds flying filetype:video'
}

HEADERS = {'User-Agent': 'SafarTravelApp/1.0 (https://safar.travel; info@safar.travel)'}

def get_video_url(search_term):
    api_url = f"https://commons.wikimedia.org/w/api.php?action=query&format=json&generator=search&gsrnamespace=6&gsrsearch={urllib.parse.quote(search_term)}&gsrlimit=15&prop=imageinfo&iiprop=url|mime|size"
    req = urllib.request.Request(api_url, headers=HEADERS)
    try:
        with urllib.request.urlopen(req, timeout=15) as res:
            data = json.loads(res.read().decode())
            pages = data.get('query', {}).get('pages', {})
            for page_id, page in pages.items():
                infos = page.get('imageinfo', [])
                for info in infos:
                    url = info.get('url', '')
                    mime = info.get('mime', '')
                    size = info.get('size', 0)
                    if ('video' in mime or url.endswith('.webm') or url.endswith('.mp4') or url.endswith('.ogv')) and size < 25000000:
                        return url, mime
    except Exception as e:
        print(f"Error searching for {search_term}: {e}")
    return None, None

for key, term in SEARCHES.items():
    print(f"Searching for {key} ({term})...")
    url, mime = get_video_url(term)
    if url:
        ext = '.webm' if 'webm' in mime or url.endswith('.webm') else '.mp4'
        out_path = os.path.join(VIDEOS_DIR, f"{key}{ext}")
        print(f"Downloading {key} from {url} to {out_path}...")
        try:
            req = urllib.request.Request(url, headers=HEADERS)
            with urllib.request.urlopen(req, timeout=30) as resp, open(out_path, 'wb') as f:
                f.write(resp.read())
            print(f"Downloaded {key} successfully ({os.path.getsize(out_path)} bytes)")
        except Exception as e:
            print(f"Download failed for {key}: {e}")
    else:
        print(f"No suitable video found for {key}")
