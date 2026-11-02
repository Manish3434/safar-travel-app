"""
Unit tests for Verifier & Entity Resolution Subagent G.
Tests multi-source verification rule, deduplication clustering, and sensitive spot masking.
"""

import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from core.models import SpotCandidate, VerificationLevel
from agents.agent_g_verifier import verifier_agent, _string_similarity, _haversine_dist_meters


def test_string_similarity():
    """Verifies fuzzy string comparison."""
    assert _string_similarity("Baga Beach", "Baga Beach") == 1.0
    assert _string_similarity("Baga Beach", "Baga Beach North Goa") > 0.60
    assert _string_similarity("Dudhsagar Falls", "Mysore Palace") == 0.0


def test_haversine_distance():
    """Verifies accurate metric distance between coordinates."""
    # Panaji to Margao ~28 km
    dist = _haversine_dist_meters(15.4909, 73.8278, 15.2736, 73.9582)
    assert 25000 < dist < 35000


def test_verification_rule_multi_source():
    """Verifies that 2 independent sources yield VERIFIED status."""
    cand1 = SpotCandidate(
        name="Fort Aguada",
        category="fort",
        latitude=15.4925,
        longitude=73.7736,
        state_code="GA",
        district_name="North Goa",
        source="osm",
        source_ref="osm:node/123",
    )
    cand2 = SpotCandidate(
        name="Aguada Fort",
        category="fort",
        latitude=15.4927,
        longitude=73.7738,
        state_code="GA",
        district_name="North Goa",
        source="wikidata",
        source_ref="wikidata:Q3534015",
    )

    spots, rejected = verifier_agent.verify_and_merge([cand1, cand2], "GA", 172, "North Goa")
    assert len(spots) == 1
    spot = spots[0]
    assert spot.verification_level == VerificationLevel.VERIFIED
    assert spot.source_count == 2
    assert "osm" in spot.data_sources
    assert "wikidata" in spot.data_sources


def test_verification_rule_single_source():
    """Verifies that single non-official source yields UNVERIFIED status."""
    cand = SpotCandidate(
        name="Random Unknown Hilltop",
        category="viewpoint",
        latitude=15.40,
        longitude=73.80,
        state_code="GA",
        district_name="North Goa",
        source="osm",
        source_ref="osm:node/999",
    )
    spots, rejected = verifier_agent.verify_and_merge([cand], "GA", 172, "North Goa")
    assert len(spots) == 1
    assert spots[0].verification_level == VerificationLevel.UNVERIFIED


def test_sensitive_spot_coordinate_masking():
    """Verifies that sensitive spots get masked coordinates (Rule 8)."""
    cand = SpotCandidate(
        name="Protected Sanctuary Core",
        category="national_park",
        latitude=15.344444,
        longitude=74.255555,
        state_code="GA",
        district_name="South Goa",
        source="moefcc",
        source_ref="MOEFCC:01",
        sensitive=True,
    )
    spots, rejected = verifier_agent.verify_and_merge([cand], "GA", 173, "South Goa")
    assert len(spots) == 1
    spot = spots[0]
    assert spot.verification_level == VerificationLevel.SENSITIVE_MASKED
    # Coordinates rounded / masked to 2 decimal places
    assert spot.latitude == 15.34
    assert spot.longitude == 74.26
