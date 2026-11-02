"""
Database Layer & PostGIS State Management.
Provides idempotent schema creation, district run checkpoints, and transactional persistence.
Includes graceful SQLite/JSON fallback for offline testing when PostgreSQL service is inactive.
"""

import json
import sqlite3
from typing import Dict, List, Optional, Any
from datetime import datetime

from config.settings import DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASSWORD, DOWNLOAD_DIR
from core.models import DistrictRun, DistrictRunStatus, VerifiedSpot, SpotImage, PassAttemptLog
from core.logger import logger

try:
    import psycopg2
    from psycopg2.extras import RealDictCursor
    HAS_PSYCOPG2 = True
except ImportError:
    HAS_PSYCOPG2 = False


class DatabaseManager:
    def __init__(self):
        self.use_postgres = False
        self.sqlite_path = DOWNLOAD_DIR / "pipeline_local.db"
        self._test_connection()

    def _test_connection(self):
        if not HAS_PSYCOPG2:
            self.use_postgres = False
            return

        try:
            conn = psycopg2.connect(
                host=DB_HOST,
                port=DB_PORT,
                dbname=DB_NAME,
                user=DB_USER,
                password=DB_PASSWORD,
                connect_timeout=2
            )
            conn.close()
            self.use_postgres = True
        except Exception:
            self.use_postgres = False

    def get_pg_connection(self):
        return psycopg2.connect(
            host=DB_HOST,
            port=DB_PORT,
            dbname=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD,
        )

    def get_sqlite_connection(self):
        self.sqlite_path.parent.mkdir(parents=True, exist_ok=True)
        conn = sqlite3.connect(str(self.sqlite_path))
        conn.row_factory = sqlite3.Row
        return conn

    def init_db(self):
        """Initializes tables idempotently in either PostgreSQL or SQLite."""
        if self.use_postgres:
            self._init_postgres()
        else:
            self._init_sqlite()

    def _init_postgres(self):
        conn = self.get_pg_connection()
        try:
            with conn.cursor() as cur:
                cur.execute("""
                CREATE EXTENSION IF NOT EXISTS postgis;
                CREATE EXTENSION IF NOT EXISTS pg_trgm;

                CREATE TABLE IF NOT EXISTS district_runs (
                    id SERIAL PRIMARY KEY,
                    state_position INT NOT NULL,
                    state_code VARCHAR(10) NOT NULL,
                    state_name VARCHAR(100) NOT NULL,
                    district_position INT NOT NULL,
                    district_code VARCHAR(20) NOT NULL,
                    district_name VARCHAR(100) NOT NULL,
                    status VARCHAR(25) NOT NULL DEFAULT 'pending',
                    started_at TIMESTAMPTZ,
                    finished_at TIMESTAMPTZ,
                    spots_collected INT DEFAULT 0,
                    spots_verified INT DEFAULT 0,
                    spots_unverified INT DEFAULT 0,
                    images_collected INT DEFAULT 0,
                    rejection_count INT DEFAULT 0,
                    passes_completed SMALLINT DEFAULT 0,
                    attempt_log JSONB DEFAULT '[]'::jsonb,
                    sources_used JSONB DEFAULT '[]'::jsonb,
                    error_message TEXT,
                    retry_count INT DEFAULT 0,
                    created_at TIMESTAMPTZ DEFAULT NOW(),
                    updated_at TIMESTAMPTZ DEFAULT NOW(),
                    UNIQUE(state_code, district_code)
                );

                CREATE TABLE IF NOT EXISTS district_pass_logs (
                    id BIGSERIAL PRIMARY KEY,
                    district_code VARCHAR(20) NOT NULL,
                    state_code VARCHAR(10) NOT NULL,
                    pass_number SMALLINT NOT NULL,
                    pass_name VARCHAR(50) NOT NULL,
                    queries_run INT DEFAULT 0,
                    pages_read INT DEFAULT 0,
                    candidates_found INT DEFAULT 0,
                    candidates_accepted INT DEFAULT 0,
                    candidates_rejected INT DEFAULT 0,
                    rejection_reasons JSONB DEFAULT '{}'::jsonb,
                    duration_ms INT DEFAULT 0,
                    executed_at TIMESTAMPTZ DEFAULT NOW()
                );

                CREATE INDEX IF NOT EXISTS idx_district_runs_status ON district_runs(status);
                CREATE INDEX IF NOT EXISTS idx_district_runs_order ON district_runs(state_position, district_position);
                CREATE INDEX IF NOT EXISTS idx_district_pass_logs ON district_pass_logs(district_code, pass_number);
                """)
                conn.commit()
            logger.info("✓ Initialized PostgreSQL schema & telemetry tables")
        finally:
            conn.close()

    def _init_sqlite(self):
        conn = self.get_sqlite_connection()
        try:
            with conn:
                conn.execute("""
                CREATE TABLE IF NOT EXISTS district_runs (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    state_position INT NOT NULL,
                    state_code TEXT NOT NULL,
                    state_name TEXT NOT NULL,
                    district_position INT NOT NULL,
                    district_code TEXT NOT NULL,
                    district_name TEXT NOT NULL,
                    status TEXT NOT NULL DEFAULT 'pending',
                    started_at TEXT,
                    finished_at TEXT,
                    spots_collected INT DEFAULT 0,
                    spots_verified INT DEFAULT 0,
                    spots_unverified INT DEFAULT 0,
                    images_collected INT DEFAULT 0,
                    rejection_count INT DEFAULT 0,
                    passes_completed INT DEFAULT 0,
                    attempt_log TEXT DEFAULT '[]',
                    sources_used TEXT DEFAULT '[]',
                    error_message TEXT,
                    retry_count INT DEFAULT 0,
                    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
                    updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
                    UNIQUE(state_code, district_code)
                );
                """)
                conn.execute("""
                CREATE TABLE IF NOT EXISTS district_pass_logs (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    district_code TEXT NOT NULL,
                    state_code TEXT NOT NULL,
                    pass_number INT NOT NULL,
                    pass_name TEXT NOT NULL,
                    queries_run INT DEFAULT 0,
                    pages_read INT DEFAULT 0,
                    candidates_found INT DEFAULT 0,
                    candidates_accepted INT DEFAULT 0,
                    candidates_rejected INT DEFAULT 0,
                    rejection_reasons TEXT DEFAULT '{}',
                    duration_ms INT DEFAULT 0,
                    executed_at TEXT DEFAULT CURRENT_TIMESTAMP
                );
                """)
                conn.execute("""
                CREATE TABLE IF NOT EXISTS local_spots (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    district_code TEXT NOT NULL,
                    name TEXT NOT NULL,
                    slug TEXT NOT NULL UNIQUE,
                    category TEXT NOT NULL,
                    latitude REAL NOT NULL,
                    longitude REAL NOT NULL,
                    wikidata_id TEXT,
                    wikipedia_url TEXT,
                    google_place_id TEXT,
                    description TEXT,
                    verification_level TEXT,
                    sources_count INT,
                    created_at TEXT DEFAULT CURRENT_TIMESTAMP
                );
                """)
                conn.execute("""
                CREATE TABLE IF NOT EXISTS spot_images (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    spot_slug TEXT NOT NULL,
                    district_code TEXT NOT NULL,
                    source_url TEXT NOT NULL,
                    source TEXT NOT NULL,
                    license TEXT NOT NULL,
                    author TEXT,
                    attribution_text TEXT,
                    width INT,
                    height INT,
                    thumbnail_path TEXT,
                    is_pointer_only INT DEFAULT 0,
                    is_primary INT DEFAULT 0,
                    fetched_at TEXT DEFAULT CURRENT_TIMESTAMP
                );
                """)
                # Migration: Ensure v0.6 columns exist on older SQLite databases
                for col, col_type in [("passes_completed", "INT DEFAULT 0"), ("attempt_log", "TEXT DEFAULT '[]'")]:
                    try:
                        conn.execute(f"ALTER TABLE district_runs ADD COLUMN {col} {col_type};")
                    except Exception:
                        pass

            logger.info(f"✓ Initialized local pipeline storage: {self.sqlite_path}")
        finally:
            conn.close()

    def register_sweep_districts(self, sweep_states: List[Dict[str, Any]]):
        """Populates district_runs table idempotently from computed sweep order."""
        self.init_db()
        for s in sweep_states:
            s_pos = s["state_position"]
            s_code = s["state_code"]
            s_name = s["state_name"]
            for d in s.get("districts", []):
                d_pos = d["district_position"]
                d_code = str(d["district_id"])
                d_name = d["district_name"]

                if self.use_postgres:
                    conn = self.get_pg_connection()
                    try:
                        with conn.cursor() as cur:
                            cur.execute("""
                            INSERT INTO district_runs (
                                state_position, state_code, state_name,
                                district_position, district_code, district_name,
                                status
                            ) VALUES (%s, %s, %s, %s, %s, %s, 'pending')
                            ON CONFLICT (state_code, district_code) DO NOTHING;
                            """, (s_pos, s_code, s_name, d_pos, d_code, d_name))
                            conn.commit()
                    finally:
                        conn.close()
                else:
                    conn = self.get_sqlite_connection()
                    try:
                        with conn:
                            conn.execute("""
                            INSERT OR IGNORE INTO district_runs (
                                state_position, state_code, state_name,
                                district_position, district_code, district_name,
                                status
                            ) VALUES (?, ?, ?, ?, ?, ?, 'pending');
                            """, (s_pos, s_code, s_name, d_pos, d_code, d_name))
                    finally:
                        conn.close()

    def get_next_pending_district(self) -> Optional[DistrictRun]:
        """Fetches the next district to run strictly following geographic sweep position."""
        if self.use_postgres:
            conn = self.get_pg_connection()
            try:
                with conn.cursor(cursor_factory=RealDictCursor) as cur:
                    cur.execute("""
                    SELECT * FROM district_runs 
                    WHERE status = 'pending' 
                    ORDER BY state_position ASC, district_position ASC 
                    LIMIT 1;
                    """)
                    row = cur.fetchone()
                    if row:
                        return DistrictRun(
                            state_position=row["state_position"],
                            state_code=row["state_code"],
                            state_name=row["state_name"],
                            district_position=row["district_position"],
                            district_code=row["district_code"],
                            district_name=row["district_name"],
                            status=DistrictRunStatus(row["status"]),
                            spots_collected=row["spots_collected"] or 0,
                            spots_verified=row["spots_verified"] or 0,
                            images_collected=row["images_collected"] or 0,
                        )
            finally:
                conn.close()
        else:
            conn = self.get_sqlite_connection()
            try:
                cur = conn.cursor()
                cur.execute("""
                SELECT * FROM district_runs 
                WHERE status = 'pending' 
                ORDER BY state_position ASC, district_position ASC 
                LIMIT 1;
                """)
                row = cur.fetchone()
                if row:
                    return DistrictRun(
                        state_position=row["state_position"],
                        state_code=row["state_code"],
                        state_name=row["state_name"],
                        district_position=row["district_position"],
                        district_code=row["district_code"],
                        district_name=row["district_name"],
                        status=DistrictRunStatus(row["status"]),
                        spots_collected=row["spots_collected"] or 0,
                        spots_verified=row["spots_verified"] or 0,
                        images_collected=row["images_collected"] or 0,
                    )
            finally:
                conn.close()
        return None

    def get_district_run(self, state_code: str, district_code: str) -> Optional[DistrictRun]:
        """Fetches the DistrictRun record for a specific state and district code."""
        if self.use_postgres:
            conn = self.get_pg_connection()
            try:
                with conn.cursor(cursor_factory=RealDictCursor) as cur:
                    cur.execute("""
                    SELECT * FROM district_runs 
                    WHERE state_code = %s AND district_code = %s
                    LIMIT 1;
                    """, (state_code, str(district_code)))
                    row = cur.fetchone()
                    if row:
                        return DistrictRun(
                            state_position=row["state_position"],
                            state_code=row["state_code"],
                            state_name=row["state_name"],
                            district_position=row["district_position"],
                            district_code=row["district_code"],
                            district_name=row["district_name"],
                            status=DistrictRunStatus(row["status"]),
                            spots_collected=row["spots_collected"] or 0,
                            spots_verified=row["spots_verified"] or 0,
                            images_collected=row["images_collected"] or 0,
                        )
            finally:
                conn.close()
        else:
            conn = self.get_sqlite_connection()
            try:
                cur = conn.cursor()
                cur.execute("""
                SELECT * FROM district_runs 
                WHERE state_code = ? AND district_code = ?
                LIMIT 1;
                """, (state_code, str(district_code)))
                row = cur.fetchone()
                if row:
                    return DistrictRun(
                        state_position=row["state_position"],
                        state_code=row["state_code"],
                        state_name=row["state_name"],
                        district_position=row["district_position"],
                        district_code=row["district_code"],
                        district_name=row["district_name"],
                        status=DistrictRunStatus(row["status"]),
                        spots_collected=row["spots_collected"] or 0,
                        spots_verified=row["spots_verified"] or 0,
                        images_collected=row["images_collected"] or 0,
                    )
            finally:
                conn.close()
        return None

    def get_failed_districts(self) -> List[DistrictRun]:
        """Fetches all districts with status in ('failed', 'needs_review')."""
        results = []
        if self.use_postgres:
            conn = self.get_pg_connection()
            try:
                with conn.cursor(cursor_factory=RealDictCursor) as cur:
                    cur.execute("""
                    SELECT * FROM district_runs 
                    WHERE status IN ('failed', 'needs_review') 
                    ORDER BY state_position ASC, district_position ASC;
                    """)
                    for row in cur.fetchall():
                        results.append(DistrictRun(
                            state_position=row["state_position"],
                            state_code=row["state_code"],
                            state_name=row["state_name"],
                            district_position=row["district_position"],
                            district_code=row["district_code"],
                            district_name=row["district_name"],
                            status=DistrictRunStatus(row["status"]),
                            spots_collected=row["spots_collected"] or 0,
                            spots_verified=row["spots_verified"] or 0,
                            images_collected=row["images_collected"] or 0,
                        ))
            finally:
                conn.close()
        else:
            conn = self.get_sqlite_connection()
            try:
                cur = conn.cursor()
                cur.execute("""
                SELECT state_position, state_code, state_name, district_position, district_code, district_name, status, spots_collected, spots_verified, images_collected 
                FROM district_runs 
                WHERE status IN ('failed', 'needs_review') 
                ORDER BY state_position ASC, district_position ASC;
                """)
                for row in cur.fetchall():
                    results.append(DistrictRun(
                        state_position=row[0],
                        state_code=row[1],
                        state_name=row[2],
                        district_position=row[3],
                        district_code=row[4],
                        district_name=row[5],
                        status=DistrictRunStatus(row[6]),
                        spots_collected=row[7] or 0,
                        spots_verified=row[8] or 0,
                        images_collected=row[9] or 0,
                    ))
            finally:
                conn.close()
        return results

    def get_districts_in_state(self, state_code: str) -> List[DistrictRun]:
        """Fetches all district runs for a given state code."""
        results = []
        if self.use_postgres:
            conn = self.get_pg_connection()
            try:
                with conn.cursor(cursor_factory=RealDictCursor) as cur:
                    cur.execute("""
                    SELECT * FROM district_runs 
                    WHERE state_code = %s 
                    ORDER BY district_position ASC;
                    """, (state_code,))
                    for row in cur.fetchall():
                        results.append(DistrictRun(
                            state_position=row["state_position"],
                            state_code=row["state_code"],
                            state_name=row["state_name"],
                            district_position=row["district_position"],
                            district_code=row["district_code"],
                            district_name=row["district_name"],
                            status=DistrictRunStatus(row["status"]),
                            spots_collected=row["spots_collected"] or 0,
                            spots_verified=row["spots_verified"] or 0,
                            images_collected=row["images_collected"] or 0,
                        ))
            finally:
                conn.close()
        else:
            conn = self.get_sqlite_connection()
            try:
                cur = conn.cursor()
                cur.execute("""
                SELECT state_position, state_code, state_name, district_position, district_code, district_name, status, spots_collected, spots_verified, images_collected 
                FROM district_runs 
                WHERE state_code = ? 
                ORDER BY district_position ASC;
                """, (state_code,))
                for row in cur.fetchall():
                    results.append(DistrictRun(
                        state_position=row[0],
                        state_code=row[1],
                        state_name=row[2],
                        district_position=row[3],
                        district_code=row[4],
                        district_name=row[5],
                        status=DistrictRunStatus(row[6]),
                        spots_collected=row[7] or 0,
                        spots_verified=row[8] or 0,
                        images_collected=row[9] or 0,
                    ))
            finally:
                conn.close()
        return results

    def log_pass_attempt(self, district_code: str, state_code: str, pass_log: PassAttemptLog):
        """Logs a single pass execution audit entry to district_pass_logs."""
        reasons_json = json.dumps(pass_log.rejection_reasons or {})
        now = pass_log.executed_at or datetime.utcnow()

        if self.use_postgres:
            conn = self.get_pg_connection()
            try:
                with conn.cursor() as cur:
                    cur.execute("""
                    INSERT INTO district_pass_logs (
                        district_code, state_code, pass_number, pass_name,
                        queries_run, pages_read, candidates_found,
                        candidates_accepted, candidates_rejected,
                        rejection_reasons, duration_ms, executed_at
                    ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s::jsonb, %s, %s);
                    """, (
                        str(district_code), state_code, pass_log.pass_number,
                        pass_log.pass_name, pass_log.queries_run, pass_log.pages_read,
                        pass_log.candidates_found, pass_log.candidates_accepted,
                        pass_log.candidates_rejected, reasons_json,
                        pass_log.duration_ms, now
                    ))
                    conn.commit()
            finally:
                conn.close()
        else:
            conn = self.get_sqlite_connection()
            try:
                with conn:
                    conn.execute("""
                    INSERT INTO district_pass_logs (
                        district_code, state_code, pass_number, pass_name,
                        queries_run, pages_read, candidates_found,
                        candidates_accepted, candidates_rejected,
                        rejection_reasons, duration_ms, executed_at
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
                    """, (
                        str(district_code), state_code, pass_log.pass_number,
                        pass_log.pass_name, pass_log.queries_run, pass_log.pages_read,
                        pass_log.candidates_found, pass_log.candidates_accepted,
                        pass_log.candidates_rejected, reasons_json,
                        pass_log.duration_ms, now.isoformat()
                    ))
            finally:
                conn.close()

    def update_district_status(
        self,
        state_code: str,
        district_code: str,
        status: DistrictRunStatus,
        spots_collected: int = 0,
        spots_verified: int = 0,
        spots_unverified: int = 0,
        images_collected: int = 0,
        rejection_count: int = 0,
        passes_completed: int = 0,
        attempt_log: Optional[List[Any]] = None,
        sources_used: Optional[List[str]] = None,
        error_message: Optional[str] = None,
    ):
        sources_json = json.dumps(sources_used or [])
        attempt_json = json.dumps([
            p.dict() if hasattr(p, 'dict') else p for p in (attempt_log or [])
        ])
        now = datetime.utcnow()

        if self.use_postgres:
            conn = self.get_pg_connection()
            try:
                with conn.cursor() as cur:
                    cur.execute("""
                    UPDATE district_runs SET
                        status = %s,
                        finished_at = %s,
                        spots_collected = %s,
                        spots_verified = %s,
                        spots_unverified = %s,
                        images_collected = %s,
                        rejection_count = %s,
                        passes_completed = %s,
                        attempt_log = %s::jsonb,
                        sources_used = %s::jsonb,
                        error_message = %s,
                        updated_at = %s
                    WHERE state_code = %s AND district_code = %s;
                    """, (
                        status.value, now, spots_collected, spots_verified,
                        spots_unverified, images_collected, rejection_count,
                        passes_completed, attempt_json, sources_json,
                        error_message, now, state_code, str(district_code)
                    ))
                    conn.commit()
            finally:
                conn.close()
        else:
            conn = self.get_sqlite_connection()
            try:
                with conn:
                    conn.execute("""
                    UPDATE district_runs SET
                        status = ?,
                        finished_at = ?,
                        spots_collected = ?,
                        spots_verified = ?,
                        spots_unverified = ?,
                        images_collected = ?,
                        rejection_count = ?,
                        passes_completed = ?,
                        attempt_log = ?,
                        sources_used = ?,
                        error_message = ?,
                        updated_at = ?
                    WHERE state_code = ? AND district_code = ?;
                    """, (
                        status.value, now.isoformat(), spots_collected, spots_verified,
                        spots_unverified, images_collected, rejection_count,
                        passes_completed, attempt_json, sources_json,
                        error_message, now.isoformat(), state_code, str(district_code)
                    ))
            finally:
                conn.close()

    def save_spots(self, district_code: str, spots: List[VerifiedSpot]):
        """Persists verified spots and their licensed images idempotently."""
        if not spots:
            return

        if not self.use_postgres:
            conn = self.get_sqlite_connection()
            try:
                with conn:
                    for s in spots:
                        conn.execute("""
                        INSERT OR REPLACE INTO local_spots (
                            district_code, name, slug, category, latitude, longitude,
                            wikidata_id, wikipedia_url, google_place_id, description,
                            verification_level, sources_count
                        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
                        """, (
                            str(district_code), s.name, s.slug, s.category, s.latitude, s.longitude,
                            s.wikidata_id, s.wikipedia_url, getattr(s, 'google_place_id', None),
                            s.description, s.verification_level.value, s.source_count
                        ))

                        for img in getattr(s, 'images', []):
                            conn.execute("""
                            INSERT OR REPLACE INTO spot_images (
                                spot_slug, district_code, source_url, source, license,
                                author, attribution_text, width, height, thumbnail_path,
                                is_pointer_only, is_primary
                            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
                            """, (
                                s.slug, str(district_code), img.source_url, img.source,
                                img.license, img.author, img.attribution_text,
                                img.width, img.height, getattr(img, 'thumbnail_path', None),
                                1 if getattr(img, 'is_pointer_only', False) else 0,
                                1 if img.is_primary else 0
                            ))
            finally:
                conn.close()

    def get_status_summary(self) -> Dict[str, Any]:
        """Returns overall progress breakdown across all states and districts."""
        counts = {
            "pending": 0, "running": 0, "done": 0, "images_pending": 0,
            "needs_review": 0, "below_target": 0, "failed": 0, "total": 0
        }
        total_spots = 0
        total_images = 0

        if self.use_postgres:
            conn = self.get_pg_connection()
            try:
                with conn.cursor(cursor_factory=RealDictCursor) as cur:
                    cur.execute("""
                    SELECT status, count(*), sum(spots_verified), sum(images_collected)
                    FROM district_runs GROUP BY status;
                    """)
                    for row in cur.fetchall():
                        st = row["status"]
                        if st in counts:
                            counts[st] = row["count"]
                        counts["total"] += row["count"]
                        total_spots += (row["sum"] or 0)
                        total_images += (row["sum_1"] or 0 if "sum_1" in row else (row["sum"] or 0))
            finally:
                conn.close()
        else:
            conn = self.get_sqlite_connection()
            try:
                cur = conn.cursor()
                cur.execute("""
                SELECT status, count(*), sum(spots_verified), sum(images_collected)
                FROM district_runs GROUP BY status;
                """)
                for row in cur.fetchall():
                    st = row[0]
                    if st in counts:
                        counts[st] = row[1]
                    counts["total"] += row[1]
                    total_spots += (row[2] or 0)
                    total_images += (row[3] or 0)
            finally:
                conn.close()

        return {
            "counts": counts,
            "total_spots_verified": total_spots,
            "total_images_collected": total_images,
            "backend": "PostgreSQL/PostGIS" if self.use_postgres else "Local SQLite"
        }


db_manager = DatabaseManager()
