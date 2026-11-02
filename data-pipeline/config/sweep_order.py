"""
Deterministic Sweep Order Generator.
Numbers states 1..N and their districts 1..M based on geographic centroid latitude.
Setting: south_to_north (default, start at bottom of India) or north_to_south.
Emits config/sweep_order.yaml for audit and review.
"""

import os
import csv
import json
from pathlib import Path
from typing import Dict, List, Any

try:
    import yaml
    HAS_YAML = True
except ImportError:
    HAS_YAML = False

# Canonical approximate centroids for India's 36 States and UTs (derived from Survey of India bounds)
STATE_CENTROIDS: Dict[str, Dict[str, Any]] = {
    "KL": {"name": "Kerala", "lat": 10.8505, "lon": 76.2711, "type": "State"},
    "TN": {"name": "Tamil Nadu", "lat": 11.1271, "lon": 78.6569, "type": "State"},
    "LD": {"name": "Lakshadweep", "lat": 10.5667, "lon": 72.6417, "type": "UT"},
    "AN": {"name": "Andaman and Nicobar Islands", "lat": 11.7401, "lon": 92.6586, "type": "UT"},
    "PY": {"name": "Puducherry", "lat": 11.9416, "lon": 79.8083, "type": "UT"},
    "KA": {"name": "Karnataka", "lat": 15.3173, "lon": 75.7139, "type": "State"},
    "GA": {"name": "Goa", "lat": 15.2993, "lon": 74.1240, "type": "State"},
    "AP": {"name": "Andhra Pradesh", "lat": 15.9129, "lon": 79.7400, "type": "State"},
    "TG": {"name": "Telangana", "lat": 18.1124, "lon": 79.0193, "type": "State"},
    "MH": {"name": "Maharashtra", "lat": 19.7515, "lon": 75.7139, "type": "State"},
    "DN": {"name": "Dadra and Nagar Haveli and Daman and Diu", "lat": 20.4283, "lon": 72.8397, "type": "UT"},
    "OD": {"name": "Odisha", "lat": 20.9517, "lon": 85.0985, "type": "State"},
    "CG": {"name": "Chhattisgarh", "lat": 21.2787, "lon": 81.8661, "type": "State"},
    "GJ": {"name": "Gujarat", "lat": 22.2587, "lon": 71.1924, "type": "State"},
    "WB": {"name": "West Bengal", "lat": 22.9868, "lon": 87.8550, "type": "State"},
    "MP": {"name": "Madhya Pradesh", "lat": 22.9734, "lon": 78.6569, "type": "State"},
    "JH": {"name": "Jharkhand", "lat": 23.6102, "lon": 85.2799, "type": "State"},
    "TR": {"name": "Tripura", "lat": 23.9408, "lon": 91.9882, "type": "State"},
    "MZ": {"name": "Mizoram", "lat": 23.1645, "lon": 92.9376, "type": "State"},
    "MN": {"name": "Manipur", "lat": 24.6637, "lon": 93.9063, "type": "State"},
    "BR": {"name": "Bihar", "lat": 25.0961, "lon": 85.3131, "type": "State"},
    "ML": {"name": "Meghalaya", "lat": 25.4670, "lon": 91.3662, "type": "State"},
    "AS": {"name": "Assam", "lat": 26.2006, "lon": 92.9376, "type": "State"},
    "NL": {"name": "Nagaland", "lat": 26.1584, "lon": 94.5624, "type": "State"},
    "UP": {"name": "Uttar Pradesh", "lat": 26.8467, "lon": 80.9462, "type": "State"},
    "RJ": {"name": "Rajasthan", "lat": 27.0238, "lon": 74.2179, "type": "State"},
    "SK": {"name": "Sikkim", "lat": 27.5330, "lon": 88.5122, "type": "State"},
    "AR": {"name": "Arunachal Pradesh", "lat": 28.2180, "lon": 94.7278, "type": "State"},
    "DL": {"name": "Delhi", "lat": 28.7041, "lon": 77.1025, "type": "UT"},
    "HR": {"name": "Haryana", "lat": 29.0588, "lon": 76.0856, "type": "State"},
    "UK": {"name": "Uttarakhand", "lat": 30.0668, "lon": 79.0193, "type": "State"},
    "CH": {"name": "Chandigarh", "lat": 30.7333, "lon": 76.7794, "type": "UT"},
    "PB": {"name": "Punjab", "lat": 31.1471, "lon": 75.3412, "type": "State"},
    "HP": {"name": "Himachal Pradesh", "lat": 31.1048, "lon": 77.1734, "type": "State"},
    "JK": {"name": "Jammu and Kashmir", "lat": 33.7782, "lon": 76.5762, "type": "UT"},
    "LA": {"name": "Ladakh", "lat": 34.1526, "lon": 77.5771, "type": "UT"},
}


def load_districts_by_state(districts_csv_path: Path) -> Dict[str, List[Dict[str, Any]]]:
    """Loads districts grouped by state_code from authoritative canonical CSV."""
    by_state: Dict[str, List[Dict[str, Any]]] = {}

    ref_path = districts_csv_path.parent / "reference" / "regions_reference.csv"
    if ref_path.exists():
        with open(ref_path, "r", encoding="utf-8") as f:
            reader = csv.DictReader(f)
            d_id = 1
            for row in reader:
                s_code = row.get("state_code", "").strip().upper()
                if s_code not in by_state:
                    by_state[s_code] = []
                d_name = row.get("district_name", "").strip()
                clean_slug = d_name.lower().replace(" ", "-")
                by_state[s_code].append({
                    "id": d_id,
                    "name": d_name,
                    "hq_name": d_name,
                    "census_code": row.get("district_code", "").strip(),
                    "slug": f"{clean_slug}-{s_code.lower()}",
                    "area_km2": 0.0,
                })
                d_id += 1
        return by_state

    if not districts_csv_path.exists():
        return by_state

    with open(districts_csv_path, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            s_code = row.get("state_code", "").strip().upper()
            if s_code not in by_state:
                by_state[s_code] = []
            by_state[s_code].append({
                "id": int(row.get("id", 0)),
                "name": row.get("name", "").strip(),
                "hq_name": row.get("hq_name", "").strip(),
                "census_code": row.get("census_2011_code", "").strip(),
                "slug": row.get("slug", "").strip(),
                "area_km2": float(row.get("area_km2", 0) or 0),
            })
    return by_state


def compute_sweep_order(
    districts_csv_path: Path,
    direction: str = "south_to_north"
) -> Dict[str, Any]:
    """
    Computes numbered state and district sweep sequence.
    direction: 'south_to_north' (ascending latitude) or 'north_to_south' (descending latitude)
    """
    reverse = (direction == "north_to_south")

    # 1. Sort states by centroid latitude
    sorted_states = sorted(
        STATE_CENTROIDS.items(),
        key=lambda item: item[1]["lat"],
        reverse=reverse
    )

    districts_by_state = load_districts_by_state(districts_csv_path)

    states_list = []
    total_districts = 0

    for state_idx, (code, meta) in enumerate(sorted_states, start=1):
        raw_districts = districts_by_state.get(code, [])

        # For districts, sort deterministically (by id/census code or name if lat is uniform)
        # Census 2011 codes in India generally sequence geographically within a state
        sorted_districts = sorted(
            raw_districts,
            key=lambda d: (d.get("census_code", ""), d.get("name", "")),
            reverse=reverse
        )

        district_entries = []
        for dist_idx, d in enumerate(sorted_districts, start=1):
            district_entries.append({
                "district_position": dist_idx,
                "district_id": d["id"],
                "district_name": d["name"],
                "hq_name": d["hq_name"],
                "census_code": d["census_code"],
                "slug": d["slug"],
            })

        states_list.append({
            "state_position": state_idx,
            "state_code": code,
            "state_name": meta["name"],
            "type": meta["type"],
            "centroid_lat": meta["lat"],
            "centroid_lon": meta["lon"],
            "total_districts": len(district_entries),
            "districts": district_entries,
        })
        total_districts += len(district_entries)

    return {
        "sweep_direction": direction,
        "total_states_and_uts": len(states_list),
        "total_districts": total_districts,
        "states": states_list,
    }


def generate_sweep_order_yaml(
    districts_csv_path: Path,
    output_yaml_path: Path,
    direction: str = "south_to_north"
) -> Path:
    """Generates the YAML and JSON sweep order files for review and execution."""
    data = compute_sweep_order(districts_csv_path, direction=direction)
    output_yaml_path.parent.mkdir(parents=True, exist_ok=True)

    json_path = output_yaml_path.with_suffix('.json')
    with open(json_path, "w", encoding="utf-8") as jf:
        json.dump(data, jf, indent=2, ensure_ascii=False)

    if HAS_YAML:
        with open(output_yaml_path, "w", encoding="utf-8") as f:
            yaml.dump(data, f, sort_keys=False, allow_unicode=True)

    print(f"✓ Generated sweep order ({direction}): {len(data['states'])} States/UTs, {data['total_districts']} Districts -> {output_yaml_path}")
    return output_yaml_path


if __name__ == "__main__":
    base_dir = Path(__file__).resolve().parent.parent.parent
    d_csv = base_dir / "data" / "districts.csv"
    out_yaml = base_dir / "data-pipeline" / "config" / "sweep_order.yaml"
    generate_sweep_order_yaml(d_csv, out_yaml, "south_to_north")
