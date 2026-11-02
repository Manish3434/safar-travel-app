"""
Unit tests for RateLimiter and Exponential Backoff Decorator.
"""

import sys
import time
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import pytest
from core.rate_limiter import RateLimiter, retry_with_backoff


def test_rate_limiter_interval():
    """Verifies that consecutive calls are paced by min_interval."""
    limiter = RateLimiter(min_interval_seconds=0.08)
    t0 = time.time()
    limiter.wait()
    limiter.wait()
    elapsed = time.time() - t0
    assert elapsed >= 0.075


def test_retry_with_backoff_success():
    """Verifies that retry_with_backoff succeeds when function recovers."""
    attempts = 0

    @retry_with_backoff(max_retries=3, initial_delay=0.01, backoff_factor=1.5, jitter=False)
    def flaky_func():
        nonlocal attempts
        attempts += 1
        if attempts < 2:
            raise ConnectionError("Temporary glitch")
        return "recovered"

    result = flaky_func()
    assert result == "recovered"
    assert attempts == 2


def test_retry_with_backoff_exhausted():
    """Verifies that retry_with_backoff raises exception when all retries fail."""
    attempts = 0

    @retry_with_backoff(max_retries=3, initial_delay=0.01, backoff_factor=1.5, jitter=False)
    def broken_func():
        nonlocal attempts
        attempts += 1
        raise ValueError("Permanent failure")

    with pytest.raises(ValueError, match="Permanent failure"):
        broken_func()
    assert attempts == 3
