"""
Geospatial math, coordinate verification, and boundary validation utilities.
"""

import math
from typing import Tuple, Optional

INDIA_BBOX = (6.5, 68.0, 37.5, 97.5)  # min_lat, min_lon, max_lat, max_lon


def is_within_india(lat: float, lon: float) -> bool:
    """Verifies that coordinates fall strictly within India's bounding envelope."""
    if lat is None or lon is None:
        return False
    min_lat, min_lon, max_lat, max_lon = INDIA_BBOX
    return min_lat <= lat <= max_lat and min_lon <= lon <= max_lon


def haversine_distance_meters(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """Calculates spherical distance between two coordinates in meters."""
    R = 6371000  # meters
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = (
        math.sin(dlat / 2) ** 2
        + math.cos(math.radians(lat1))
        * math.cos(math.radians(lat2))
        * math.sin(dlon / 2) ** 2
    )
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return R * c


def point_in_bbox(lat: float, lon: float, bbox: Tuple[float, float, float, float]) -> bool:
    """Checks if point (lat, lon) is inside bbox (south, west, north, east)."""
    s, w, n, e = bbox
    return s <= lat <= n and w <= lon <= e
