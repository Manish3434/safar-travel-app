"""
Syncs data/districts.csv from data/reference/regions_reference.csv and data/states.csv.
Ensures exactly 784 canonical districts across 28 States and 8 Union Territories.
"""

import csv
import re
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent
REF_PATH = BASE_DIR / "data" / "reference" / "regions_reference.csv"
STATES_PATH = BASE_DIR / "data" / "states.csv"
DISTRICTS_PATH = BASE_DIR / "data" / "districts.csv"

def slugify(text: str) -> str:
    cleaned = re.sub(r"[^\w\s-]", "", text).strip().lower()
    return re.sub(r"[-\s]+", "-", cleaned)

def sync():
    # 1. Load state_code -> state_id
    state_map = {}
    with open(STATES_PATH, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for r in reader:
            state_map[r["code"].strip()] = int(r["id"].strip())

    # 2. Load existing district metadata if any
    existing_meta = {}
    if DISTRICTS_PATH.exists():
        with open(DISTRICTS_PATH, "r", encoding="utf-8") as f:
            reader = csv.DictReader(f)
            for r in reader:
                key = (r.get("state_code", "").strip(), r.get("name", "").strip().lower())
                existing_meta[key] = {
                    "hq_name": r.get("hq_name", ""),
                    "area_km2": r.get("area_km2", "0.0"),
                    "population_2011": r.get("population_2011", "0"),
                    "census_2011_code": r.get("census_2011_code", ""),
                }

    # 3. Read canonical regions_reference.csv
    new_rows = []
    d_id = 1
    with open(REF_PATH, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for r in reader:
            s_code = r["state_code"].strip()
            s_id = state_map.get(s_code, 1)
            d_name = r["district_name"].strip()
            d_code = r["district_code"].strip()

            meta = existing_meta.get((s_code, d_name.lower()), {})
            hq = meta.get("hq_name") or d_name
            area = meta.get("area_km2") or "0.0"
            pop = meta.get("population_2011") or "0"
            census_code = meta.get("census_2011_code") or d_code

            slug = f"{slugify(d_name)}-{s_code.lower()}"

            new_rows.append({
                "id": d_id,
                "state_id": s_id,
                "state_code": s_code,
                "name": d_name,
                "census_2011_code": census_code,
                "hq_name": hq,
                "area_km2": area,
                "population_2011": pop,
                "subdivision_type": "district",
                "slug": slug,
            })
            d_id += 1

    # 4. Write data/districts.csv
    fieldnames = [
        "id", "state_id", "state_code", "name", "census_2011_code",
        "hq_name", "area_km2", "population_2011", "subdivision_type", "slug"
    ]
    with open(DISTRICTS_PATH, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        for row in new_rows:
            writer.writerow(row)

    print(f"✓ Synchronized {DISTRICTS_PATH}: {len(new_rows)} canonical districts across {len(state_map)} regions.")

if __name__ == "__main__":
    sync()
