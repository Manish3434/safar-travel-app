"""
Configuration, path resolution, and rate limiting constants for the
India Tourist Spots Data Pipeline.
"""

import os
import time
import threading

# Base directory: default to project root or /home/z/my-project if on Linux/specified
DEFAULT_BASE = os.environ.get(
    "PIPELINE_BASE_DIR",
    os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
)

BASE_DIR = DEFAULT_BASE
SCRIPTS_DIR = os.path.join(BASE_DIR, "scripts")
DOWNLOAD_DIR = os.path.join(BASE_DIR, "download")
PHOTOS_DIR = os.path.join(DOWNLOAD_DIR, "photos")
SPOTS_CSV = os.path.join(DOWNLOAD_DIR, "spots.csv")
PROGRESS_FILE = os.path.join(DOWNLOAD_DIR, "progress.json")
LOG_FILE = os.path.join(DOWNLOAD_DIR, "run.log")
IMPORT_SQL = os.path.join(BASE_DIR, "import.sql")

# Ensure critical directories exist
os.makedirs(SCRIPTS_DIR, exist_ok=True)
os.makedirs(DOWNLOAD_DIR, exist_ok=True)
os.makedirs(PHOTOS_DIR, exist_ok=True)

# User-Agent compliance for OSM & Wikimedia foundations
USER_AGENT = (
    "SafarTravelExplorer/1.0 "
    "(https://safar-travel.internal; travel-pipeline@safar.internal)"
)

# Overpass API endpoints (with fallback)
OVERPASS_ENDPOINTS = [
    "https://overpass-api.de/api/interpreter",
    "https://overpass.kumi.systems/api/interpreter",
]

# Wikidata & Wikipedia API endpoints
WIKIDATA_SPARQL_URL = "https://query.wikidata.org/sparql"
WIKIPEDIA_REST_BASE = "https://en.wikipedia.org/api/rest_v1"
COMMONS_API_URL = "https://commons.wikimedia.org/w/api.php"

# Rate Limits (seconds between requests)
OVERPASS_MIN_INTERVAL = 0.5   # Cap at <= 2 requests/sec
WIKIMEDIA_MIN_INTERVAL = 0.2  # Cap at <= 5 requests/sec

# Acceptable Open Licenses for commercial travel app usage
ALLOWED_LICENSES = {
    "cc0",
    "public domain",
    "pd",
    "cc-by",
    "cc-by-1.0",
    "cc-by-2.0",
    "cc-by-2.5",
    "cc-by-3.0",
    "cc-by-4.0",
    "cc-by-sa",
    "cc-by-sa-1.0",
    "cc-by-sa-2.0",
    "cc-by-sa-2.5",
    "cc-by-sa-3.0",
    "cc-by-sa-4.0",
}


class RateLimiter:
    """Thread-safe rate limiter to strictly adhere to provider caps."""

    def __init__(self, min_interval_seconds: float):
        self.min_interval = min_interval_seconds
        self.last_call = 0.0
        self.lock = threading.Lock()

    def wait(self):
        with self.lock:
            now = time.time()
            elapsed = now - self.last_call
            if elapsed < self.min_interval:
                time.sleep(self.min_interval - elapsed)
            self.last_call = time.time()


overpass_limiter = RateLimiter(OVERPASS_MIN_INTERVAL)
wikimedia_limiter = RateLimiter(WIKIMEDIA_MIN_INTERVAL)
