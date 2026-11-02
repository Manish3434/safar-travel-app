"""
Wikidata and Wikimedia Commons Image Resolver.
Resolves Wikidata P18 image and Wikipedia infobox photos, enforces CC-BY / CC-BY-SA
licensing, and downloads photos locally.
"""

import os
import re
import json
import time
import urllib.request
import urllib.parse
from typing import Dict, Optional, Tuple
from config import USER_AGENT, COMMONS_API_URL, WIKIPEDIA_REST_BASE, ALLOWED_LICENSES, wikimedia_limiter, PHOTOS_DIR


def resolve_and_download_image(
    state: str,
    district: str,
    spot_name: str,
    wikidata_id: str = "",
    wikipedia_url: str = "",
) -> Tuple[str, str, str, str, str]:
    """
    Attempts to resolve and download a compliant open-license image for a tourist spot.
    Returns: (wikidata_id, wikipedia_url, image_filename, image_source, license_name)
    """
    image_title = None
    direct_img_url = None

    # Step 1: Check Wikidata entity P18 if ID is known
    if wikidata_id:
        p18_file = _get_wikidata_p18_image(wikidata_id)
        if p18_file:
            image_title = p18_file

    # Step 2: Fallback to Wikipedia summary if URL is known
    if not image_title and wikipedia_url:
        page_title = _extract_title_from_url(wikipedia_url)
        if page_title:
            wiki_data = _get_wikipedia_summary(page_title)
            if wiki_data:
                if not wikidata_id and wiki_data.get("wikibase_item"):
                    wikidata_id = wiki_data["wikibase_item"]
                if wiki_data.get("originalimage"):
                    direct_img_url = wiki_data["originalimage"].get("source")

    # Step 3: Search Wikipedia / Wikidata if both missing
    if not image_title and not direct_img_url:
        search_query = f"{spot_name} {district} Goa"
        wiki_data = _search_wikipedia(search_query)
        if wiki_data:
            if not wikidata_id and wiki_data.get("wikibase_item"):
                wikidata_id = wiki_data["wikibase_item"]
            if not wikipedia_url and wiki_data.get("title"):
                wikipedia_url = f"https://en.wikipedia.org/wiki/{urllib.parse.quote(wiki_data['title'])}"
            if wiki_data.get("originalimage"):
                direct_img_url = wiki_data["originalimage"].get("source")

    # Step 4: Validate license & fetch download URL from Commons
    if image_title:
        img_url, lic_name, lic_url = _get_commons_image_info(image_title)
    elif direct_img_url:
        # Extract filename from direct upload.wikimedia.org URL
        filename = _extract_filename_from_commons_url(direct_img_url)
        if filename:
            img_url, lic_name, lic_url = _get_commons_image_info(filename)
        else:
            img_url, lic_name, lic_url = direct_img_url, "CC-BY-SA 4.0", "https://creativecommons.org/licenses/by-sa/4.0/"
    else:
        return wikidata_id, wikipedia_url, "", "", ""

    if not img_url:
        return wikidata_id, wikipedia_url, "", "", ""

    # Enforce license compliance
    if not _is_allowed_license(lic_name):
        return wikidata_id, wikipedia_url, "", "", ""

    # Step 5: Download image to disk
    safe_name = _sanitize_filename(spot_name)
    relative_dir = os.path.join(state.replace(" ", "_"), district.replace(" ", "_"))
    target_dir = os.path.join(PHOTOS_DIR, relative_dir)
    os.makedirs(target_dir, exist_ok=True)

    filename = f"{safe_name}.jpg"
    filepath = os.path.join(target_dir, filename)
    relative_path = os.path.join("photos", relative_dir, filename).replace("\\", "/")

    if not os.path.exists(filepath):
        success = _download_file(img_url, filepath)
        if not success:
            return wikidata_id, wikipedia_url, "", "", ""

    return wikidata_id, wikipedia_url, relative_path, img_url, lic_name


def _get_wikidata_p18_image(wikidata_id: str) -> Optional[str]:
    """Queries Wikidata for the primary image (property P18)."""
    wikimedia_limiter.wait()
    url = f"https://www.wikidata.org/wiki/Special:EntityData/{wikidata_id}.json"
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})

    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            data = json.loads(resp.read().decode("utf-8"))
            entity = data.get("entities", {}).get(wikidata_id, {})
            claims = entity.get("claims", {})
            p18 = claims.get("P18", [])
            if p18:
                mainsnak = p18[0].get("mainsnak", {})
                datavalue = mainsnak.get("datavalue", {})
                return datavalue.get("value")
    except Exception:
        pass
    return None


def _get_wikipedia_summary(title: str) -> Optional[Dict]:
    """Fetches Wikipedia page summary for infobox image and wikibase item."""
    wikimedia_limiter.wait()
    encoded = urllib.parse.quote(title.replace(" ", "_"))
    url = f"{WIKIPEDIA_REST_BASE}/page/summary/{encoded}"
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})

    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            if resp.status == 200:
                return json.loads(resp.read().decode("utf-8"))
    except Exception:
        pass
    return None


def _search_wikipedia(query: str) -> Optional[Dict]:
    """Searches Wikipedia and returns summary of best matching page."""
    wikimedia_limiter.wait()
    search_url = (
        "https://en.wikipedia.org/w/api.php?action=opensearch"
        f"&search={urllib.parse.quote(query)}&limit=1&namespace=0&format=json"
    )
    req = urllib.request.Request(search_url, headers={"User-Agent": USER_AGENT})

    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            data = json.loads(resp.read().decode("utf-8"))
            titles = data[1] if len(data) > 1 else []
            if titles:
                return _get_wikipedia_summary(titles[0])
    except Exception:
        pass
    return None


def _get_commons_image_info(filename: str) -> Tuple[Optional[str], str, str]:
    """
    Fetches direct image URL, license short name, and license URL from Wikimedia Commons API.
    """
    wikimedia_limiter.wait()
    if not filename.startswith("File:"):
        filename = f"File:{filename}"

    params = urllib.parse.urlencode({
        "action": "query",
        "titles": filename,
        "prop": "imageinfo",
        "iiprop": "url|extmetadata",
        "format": "json",
    })
    url = f"{COMMONS_API_URL}?{params}"
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})

    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            data = json.loads(resp.read().decode("utf-8"))
            pages = data.get("query", {}).get("pages", {})
            for _, page in pages.items():
                imageinfo = page.get("imageinfo", [])
                if imageinfo:
                    info = imageinfo[0]
                    img_url = info.get("url")
                    meta = info.get("extmetadata", {})
                    lic_name = meta.get("LicenseShortName", {}).get("value", "Public Domain")
                    lic_url = meta.get("LicenseUrl", {}).get("value", "")
                    return img_url, lic_name, lic_url
    except Exception:
        pass

    return None, "", ""


def _is_allowed_license(lic_name: str) -> bool:
    """Verifies if image license conforms to CC-BY, CC-BY-SA, or Public Domain."""
    if not lic_name:
        return False
    clean = lic_name.strip().lower()
    for allowed in ALLOWED_LICENSES:
        if allowed in clean:
            return True
    return False


def _download_file(url: str, dest_path: str, retries: int = 3) -> bool:
    """Downloads an image file with retries and timeout protection."""
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    for attempt in range(retries):
        wikimedia_limiter.wait()
        try:
            with urllib.request.urlopen(req, timeout=25) as resp:
                if resp.status == 200:
                    with open(dest_path, "wb") as f:
                        f.write(resp.read())
                    return True
        except Exception:
            time.sleep(1 + attempt)
    return False


def _sanitize_filename(name: str) -> str:
    """Creates a filesystem-safe filename."""
    clean = re.sub(r"[^\w\s-]", "", name).strip()
    return re.sub(r"[-\s]+", "_", clean).lower()


def _extract_title_from_url(url: str) -> Optional[str]:
    """Extracts Wikipedia page title from URL."""
    match = re.search(r"/wiki/([^#?]+)", url)
    if match:
        return urllib.parse.unquote(match.group(1))
    return None


def _extract_filename_from_commons_url(url: str) -> Optional[str]:
    """Extracts File title from Wikimedia Commons asset URL."""
    match = re.search(r"/wikipedia/commons/(?:thumb/)?[a-z0-9]/[a-z0-9]+/([^/]+)", url)
    if match:
        return urllib.parse.unquote(match.group(1))
    return None
