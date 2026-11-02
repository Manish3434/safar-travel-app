"""
Data Pipeline Domain Models & Typing Specifications.
Adheres strictly to Clean Architecture: immutable types, explicit provenance, strict validations.
"""

from enum import Enum
from typing import Dict, List, Optional, Any
from datetime import datetime

try:
    from pydantic import BaseModel, Field
    HAS_PYDANTIC = True
except ImportError:
    HAS_PYDANTIC = False

    class _FieldMeta:
        def __init__(self, default_factory=None, default=None):
            self.default_factory = default_factory
            self.default = default

    def Field(default_factory=None, default=None):
        return _FieldMeta(default_factory=default_factory, default=default)

    class BaseModel:
        def __init__(self, **kwargs):
            for attr in dir(self.__class__):
                if not attr.startswith('_') and not callable(getattr(self.__class__, attr)):
                    val = getattr(self.__class__, attr)
                    if isinstance(val, _FieldMeta):
                        if val.default_factory and callable(val.default_factory):
                            setattr(self, attr, val.default_factory())
                        else:
                            setattr(self, attr, val.default)
                    else:
                        setattr(self, attr, val)
            for k, v in kwargs.items():
                setattr(self, k, v)


class DistrictRunStatus(str, Enum):
    PENDING = "pending"
    RUNNING = "running"
    DONE = "done"                       # >= 10 verified spots AND >= 10 with licensed images
    IMAGES_PENDING = "images_pending"   # >= 10 spots BUT < 10 with licensed images
    NEEDS_REVIEW = "needs_review"       # Query limit or daily budget reached, soft review
    BELOW_TARGET = "below_target"       # All 8 passes completed and logged, still < 10 spots
    FAILED = "failed"                   # Hard technical failure (network down, DB crash)


class VerificationLevel(str, Enum):
    VERIFIED = "verified"         # >= 2 independent sources or 1 official gov source
    UNVERIFIED = "unverified"     # Single source, retained with review flag
    SENSITIVE_MASKED = "sensitive_masked"  # Defense, ecological, or border area


class PassAttemptLog(BaseModel):
    pass_number: int              # 1 to 8
    pass_name: str
    queries_run: int = 0
    pages_read: int = 0
    candidates_found: int = 0
    candidates_accepted: int = 0
    candidates_rejected: int = 0
    rejection_reasons: Dict[str, int] = Field(default_factory=dict)
    duration_ms: int = 0
    executed_at: datetime = Field(default_factory=datetime.utcnow)


class DistrictRun(BaseModel):
    state_position: int
    state_code: str
    state_name: str
    district_position: int
    district_code: str            # LGD District Code
    district_name: str
    status: DistrictRunStatus = DistrictRunStatus.PENDING
    started_at: Optional[datetime] = None
    finished_at: Optional[datetime] = None
    spots_collected: int = 0
    spots_verified: int = 0
    spots_unverified: int = 0
    images_collected: int = 0
    rejection_count: int = 0
    passes_completed: int = 0
    pool_widened: bool = False
    attempt_log: List[PassAttemptLog] = Field(default_factory=list)
    sources_used: List[str] = Field(default_factory=list)
    error_message: Optional[str] = None
    retry_count: int = 0


class SpotImage(BaseModel):
    source_url: str
    filename: str
    license: str
    license_url: Optional[str] = None
    author: Optional[str] = None
    attribution_text: Optional[str] = None
    source: str  # wikidata_p18, wikipedia_lead, commons_category, commons_search, commons_geo, openverse, flickr_cc, official_portal, google_places_ptr
    width: Optional[int] = None
    height: Optional[int] = None
    thumbnail_path: Optional[str] = None
    is_pointer_only: bool = False  # True for Google Place ID leads (view-time only, never stored locally)
    is_primary: bool = False
    fetched_at: datetime = Field(default_factory=datetime.utcnow)


class SpotCandidate(BaseModel):
    name: str
    name_ta: Optional[str] = None
    name_hi: Optional[str] = None
    category: str
    latitude: float
    longitude: float
    state_code: str
    district_name: str
    wikidata_id: Optional[str] = None
    wikipedia_url: Optional[str] = None
    osm_id: Optional[str] = None
    source: str
    source_ref: str
    description: Optional[str] = None
    sensitive: bool = False
    permit_required: bool = False
    fetched_at: datetime = Field(default_factory=datetime.utcnow)


class VerifiedSpot(BaseModel):
    name: str
    slug: str
    name_ta: Optional[str] = None
    name_hi: Optional[str] = None
    category: str
    latitude: float
    longitude: float
    state_code: str
    district_id: int
    district_name: str
    wikidata_id: Optional[str] = None
    wikipedia_url: Optional[str] = None
    description: Optional[str] = None
    best_season: Optional[str] = None
    sensitive: bool = False
    permit_required: bool = False
    verification_level: VerificationLevel = VerificationLevel.UNVERIFIED
    google_place_id: Optional[str] = None
    data_sources: List[str] = Field(default_factory=list)
    source_count: int = 0
    source_details: List[Dict[str, Any]] = Field(default_factory=list)
    prominence_score: float = 0.0
    images: List[SpotImage] = Field(default_factory=list)
    first_seen_at: datetime = Field(default_factory=datetime.utcnow)
    last_verified_at: datetime = Field(default_factory=datetime.utcnow)
