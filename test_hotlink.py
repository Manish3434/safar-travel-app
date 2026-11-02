import urllib.request

test_urls = [
    'https://thumb.wikimedia.org/wikipedia/commons/thumb/d/dd/Brihadisvara_Temple_during_Maha_Shivaratri-WUS03611_%28edit%29.jpg/1280px-Brihadisvara_Temple_during_Maha_Shivaratri-WUS03611_%28edit%29.jpg?utm_source=en.wikipedia.org&utm_campaign=api&utm_content=thumbnail',
    'https://upload.wikimedia.org/wikipedia/commons/d/d7/Morning_at_Ponmudi.jpg?utm_source=en.wikipedia.org&utm_campaign=api&utm_content=thumbnail_unscaled',
    'https://thumb.wikimedia.org/wikipedia/commons/thumb/f/f5/Courtallam.jpg/1280px-Courtallam.jpg?utm_source=en.wikipedia.org&utm_campaign=api&utm_content=thumbnail'
]

for url in test_urls:
    # Standard browser headers (no custom app user agent)
    req = urllib.request.Request(url, headers={
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Referer': 'http://localhost:8080/'
    })
    try:
        with urllib.request.urlopen(req, timeout=5) as resp:
            print(f"Status for {url[:50]}...: {resp.status}, length: {len(resp.read())}")
    except Exception as e:
        print(f"FAILED for {url[:50]}...: {e}")
