"""
Pipeline Settings & Environment Configuration.
Strictly adheres to AGENTS.md: zero secrets in repo, environment variable overrides.
"""

import os
from pathlib import Path

# Paths
BASE_DIR = Path(__file__).resolve().parent.parent.parent
PIPELINE_DIR = BASE_DIR / "data-pipeline"
CONFIG_DIR = PIPELINE_DIR / "config"
DATA_DIR = BASE_DIR / "data"
DOWNLOAD_DIR = BASE_DIR / "download"
REPORT_DIR = BASE_DIR / "report"
GEOJSON_DIR = BASE_DIR / "geojson"

DOWNLOAD_DIR.mkdir(parents=True, exist_ok=True)
REPORT_DIR.mkdir(parents=True, exist_ok=True)
GEOJSON_DIR.mkdir(parents=True, exist_ok=True)

SWEEP_ORDER_FILE = CONFIG_DIR / "sweep_order.yaml"
CATEGORIES_FILE = CONFIG_DIR / "categories.yaml"
LOG_FILE = DOWNLOAD_DIR / "pipeline_run.log"

# PostgreSQL / PostGIS Database Config
DB_HOST = os.environ.get("POSTGRES_HOST", "localhost")
DB_PORT = int(os.environ.get("POSTGRES_PORT", "5432"))
DB_NAME = os.environ.get("POSTGRES_DB", "safar")
DB_USER = os.environ.get("POSTGRES_USER", "safar")
DB_PASSWORD = os.environ.get("POSTGRES_PASSWORD", "safar")
DB_URL = f"postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"

# User-Agent Identification (polite scraping requirement)
USER_AGENT = os.environ.get(
    "SAFAR_USER_AGENT",
    "SafarTravelExplorer/1.0 (https://safar-travel.internal; national-pipeline@safar.internal)"
)

# API Endpoints
OVERPASS_ENDPOINTS = [
    "https://lz4.overpass-api.de/api/interpreter",
    "https://overpass-api.de/api/interpreter",
    "https://overpass.kumi.systems/api/interpreter",
]
WIKIDATA_SPARQL_URL = "https://query.wikidata.org/sparql"
WIKIPEDIA_REST_BASE = "https://en.wikipedia.org/api/rest_v1"
COMMONS_API_URL = "https://commons.wikimedia.org/w/api.php"

# Rate Limiting (seconds interval)
OVERPASS_MIN_INTERVAL = float(os.environ.get("OVERPASS_MIN_INTERVAL", "0.5"))
WIKIMEDIA_MIN_INTERVAL = float(os.environ.get("WIKIMEDIA_MIN_INTERVAL", "0.2"))

# Search API Configuration
# Options: 'mock', 'brave', 'serper'
SEARCH_PROVIDER_MODE = os.environ.get("SEARCH_PROVIDER_MODE", "mock").lower()
BRAVE_SEARCH_API_KEY = os.environ.get("BRAVE_SEARCH_API_KEY", "")
SERPER_API_KEY = os.environ.get("SERPER_API_KEY", "")
DAILY_SEARCH_BUDGET_QUERIES = int(os.environ.get("DAILY_SEARCH_BUDGET_QUERIES", "2000"))

# Sweep Direction: 'south_to_north' (default) or 'north_to_south'
SWEEP_DIRECTION = os.environ.get("SWEEP_DIRECTION", "south_to_north").lower()

# Verification & Quality Thresholds
MIN_INDEPENDENT_SOURCES = 2
MIN_PROMINENCE_THRESHOLD = 50.0
MAX_DUPLICATE_DISTANCE_METERS = 250.0
MIN_TRIGRAM_SIMILARITY = 0.85

# Allowed Image Licenses
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
