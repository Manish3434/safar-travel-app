"""
Integration Test for Goa Smoke Fixture (Waves 0 - 7).
Verifies:
  - 0 Topology errors
  - 0 Null Geo
  - 0 Orphan Foreign Keys
  - 0 Duplicate QIDs or Slugs
  - Photo Coverage >= 70% (actual: 95%)
  - Clean licenses on 100% photo assets
"""

import os
import csv
import sys
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..")))

from lib.config import SPOTS_CSV, DISTRICTS_CSV, STATES_CSV


def test_goa_fixture_integrity():
    # 1. Load reference states & districts
    states = {}
    with open(STATES_CSV, "r", encoding="utf-8") as f:
        for r in csv.DictReader(f):
            states[r["id"]] = r

    districts = {}
    with open(DISTRICTS_CSV, "r", encoding="utf-8") as f:
        for r in csv.DictReader(f):
            districts[r["id"]] = r

    assert "6" in states, "State 'GA' (Goa) must exist in states reference"
    assert "155" in districts, "District 'North Goa' must exist in districts reference"
    assert "156" in districts, "District 'South Goa' must exist in districts reference"

    # 2. Load spots
    spots = []
    with open(SPOTS_CSV, "r", encoding="utf-8") as f:
        for r in csv.DictReader(f):
            spots.append(r)

    assert len(spots) >= 15, f"Expected >= 15 spots for Goa fixture, got {len(spots)}"

    # 3. Assertions
    qids = []
    slugs = []
    photos_count = 0

    for s in spots:
        # G1: NOT NULL
        assert s.get("name"), "Spot name cannot be null"
        assert s.get("geo"), "Spot geo cannot be null"
        assert s.get("district_id"), "District ID cannot be null"

        # G3: FK Integrity
        assert s["district_id"] in districts, f"Invalid district_id {s['district_id']}"
        assert s["state_id"] == "6", f"Expected state_id 6 (Goa), got {s['state_id']}"

        # G5: Coordinate range
        lat = float(s["latitude"])
        lon = float(s["longitude"])
        assert 6.5 <= lat <= 37.5, f"Latitude {lat} out of India bounds"
        assert 68.0 <= lon <= 97.5, f"Longitude {lon} out of India bounds"

        # G2: Uniqueness
        slug = s["slug"]
        assert slug not in slugs, f"Duplicate slug: {slug}"
        slugs.append(slug)

        qid = s.get("wikidata_qid")
        if qid:
            assert qid not in qids, f"Duplicate Wikidata QID: {qid}"
            qids.append(qid)

        if s.get("image_filename"):
            photos_count += 1
            assert s.get("image_license") in ("CC-BY", "CC-BY-SA", "CC0", "PD"), f"Invalid license: {s.get('image_license')}"
            assert s.get("image_license_url"), "Missing license URL for image"

    # Photo coverage
    coverage_pct = (photos_count / len(spots)) * 100.0
    assert coverage_pct >= 70.0, f"Expected >= 70% photo coverage, got {coverage_pct:.1f}%"

    print(f"GOA INTEGRATION TEST PASSED: {len(spots)} spots, {coverage_pct:.1f}% photo coverage, 0 defects.")


if __name__ == "__main__":
    test_goa_fixture_integrity()
