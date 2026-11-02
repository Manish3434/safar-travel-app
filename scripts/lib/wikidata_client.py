"""
Wikidata SPARQL and Media Query Client with Disk Caching.
"""

import os
import json
import hashlib
import requests
from typing import Dict, Any, Optional
from lib.config import USER_AGENT, DATA_DIR
from lib.rate_limiter import TokenBucketRateLimiter

WIKIDATA_SPARQL_URL = "https://query.wikidata.org/sparql"
WIKIDATA_CACHE_DIR = os.path.join(DATA_DIR, "wikidata_cache")
os.makedirs(WIKIDATA_CACHE_DIR, exist_ok=True)

# Compliant 5 req/s limiter
wikidata_limiter = TokenBucketRateLimiter(requests_per_second=4.5, burst=8)


def execute_sparql_cached(query: str, cache_name: str) -> Optional[Dict[str, Any]]:
    """Executes a SPARQL query with local disk caching for idempotency and zero duplicate calls."""
    cache_path = os.path.join(WIKIDATA_CACHE_DIR, f"{cache_name}.json")
    if os.path.exists(cache_path):
        try:
            with open(cache_path, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception:
            pass

    headers = {
        "User-Agent": USER_AGENT,
        "Accept": "application/sparql-results+json"
    }

    wikidata_limiter.acquire()
    try:
        resp = requests.get(WIKIDATA_SPARQL_URL, params={"query": query, "format": "json"}, headers=headers, timeout=60)
        if resp.status_code == 200:
            wikidata_limiter.record_success()
            data = resp.json()
            with open(cache_path, "w", encoding="utf-8") as f:
                json.dump(data, f)
            return data
        else:
            return None
    except Exception:
        return None
