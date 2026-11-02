"""
Resilient Token-Bucket Rate Limiter with Exponential Backoff & Jitter.
Enforces polite access terms for Overpass, Wikimedia, and Government endpoints.
"""

import time
import random
import threading
from typing import Callable, Any
from functools import wraps


class RateLimiter:
    """Thread-safe rate limiter with minimum interval enforcement."""

    def __init__(self, min_interval_seconds: float, name: str = "default"):
        self.min_interval = min_interval_seconds
        self.name = name
        self.last_call = 0.0
        self.lock = threading.Lock()

    def wait(self):
        with self.lock:
            now = time.time()
            elapsed = now - self.last_call
            if elapsed < self.min_interval:
                sleep_time = self.min_interval - elapsed
                time.sleep(sleep_time)
            self.last_call = time.time()


def retry_with_backoff(
    max_retries: int = 4,
    initial_delay: float = 1.0,
    backoff_factor: float = 2.0,
    jitter: bool = True,
    retry_exceptions: tuple = (Exception,)
):
    """
    Decorator for network requests with exponential backoff, jitter, and consecutive failure detection.
    """
    def decorator(func: Callable):
        @wraps(func)
        def wrapper(*args, **kwargs) -> Any:
            delay = initial_delay
            last_err = None

            for attempt in range(1, max_retries + 1):
                try:
                    return func(*args, **kwargs)
                except retry_exceptions as e:
                    last_err = e
                    if attempt == max_retries:
                        raise e

                    sleep_dur = delay
                    if jitter:
                        sleep_dur += random.uniform(0.1, 0.5)

                    time.sleep(sleep_dur)
                    delay *= backoff_factor

            raise last_err
        return wrapper
    return decorator
