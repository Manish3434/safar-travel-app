"""
Prometheus Metrics Textfile Collector for Pipeline Observability.
"""

import os
from typing import Dict, Any
from lib.config import LOGS_DIR

METRICS_FILE = os.path.join(LOGS_DIR, "metrics.prom")


class PipelineMetrics:
    def __init__(self):
        self.spots_harvested: Dict[str, int] = {}
        self.spots_merged: Dict[str, int] = {}
        self.photo_success: Dict[str, int] = {}
        self.photo_attempts: Dict[str, int] = {}
        self.api_errors: Dict[str, int] = {}

    def inc_harvested(self, wave: str, source: str, count: int = 1):
        key = f'{wave}_{source}'
        self.spots_harvested[key] = self.spots_harvested.get(key, 0) + count
        self.export()

    def inc_photo_result(self, tier: str, success: bool):
        self.photo_attempts[tier] = self.photo_attempts.get(tier, 0) + 1
        if success:
            self.photo_success[tier] = self.photo_success.get(tier, 0) + 1
        self.export()

    def inc_error(self, source: str, code: str):
        key = f'{source}_{code}'
        self.api_errors[key] = self.api_errors.get(key, 0) + 1
        self.export()

    def export(self):
        lines = []
        lines.append("# HELP spots_harvested_total Total raw spots yielded per wave and source")
        lines.append("# TYPE spots_harvested_total counter")
        for k, v in self.spots_harvested.items():
            w, s = k.split("_", 1)
            lines.append(f'spots_harvested_total{{wave="{w}",source="{s}"}} {v}')

        lines.append("# HELP photo_success_total Successful photo downloads per tier")
        lines.append("# TYPE photo_success_total counter")
        for t, v in self.photo_success.items():
            lines.append(f'photo_success_total{{tier="{t}"}} {v}')

        try:
            with open(METRICS_FILE, "w", encoding="utf-8") as f:
                f.write("\n".join(lines) + "\n")
        except Exception:
            pass
