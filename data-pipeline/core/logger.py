"""
Structured Logger for Nationwide Travel Pipeline.
Ensures standardized log lines with progress context: 'State X of N, District Y of M'.
"""

import sys
from datetime import datetime
from typing import Optional
from pathlib import Path

# Configure utf-8 stdout/stderr on Windows consoles to prevent cp1252 charmap errors
if hasattr(sys.stdout, 'reconfigure'):
    try:
        sys.stdout.reconfigure(encoding='utf-8', errors='replace')
        sys.stderr.reconfigure(encoding='utf-8', errors='replace')
    except Exception:
        pass

from config.settings import LOG_FILE


class PipelineLogger:
    def __init__(self, log_file: Path = LOG_FILE):
        self.log_file = log_file
        self.log_file.parent.mkdir(parents=True, exist_ok=True)

    def _format_prefix(
        self,
        state_pos: Optional[int] = None,
        state_total: Optional[int] = None,
        dist_pos: Optional[int] = None,
        dist_total: Optional[int] = None,
        district_name: Optional[str] = None,
    ) -> str:
        parts = []
        if state_pos and state_total:
            parts.append(f"State {state_pos} of {state_total}")
        if dist_pos and dist_total:
            parts.append(f"District {dist_pos} of {dist_total}")
        if district_name:
            parts.append(district_name)

        context = f"[{' | '.join(parts)}] " if parts else ""
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        return f"[{timestamp}] {context}"

    def info(self, msg: str, **kwargs):
        prefix = self._format_prefix(**kwargs)
        line = f"{prefix}INFO: {msg}"
        print(line)
        self._write_file(line)

    def warning(self, msg: str, **kwargs):
        prefix = self._format_prefix(**kwargs)
        line = f"{prefix}WARN: {msg}"
        print(f"\033[93m{line}\033[0m" if sys.stdout.isatty() else line)
        self._write_file(line)

    def error(self, msg: str, **kwargs):
        prefix = self._format_prefix(**kwargs)
        line = f"{prefix}ERROR: {msg}"
        print(f"\033[91m{line}\033[0m" if sys.stdout.isatty() else line)
        self._write_file(line)

    def success(self, msg: str, **kwargs):
        prefix = self._format_prefix(**kwargs)
        line = f"{prefix}SUCCESS: {msg}"
        print(f"\033[92m{line}\033[0m" if sys.stdout.isatty() else line)
        self._write_file(line)

    def _write_file(self, line: str):
        try:
            with open(self.log_file, "a", encoding="utf-8") as f:
                f.write(line + "\n")
        except Exception:
            pass


logger = PipelineLogger()
