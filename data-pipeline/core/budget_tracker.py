"""
Search API Budget Tracker & Daily Quota Guard.
Enforces hard stops when daily search quota is exhausted, preventing unexpected billing.
"""

import json
from datetime import date
from pathlib import Path
from config.settings import DOWNLOAD_DIR, DAILY_SEARCH_BUDGET_QUERIES


class BudgetExceededError(Exception):
    """Raised when the daily licensed search query budget is reached."""
    pass


class BudgetTracker:
    def __init__(
        self,
        daily_limit: int = DAILY_SEARCH_BUDGET_QUERIES,
        storage_file: Path = DOWNLOAD_DIR / "search_budget.json"
    ):
        self.daily_limit = daily_limit
        self.storage_file = storage_file
        self._load()

    def _load(self):
        self.today_str = date.today().isoformat()
        self.count = 0
        if self.storage_file.exists():
            try:
                with open(self.storage_file, "r", encoding="utf-8") as f:
                    data = json.load(f)
                    if data.get("date") == self.today_str:
                        self.count = data.get("count", 0)
            except Exception:
                self.count = 0

    def _save(self):
        try:
            self.storage_file.parent.mkdir(parents=True, exist_ok=True)
            with open(self.storage_file, "w", encoding="utf-8") as f:
                json.dump({
                    "date": self.today_str,
                    "count": self.count,
                    "daily_limit": self.daily_limit,
                    "remaining": max(0, self.daily_limit - self.count)
                }, f, indent=2)
        except Exception:
            pass

    def check_and_increment(self, queries: int = 1):
        """Validates that query will not exceed budget and increments counter."""
        current_today = date.today().isoformat()
        if current_today != self.today_str:
            self.today_str = current_today
            self.count = 0

        if self.count + queries > self.daily_limit:
            raise BudgetExceededError(
                f"Daily search API quota reached: {self.count}/{self.daily_limit} queries. "
                f"Pipeline halting safely. Resume tomorrow or increase DAILY_SEARCH_BUDGET_QUERIES."
            )

        self.count += queries
        self._save()

    @property
    def remaining_queries(self) -> int:
        return max(0, self.daily_limit - self.count)


budget_tracker = BudgetTracker()
