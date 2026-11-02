"""
WAVE 1 — GRID SWEEP OF OPENSTREETMAP (OSM)
Tiles India's BBox (6.5°N–37.5°N, 68.0°E–97.5°E) into 0.25° x 0.25° cells.
Catches all tourism, historic, leisure, and natural POIs with zero admin boundary bias.
"""

import os
import json
import time
from typing import List, Dict, Any
from lib.config import DATA_DIR, LOGS_DIR
from lib.overpass_client import build_grid_cell_query, execute_overpass_query
from lib.metrics import PipelineMetrics

GRID_CACHE_DIR = os.path.join(DATA_DIR, "osm_grid_cache")
os.makedirs(GRID_CACHE_DIR, exist_ok=True)

metrics = PipelineMetrics()


def generate_india_grid(step: float = 0.25) -> List[Dict[str, float]]:
    """Generates ~2,300 bounding box cells across India's land bounding box."""
    min_lat, max_lat = 6.5, 37.5
    min_lon, max_lon = 68.0, 97.5
    cells = []
    lat = min_lat
    while lat < max_lat:
        lon = min_lon
        while lon < max_lon:
            cells.append({
                "south": round(lat, 4),
                "west": round(lon, 4),
                "north": round(min(lat + step, max_lat), 4),
                "east": round(min(lon + step, max_lon), 4),
            })
            lon += step
        lat += step
    return cells


def run_wave_1(cells_limit: int = None):
    print("=" * 70)
    print("WAVE 1 — OPENSTREETMAP 0.25° GRID SWEEP")
    print("=" * 70)

    grid = generate_india_grid()
    if cells_limit:
        grid = grid[:cells_limit]

    print(f"Total grid cells generated: {len(grid)}")
    raw_yield_total = 0

    for idx, cell in enumerate(grid, 1):
        cell_id = f"cell_{cell['south']}_{cell['west']}"
        cache_file = os.path.join(GRID_CACHE_DIR, f"{cell_id}.json")

        if os.path.exists(cache_file):
            with open(cache_file, "r", encoding="utf-8") as f:
                cached = json.load(f)
                count = len(cached.get("elements", []))
                raw_yield_total += count
                continue

        query = build_grid_cell_query(cell["south"], cell["west"], cell["north"], cell["east"])
        data = execute_overpass_query(query)

        if data and "elements" in data:
            elements = data["elements"]
            count = len(elements)
            raw_yield_total += count
            metrics.inc_harvested("wave1", "osm", count)
            with open(cache_file, "w", encoding="utf-8") as f:
                json.dump(data, f)
            print(f"Cell {idx}/{len(grid)} [{cell_id}]: {count} POIs found")
        else:
            metrics.inc_error("overpass", "cell_failure")

        # Rate control
        time.sleep(0.5)

    print(f"\nWAVE 1 COMPLETE: {raw_yield_total} raw OSM POIs captured.")


if __name__ == "__main__":
    run_wave_1()
