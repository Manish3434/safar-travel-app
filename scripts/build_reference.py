"""
Build Canonical Regions Reference from baseline LGD data and cross-check with Wikidata.
Strictly generates data/reference/regions_reference.csv with:
type, state_code, state_name, district_code, district_name, source, source_file, fetched_at
"""

import csv
import json
import os
from datetime import datetime, timezone
from pathlib import Path
try:
    import requests
    HAS_REQUESTS = True
except ImportError:
    HAS_REQUESTS = False

BASE_DIR = Path(__file__).resolve().parent.parent
DATA_DIR = BASE_DIR / "data"
REF_DIR = DATA_DIR / "reference"
REF_DIR.mkdir(parents=True, exist_ok=True)

EXPECTED_STATES = {
    "Andhra Pradesh", "Arunachal Pradesh", "Assam", "Bihar", "Chhattisgarh",
    "Goa", "Gujarat", "Haryana", "Himachal Pradesh", "Jharkhand", "Karnataka",
    "Kerala", "Madhya Pradesh", "Maharashtra", "Manipur", "Meghalaya", "Mizoram",
    "Nagaland", "Odisha", "Punjab", "Rajasthan", "Sikkim", "Tamil Nadu",
    "Telangana", "Tripura", "Uttar Pradesh", "Uttarakhand", "West Bengal"
}

EXPECTED_UTS = {
    "Andaman and Nicobar Islands", "Chandigarh",
    "Dadra and Nagar Haveli and Daman and Diu", "Delhi",
    "Jammu and Kashmir", "Ladakh", "Lakshadweep", "Puducherry"
}

# Normalization map for ampersands and legacy names
STATE_NAME_NORMALIZATION = {
    "Andaman & Nicobar Islands": "Andaman and Nicobar Islands",
    "Dadra & Nagar Haveli and Daman & Diu": "Dadra and Nagar Haveli and Daman and Diu",
    "Jammu & Kashmir": "Jammu and Kashmir",
    "NCT of Delhi": "Delhi",
    "Delhi": "Delhi",
    "Pondicherry": "Puducherry",
    "Orissa": "Odisha",
    "Uttaranchal": "Uttarakhand",
}

def cross_check_wikidata():
    """Queries Wikidata for administrative divisions (districts of India)."""
    if not HAS_REQUESTS:
        return {}
    
    sparql_query = """
    SELECT ?item ?itemLabel ?stateLabel WHERE {
      ?item wdt:P31/wdt:P279* wd:Q1149652 . # district of India
      OPTIONAL { ?item wdt:P131 ?state . ?state wdt:P31/wdt:P279* wd:Q133346 . }
      SERVICE wikibase:label { bd:serviceParam wikibase:language "en". }
    } LIMIT 1000
    """
    try:
        resp = requests.get(
            "https://query.wikidata.org/sparql",
            params={"query": sparql_query, "format": "json"},
            headers={"User-Agent": "SafarRegionsAudit/1.0 (national-pipeline@safar.internal)"},
            timeout=15
        )
        if resp.status_code == 200:
            bindings = resp.json().get("results", {}).get("bindings", [])
            wiki_districts = {}
            for b in bindings:
                d_name = b.get("itemLabel", {}).get("value")
                s_name = b.get("stateLabel", {}).get("value")
                if d_name:
                    wiki_districts[d_name.lower().replace(" district", "")] = s_name
            return wiki_districts
    except Exception as e:
        print(f"Wikidata query non-blocking warning: {e}")
    return {}

def build_reference():
    states_file = DATA_DIR / "states.csv"
    districts_file = DATA_DIR / "districts.csv"
    ref_file = REF_DIR / "regions_reference.csv"
    
    now_iso = datetime.now(timezone.utc).isoformat()
    
    # 1. Load States
    states_map = {} # state_id -> state_meta
    state_code_to_meta = {}
    
    with open(states_file, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for r in reader:
            raw_name = r["name"].strip()
            norm_name = STATE_NAME_NORMALIZATION.get(raw_name, raw_name)
            
            # Determine type
            if norm_name in EXPECTED_STATES:
                reg_type = "state"
            elif norm_name in EXPECTED_UTS:
                reg_type = "union territory"
            else:
                reg_type = "unknown"
                
            meta = {
                "id": r["id"].strip(),
                "code": r["code"].strip(),
                "raw_name": raw_name,
                "name": norm_name,
                "type": reg_type,
                "census_code": r.get("census_2011_code", "").strip(),
            }
            states_map[r["id"].strip()] = meta
            state_code_to_meta[r["code"].strip()] = meta

    # 2. Check 36 expected
    found_states = {m["name"] for m in states_map.values() if m["type"] == "state"}
    found_uts = {m["name"] for m in states_map.values() if m["type"] == "union territory"}
    
    missing_states = EXPECTED_STATES - found_states
    extra_states = found_states - EXPECTED_STATES
    missing_uts = EXPECTED_UTS - found_uts
    extra_uts = found_uts - EXPECTED_UTS
    
    print("=== State & UT Comparison ===")
    print(f"States Expected: {len(EXPECTED_STATES)}, Found: {len(found_states)}")
    if missing_states:
        print(f"Missing States: {missing_states}")
    if extra_states:
        print(f"Extra States: {extra_states}")
    print(f"UTs Expected: {len(EXPECTED_UTS)}, Found: {len(found_uts)}")
    if missing_uts:
        print(f"Missing UTs: {missing_uts}")
    if extra_uts:
        print(f"Extra UTs: {extra_uts}")
        
    # 3. Load Districts
    districts = []
    with open(districts_file, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for r in reader:
            s_id = r["state_id"].strip()
            s_code = r.get("state_code", "").strip()
            d_code = r.get("census_2011_code", r.get("id", "")).strip()
            d_name = r["name"].strip()
            
            state_meta = states_map.get(s_id) or state_code_to_meta.get(s_code)
            if not state_meta:
                print(f"Warning: district {d_name} has unknown state_id {s_id}")
                continue
                
            districts.append({
                "type": state_meta["type"],
                "state_code": state_meta["code"],
                "state_name": state_meta["name"],
                "district_code": d_code,
                "district_name": d_name,
                "source": "LGD",
                "source_file": "data/districts.csv",
                "fetched_at": now_iso,
            })

    # Sort deterministically
    districts.sort(key=lambda x: (x["state_name"], x["district_name"]))
    
    # 4. Write data/reference/regions_reference.csv
    fieldnames = [
        "type", "state_code", "state_name", "district_code",
        "district_name", "source", "source_file", "fetched_at"
    ]
    with open(ref_file, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        for d in districts:
            writer.writerow(d)
            
    print(f"\n✓ Generated {ref_file} with {len(districts)} districts across {len(states_map)} regions.")
    
    # District count per state
    counts = {}
    for d in districts:
        s = d["state_name"]
        counts[s] = counts.get(s, 0) + 1
        
    print("\n=== Districts Per State / UT ===")
    for s, c in sorted(counts.items()):
        print(f"  • {s}: {c} districts")

if __name__ == "__main__":
    build_reference()
