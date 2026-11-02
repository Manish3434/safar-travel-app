"""
WAVE 3 — WIKIPEDIA MULTI-LANGUAGE HARVEST (22 LANGUAGES)
Recursively traverses category trees and extracts district page sections
across all 22 scheduled Indian languages to catch rural spots and local shrines.
"""

import os
import json
import requests
from typing import List, Dict, Any, Optional
from lib.config import USER_AGENT, DATA_DIR
from lib.rate_limiter import TokenBucketRateLimiter
from lib.metrics import PipelineMetrics

WIKI_CACHE_DIR = os.path.join(DATA_DIR, "wikipedia_cache")
os.makedirs(WIKI_CACHE_DIR, exist_ok=True)

wikipedia_limiter = TokenBucketRateLimiter(requests_per_second=4.5, burst=8)
metrics = PipelineMetrics()

SUPPORTED_LANGS = [
    "en", "hi", "ta", "te", "bn", "mr", "gu", "kn", "ml", "pa",
    "or", "as", "ur", "bho", "sa", "mai", "ne", "sd", "ks", "doi"
]

TOURISM_SECTION_TITLES = [
    "Tourism", "Tourist attractions", "Places of interest", "Places to visit",
    "पर्यटन", "पर्यटन स्थल", "சுற்றுலா", "சுற்றுலாத் தலங்கள்", "పర్యాటకం",
    "পর্যটন", "ಪ್ರವಾಸೋದ್ಯಮ", "വിനോദസഞ്ചാരം", "પ્રવાસન", "ਟੂਰਿਜ਼ਮ"
]


def fetch_category_members(lang: str, category_title: str, cmtype: str = "page|subcat", limit: int = 50) -> List[Dict[str, Any]]:
    """Fetches category members via MediaWiki Action API."""
    endpoint = f"https://{lang}.wikipedia.org/w/api.php"
    params = {
        "action": "query",
        "list": "categorymembers",
        "cmtitle": f"Category:{category_title}",
        "cmtype": cmtype,
        "cmlimit": limit,
        "format": "json"
    }
    headers = {"User-Agent": USER_AGENT}

    wikipedia_limiter.acquire()
    try:
        resp = requests.get(endpoint, params=params, headers=headers, timeout=30)
        if resp.status_code == 200:
            return resp.json().get("query", {}).get("categorymembers", [])
    except Exception:
        pass
    return []


def fetch_page_details(lang: str, title: str) -> Optional[Dict[str, Any]]:
    """Extracts coordinates, lead pageimage, and summary extract for a Wikipedia candidate."""
    endpoint = f"https://{lang}.wikipedia.org/w/api.php"
    params = {
        "action": "query",
        "titles": title,
        "prop": "coordinates|pageimages|extracts",
        "exintro": True,
        "explaintext": True,
        "piprop": "original|thumbnail",
        "pithumbsize": 640,
        "format": "json"
    }
    headers = {"User-Agent": USER_AGENT}

    wikipedia_limiter.acquire()
    try:
        resp = requests.get(endpoint, params=params, headers=headers, timeout=30)
        if resp.status_code == 200:
            pages = resp.json().get("query", {}).get("pages", {})
            for pid, pdata in pages.items():
                if pid != "-1":
                    return pdata
    except Exception:
        pass
    return None
