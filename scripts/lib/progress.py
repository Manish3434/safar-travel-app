"""
Resumable Progress Tracking and Atomic Audit State for Pipeline Execution.
"""

import os
import json
import tempfile
from datetime import datetime, timezone
from typing import Dict, Any, List
from lib.config import PROGRESS_JSON


def load_progress() -> Dict[str, Any]:
    if os.path.exists(PROGRESS_JSON):
        try:
            with open(PROGRESS_JSON, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception:
            pass
    return {
        "completed_districts": [],
        "completed_waves": [],
        "last_updated": datetime.now(timezone.utc).isoformat(),
        "state_coverage": {},
    }


def record_district_complete(state_code: str, district_name: str, spots_found: int, photos_found: int):
    prog = load_progress()
    dist_key = f"{state_code}_{district_name}"
    if dist_key not in prog["completed_districts"]:
        prog["completed_districts"].append(dist_key)

    sc = prog["state_coverage"].setdefault(state_code, {
        "spots_found": 0,
        "spots_with_photo": 0,
        "districts_completed": 0
    })
    sc["spots_found"] += spots_found
    sc["spots_with_photo"] += photos_found
    sc["districts_completed"] = sum(1 for d in prog["completed_districts"] if d.startswith(f"{state_code}_"))
    prog["last_updated"] = datetime.now(timezone.utc).isoformat()

    # Atomic write to avoid corruption during crashes
    temp_dir = os.path.dirname(PROGRESS_JSON)
    fd, temp_path = tempfile.mkstemp(dir=temp_dir, suffix=".tmp")
    with os.fdopen(fd, "w", encoding="utf-8") as f:
        json.dump(prog, f, indent=2)
    os.replace(temp_path, PROGRESS_JSON)
