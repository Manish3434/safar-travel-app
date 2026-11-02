"""
OpenStreetMap Overpass API Client.
Queries tourism and heritage POIs per district with rate limiting and exponential backoff.
"""

import time
import urllib.request
import urllib.parse
import json
from typing import Dict, List, Optional
from config import USER_AGENT, OVERPASS_ENDPOINTS, overpass_limiter


def query_overpass_district(state_name: str, district_name: str, bbox: Optional[tuple] = None, max_retries: int = 4) -> List[Dict]:
    """
    Queries Overpass API for tourist spots in a district.
    Uses bounding box if available, otherwise queries by area name.
    """
    if bbox:
        s, w, n, e = bbox
        area_filter = f"({s},{w},{n},{e})"
        query = f"""
        [out:json][timeout:60];
        (
          node["tourism"~"attraction|museum|viewpoint|gallery|theme_park|zoo"]{area_filter};
          way["tourism"~"attraction|museum|viewpoint|gallery|theme_park|zoo"]{area_filter};
          node["historic"~"fort|monument|castle|ruins|archaeological_site|memorial"]{area_filter};
          way["historic"~"fort|monument|castle|ruins|archaeological_site|memorial"]{area_filter};
          node["leisure"~"park|nature_reserve"]{area_filter};
          way["leisure"~"park|nature_reserve"]{area_filter};
          node["natural"="peak"]["tourism"="yes"]{area_filter};
          node["tourism"="beach"]{area_filter};
        );
        out center 60;
        """
    else:
        query = f"""
        [out:json][timeout:60];
        area["name"="{district_name}"]["boundary"="administrative"]->.a;
        (
          node["tourism"~"attraction|museum|viewpoint|gallery|theme_park|zoo"](area.a);
          way["tourism"~"attraction|museum|viewpoint|gallery|theme_park|zoo"](area.a);
          node["historic"~"fort|monument|castle|ruins|archaeological_site|memorial"](area.a);
          way["historic"~"fort|monument|castle|ruins|archaeological_site|memorial"](area.a);
          node["leisure"~"park|nature_reserve"](area.a);
          way["leisure"~"park|nature_reserve"](area.a);
        );
        out center 60;
        """

    data = urllib.parse.urlencode({"data": query}).encode("utf-8")
    headers = {
        "User-Agent": USER_AGENT,
        "Accept": "application/json",
        "Content-Type": "application/x-www-form-urlencoded",
    }

    last_error = None
    for attempt in range(max_retries):
        for endpoint in OVERPASS_ENDPOINTS:
            overpass_limiter.wait()
            try:
                req = urllib.request.Request(endpoint, data=data, headers=headers)
                with urllib.request.urlopen(req, timeout=45) as resp:
                    if resp.status == 200:
                        body = json.loads(resp.read().decode("utf-8"))
                        return _parse_overpass_elements(body.get("elements", []))
            except urllib.error.HTTPError as e:
                last_error = e
                if e.code in (429, 502, 503, 504):
                    backoff = 2 ** (attempt + 1)
                    time.sleep(backoff)
                    continue
                break
            except Exception as e:
                last_error = e
                time.sleep(2)
                continue

    print(f"Warning: Overpass query failed for {district_name} after retries: {last_error}")
    return []


def _parse_overpass_elements(elements: List[Dict]) -> List[Dict]:
    """Parses raw Overpass JSON elements into structured tourist spot records."""
    spots = []
    seen_names = set()

    for el in elements:
        tags = el.get("tags", {})
        name = tags.get("name") or tags.get("name:en")
        if not name or name.strip() in seen_names:
            continue

        # Get coordinates (center for ways/relations, lat/lon for nodes)
        lat = el.get("lat") or el.get("center", {}).get("lat")
        lon = el.get("lon") or el.get("center", {}).get("lon")
        if lat is None or lon is None:
            continue

        category = _infer_category(tags)
        wikidata_id = tags.get("wikidata", "").strip()
        wikipedia_tag = tags.get("wikipedia", "").strip()

        seen_names.add(name.strip())
        spots.append({
            "spot_name": name.strip(),
            "category": category,
            "latitude": round(lat, 6),
            "longitude": round(lon, 6),
            "wikidata_id": wikidata_id,
            "wikipedia_url": _normalize_wikipedia_url(wikipedia_tag),
            "osm_id": el.get("id"),
        })

    return spots


def _infer_category(tags: Dict[str, str]) -> str:
    """Classifies the primary tourism category."""
    if "historic" in tags:
        val = tags["historic"]
        if val in ("fort", "castle"):
            return "fort"
        if val in ("monument", "memorial"):
            return "monument"
        return "heritage"
    if "tourism" in tags:
        val = tags["tourism"]
        if val in ("viewpoint", "museum", "gallery", "theme_park", "zoo", "attraction", "beach"):
            return val
    if "leisure" in tags:
        return "park"
    if tags.get("natural") == "peak":
        return "peak"
    return "attraction"


def _normalize_wikipedia_url(wikipedia_tag: str) -> str:
    """Converts OSM wikipedia tag (e.g. 'en:Fort Aguada') into a full URL."""
    if not wikipedia_tag:
        return ""
    if wikipedia_tag.startswith("http"):
        return wikipedia_tag
    if ":" in wikipedia_tag:
        lang, title = wikipedia_tag.split(":", 1)
        safe_title = urllib.parse.quote(title.replace(" ", "_"))
        return f"https://{lang}.wikipedia.org/wiki/{safe_title}"
    safe_title = urllib.parse.quote(wikipedia_tag.replace(" ", "_"))
    return f"https://en.wikipedia.org/wiki/{safe_title}"
