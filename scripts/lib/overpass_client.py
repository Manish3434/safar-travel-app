"""
Robust OpenStreetMap Overpass API Client with Grid Sweeping and Retries.
"""

import time
import requests
from typing import Dict, Any, List, Optional
from lib.config import USER_AGENT
from lib.rate_limiter import TokenBucketRateLimiter

OVERPASS_ENDPOINT = "https://overpass-api.de/api/interpreter"

# Compliant 2 req/s limiter
overpass_limiter = TokenBucketRateLimiter(requests_per_second=1.8, burst=4)


def build_grid_cell_query(south: float, west: float, north: float, east: float, timeout: int = 60) -> str:
    """Builds Overpass QL for all mandatory tourism, historic, leisure, and natural POIs."""
    bbox = f"{south:.4f},{west:.4f},{north:.4f},{east:.4f}"
    return f"""[out:json][timeout:{timeout}];
(
  node["tourism"~"attraction|museum|viewpoint|zoo|theme_park|aquarium|gallery|artwork|wilderness_hut|camp_site|caravan_site"]({bbox});
  way["tourism"~"attraction|museum|viewpoint|zoo|theme_park|aquarium|gallery|artwork|wilderness_hut|camp_site|caravan_site"]({bbox});
  relation["tourism"~"attraction|museum|viewpoint|zoo|theme_park|aquarium|gallery|artwork|wilderness_hut|camp_site|caravan_site"]({bbox});

  node["historic"~"monument|memorial|castle|fort|ruins|archaeological_site|tomb|wayside_cross|wayside_shrine|battleground|city_gate|lighthouse"]({bbox});
  way["historic"~"monument|memorial|castle|fort|ruins|archaeological_site|tomb|wayside_cross|wayside_shrine|battleground|city_gate|lighthouse"]({bbox});

  node["leisure"~"park|nature_reserve|garden"]({bbox});
  way["leisure"~"park|nature_reserve|garden"]({bbox});

  node["natural"~"beach|cave_entrance|hot_spring|geyser|waterfall"]({bbox});
  way["natural"~"beach|cave_entrance|hot_spring|geyser|waterfall"]({bbox});
  node["waterway"="waterfall"]({bbox});
  node["natural"="peak"]["tourism"="yes"]({bbox});
);
out body;
>;
out skel qt;
"""


def execute_overpass_query(query: str, max_retries: int = 5) -> Optional[Dict[str, Any]]:
    """Executes Overpass query with rate limiting and exponential backoff."""
    headers = {
        "User-Agent": USER_AGENT,
        "Accept": "application/json",
        "Content-Type": "application/x-www-form-urlencoded"
    }

    backoff = 2.0
    for attempt in range(1, max_retries + 1):
        overpass_limiter.acquire()
        try:
            resp = requests.post(OVERPASS_ENDPOINT, data={"data": query}, headers=headers, timeout=90)
            if resp.status_code == 200:
                overpass_limiter.record_success()
                return resp.json()
            elif resp.status_code == 429:
                retry_after = int(resp.headers.get("Retry-After", 10))
                overpass_limiter.record_failure(retry_after)
                time.sleep(retry_after)
            elif resp.status_code in (502, 503, 504):
                time.sleep(backoff)
                backoff = min(backoff * 2.0, 60.0)
            else:
                return None
        except Exception:
            time.sleep(backoff)
            backoff = min(backoff * 2.0, 60.0)

    return None
