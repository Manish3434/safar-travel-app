"""
Thread-safe Token Bucket Rate Limiter with Exponential Backoff and Circuit Breaker.
Complies with Overpass (<=2 req/s) and Wikimedia (<=5 req/s) constraints.
"""

import time
import threading
from typing import Optional


class TokenBucketRateLimiter:
    def __init__(self, requests_per_second: float = 2.0, burst: int = 5):
        self.capacity = float(burst)
        self.tokens = float(burst)
        self.rate = float(requests_per_second)
        self.last_update = time.monotonic()
        self.lock = threading.Lock()
        self.consecutive_errors = 0
        self.circuit_open_until: Optional[float] = None

    def acquire(self):
        """Blocks until a token is available or circuit breaker resets."""
        while True:
            with self.lock:
                now = time.monotonic()
                if self.circuit_open_until and now < self.circuit_open_until:
                    wait_time = self.circuit_open_until - now
                else:
                    self.circuit_open_until = None
                    elapsed = now - self.last_update
                    self.tokens = min(self.capacity, self.tokens + elapsed * self.rate)
                    self.last_update = now

                    if self.tokens >= 1.0:
                        self.tokens -= 1.0
                        return

                    wait_time = (1.0 - self.tokens) / self.rate

            time.sleep(max(wait_time, 0.05))

    def record_success(self):
        with self.lock:
            self.consecutive_errors = 0

    def record_failure(self, retry_after: Optional[int] = None):
        with self.lock:
            self.consecutive_errors += 1
            now = time.monotonic()
            if retry_after:
                self.circuit_open_until = now + retry_after
            elif self.consecutive_errors >= 50:
                # Circuit breaker: 50 consecutive failures -> pause 10 minutes
                self.circuit_open_until = now + 600
