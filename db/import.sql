-- ============================================================================
-- INDIA TRAVEL SPOTS — POSTGIS IMPORT & EXPLAIN ANALYZE VERIFICATION
-- ============================================================================

-- 1. Import Reference Data
\copy countries(id, iso2, name) FROM 'data/countries.csv' WITH (FORMAT csv, HEADER true);
\copy states(id, country_id, name, code, census_2011_code, capital_name, capital_lat, capital_lon, languages, slug) FROM 'data/states.csv' WITH (FORMAT csv, HEADER true);
\copy districts(id, state_id, state_code, name, census_2011_code, hq_name, area_km2, population_2011, subdivision_type, slug) FROM 'data/districts.csv' WITH (FORMAT csv, HEADER true);
\copy spot_categories(id, code, name_en, name_hi, parent_code) FROM 'data/spot_categories.csv' WITH (FORMAT csv, HEADER true);

-- 2. Populate Geometry Columns
UPDATE states SET capital_geo = ST_SetSRID(ST_MakePoint(capital_lon, capital_lat), 4326)::geography WHERE capital_lat IS NOT NULL;

-- 3. Import Core Spots
\copy spots(id, district_id, state_id, subdistrict_id, name, alt_names, slug, category_id, subcategory, latitude, longitude, geo, osm_type, osm_id, wikidata_qid, geonames_id, wikipedia_url, wikipedia_lang_urls, description, description_lang, established_year, best_season, entry_fee_inr, opening_hours, official_website, unesco_inscribed, asi_protection_level, prominence_score, image_filename, image_url, image_license, image_license_url, image_attribution, image_width, image_height, data_sources, source_count, confidence, needs_review, harvest_wave, first_seen_at, last_verified_at, created_at, updated_at) FROM 'data/spots.csv' WITH (FORMAT csv, HEADER true);

-- 4. Import Images and Evidence Lineage
\copy spot_images(id, spot_id, filename, source_url, source, license, license_url, attribution_text, author, width, height, is_primary, sort_order) FROM 'data/spot_images.csv' WITH (FORMAT csv, HEADER true);
\copy spot_source_map(spot_id, source, source_ref, harvested_at) FROM 'data/spot_source_map.csv' WITH (FORMAT csv, HEADER true);

-- ============================================================================
-- POST-IMPORT SANITY & QUALITY VERIFICATION QUERIES
-- ============================================================================

-- Check A: Total spot counts
SELECT COUNT(*) AS total_spots, COUNT(DISTINCT wikidata_qid) AS unique_qids, COUNT(image_filename) AS photos_present FROM spots;

-- Check B: Zero Orphan Spots (FK integrity)
SELECT COUNT(*) AS orphan_spots FROM spots s LEFT JOIN districts d ON s.district_id = d.id WHERE d.id IS NULL;

-- Check C: Zero Null Geo
SELECT COUNT(*) AS null_geo_spots FROM spots WHERE geo IS NULL;

-- ============================================================================
-- MANDATORY PERFORMANCE EXPLAIN ANALYZE QUERIES
-- ============================================================================

-- Query 1: Spots in a state (Index scan on idx_spots_state_cat)
EXPLAIN ANALYZE
SELECT s.id, s.name, s.slug, c.name_en AS category, s.prominence_score, s.image_filename
FROM spots s
JOIN states st ON s.state_id = st.id
LEFT JOIN spot_categories c ON s.category_id = c.id
WHERE st.code = 'GA'
ORDER BY s.prominence_score DESC;

-- Query 2: Spatial Proximity: spots within 50km of Panaji (ST_DWithin on idx_spots_geo)
EXPLAIN ANALYZE
SELECT s.id, s.name, s.latitude, s.longitude,
       ROUND((ST_Distance(s.geo, ST_SetSRID(ST_MakePoint(73.8278, 15.4909), 4326)::geography) / 1000.0)::numeric, 2) AS distance_km
FROM spots s
WHERE ST_DWithin(s.geo, ST_SetSRID(ST_MakePoint(73.8278, 15.4909), 4326)::geography, 50000)
ORDER BY distance_km ASC;

-- Query 3: Top-100 National Spots by Prominence
EXPLAIN ANALYZE
SELECT s.id, s.name, d.name AS district, st.name AS state, s.prominence_score, s.confidence
FROM spots s
JOIN districts d ON s.district_id = d.id
JOIN states st ON s.state_id = st.id
ORDER BY s.prominence_score DESC
LIMIT 100;
