-- ============================================================================
-- INDIA TRAVEL SPOTS — POSTGRESQL 15 + POSTGIS 3.4 PRODUCTION SCHEMA
-- Mandate: Exhaustive National Harvest (v3.0)
-- Strict hierarchy: countries -> states -> districts -> subdistricts -> spots
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- 1. Reference Enums
DO $$ BEGIN
    CREATE TYPE subdivision_type_enum AS ENUM (
        'tehsil', 'taluk', 'block', 'mandal', 'revenue_division', 'circle'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE asi_protection_enum AS ENUM (
        'centrally', 'state', 'none'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE image_source_enum AS ENUM (
        'wikidata_p18', 'wikipedia_infobox', 'commons_category',
        'commons_search', 'osm_image_tag', 'commons_geoproximity'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE image_license_enum AS ENUM (
        'CC-BY', 'CC-BY-SA', 'CC0', 'PD'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- 2. Reference Hierarchy (strict FK chain)
CREATE TABLE IF NOT EXISTS countries (
    id SERIAL PRIMARY KEY,
    iso2 CHAR(2) NOT NULL UNIQUE DEFAULT 'IN',
    name VARCHAR(100) NOT NULL
);

CREATE TABLE IF NOT EXISTS states (
    id SERIAL PRIMARY KEY,
    country_id INT NOT NULL REFERENCES countries(id),
    name VARCHAR(100) NOT NULL,
    code VARCHAR(10) NOT NULL UNIQUE,
    census_2011_code VARCHAR(10),
    capital_name VARCHAR(100),
    capital_geo GEOGRAPHY(POINT, 4326),
    geometry GEOMETRY(MULTIPOLYGON, 4326),
    languages JSONB DEFAULT '[]'::jsonb,
    tourism_website TEXT,
    slug VARCHAR(120) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS districts (
    id SERIAL PRIMARY KEY,
    state_id INT NOT NULL REFERENCES states(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    census_2011_code VARCHAR(10),
    hq_name VARCHAR(100),
    hq_geo GEOGRAPHY(POINT, 4326),
    geometry GEOMETRY(MULTIPOLYGON, 4326),
    area_km2 NUMERIC(10, 2),
    population_2011 BIGINT,
    subdivision_type VARCHAR(50) DEFAULT 'district',
    slug VARCHAR(120) NOT NULL,
    UNIQUE(state_id, slug)
);

CREATE TABLE IF NOT EXISTS subdistricts (
    id SERIAL PRIMARY KEY,
    district_id INT NOT NULL REFERENCES districts(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    subdivision_type subdivision_type_enum,
    geometry GEOMETRY(MULTIPOLYGON, 4326),
    slug VARCHAR(120) NOT NULL
);

-- 3. Category Taxonomy (exhaustive, multilingual labels)
CREATE TABLE IF NOT EXISTS spot_categories (
    id SERIAL PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    name_en VARCHAR(100) NOT NULL,
    name_hi VARCHAR(100),
    parent_id INT REFERENCES spot_categories(id),
    description TEXT
);

-- 4. Core Entity: spots
CREATE TABLE IF NOT EXISTS spots (
    id BIGSERIAL PRIMARY KEY,
    district_id INT NOT NULL REFERENCES districts(id),
    state_id INT NOT NULL REFERENCES states(id),
    subdistrict_id INT REFERENCES subdistricts(id),
    name VARCHAR(255) NOT NULL,
    alt_names JSONB DEFAULT '{}'::jsonb,
    slug VARCHAR(280) NOT NULL UNIQUE,
    category_id INT REFERENCES spot_categories(id),
    subcategory VARCHAR(100),
    latitude NUMERIC(9, 6) NOT NULL,
    longitude NUMERIC(9, 6) NOT NULL,
    geo GEOGRAPHY(POINT, 4326) NOT NULL,
    osm_type VARCHAR(20),
    osm_id BIGINT,
    wikidata_qid VARCHAR(30) UNIQUE,
    geonames_id BIGINT,
    wikipedia_url TEXT,
    wikipedia_lang_urls JSONB DEFAULT '{}'::jsonb,
    description TEXT,
    description_lang VARCHAR(10) DEFAULT 'en',
    established_year INT,
    best_season VARCHAR(100),
    entry_fee_inr NUMERIC(10, 2),
    opening_hours VARCHAR(150),
    official_website TEXT,
    unesco_inscribed BOOLEAN DEFAULT FALSE,
    asi_protection_level asi_protection_enum DEFAULT 'none',
    prominence_score NUMERIC(6, 2) DEFAULT 0.0,
    image_filename TEXT,
    image_url TEXT,
    image_license VARCHAR(50),
    image_license_url TEXT,
    image_attribution TEXT,
    image_width INT,
    image_height INT,
    data_sources JSONB DEFAULT '[]'::jsonb,
    source_count SMALLINT DEFAULT 1,
    confidence NUMERIC(3, 2) DEFAULT 0.50,
    needs_review BOOLEAN DEFAULT FALSE,
    harvest_wave SMALLINT DEFAULT 1,
    first_seen_at TIMESTAMPTZ DEFAULT NOW(),
    last_verified_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Photos: one spot -> many
CREATE TABLE IF NOT EXISTS spot_images (
    id BIGSERIAL PRIMARY KEY,
    spot_id BIGINT NOT NULL REFERENCES spots(id) ON DELETE CASCADE,
    filename TEXT NOT NULL,
    source_url TEXT,
    source image_source_enum,
    license image_license_enum,
    license_url TEXT,
    attribution_text TEXT,
    author TEXT,
    width INT,
    height INT,
    is_primary BOOLEAN DEFAULT FALSE,
    sort_order SMALLINT DEFAULT 0
);

-- 6. Harvest Telemetry & Lineage
CREATE TABLE IF NOT EXISTS harvest_runs (
    id SERIAL PRIMARY KEY,
    wave SMALLINT NOT NULL,
    source VARCHAR(50) NOT NULL,
    started_at TIMESTAMPTZ NOT NULL,
    ended_at TIMESTAMPTZ,
    spots_yielded INT DEFAULT 0,
    errors INT DEFAULT 0,
    status VARCHAR(30) DEFAULT 'running'
);

CREATE TABLE IF NOT EXISTS spot_source_map (
    spot_id BIGINT NOT NULL REFERENCES spots(id) ON DELETE CASCADE,
    source VARCHAR(50) NOT NULL,
    source_ref TEXT NOT NULL,
    harvested_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY(spot_id, source)
);

-- 7. Quality Gates
CREATE TABLE IF NOT EXISTS quality_results (
    id SERIAL PRIMARY KEY,
    gate_name VARCHAR(100) NOT NULL,
    run_id INT REFERENCES harvest_runs(id),
    passed BOOLEAN NOT NULL,
    details JSONB
);

-- Mandatory Indexes
CREATE INDEX IF NOT EXISTS idx_states_geo ON states USING GIST(geometry);
CREATE INDEX IF NOT EXISTS idx_districts_geo ON districts USING GIST(geometry);
CREATE INDEX IF NOT EXISTS idx_spots_geo ON spots USING GIST(geo);
CREATE INDEX IF NOT EXISTS idx_spots_created_brin ON spots USING BRIN(created_at);
CREATE INDEX IF NOT EXISTS idx_spots_state_cat ON spots(state_id, category_id);
CREATE INDEX IF NOT EXISTS idx_spots_district_cat ON spots(district_id, category_id);
CREATE INDEX IF NOT EXISTS idx_spots_slug ON spots(slug);
CREATE INDEX IF NOT EXISTS idx_spots_name_trgm ON spots USING GIN(name gin_trgm_ops);
