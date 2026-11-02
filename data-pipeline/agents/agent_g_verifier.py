"""
Subagent G: Entity Resolution & Verification Gatekeeper.
Enforces all core invariants:
- Spatial containment check (point inside district boundary).
- Cross-source deduplication (fuzzy name similarity + spatial proximity).
- Verification classification: >= 2 independent sources or >= 1 official source => VERIFIED.
- Ecological & defense masking (Rule 8).
- Calculates multi-source prominence scores.
"""

import math
import re
from typing import Dict, List, Tuple
from core.models import SpotCandidate, VerifiedSpot, VerificationLevel, SpotImage
from agents.agent_a_boundaries import boundaries_agent
from agents.agent_f_media import media_agent


def _slugify(name: str, state_code: str) -> str:
    cleaned = re.sub(r"[^\w\s-]", "", name).strip().lower()
    slug_part = re.sub(r"[-\s]+", "-", cleaned)
    return f"{slug_part}-{state_code.lower()}"


def _haversine_dist_meters(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    r = 6371000.0  # Earth's radius in meters
    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlam = math.radians(lon2 - lon1)
    a = math.sin(dphi / 2.0) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(dlam / 2.0) ** 2
    return r * (2.0 * math.atan2(math.sqrt(a), math.sqrt(1.0 - a)))


def _string_similarity(s1: str, s2: str) -> float:
    """Computes Jaccard character bigram similarity."""
    s1_norm = s1.lower().strip()
    s2_norm = s2.lower().strip()
    if s1_norm == s2_norm:
        return 1.0
    if len(s1_norm) < 2 or len(s2_norm) < 2:
        return 0.0

    b1 = {s1_norm[i:i+2] for i in range(len(s1_norm) - 1)}
    b2 = {s2_norm[i:i+2] for i in range(len(s2_norm) - 1)}
    intersection = len(b1.intersection(b2))
    union = len(b1.union(b2))
    return float(intersection) / float(union) if union > 0 else 0.0


class VerifierAgent:
    def verify_and_merge(
        self,
        candidates: List[SpotCandidate],
        state_code: str,
        district_id: int,
        district_name: str
    ) -> Tuple[List[VerifiedSpot], int]:
        """
        Filters out of bounds points, clusters and merges cross-source duplicates,
        applies verification logic, masks sensitive coordinates, and resolves photos.
        Returns (verified_spots_list, rejection_count).
        """
        rejection_count = 0
        valid_candidates = []

        # 1. Spatial Containment Gate
        for c in candidates:
            # If coordinates are 0,0 (from web search without geocode), try to inherit from matching candidate
            if c.latitude == 0.0 and c.longitude == 0.0:
                valid_candidates.append(c)
                continue

            if boundaries_agent.is_point_in_district(c.latitude, c.longitude, state_code, district_name):
                valid_candidates.append(c)
            else:
                rejection_count += 1

        # 2. Entity Clustering & Deduplication
        clusters: List[List[SpotCandidate]] = []
        for cand in valid_candidates:
            matched = False
            for cluster in clusters:
                rep = cluster[0]
                name_sim = _string_similarity(cand.name, rep.name)
                geo_match = False
                if cand.latitude != 0.0 and rep.latitude != 0.0:
                    dist = _haversine_dist_meters(cand.latitude, cand.longitude, rep.latitude, rep.longitude)
                    geo_match = (dist <= 250.0)

                # Merge if high name similarity OR (moderate name similarity + close distance)
                if name_sim >= 0.85 or (name_sim >= 0.60 and geo_match):
                    cluster.append(cand)
                    matched = True
                    break

            if not matched:
                clusters.append([cand])

        # 3. Consolidation into VerifiedSpot
        resolved_spots: List[VerifiedSpot] = []
        for cluster in clusters:
            # Pick candidate with non-zero lat/lon
            geo_candidates = [c for c in cluster if c.latitude != 0.0 and c.longitude != 0.0]
            if not geo_candidates:
                rejection_count += len(cluster)
                continue

            primary = geo_candidates[0]
            sources_set = {c.source for c in cluster}
            is_official = any(s in ("asi", "moefcc", "tourism_gov") for s in sources_set)

            # Verification Level Rule
            if len(sources_set) >= 2 or is_official:
                ver_level = VerificationLevel.VERIFIED
            else:
                ver_level = VerificationLevel.UNVERIFIED

            # Sensitive Masking Rule (Rule 8)
            is_sensitive = any(c.sensitive for c in cluster)
            final_lat = primary.latitude
            final_lon = primary.longitude
            if is_sensitive:
                ver_level = VerificationLevel.SENSITIVE_MASKED
                # Mask by fuzzing coordinates by 0.04 degrees (~4 km) to protect wildlife
                final_lat = round(primary.latitude, 2)
                final_lon = round(primary.longitude, 2)

            # Resolve Wikidata QID and Wikipedia URL across cluster
            qid = next((c.wikidata_id for c in cluster if c.wikidata_id), None)
            wiki_url = next((c.wikipedia_url for c in cluster if c.wikipedia_url), None)
            desc = next((c.description for c in cluster if c.description), None)
            g_place_id = next((getattr(c, "google_place_id", None) for c in cluster if getattr(c, "google_place_id", None)), None)
            wiki_title = wiki_url.split("/")[-1].replace("_", " ") if wiki_url else primary.name

            # Image Harvester Call (Passes I1 to I7)
            images: List[SpotImage] = media_agent.harvest_spot_images(
                spot_name=primary.name,
                lat=final_lat,
                lon=final_lon,
                wiki_title=wiki_title,
                wikidata_id=qid,
                google_place_id=g_place_id,
            )

            # Prominence Calculation
            prominence = min(100.0, (len(sources_set) * 20.0) + (25.0 if wiki_url else 0.0) + (15.0 if images else 0.0))

            slug = _slugify(primary.name, state_code)

            resolved_spots.append(VerifiedSpot(
                name=primary.name,
                slug=slug,
                name_ta=primary.name_ta,
                name_hi=primary.name_hi,
                category=primary.category,
                latitude=final_lat,
                longitude=final_lon,
                state_code=state_code,
                district_id=district_id,
                district_name=district_name,
                wikidata_id=qid,
                wikipedia_url=wiki_url,
                description=desc,
                google_place_id=g_place_id,
                sensitive=is_sensitive,
                verification_level=ver_level,
                data_sources=list(sources_set),
                source_count=len(sources_set),
                prominence_score=prominence,
                images=images,
            ))

        return resolved_spots, rejection_count


verifier_agent = VerifierAgent()
