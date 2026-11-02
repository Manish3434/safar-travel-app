"""
Pipeline Configuration, Path Resolution, and Taxonomies.
"""

import os

# Root directory resolution
DEFAULT_ROOT = os.environ.get(
    "PIPELINE_ROOT",
    os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
)

PROJECT_ROOT = DEFAULT_ROOT
SCRIPTS_DIR = os.path.join(PROJECT_ROOT, "scripts")
DATA_DIR = os.path.join(PROJECT_ROOT, "data")
PHOTOS_DIR = os.path.join(PROJECT_ROOT, "photos")
GEOJSON_DIR = os.path.join(PROJECT_ROOT, "geojson")
DB_DIR = os.path.join(PROJECT_ROOT, "db")
REPORT_DIR = os.path.join(PROJECT_ROOT, "report")
LOGS_DIR = os.path.join(PROJECT_ROOT, "logs")

# Ensure directories exist
for d in [DATA_DIR, PHOTOS_DIR, GEOJSON_DIR, DB_DIR, REPORT_DIR, LOGS_DIR]:
    os.makedirs(d, exist_ok=True)

# Data file paths
COUNTRIES_CSV = os.path.join(DATA_DIR, "countries.csv")
STATES_CSV = os.path.join(DATA_DIR, "states.csv")
DISTRICTS_CSV = os.path.join(DATA_DIR, "districts.csv")
SPOT_CATEGORIES_CSV = os.path.join(DATA_DIR, "spot_categories.csv")
SPOTS_CSV = os.path.join(DATA_DIR, "spots.csv")
SPOT_IMAGES_CSV = os.path.join(DATA_DIR, "spot_images.csv")
SPOT_SOURCE_MAP_CSV = os.path.join(DATA_DIR, "spot_source_map.csv")
PROGRESS_JSON = os.path.join(LOGS_DIR, "progress.json")
HARVEST_LOG = os.path.join(LOGS_DIR, "harvest.log")
ERRORS_LOG = os.path.join(LOGS_DIR, "errors.log")

SCHEMA_SQL = os.path.join(DB_DIR, "schema.sql")
IMPORT_SQL = os.path.join(DB_DIR, "import.sql")

# HTTP & API Compliance
USER_AGENT = "SafarNationalTravelPlatform/3.0 (https://safar.internal; data-platform@safar.internal)"

OVERPASS_RATE_LIMIT = 0.5    # <= 2 req/s
WIKIMEDIA_RATE_LIMIT = 0.2   # <= 5 req/s

# Category Taxonomy (hierarchical)
CATEGORIES_TAXONOMY = [
    {"code": "heritage", "name_en": "Heritage & Monuments", "name_hi": "विरासत और स्मारक", "parent": None},
    {"code": "fort", "name_en": "Forts & Palaces", "name_hi": "किले और महल", "parent": "heritage"},
    {"code": "monument", "name_en": "Monuments & Memorials", "name_hi": "स्मारक", "parent": "heritage"},
    {"code": "religious", "name_en": "Pilgrimage & Sacred Sites", "name_hi": "धार्मिक और तीर्थ स्थल", "parent": None},
    {"code": "temple", "name_en": "Temples", "name_hi": "मंदिर", "parent": "religious"},
    {"code": "church", "name_en": "Churches & Cathedrals", "name_hi": "चर्च", "parent": "religious"},
    {"code": "nature", "name_en": "Nature & Wildlife", "name_hi": "प्रकृति और वन्यजीव", "parent": None},
    {"code": "waterfall", "name_en": "Waterfalls", "name_hi": "जलप्रपात", "parent": "nature"},
    {"code": "beach", "name_en": "Beaches & Coastal", "name_hi": "समुद्र तट", "parent": "nature"},
    {"code": "national_park", "name_en": "National Parks & Sanctuaries", "name_hi": "राष्ट्रीय उद्यान", "parent": "nature"},
    {"code": "hill_station", "name_en": "Hill Stations & Peaks", "name_hi": "पर्वतीय स्थल", "parent": "nature"},
    {"code": "viewpoint", "name_en": "Scenic Viewpoints", "name_hi": "प्राकृतिक दृश्य स्थल", "parent": "nature"},
    {"code": "urban", "name_en": "Urban & Culture", "name_hi": "शहरी और सांस्कृतिक", "parent": None},
    {"code": "museum", "name_en": "Museums & Galleries", "name_hi": "संग्रहालय", "parent": "urban"},
    {"code": "attraction", "name_en": "General Attractions", "name_hi": "पर्यटन स्थल", "parent": "urban"},
]
