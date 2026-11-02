"""
Unit tests for Deterministic Sweep Order Generator.
Verifies south_to_north and north_to_south geographic sorting across all 36 states.
"""

import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from config.sweep_order import compute_sweep_order, STATE_CENTROIDS


def test_state_centroids_complete():
    """Verifies that all 36 States and UTs are defined with valid lat/lon."""
    assert len(STATE_CENTROIDS) == 36
    for code, meta in STATE_CENTROIDS.items():
        assert 8.0 <= meta["lat"] <= 38.0, f"Latitude out of India bounds for {code}: {meta['lat']}"
        assert 68.0 <= meta["lon"] <= 98.0, f"Longitude out of India bounds for {code}: {meta['lon']}"


def test_south_to_north_sweep_order():
    """Verifies that south_to_north starts at bottom of India and ends at top."""
    base = Path(__file__).resolve().parent.parent.parent
    d_csv = base / "data" / "districts.csv"
    data = compute_sweep_order(d_csv, direction="south_to_north")

    states = data["states"]
    assert len(states) == 36
    assert data["total_districts"] > 700

    # Southernmost state (lat < 12)
    first_state = states[0]
    assert first_state["centroid_lat"] < 12.0
    assert first_state["state_position"] == 1

    # Northernmost state (lat > 32)
    last_state = states[-1]
    assert last_state["centroid_lat"] > 32.0
    assert last_state["state_position"] == 36


def test_north_to_south_sweep_order():
    """Verifies that north_to_south reverses the sequence properly."""
    base = Path(__file__).resolve().parent.parent.parent
    d_csv = base / "data" / "districts.csv"
    data = compute_sweep_order(d_csv, direction="north_to_south")

    states = data["states"]
    first_state = states[0]
    last_state = states[-1]

    assert first_state["centroid_lat"] > 32.0
    assert last_state["centroid_lat"] < 12.0
