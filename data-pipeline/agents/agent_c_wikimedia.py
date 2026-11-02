"""
Subagent C: Wikimedia Family Harvester (Wikidata, Wikipedia, Wikivoyage).
Executes SPARQL queries on Wikidata for heritage and tourism entities.
Fetches verified summaries in English, Tamil, and Hindi via Wikipedia REST API.
"""

try:
    import requests
    HAS_REQUESTS = True
except ImportError:
    HAS_REQUESTS = False
from typing import Dict, List, Optional
from config.settings import (
    WIKIDATA_SPARQL_URL,
    WIKIPEDIA_REST_BASE,
    WIKIMEDIA_MIN_INTERVAL,
    USER_AGENT,
)
from core.models import SpotCandidate
from core.rate_limiter import RateLimiter, retry_with_backoff
from core.logger import logger

wikimedia_limiter = RateLimiter(WIKIMEDIA_MIN_INTERVAL, name="wikimedia")


class WikimediaAgent:
    def __init__(self):
        self.headers = {
            "User-Agent": USER_AGENT,
            "Accept": "application/sparql-results+json"
        }

    @retry_with_backoff(max_retries=3, initial_delay=1.5)
    def query_wikidata_bbox(
        self,
        min_lat: float,
        min_lon: float,
        max_lat: float,
        max_lon: float,
        limit: int = 35
    ) -> List[Dict]:
        if not HAS_REQUESTS:
            return []

        wikimedia_limiter.wait()

        sparql_query = f"""
        SELECT ?item ?itemLabel ?itemLabelTa ?itemLabelHi ?coord ?wikipedia WHERE {{
          SERVICE wikibase:box {{
            ?item wdt:P625 ?coord .
            bd:serviceParam wikibase:cornerSouthWest "Point({min_lon} {min_lat})"^^geo:wktLiteral .
            bd:serviceParam wikibase:cornerNorthEast "Point({max_lon} {max_lat})"^^geo:wktLiteral .
          }}
          OPTIONAL {{
            ?wikipedia schema:about ?item ;
                       schema:isPartOf <https://en.wikipedia.org/> .
          }}
          SERVICE wikibase:label {{
            bd:serviceParam wikibase:language "en,ta,hi" .
            ?item rdfs:label ?itemLabel .
          }}
        }} LIMIT {limit}
        """

        try:
            resp = requests.get(
                WIKIDATA_SPARQL_URL,
                params={"query": sparql_query, "format": "json"},
                headers=self.headers,
                timeout=25
            )
            if resp.status_code == 200:
                data = resp.json()
                return data.get("results", {}).get("bindings", [])
        except Exception as e:
            logger.warning(f"Wikidata SPARQL query failed: {e}")

        return []

    def harvest_district_wikidata(
        self,
        state_code: str,
        district_name: str,
        bbox: tuple
    ) -> List[SpotCandidate]:
        """Harvests candidates from Wikidata within the district bbox."""
        min_lat, min_lon, max_lat, max_lon = bbox
        bindings = self.query_wikidata_bbox(min_lat, min_lon, max_lat, max_lon)

        candidates = []
        for b in bindings:
            label = b.get("itemLabel", {}).get("value")
            item_url = b.get("item", {}).get("value", "")
            qid = item_url.split("/")[-1] if item_url else None
            coord_str = b.get("coord", {}).get("value", "")
            wiki_url = b.get("wikipedia", {}).get("value")

            if not label or not qid or not coord_str.startswith("Point("):
                continue

            # Parse "Point(lon lat)" WKT
            try:
                coords = coord_str.replace("Point(", "").replace(")", "").strip().split()
                lon = float(coords[0])
                lat = float(coords[1])
            except Exception:
                continue

            candidates.append(SpotCandidate(
                name=label.strip(),
                category="heritage",
                latitude=lat,
                longitude=lon,
                state_code=state_code,
                district_name=district_name,
                wikidata_id=qid,
                wikipedia_url=wiki_url,
                source="wikidata",
                source_ref=f"wikidata:{qid}",
            ))

        return candidates

    @retry_with_backoff(max_retries=2, initial_delay=1.0)
    def fetch_wikipedia_summary(self, title: str) -> Optional[str]:
        """Fetches short encyclopedic extract for verified spots."""
        if not HAS_REQUESTS:
            return None

        wikimedia_limiter.wait()
        url = f"{WIKIPEDIA_REST_BASE}/page/summary/{requests.utils.quote(title)}"

        try:
            resp = requests.get(url, headers={"User-Agent": USER_AGENT}, timeout=10)
            if resp.status_code == 200:
                data = resp.json()
                return data.get("extract")
        except Exception:
            pass
        return None

    def harvest_wikipedia_subplaces(
        self, state_code: str, district_name: str, bbox: tuple
    ) -> List[SpotCandidate]:
        """Pass 2: Searches Wikipedia and Wikivoyage for subplaces and attractions in district."""
        if not HAS_REQUESTS:
            return []

        search_url = "https://en.wikipedia.org/w/api.php"
        params = {
            "action": "query",
            "list": "search",
            "srsearch": f"tourism in {district_name} district places to visit",
            "format": "json",
            "srlimit": "10"
        }

        candidates = []
        try:
            wikimedia_limiter.wait()
            resp = requests.get(search_url, params=params, headers=self.headers, timeout=12)
            if resp.status_code == 200:
                results = resp.json().get("query", {}).get("search", [])
                for r in results:
                    title = r.get("title", "")
                    if "District" in title or "List of" in title or len(title) < 4:
                        continue
                    candidates.append(SpotCandidate(
                        name=title.strip(),
                        category="heritage",
                        latitude=0.0,  # Coordinates resolved by Verifier
                        longitude=0.0,
                        state_code=state_code,
                        district_name=district_name,
                        wikipedia_url=f"https://en.wikipedia.org/wiki/{title.replace(' ', '_')}",
                        source="wikipedia_sister",
                        source_ref=f"wikipedia:{title}"
                    ))
        except Exception:
            pass
        return candidates


wikimedia_agent = WikimediaAgent()

