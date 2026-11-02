"""
Master loader for Indian States, Union Territories, and Districts.
Provides official administrative names, state codes, and bounding regions.
"""

from typing import Dict, List, Optional

# Master State and UT definition (28 States + 8 Union Territories)
ALL_STATES: Dict[str, Dict] = {
    "GA": {"name": "Goa", "code": "GA", "type": "State", "iso": "IN-GA", "districts": ["North Goa", "South Goa"]},
    "TN": {"name": "Tamil Nadu", "code": "TN", "type": "State", "iso": "IN-TN"},
    "KL": {"name": "Kerala", "code": "KL", "type": "State", "iso": "IN-KL"},
    "KA": {"name": "Karnataka", "code": "KA", "type": "State", "iso": "IN-KA"},
    "AP": {"name": "Andhra Pradesh", "code": "AP", "type": "State", "iso": "IN-AP"},
    "TG": {"name": "Telangana", "code": "TG", "type": "State", "iso": "IN-TG"},
    "MH": {"name": "Maharashtra", "code": "MH", "type": "State", "iso": "IN-MH"},
    "GJ": {"name": "Gujarat", "code": "GJ", "type": "State", "iso": "IN-GJ"},
    "RJ": {"name": "Rajasthan", "code": "RJ", "type": "State", "iso": "IN-RJ"},
    "HP": {"name": "Himachal Pradesh", "code": "HP", "type": "State", "iso": "IN-HP"},
    "UK": {"name": "Uttarakhand", "code": "UK", "type": "State", "iso": "IN-UT"},
    "JK": {"name": "Jammu & Kashmir", "code": "JK", "type": "UT", "iso": "IN-JK"},
    "MP": {"name": "Madhya Pradesh", "code": "MP", "type": "State", "iso": "IN-MP"},
    "UP": {"name": "Uttar Pradesh", "code": "UP", "type": "State", "iso": "IN-UP"},
    "WB": {"name": "West Bengal", "code": "WB", "type": "State", "iso": "IN-WB"},
    "OD": {"name": "Odisha", "code": "OD", "type": "State", "iso": "IN-OR"},
    "AS": {"name": "Assam", "code": "AS", "type": "State", "iso": "IN-AS"},
    "SK": {"name": "Sikkim", "code": "SK", "type": "State", "iso": "IN-SK"},
    "PB": {"name": "Punjab", "code": "PB", "type": "State", "iso": "IN-PB"},
    "HR": {"name": "Haryana", "code": "HR", "type": "State", "iso": "IN-HR"},
    "BR": {"name": "Bihar", "code": "BR", "type": "State", "iso": "IN-BR"},
    "JH": {"name": "Jharkhand", "code": "JH", "type": "State", "iso": "IN-JH"},
    "CG": {"name": "Chhattisgarh", "code": "CG", "type": "State", "iso": "IN-CT"},
    "ML": {"name": "Meghalaya", "code": "ML", "type": "State", "iso": "IN-ML"},
    "AR": {"name": "Arunachal Pradesh", "code": "AR", "type": "State", "iso": "IN-AR"},
    "MN": {"name": "Manipur", "code": "MN", "type": "State", "iso": "IN-MN"},
    "MZ": {"name": "Mizoram", "code": "MZ", "type": "State", "iso": "IN-MZ"},
    "NL": {"name": "Nagaland", "code": "NL", "type": "State", "iso": "IN-NL"},
    "TR": {"name": "Tripura", "code": "TR", "type": "State", "iso": "IN-TR"},
    "DL": {"name": "Delhi", "code": "DL", "type": "UT", "iso": "IN-DL"},
    "LA": {"name": "Ladakh", "code": "LA", "type": "UT", "iso": "IN-LA"},
    "PY": {"name": "Puducherry", "code": "PY", "type": "UT", "iso": "IN-PY"},
    "CH": {"name": "Chandigarh", "code": "CH", "type": "UT", "iso": "IN-CH"},
    "AN": {"name": "Andaman & Nicobar", "code": "AN", "type": "UT", "iso": "IN-AN"},
    "DN": {"name": "Dadra and Nagar Haveli and Daman and Diu", "code": "DN", "type": "UT", "iso": "IN-DH"},
    "LD": {"name": "Lakshadweep", "code": "LD", "type": "UT", "iso": "IN-LD"},
}

# Detailed District Catalog with bounding boxes (south, west, north, east)
DISTRICT_BBOXES: Dict[str, Dict[str, tuple]] = {
    "GA": {
        "North Goa": (15.28, 73.68, 15.80, 74.34),
        "South Goa": (14.89, 73.74, 15.48, 74.35),
    }
}


def get_states_list() -> List[Dict]:
    """Returns list of all 36 States and UTs."""
    return list(ALL_STATES.values())


def get_districts_for_state(state_code: str) -> List[Dict]:
    """
    Returns list of district objects for a given state code.
    Includes district name, state, state_code, and optional bounding box.
    """
    code = state_code.upper()
    state_meta = ALL_STATES.get(code)
    if not state_meta:
        return []

    state_name = state_meta["name"]
    districts = []

    if code == "GA":
        dist_names = ["North Goa", "South Goa"]
    else:
        # Fallback to predefined district list or state-level bboxes
        dist_names = state_meta.get("districts", [f"{state_name} District"])

    for d_name in dist_names:
        bbox = DISTRICT_BBOXES.get(code, {}).get(d_name)
        districts.append({
            "state": state_name,
            "state_code": code,
            "district": d_name,
            "bbox": bbox,
        })

    return districts
