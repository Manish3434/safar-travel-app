# Safar India-Wide Travel Spots Pipeline (v0.6)

An automated, repeatable, and crash-resumable data collection pipeline that harvests travel spots for **every district of all 36 States and Union Territories of India** (~784 districts). For each district, the pipeline discovers at least 10 real tourist spots, resolves verified coordinates, fetches legally licensed media, validates topological boundaries, and populates PostgreSQL/PostGIS.

---

## 1. Quickstart: The Single Run Command

To start the full nationwide sweep across all 36 states and 784 districts in computed South-to-North geographic sequence:

```bash
# 1. Start PostGIS and Redis (if not already running)
docker-compose up -d

# 2. Run the nationwide pipeline sweep
python data-pipeline/cli.py run --all
```

---

## 2. How to Watch Progress

The pipeline outputs real-time standardized logs in the terminal with geographic progress context:

```
[2026-10-30 12:00:15] [State 7 of 36 | District 2 of 2 | South Goa] INFO: Starting harvest for South Goa (Goa) [LGD: 586]
[2026-10-30 12:00:22] [State 7 of 36 | District 2 of 2 | South Goa] SUCCESS: Finished South Goa: 10 verified spots, 10/10 with photos (Pool Widened: False). Status: DONE
=== Entering State 8 of 36: Andhra Pradesh (26 Districts) ===
```

To view a live national status summary at any time from another terminal:

```bash
python data-pipeline/cli.py status
```

---

## 3. How to Resume After a Stop

The pipeline is completely stateful and crash-resilient. Each district's state is persisted in the database (`pending`, `running`, `done`, `images_pending`, `below_target`, `needs_review`, `failed`).

If the process is stopped (`Ctrl+C`, network failure, system reboot), simply re-run:

```bash
# Automatically resumes from the exact district where it left off
python data-pipeline/cli.py run --all
```

To retry any districts that were flagged as `needs_review` or `failed`:

```bash
python data-pipeline/cli.py retry --failed
```

---

## 4. The 8-Pass Search Architecture (v0.6)

The pipeline guarantees that no district is ever marked "below target" without exhausting 8 rigorous search passes:

1. **Pass 1: Structured Open Data**: Overpass OSM (`tourism`, `historic`, `leisure`, `amenity`), Wikidata SPARQL, ASI National Monuments, and MoEFCC Wildlife Registries.
2. **Pass 2: Wikipedia & Sister Projects**: Multilingual article extraction (`en`, `hi`, `ta`, `te`, `kn`, `ml`, `mr`), Wikivoyage travel guides, and district subplace lists.
3. **Pass 3: Sub-District Sweep**: Recursively queries tehsils, taluks, mandals, and blocks to uncover inland and rural spots.
4. **Pass 4: Taxonomy Category Sweep**: 15 distinct categories with regional vernacular synonyms (e.g., *Kottai*, *Kote*, *Gadi* for forts; *Kund*, *Eri*, *Cheruvu* for stepwells).
5. **Pass 5: Web Discovery & Snowballing**: Licensed web discovery API scanning top 20 query results and snowballing outward from known landmark centroids.
6. **Pass 6: Natural & Cultural Deep Scan**: Scans geological features (peaks, waterfalls, caves, river confluences, reserved forests).
7. **Pass 7: Targeted Gap Analysis & Leads**: Historical/colonial name variations, vernacular alternate spellings, and Google Place ID pointers.
8. **Pass 8: Local-Interest Places & Below-Target Transition**: Civic parks, prominent community landmarks, and formal below-target transition audit logging.

### Image Passes (I1 to I7)
Strict whitelist: `CC0`, `Public Domain`, `CC-BY`, `CC-BY-SA`.  
Strict rejection: Any license containing `-NC` (Non-Commercial) or `-ND` (No Derivatives).  
Candidate pool widening: If verified spots $\ge 10$ but licensed photos $< 10$, candidate pool widens to ranks 11–50.  
Google Places photos: Handled as view-time photo pointers (`google_place_id` reference only, with mandatory attribution; image bytes are never stored locally).

---

## 5. CLI Commands Reference

| Command | Action |
| :--- | :--- |
| `python data-pipeline/cli.py run --all` | Runs full nationwide sweep from South to North |
| `python data-pipeline/cli.py run --next` | Runs exactly the next pending district and pauses |
| `python data-pipeline/cli.py run --state TN` | Runs all districts of a specific state (e.g. Tamil Nadu) |
| `python data-pipeline/cli.py run --district 586` | Runs a single district by LGD code or name |
| `python data-pipeline/cli.py status` | Shows nationwide progress breakdown across all 7 statuses |
| `python data-pipeline/cli.py retry --failed` | Retries all `failed` and `needs_review` districts |
| `python data-pipeline/cli.py report --state GA` | Generates detailed Markdown summary report for a state |
| `python data-pipeline/cli.py test-smoke` | Runs automated smoke test across 3 archetypes (South Goa, Ariyalur, Nicobar) |
| `python data-pipeline/cli.py sweep --order south_to_north` | Recomputes geographic sweep order to `config/sweep_order.yaml` |

---

## 6. SQL Verification Queries

Run these queries to audit pipeline results:

### 1. Overall Progress & Status Breakdown
```sql
SELECT 
    status, 
    COUNT(*) AS total_districts,
    SUM(spots_verified) AS verified_spots,
    SUM(images_collected) AS total_photos
FROM district_runs 
GROUP BY status 
ORDER BY total_districts DESC;
```

### 2. Below-Target Districts with Attempt Log Audit
```sql
SELECT 
    state_code, 
    district_code, 
    district_name, 
    spots_verified, 
    passes_completed,
    jsonb_array_length(attempt_log) AS passes_logged
FROM district_runs 
WHERE status = 'below_target'
ORDER BY state_code, district_name;
```

### 3. Districts with Images Pending (Eligible for Candidate Pool Widening)
```sql
SELECT 
    state_code, 
    district_name, 
    spots_verified, 
    images_collected
FROM district_runs 
WHERE status = 'images_pending'
ORDER BY spots_verified DESC;
```

### 4. License Compliance Audit (100% must be CC-BY, CC-BY-SA, CC0, or PD — Zero NC/ND)
```sql
SELECT 
    license, 
    COUNT(*) AS image_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage
FROM spot_images
GROUP BY license
ORDER BY image_count DESC;
```

### 5. Sensitive Spots Masking Audit (Rule 8)
```sql
SELECT 
    name, 
    district_code, 
    latitude, 
    longitude, 
    verification_level
FROM local_spots
WHERE verification_level = 'sensitive_masked';
```
