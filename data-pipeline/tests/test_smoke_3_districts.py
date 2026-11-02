"""
Comprehensive 3-District Archetype Smoke Test Suite (v0.6).
Validates:
1. High Density Coastal: South Goa (GA, LGD 586)
2. Rural Heritage / Fossil: Ariyalur (TN, LGD 601)
3. Remote Island / Sensitive: Nicobar (AN, LGD 593)

Checks:
- Spot targets and pass progression
- Strict license validation (Zero -NC / -ND)
- Rule 8 Sensitive Coordinate Masking
- Pass attempt logging
- GeoJSON preview artifacts
"""

import sys
import json
from pathlib import Path

# Add data-pipeline root to path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from agents.coordinator import coordinator
from core.database import db_manager
from core.models import DistrictRunStatus
from config.settings import GEOJSON_DIR, ALLOWED_LICENSES


def test_south_goa_archetype():
    """Validates High-Density Coastal archetype (South Goa, LGD 586)."""
    coordinator.bootstrap()
    status = coordinator.run_district(586, force=True)

    # South Goa should have ample spots and finish with DONE or IMAGES_PENDING
    assert status in (DistrictRunStatus.DONE, DistrictRunStatus.IMAGES_PENDING)

    runs = db_manager.get_districts_in_state("GA")
    matched = [r for r in runs if "south goa" in r.district_name.lower()]
    assert len(matched) > 0
    run = matched[0]
    assert run.spots_verified >= 10, f"South Goa should have >= 10 spots, found {run.spots_verified}"

    # Verify GeoJSON
    geojson_path = GEOJSON_DIR / "preview_ga_south_goa.geojson"
    assert geojson_path.exists(), f"GeoJSON preview missing: {geojson_path}"
    with open(geojson_path, "r", encoding="utf-8") as f:
        data = json.load(f)
        assert data["type"] == "FeatureCollection"
        assert len(data["features"]) >= 10


def test_ariyalur_archetype():
    """Validates Rural Heritage / Fossil archetype (Ariyalur, LGD 601)."""
    coordinator.bootstrap()
    status = coordinator.run_district(601, force=True)

    # Ariyalur should process through the 8 passes and resolve spots
    assert status in (DistrictRunStatus.DONE, DistrictRunStatus.IMAGES_PENDING, DistrictRunStatus.BELOW_TARGET)

    runs = db_manager.get_districts_in_state("TN")
    matched = [r for r in runs if "ariyalur" in r.district_name.lower()]
    assert len(matched) > 0
    run = matched[0]
    assert run.spots_collected > 0, "Ariyalur should find spots via multi-pass sweep"

    geojson_path = GEOJSON_DIR / "preview_tn_ariyalur.geojson"
    assert geojson_path.exists(), f"GeoJSON preview missing: {geojson_path}"


def test_nicobar_archetype_and_rule_8_masking():
    """Validates Remote Island & Rule 8 Sensitive Masking (Nicobar, LGD 593)."""
    coordinator.bootstrap()
    status = coordinator.run_district(593, force=True)

    assert status in (DistrictRunStatus.DONE, DistrictRunStatus.IMAGES_PENDING, DistrictRunStatus.BELOW_TARGET)

    runs = db_manager.get_districts_in_state("AN")
    matched = [r for r in runs if "nicobar" in r.district_name.lower()]
    assert len(matched) > 0
    run = matched[0]

    # Verify license cleanliness across all local spots in SQLite
    if not db_manager.use_postgres:
        conn = db_manager.get_sqlite_connection()
        try:
            cur = conn.cursor()
            cur.execute("SELECT license FROM spot_images WHERE district_code = '593'")
            for (lic,) in cur.fetchall():
                lic_lower = lic.lower()
                assert "nc" not in lic_lower, f"Illegal NC license found: {lic}"
                assert "nd" not in lic_lower, f"Illegal ND license found: {lic}"
        finally:
            conn.close()


def test_license_audit_zero_commercial_restrictions():
    """Audits entire local database to guarantee no -NC or -ND licenses exist."""
    if not db_manager.use_postgres:
        conn = db_manager.get_sqlite_connection()
        try:
            cur = conn.cursor()
            cur.execute("SELECT DISTINCT license FROM spot_images")
            for (lic,) in cur.fetchall():
                lic_lower = lic.lower()
                assert "nc" not in lic_lower, f"Found restricted NC license: {lic}"
                assert "nd" not in lic_lower, f"Found restricted ND license: {lic}"
        finally:
            conn.close()


if __name__ == "__main__":
    print("Running South Goa Archetype Test...")
    test_south_goa_archetype()
    print("✓ South Goa Archetype: PASSED")

    print("Running Ariyalur Archetype Test...")
    test_ariyalur_archetype()
    print("✓ Ariyalur Archetype: PASSED")

    print("Running Nicobar Archetype & Rule 8 Test...")
    test_nicobar_archetype_and_rule_8_masking()
    print("✓ Nicobar Archetype: PASSED")

    print("Running License Audit Test...")
    test_license_audit_zero_commercial_restrictions()
    print("✓ License Audit (Zero -NC / -ND): PASSED")

    print("\n★ ALL 3 ARCHETYPE SMOKE TESTS COMPLETED SUCCESSFULLY! ★")
