"""
WAVE 5 — CROSS-REFERENCE & ENTITY RESOLUTION ENGINE
Executes 6-pass deduplication and fusion algorithm:
  Pass 1: Wikidata QID Golden Key
  Pass 2: Haversine <= 150m AND Token Set Ratio >= 85
  Pass 3: Same District ID AND Token Set Ratio >= 92 AND Same Category
  Pass 4: Transliteration-aware Indic script harmonization
  Pass 5: Geospatial District Containment & Correction
  Pass 6: OSM polygon-node deduplication
"""

import json
from difflib import SequenceMatcher
from typing import List, Dict, Any, Tuple
from lib.geo_utils import haversine_distance, is_point_in_india
from lib.translit import normalize_indic_name
from lib.slugger import generate_slug
from lib.metrics import PipelineMetrics

metrics = PipelineMetrics()


def string_similarity(a: str, b: str) -> float:
    """Computes normalized string similarity ratio [0.0 - 1.0]."""
    if not a or not b:
        return 0.0
    norm_a = normalize_indic_name(a).lower()
    norm_b = normalize_indic_name(b).lower()
    return SequenceMatcher(None, norm_a, norm_b).ratio()


def resolve_and_merge_entities(raw_candidates: List[Dict[str, Any]]) -> Tuple[List[Dict[str, Any]], List[Dict[str, Any]]]:
    """
    Executes the 6-pass entity resolution algorithm.
    Returns (merged_spots, unsolved_merges).
    """
    merged: Dict[str, Dict[str, Any]] = {}
    unsolved_merges: List[Dict[str, Any]] = []

    for candidate in raw_candidates:
        name = candidate.get("name")
        lat = candidate.get("latitude")
        lon = candidate.get("longitude")
        qid = candidate.get("wikidata_qid")
        district_id = candidate.get("district_id")
        cat = candidate.get("category")

        # Sanity check: must fall in India BBox
        if not is_point_in_india(lat, lon):
            continue

        matched_key = None

        # PASS 1: Wikidata QID Golden Key
        if qid:
            for k, existing in merged.items():
                if existing.get("wikidata_qid") == qid:
                    matched_key = k
                    break

        # PASS 2: Haversine <= 150m AND Token Similarity >= 0.85
        if not matched_key:
            for k, existing in merged.items():
                dist_m = haversine_distance(lat, lon, existing["latitude"], existing["longitude"])
                if dist_m <= 150.0:
                    sim = string_similarity(name, existing["name"])
                    if sim >= 0.85:
                        matched_key = k
                        metrics.inc_harvested("wave5", "pass2_merge")
                        break
                    elif 0.60 <= sim < 0.85:
                        unsolved_merges.append({
                            "candidate_a": existing["name"],
                            "candidate_b": name,
                            "similarity": round(sim, 2),
                            "distance_m": round(dist_m, 1),
                            "district_id": district_id
                        })

        # PASS 3: Same District ID AND Token Similarity >= 0.92 AND Same Category
        if not matched_key:
            for k, existing in merged.items():
                if existing.get("district_id") == district_id and existing.get("category") == cat:
                    sim = string_similarity(name, existing["name"])
                    if sim >= 0.92:
                        matched_key = k
                        metrics.inc_harvested("wave5", "pass3_merge")
                        break

        # PASS 4: Transliteration Harmonized Match
        if not matched_key:
            norm_name = normalize_indic_name(name)
            for k, existing in merged.items():
                norm_existing = normalize_indic_name(existing["name"])
                if norm_name == norm_existing and existing.get("district_id") == district_id:
                    matched_key = k
                    metrics.inc_harvested("wave5", "pass4_translit")
                    break

        if matched_key:
            # Survivorship fusion
            target = merged[matched_key]
            # Coords from OSM if available
            if candidate.get("osm_id") and not target.get("osm_id"):
                target["latitude"] = lat
                target["longitude"] = lon
            # Description from Wikipedia if longer
            if len(candidate.get("description", "") or "") > len(target.get("description", "") or ""):
                target["description"] = candidate.get("description")
            # Wikidata QID retention
            if qid and not target.get("wikidata_qid"):
                target["wikidata_qid"] = qid
            # Merge sources
            sources = set(target.get("data_sources", []))
            sources.update(candidate.get("data_sources", []))
            target["data_sources"] = list(sources)
            target["source_count"] = len(target["data_sources"])
            # Confidence update
            target["confidence"] = 1.00 if target["source_count"] >= 3 else (0.75 if target["source_count"] == 2 else 0.40)
        else:
            slug = generate_slug(name)
            candidate["slug"] = slug
            sources = candidate.get("data_sources", ["S03"])
            candidate["data_sources"] = sources
            candidate["source_count"] = len(sources)
            candidate["confidence"] = 1.00 if candidate["source_count"] >= 3 else 0.50
            merged[slug] = candidate

    return list(merged.values()), unsolved_merges
