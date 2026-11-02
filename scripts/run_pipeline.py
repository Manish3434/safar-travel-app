"""
Main Pipeline Runner for India Tourist Spots POI & Photo Collection.
Executes Overpass querying, Wikidata image resolution, CC-BY licensing validation,
resumable progress tracking, CSV emission, and Postgres import generation.
"""

import os
import sys
import csv
import json
import time
import argparse
from datetime import datetime
from typing import Dict, List, Set

from config import (
    BASE_DIR,
    DOWNLOAD_DIR,
    PHOTOS_DIR,
    SPOTS_CSV,
    PROGRESS_FILE,
    LOG_FILE,
    IMPORT_SQL,
)
from districts_loader import get_states_list, get_districts_for_state
from osm_overpass import query_overpass_district
from wikidata_media import resolve_and_download_image
from generate_sql import generate_import_sql


CSV_COLUMNS = [
    "state",
    "state_code",
    "district",
    "spot_name",
    "category",
    "latitude",
    "longitude",
    "wikidata_id",
    "wikipedia_url",
    "image_filename",
    "image_source",
    "license",
]


def log_message(msg: str):
    """Appends timestamped message to run.log and stdout."""
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    formatted = f"[{timestamp}] {msg}"
    print(formatted)
    try:
        with open(LOG_FILE, "a", encoding="utf-8") as f:
            f.write(formatted + "\n")
    except Exception:
        pass


def load_progress() -> Dict:
    """Loads existing progress checkpoint."""
    if os.path.exists(PROGRESS_FILE):
        try:
            with open(PROGRESS_FILE, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception:
            pass
    return {"completed_districts": [], "last_updated": None}


def save_progress(completed_districts: List[str]):
    """Persists progress checkpoint."""
    data = {
        "completed_districts": list(set(completed_districts)),
        "last_updated": datetime.now().isoformat(),
    }
    with open(PROGRESS_FILE, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2)


def get_existing_spots() -> Set[str]:
    """Reads existing spots to prevent duplicates."""
    existing = set()
    if os.path.exists(SPOTS_CSV):
        try:
            with open(SPOTS_CSV, "r", encoding="utf-8") as f:
                reader = csv.DictReader(f)
                for row in reader:
                    key = f"{row.get('district', '')}::{row.get('spot_name', '')}"
                    existing.add(key)
        except Exception:
            pass
    return existing


def run_pipeline(
    state_code: str = "GA",
    all_states: bool = False,
    force: bool = False,
    limit_districts: int = None,
    limit_spots_per_district: int = None,
):
    start_time = time.time()
    log_message("=" * 60)
    log_message(f"Starting India Tourist Spots Pipeline. Mode: {'ALL STATES' if all_states else state_code}")

    # Determine districts to process
    districts_to_process = []
    if all_states:
        for s in get_states_list():
            districts_to_process.extend(get_districts_for_state(s["code"]))
    else:
        districts_to_process = get_districts_for_state(state_code)

    if limit_districts:
        districts_to_process = districts_to_process[:limit_districts]

    log_message(f"Total districts queued: {len(districts_to_process)}")

    # Load progress checkpoint
    progress = load_progress()
    completed_districts = set(progress.get("completed_districts", []))
    existing_spot_keys = get_existing_spots()

    # Initialize CSV header if new
    csv_exists = os.path.exists(SPOTS_CSV)
    if not csv_exists:
        with open(SPOTS_CSV, "w", newline="", encoding="utf-8") as f:
            writer = csv.writer(f)
            writer.writerow(CSV_COLUMNS)

    total_spots_collected = 0
    total_photos_collected = 0

    for d_idx, d_meta in enumerate(districts_to_process, start=1):
        state = d_meta["state"]
        code = d_meta["state_code"]
        district = d_meta["district"]
        dist_key = f"{code}_{district}"

        if dist_key in completed_districts and not force:
            log_message(f"[{d_idx}/{len(districts_to_process)}] Skipping already completed district: {district} ({state})")
            continue

        log_message(f"[{d_idx}/{len(districts_to_process)}] Processing: {district}, {state}...")
        spots = query_overpass_district(state, district, bbox=d_meta.get("bbox"))
        log_message(f"  -> Found {len(spots)} candidate POIs in OSM for {district}")

        if limit_spots_per_district:
            spots = spots[:limit_spots_per_district]

        district_rows = []
        for s_idx, spot in enumerate(spots, start=1):
            spot_name = spot["spot_name"]
            key = f"{district}::{spot_name}"
            if key in existing_spot_keys and not force:
                continue

            wid, wurl, img_fn, img_src, lic_name = resolve_and_download_image(
                state=state,
                district=district,
                spot_name=spot_name,
                wikidata_id=spot.get("wikidata_id", ""),
                wikipedia_url=spot.get("wikipedia_url", ""),
            )

            has_photo = bool(img_fn)
            if has_photo:
                total_photos_collected += 1

            row = {
                "state": state,
                "state_code": code,
                "district": district,
                "spot_name": spot_name,
                "category": spot.get("category", "attraction"),
                "latitude": spot.get("latitude"),
                "longitude": spot.get("longitude"),
                "wikidata_id": wid or "",
                "wikipedia_url": wurl or "",
                "image_filename": img_fn or "",
                "image_source": img_src or "",
                "license": lic_name or "",
            }

            district_rows.append(row)
            existing_spot_keys.add(key)
            total_spots_collected += 1

        # Append district records to CSV
        if district_rows:
            with open(SPOTS_CSV, "a", newline="", encoding="utf-8") as f:
                writer = csv.DictWriter(f, fieldnames=CSV_COLUMNS)
                for r in district_rows:
                    writer.writerow(r)

        completed_districts.add(dist_key)
        save_progress(list(completed_districts))
        log_message(f"  -> Completed {district}: saved {len(district_rows)} spots")

    # Generate import.sql
    log_message("Generating import.sql from spots.csv...")
    generate_import_sql(SPOTS_CSV, IMPORT_SQL)

    elapsed = time.time() - start_time
    log_message("=" * 60)
    log_message(f"Pipeline run finished in {elapsed:.2f} seconds.")

    # Calculate metrics
    _print_summary(elapsed)


def _print_summary(elapsed_seconds: float):
    """Calculates and prints disk usage and coverage metrics."""
    total_rows = 0
    with_photo = 0
    if os.path.exists(SPOTS_CSV):
        with open(SPOTS_CSV, "r", encoding="utf-8") as f:
            reader = csv.DictReader(f)
            for r in reader:
                total_rows += 1
                if r.get("image_filename"):
                    with_photo += 1

    photo_dir_size = 0
    for root, _, files in os.walk(PHOTOS_DIR):
        for f in files:
            fp = os.path.join(root, f)
            photo_dir_size += os.path.getsize(fp)

    cov_pct = (with_photo / total_rows * 100) if total_rows > 0 else 0.0

    print("\n" + "=" * 60)
    print("PIPELINE EXECUTION SUMMARY")
    print("=" * 60)
    print(f"Total Spots in CSV    : {total_rows}")
    print(f"Spots with Photo      : {with_photo}")
    print(f"Photo Coverage        : {cov_pct:.1f}%")
    print(f"Photos Folder Size    : {photo_dir_size / (1024 * 1024):.2f} MB")
    print(f"Total Runtime         : {elapsed_seconds:.2f}s")
    print(f"CSV Path              : {SPOTS_CSV}")
    print(f"Import SQL Path       : {IMPORT_SQL}")
    print(f"Log File Path         : {LOG_FILE}")
    print("=" * 60 + "\n")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="India Tourist Spots Pipeline")
    parser.add_argument("--state", type=str, default="GA", help="State code to run (default: GA for Goa dry run)")
    parser.add_argument("--all", action="store_true", help="Run for all 28 states and 8 UTs")
    parser.add_argument("--force", action="store_true", help="Force re-processing of completed districts")
    parser.add_argument("--limit-districts", type=int, default=None, help="Limit number of districts")
    parser.add_argument("--limit-spots", type=int, default=None, help="Limit spots per district")
    args = parser.parse_args()

    run_pipeline(
        state_code=args.state,
        all_states=args.all,
        force=args.force,
        limit_districts=args.limit_districts,
        limit_spots_per_district=args.limit_spots,
    )
