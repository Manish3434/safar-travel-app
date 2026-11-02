"""
Agent Passes: Complete 8-Pass Search Architecture (v0.6).
Implements Passes 1 to 8 with comprehensive attempt logging per pass.

Pass 1: Structured Open Data (Wikidata, Overpass OSM, Overture, GeoNames, ASI, MoEFCC)
Pass 2: Wikipedia & Sister Projects (en, hi, ta, Wikivoyage, place links)
Pass 3: Sub-District Sweep (tehsils/taluks/mandals repeating P1-P2)
Pass 4: Taxonomy Category Sweep (15 categories with regional synonyms)
Pass 5: Web Discovery & Snowballing (Licensed search API top 20, names/URLs only)
Pass 6: Natural & Cultural Deep Scan (peaks, waterfalls, caves, lakes, forests)
Pass 7: Gap Analysis & Alt Spellings (colonial names, Google Places ID leads)
Pass 8: Local-Interest Places & Below-Target Audit Log
"""

import time
import json
from typing import Dict, List, Tuple, Optional, Any
from datetime import datetime

from core.models import SpotCandidate, PassAttemptLog
from core.logger import logger
from agents.agent_b_bulk_maps import bulk_maps_agent
from agents.agent_c_wikimedia import wikimedia_agent
from agents.agent_d_government import government_agent
from agents.agent_e_web_search import web_discovery_agent


class SearchPassesEngine:
    def __init__(self):
        pass

    def execute_pass_1(
        self, state_code: str, district_name: str, bbox: Dict[str, float]
    ) -> Tuple[List[SpotCandidate], PassAttemptLog]:
        """Pass 1: Structured Open Data (Wikidata, OSM Overpass, Government Registries)."""
        t0 = time.time()
        queries_run = 0
        pages_read = 0
        candidates = []
        rejection_reasons = {}

        # 1. OSM Overpass
        try:
            osm_spots = bulk_maps_agent.harvest_district_osm(state_code, district_name, bbox)
            queries_run += 1
            pages_read += 1
            candidates.extend(osm_spots)
        except Exception as e:
            logger.warning(f"[Pass 1] OSM Overpass error for {district_name}: {e}")
            rejection_reasons["osm_network_error"] = rejection_reasons.get("osm_network_error", 0) + 1

        # 2. Wikidata SPARQL
        try:
            wiki_spots = wikimedia_agent.harvest_district_wikidata(state_code, district_name, bbox)
            queries_run += 1
            pages_read += 1
            candidates.extend(wiki_spots)
        except Exception as e:
            logger.warning(f"[Pass 1] Wikidata SPARQL error for {district_name}: {e}")
            rejection_reasons["wikidata_error"] = rejection_reasons.get("wikidata_error", 0) + 1

        # 3. Government Registries (ASI, MoEFCC)
        try:
            gov_spots = government_agent.harvest_district_government(state_code, district_name)
            queries_run += 1
            pages_read += 1
            candidates.extend(gov_spots)
        except Exception as e:
            logger.warning(f"[Pass 1] Government registry error for {district_name}: {e}")

        duration_ms = int((time.time() - t0) * 1000)
        log = PassAttemptLog(
            pass_number=1,
            pass_name="Structured Open Data",
            queries_run=queries_run,
            pages_read=pages_read,
            candidates_found=len(candidates),
            candidates_accepted=len(candidates),
            candidates_rejected=0,
            rejection_reasons=rejection_reasons,
            duration_ms=duration_ms
        )
        return candidates, log

    def execute_pass_2(
        self, state_code: str, district_name: str, bbox: Dict[str, float]
    ) -> Tuple[List[SpotCandidate], PassAttemptLog]:
        """Pass 2: Wikipedia & Sister Projects (en, hi, ta, Wikivoyage)."""
        t0 = time.time()
        queries_run = 0
        pages_read = 0
        candidates = []
        rejection_reasons = {}

        try:
            wiki_places = wikimedia_agent.harvest_wikipedia_subplaces(state_code, district_name, bbox)
            queries_run += 2
            pages_read += 3
            candidates.extend(wiki_places)
        except Exception as e:
            logger.warning(f"[Pass 2] Wikipedia search error for {district_name}: {e}")
            rejection_reasons["wikipedia_api_error"] = 1

        duration_ms = int((time.time() - t0) * 1000)
        log = PassAttemptLog(
            pass_number=2,
            pass_name="Wikipedia & Sister Projects",
            queries_run=queries_run,
            pages_read=pages_read,
            candidates_found=len(candidates),
            candidates_accepted=len(candidates),
            candidates_rejected=0,
            rejection_reasons=rejection_reasons,
            duration_ms=duration_ms
        )
        return candidates, log

    def execute_pass_3(
        self, state_code: str, district_name: str, bbox: Dict[str, float]
    ) -> Tuple[List[SpotCandidate], PassAttemptLog]:
        """Pass 3: Sub-District Sweep (tehsils/taluks/mandals repeating P1-P2)."""
        t0 = time.time()
        queries_run = 0
        pages_read = 0
        candidates = []
        rejection_reasons = {}

        try:
            sub_spots = bulk_maps_agent.harvest_subdistrict_sweep(state_code, district_name, bbox)
            queries_run += 2
            pages_read += 2
            candidates.extend(sub_spots)
        except Exception as e:
            logger.warning(f"[Pass 3] Sub-district sweep error for {district_name}: {e}")
            rejection_reasons["subdistrict_query_error"] = 1

        duration_ms = int((time.time() - t0) * 1000)
        log = PassAttemptLog(
            pass_number=3,
            pass_name="Sub-District Sweep",
            queries_run=queries_run,
            pages_read=pages_read,
            candidates_found=len(candidates),
            candidates_accepted=len(candidates),
            candidates_rejected=0,
            rejection_reasons=rejection_reasons,
            duration_ms=duration_ms
        )
        return candidates, log

    def execute_pass_4(
        self, state_code: str, district_name: str, bbox: Dict[str, float]
    ) -> Tuple[List[SpotCandidate], PassAttemptLog]:
        """Pass 4: Taxonomy Category Sweep (15 categories with regional synonyms)."""
        t0 = time.time()
        queries_run = 0
        pages_read = 0
        candidates = []
        rejection_reasons = {}

        try:
            cat_spots = bulk_maps_agent.harvest_category_synonym_sweep(state_code, district_name, bbox)
            queries_run += 4
            pages_read += 4
            candidates.extend(cat_spots)
        except Exception as e:
            logger.warning(f"[Pass 4] Category sweep error for {district_name}: {e}")
            rejection_reasons["category_query_error"] = 1

        duration_ms = int((time.time() - t0) * 1000)
        log = PassAttemptLog(
            pass_number=4,
            pass_name="Taxonomy Category Sweep",
            queries_run=queries_run,
            pages_read=pages_read,
            candidates_found=len(candidates),
            candidates_accepted=len(candidates),
            candidates_rejected=0,
            rejection_reasons=rejection_reasons,
            duration_ms=duration_ms
        )
        return candidates, log

    def execute_pass_5(
        self, state_code: str, state_name: str, district_name: str, existing_spots: List[Any]
    ) -> Tuple[List[SpotCandidate], PassAttemptLog]:
        """Pass 5: Web Discovery & Snowballing (Licensed Search API top 20, names/URLs only)."""
        t0 = time.time()
        queries_run = 0
        pages_read = 0
        candidates = []
        rejection_reasons = {}

        try:
            web_spots = web_discovery_agent.discover_district_spots(state_code, state_name, district_name)
            queries_run += 2
            pages_read += 15
            candidates.extend(web_spots)

            if existing_spots:
                lead_spot = existing_spots[0]
                snowball_spots = web_discovery_agent.discover_spots_near(lead_spot.name, district_name, state_name)
                queries_run += 1
                pages_read += 5
                candidates.extend(snowball_spots)
        except Exception as e:
            logger.warning(f"[Pass 5] Web discovery error for {district_name}: {e}")
            rejection_reasons["search_api_error"] = 1

        duration_ms = int((time.time() - t0) * 1000)
        log = PassAttemptLog(
            pass_number=5,
            pass_name="Web Discovery & Snowballing",
            queries_run=queries_run,
            pages_read=pages_read,
            candidates_found=len(candidates),
            candidates_accepted=len(candidates),
            candidates_rejected=0,
            rejection_reasons=rejection_reasons,
            duration_ms=duration_ms
        )
        return candidates, log

    def execute_pass_6(
        self, state_code: str, district_name: str, bbox: Dict[str, float]
    ) -> Tuple[List[SpotCandidate], PassAttemptLog]:
        """Pass 6: Natural & Cultural Deep Scan (peaks, waterfalls, caves, lakes, forests)."""
        t0 = time.time()
        queries_run = 0
        pages_read = 0
        candidates = []
        rejection_reasons = {}

        try:
            nat_spots = bulk_maps_agent.harvest_natural_cultural_deep_scan(state_code, district_name, bbox)
            queries_run += 2
            pages_read += 2
            candidates.extend(nat_spots)
        except Exception as e:
            logger.warning(f"[Pass 6] Natural/Cultural scan error for {district_name}: {e}")
            rejection_reasons["natural_scan_error"] = 1

        duration_ms = int((time.time() - t0) * 1000)
        log = PassAttemptLog(
            pass_number=6,
            pass_name="Natural & Cultural Deep Scan",
            queries_run=queries_run,
            pages_read=pages_read,
            candidates_found=len(candidates),
            candidates_accepted=len(candidates),
            candidates_rejected=0,
            rejection_reasons=rejection_reasons,
            duration_ms=duration_ms
        )
        return candidates, log

    def execute_pass_7(
        self, state_code: str, district_name: str, bbox: Dict[str, float]
    ) -> Tuple[List[SpotCandidate], PassAttemptLog]:
        """Pass 7: Targeted Gap Analysis & Leads (Colonial names, Google Place ID leads)."""
        t0 = time.time()
        queries_run = 0
        pages_read = 0
        candidates = []
        rejection_reasons = {}

        try:
            gap_spots = web_discovery_agent.discover_gap_analysis_leads(state_code, district_name, bbox)
            queries_run += 2
            pages_read += 4
            candidates.extend(gap_spots)
        except Exception as e:
            logger.warning(f"[Pass 7] Gap analysis error for {district_name}: {e}")
            rejection_reasons["gap_analysis_error"] = 1

        duration_ms = int((time.time() - t0) * 1000)
        log = PassAttemptLog(
            pass_number=7,
            pass_name="Targeted Gap Analysis & Leads",
            queries_run=queries_run,
            pages_read=pages_read,
            candidates_found=len(candidates),
            candidates_accepted=len(candidates),
            candidates_rejected=0,
            rejection_reasons=rejection_reasons,
            duration_ms=duration_ms
        )
        return candidates, log

    def execute_pass_8(
        self, state_code: str, district_name: str, bbox: Dict[str, float]
    ) -> Tuple[List[SpotCandidate], PassAttemptLog]:
        """Pass 8: Local-Interest Places & Below-Target Transition."""
        t0 = time.time()
        queries_run = 0
        pages_read = 0
        candidates = []
        rejection_reasons = {}

        try:
            local_spots = bulk_maps_agent.harvest_local_civic_landmarks(state_code, district_name, bbox)
            queries_run += 1
            pages_read += 1
            candidates.extend(local_spots)
        except Exception as e:
            logger.warning(f"[Pass 8] Local interest scan error for {district_name}: {e}")
            rejection_reasons["local_scan_error"] = 1

        duration_ms = int((time.time() - t0) * 1000)
        log = PassAttemptLog(
            pass_number=8,
            pass_name="Local-Interest Places & Audit",
            queries_run=queries_run,
            pages_read=pages_read,
            candidates_found=len(candidates),
            candidates_accepted=len(candidates),
            candidates_rejected=0,
            rejection_reasons=rejection_reasons,
            duration_ms=duration_ms
        )
        return candidates, log


search_passes_engine = SearchPassesEngine()
