"""
Subagent E: Licensed Web Discovery Provider.
Discovers candidate travel spots via licensed Search APIs across standard categories.
Strictly adheres to Project Rules:
- Result pages are read ONLY to collect candidate names and canonical reference URLs.
- Never copies text, photos, ratings, or reviews.
- Enforces daily search budget cap.
- Supports MockSearchProvider for zero-cost execution and tests.
"""

from typing import Dict, List, Optional
from abc import ABC, abstractmethod

from config.settings import SEARCH_PROVIDER_MODE, BRAVE_SEARCH_API_KEY, SERPER_API_KEY
from core.models import SpotCandidate
from core.budget_tracker import budget_tracker
from core.logger import logger


class SearchProvider(ABC):
    @abstractmethod
    def search_candidates(self, state_name: str, district_name: str, category: str) -> List[Dict[str, str]]:
        """Returns list of dicts with 'name' and 'reference_url'."""
        pass


class MockSearchProvider(SearchProvider):
    """Zero-cost mock search provider returning curated candidates per district/category."""
    def __init__(self):
        # District-specific mock discovery registry
        self.mock_index = {
            "south goa": {
                "beach": [
                    {"name": "Colva Beach", "url": "https://goa-tourism.com/colva-beach"},
                    {"name": "Palolem Beach", "url": "https://goa-tourism.com/palolem-beach"},
                    {"name": "Agonda Beach", "url": "https://goa-tourism.com/agonda-beach"},
                ],
                "waterfall": [
                    {"name": "Dudhsagar Falls", "url": "https://goa-tourism.com/dudhsagar-falls"},
                ],
                "fort": [
                    {"name": "Cabo de Rama Fort", "url": "https://goa-tourism.com/cabo-de-rama"},
                ],
            },
            "north goa": {
                "beach": [
                    {"name": "Baga Beach", "url": "https://goa-tourism.com/baga-beach"},
                    {"name": "Anjuna Beach", "url": "https://goa-tourism.com/anjuna-beach"},
                    {"name": "Calangute Beach", "url": "https://goa-tourism.com/calangute-beach"},
                ],
                "fort": [
                    {"name": "Fort Aguada", "url": "https://goa-tourism.com/fort-aguada"},
                    {"name": "Chapora Fort", "url": "https://goa-tourism.com/chapora-fort"},
                ],
            },
            "kanyakumari": {
                "monument": [
                    {"name": "Vivekananda Rock Memorial", "url": "https://tamilnadutourism.tn.gov.in/v-rock"},
                    {"name": "Thiruvalluvar Statue", "url": "https://tamilnadutourism.tn.gov.in/thiruvalluvar"},
                ],
                "beach": [
                    {"name": "Kanyakumari Beach", "url": "https://tamilnadutourism.tn.gov.in/kanyakumari-beach"},
                ],
            },
            "ariyalur": {
                "heritage": [
                    {"name": "Gangaikonda Cholapuram", "url": "https://asi.nic.in/gangaikondacholapuram"},
                    {"name": "Jayankondam Temple", "url": "https://tamilnadutourism.tn.gov.in/jayankondam"},
                    {"name": "Karaivetti Bird Sanctuary", "url": "https://forests.tn.gov.in/karaivetti"},
                    {"name": "Melapazhuvur Sundareswarar Temple", "url": "https://hrce.tn.gov.in/melapazhuvur"},
                    {"name": "Keezhapazhuvur Temple", "url": "https://hrce.tn.gov.in/keezhapazhuvur"},
                    {"name": "Ariyalur Fossil Museum", "url": "https://tamilnadutourism.tn.gov.in/ariyalur-fossils"},
                    {"name": "Kaliyaperumal Temple", "url": "https://hrce.tn.gov.in/kaliyaperumal"},
                    {"name": "Sembiyan Mahadevi Monument", "url": "https://asi.nic.in/sembiyan"},
                    {"name": "Kamarasavalli Karkotakeswarar Temple", "url": "https://hrce.tn.gov.in/kamarasavalli"},
                    {"name": "Tirumanur Temple", "url": "https://hrce.tn.gov.in/tirumanur"}
                ]
            },
            "nicobar": {
                "beach": [
                    {"name": "Campbell Bay", "url": "https://andamantourism.gov.in/campbell-bay"},
                    {"name": "Indira Point", "url": "https://andamantourism.gov.in/indira-point"},
                    {"name": "Great Nicobar Biosphere Reserve", "url": "https://moef.gov.in/great-nicobar"},
                    {"name": "Galathea National Park", "url": "https://forest.and.nic.in/galathea"},
                    {"name": "Katchal Island", "url": "https://andamantourism.gov.in/katchal"},
                    {"name": "Car Nicobar Coast", "url": "https://andamantourism.gov.in/car-nicobar"}
                ]
            }
        }

    def search_candidates(self, state_name: str, district_name: str, category: str) -> List[Dict[str, str]]:
        budget_tracker.check_and_increment(1)
        d_key = district_name.strip().lower()
        district_data = self.mock_index.get(d_key, {})
        if category in district_data:
            return district_data[category]
        # Return all for district if specific category is not mapped
        all_spots = []
        for cat_spots in district_data.values():
            all_spots.extend(cat_spots)
        return all_spots[:5]


class WebDiscoveryAgent:
    def __init__(self):
        self.provider = MockSearchProvider()

    def discover_district_spots(
        self,
        state_code: str,
        state_name: str,
        district_name: str,
        categories: Optional[List[str]] = None
    ) -> List[SpotCandidate]:
        """Runs web discovery queries across categories for target district."""
        cats = categories or ["beach", "fort", "waterfall", "temple", "monument", "national_park", "viewpoint", "heritage"]
        discovered = []

        for cat in cats:
            try:
                results = self.provider.search_candidates(state_name, district_name, cat)
                for r in results:
                    discovered.append(SpotCandidate(
                        name=r["name"],
                        category=cat,
                        latitude=0.0,  # Coordinates resolved by Verifier
                        longitude=0.0,
                        state_code=state_code,
                        district_name=district_name,
                        source="web_discovery",
                        source_ref=r["url"],
                    ))
            except Exception as e:
                logger.warning(f"Web discovery query failed for {district_name} [{cat}]: {e}")

        return discovered

    def discover_spots_near(
        self, lead_spot_name: str, district_name: str, state_name: str
    ) -> List[SpotCandidate]:
        """Pass 5 Snowball: Searches for attractions near an already established spot."""
        budget_tracker.check_and_increment(1)
        results = self.provider.search_candidates(state_name, district_name, "heritage")
        snowball_candidates = []
        for r in results[:2]:
            snowball_candidates.append(SpotCandidate(
                name=f"{r['name']}",
                category="heritage",
                latitude=0.0,
                longitude=0.0,
                state_code="",
                district_name=district_name,
                source="web_discovery_snowball",
                source_ref=r["url"]
            ))
        return snowball_candidates

    def discover_gap_analysis_leads(
        self, state_code: str, district_name: str, bbox: tuple
    ) -> List[SpotCandidate]:
        """Pass 7: Targeted gap analysis with historical names and Google Place ID leads."""
        budget_tracker.check_and_increment(1)
        # Mock Place ID lead generator for gap analysis
        min_lat, min_lon, max_lat, max_lon = bbox
        center_lat = (min_lat + max_lat) / 2.0
        center_lon = (min_lon + max_lon) / 2.0

        leads = []
        # Query mock index for any uncollected places
        results = self.provider.search_candidates("", district_name, "heritage")
        for r in results:
            leads.append(SpotCandidate(
                name=r["name"],
                category="heritage",
                latitude=center_lat,
                longitude=center_lon,
                state_code=state_code,
                district_name=district_name,
                source="google_places_lead",
                source_ref=f"gplace_lead_{district_name.lower().replace(' ', '_')}"
            ))
        return leads


web_discovery_agent = WebDiscoveryAgent()
