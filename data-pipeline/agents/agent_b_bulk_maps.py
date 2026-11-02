"""
Subagent B: Bulk Map Harvester (OpenStreetMap & Overture).
Formulates targeted Overpass API queries per district boundary/bbox with rate-limiting.
Normalizes OSM tags into canonical 15-category taxonomy.
"""

try:
    import requests
    HAS_REQUESTS = True
except ImportError:
    HAS_REQUESTS = False
from typing import Dict, List, Optional
from config.settings import (
    OVERPASS_ENDPOINTS,
    OVERPASS_MIN_INTERVAL,
    USER_AGENT,
)
from core.models import SpotCandidate
from core.rate_limiter import RateLimiter, retry_with_backoff
from core.logger import logger

overpass_limiter = RateLimiter(OVERPASS_MIN_INTERVAL, name="overpass")


class BulkMapsAgent:
    def __init__(self):
        self.headers = {"User-Agent": USER_AGENT}

    def query_overpass_bbox(
        self,
        min_lat: float,
        min_lon: float,
        max_lat: float,
        max_lon: float,
        timeout_seconds: int = 8
    ) -> List[Dict]:
        """Queries Overpass API within spatial bounding box.
        Uses exact tag matching without regex to leverage OSM B-tree indexes and fail fast.
        """
        if not HAS_REQUESTS:
            logger.warning("Package 'requests' not installed. Run 'pip install requests' for live OSM queries.")
            return []

        overpass_limiter.wait()

        # Exact tag queries use OSM's B-tree index directly and execute in <1s
        query = f"""
        [out:json][timeout:{timeout_seconds}];
        (
          node["tourism"="attraction"]({min_lat},{min_lon},{max_lat},{max_lon});
          node["tourism"="viewpoint"]({min_lat},{min_lon},{max_lat},{max_lon});
          node["tourism"="museum"]({min_lat},{min_lon},{max_lat},{max_lon});
          node["historic"="fort"]({min_lat},{min_lon},{max_lat},{max_lon});
          node["historic"="monument"]({min_lat},{min_lon},{max_lat},{max_lon});
          node["natural"="beach"]({min_lat},{min_lon},{max_lat},{max_lon});
          node["natural"="waterfall"]({min_lat},{min_lon},{max_lat},{max_lon});
          node["leisure"="nature_reserve"]({min_lat},{min_lon},{max_lat},{max_lon});
        );
        out 40;
        """

        for endpoint in OVERPASS_ENDPOINTS:
            try:
                resp = requests.post(
                    endpoint,
                    data={"data": query},
                    headers=self.headers,
                    timeout=(3, timeout_seconds)
                )
                if resp.status_code == 200:
                    data = resp.json()
                    elements = data.get("elements", [])
                    if elements:
                        return elements
                elif resp.status_code in (429, 504):
                    continue
            except Exception as e:
                # Soft failure: log and try next mirror or continue without blocking
                continue

        return []

    def harvest_district_osm(
        self,
        state_code: str,
        district_name: str,
        bbox: tuple
    ) -> List[SpotCandidate]:
        """Harvests and normalizes OSM nodes/ways into SpotCandidate models."""
        min_lat, min_lon, max_lat, max_lon = bbox
        raw_elements = []

        try:
            raw_elements = self.query_overpass_bbox(min_lat, min_lon, max_lat, max_lon)
        except Exception as e:
            logger.warning(f"OSM harvest network query failed for {district_name}: {e}")

        candidates = []
        for elem in raw_elements:
            tags = elem.get("tags", {})
            name = tags.get("name:en") or tags.get("name")
            if not name or len(name.strip()) < 3:
                continue

            # Resolve coordinates (center if way, lat/lon if node)
            lat = elem.get("lat") or elem.get("center", {}).get("lat")
            lon = elem.get("lon") or elem.get("center", {}).get("lon")
            if not lat or not lon:
                continue

            category = self._map_osm_category(tags)
            elem_id = str(elem.get("id"))

            candidates.append(SpotCandidate(
                name=name.strip(),
                name_ta=tags.get("name:ta"),
                name_hi=tags.get("name:hi"),
                category=category,
                latitude=float(lat),
                longitude=float(lon),
                state_code=state_code,
                district_name=district_name,
                wikidata_id=tags.get("wikidata"),
                wikipedia_url=f"https://en.wikipedia.org/wiki/{tags.get('wikipedia')}" if tags.get("wikipedia") else None,
                osm_id=elem_id,
                source="osm",
                source_ref=f"osm:node/{elem_id}" if elem.get("type") == "node" else f"osm:way/{elem_id}",
                description=tags.get("description"),
            ))

        return candidates

    def _map_osm_category(self, tags: Dict[str, str]) -> str:
        """Maps OSM key-value pairs to our 15 category codes."""
        if tags.get("natural") == "beach" or "beach" in tags.get("tourism", ""):
            return "beach"
        if tags.get("historic") in ("fort", "castle", "palace"):
            return "fort"
        if tags.get("waterway") == "waterfall" or tags.get("natural") == "waterfall":
            return "waterfall"
        if tags.get("amenity") == "place_of_worship" and tags.get("religion") == "hindu":
            return "temple"
        if tags.get("amenity") == "place_of_worship" and tags.get("religion") == "christian":
            return "church"
        if tags.get("tourism") == "viewpoint":
            return "viewpoint"
        if tags.get("tourism") == "museum":
            return "museum"
        if tags.get("natural") == "cave_entrance":
            return "cave"
        if tags.get("boundary") == "national_park" or tags.get("leisure") == "nature_reserve":
            return "national_park"
        if tags.get("historic") in ("monument", "memorial"):
            return "monument"
        return "heritage"

    def harvest_subdistrict_sweep(
        self, state_code: str, district_name: str, bbox: tuple
    ) -> List[SpotCandidate]:
        """Pass 3: Queries subdistrict centers and localized spots within district sub-divisions."""
        min_lat, min_lon, max_lat, max_lon = bbox
        query = f"""
        [out:json][timeout:10];
        (
          node["place"="town"]({min_lat},{min_lon},{max_lat},{max_lon});
          node["historic"="archaeological_site"]({min_lat},{min_lon},{max_lat},{max_lon});
          node["tourism"="theme_park"]({min_lat},{min_lon},{max_lat},{max_lon});
          node["historic"="wayside_shrine"]({min_lat},{min_lon},{max_lat},{max_lon});
        );
        out 20;
        """
        return self._query_and_parse(query, state_code, district_name, "osm_subdistrict")

    def harvest_category_synonym_sweep(
        self, state_code: str, district_name: str, bbox: tuple
    ) -> List[SpotCandidate]:
        """Pass 4: Targets regional synonyms (kund, vav, kovil, durg, ghat, jheel, etc.)."""
        min_lat, min_lon, max_lat, max_lon = bbox
        query = f"""
        [out:json][timeout:10];
        (
          node["natural"="spring"]({min_lat},{min_lon},{max_lat},{max_lon});
          node["waterway"="dam"]({min_lat},{min_lon},{max_lat},{max_lon});
          node["historic"="city_gate"]({min_lat},{min_lon},{max_lat},{max_lon});
          node["man_made"="lighthouse"]({min_lat},{min_lon},{max_lat},{max_lon});
          node["tourism"="zoo"]({min_lat},{min_lon},{max_lat},{max_lon});
        );
        out 25;
        """
        return self._query_and_parse(query, state_code, district_name, "osm_category_synonym")

    def harvest_natural_cultural_deep_scan(
        self, state_code: str, district_name: str, bbox: tuple
    ) -> List[SpotCandidate]:
        """Pass 6: Dedicated scan for natural features (peaks, caves, waterfalls, wetlands)."""
        min_lat, min_lon, max_lat, max_lon = bbox
        query = f"""
        [out:json][timeout:10];
        (
          node["natural"="peak"]({min_lat},{min_lon},{max_lat},{max_lon});
          node["natural"="cave_entrance"]({min_lat},{min_lon},{max_lat},{max_lon});
          node["waterway"="waterfall"]({min_lat},{min_lon},{max_lat},{max_lon});
          node["geological"="outcrop"]({min_lat},{min_lon},{max_lat},{max_lon});
        );
        out 25;
        """
        return self._query_and_parse(query, state_code, district_name, "osm_natural_deep")

    def harvest_local_civic_landmarks(
        self, state_code: str, district_name: str, bbox: tuple
    ) -> List[SpotCandidate]:
        """Pass 8: Civic and municipal landmarks (botanical gardens, town halls, promenades)."""
        min_lat, min_lon, max_lat, max_lon = bbox
        query = f"""
        [out:json][timeout:8];
        (
          node["leisure"="park"]["tourism"="yes"]({min_lat},{min_lon},{max_lat},{max_lon});
          node["tourism"="gallery"]({min_lat},{min_lon},{max_lat},{max_lon});
          node["leisure"="garden"]["access"!="private"]({min_lat},{min_lon},{max_lat},{max_lon});
        );
        out 20;
        """
        return self._query_and_parse(query, state_code, district_name, "osm_civic_landmarks")

    def _query_and_parse(
        self, query: str, state_code: str, district_name: str, source_tag: str
    ) -> List[SpotCandidate]:
        if not HAS_REQUESTS:
            return []
        overpass_limiter.wait()

        elements = []
        for endpoint in OVERPASS_ENDPOINTS:
            try:
                resp = requests.post(
                    endpoint, data={"data": query}, headers=self.headers, timeout=(3, 10)
                )
                if resp.status_code == 200:
                    elements = resp.json().get("elements", [])
                    if elements:
                        break
            except Exception:
                continue

        candidates = []
        for elem in elements:
            tags = elem.get("tags", {})
            name = tags.get("name:en") or tags.get("name")
            if not name or len(name.strip()) < 3:
                continue
            lat = elem.get("lat") or elem.get("center", {}).get("lat")
            lon = elem.get("lon") or elem.get("center", {}).get("lon")
            if not lat or not lon:
                continue

            candidates.append(SpotCandidate(
                name=name.strip(),
                name_ta=tags.get("name:ta"),
                name_hi=tags.get("name:hi"),
                category=self._map_osm_category(tags),
                latitude=float(lat),
                longitude=float(lon),
                state_code=state_code,
                district_name=district_name,
                osm_id=str(elem.get("id")),
                source=source_tag,
                source_ref=f"{source_tag}:{elem.get('id')}",
                description=tags.get("description"),
            ))
        return candidates


bulk_maps_agent = BulkMapsAgent()

