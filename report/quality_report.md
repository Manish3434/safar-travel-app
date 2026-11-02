# Production Data Quality Audit Report
**Specification**: Principal-Engineer Data Platform Specification (v3.0)  
**Run Mode**: Goa Smoke Test Fixture (Waves 0–6)  
**Timestamp**: 2026-10-29T22:40:00+05:30  
**Overall Verdict**: **ALL GATES PASSED (100%)**

---

## 1. Quality Gates Scorecard

| Gate | Name | Assertion Rule | Tested Rows | Failures | Status |
| :---: | :--- | :--- | :---: | :---: | :---: |
| **G1** | NOT NULL Check | `spots.name`, `spots.geo`, `spots.district_id` NOT NULL | 20 | 0 | **PASS** |
| **G2** | Uniqueness Check | `UNIQUE(wikidata_qid)`, `UNIQUE(slug)` | 20 | 0 | **PASS** |
| **G3** | FK Integrity | `spots.district_id ∈ districts.id`, `spots.state_id ∈ states.id` | 20 | 0 | **PASS** |
| **G4** | Spatial Bounding | `ST_Contains(district.geometry, spot.geo)` | 20 | 0 | **PASS** |
| **G5** | Coordinate Envelope | `lat ∈ [6.5, 37.5]`, `lon ∈ [68.0, 97.5]` | 20 | 0 | **PASS** |
| **G6** | Taxonomy & Enum | `category_id ∈ spot_categories`, `license ∈ {CC-BY, CC-BY-SA, CC0, PD}` | 20 | 0 | **PASS** |
| **G7** | Statistical Anomaly | Spot count per district within expected threshold | 2 districts | 0 | **PASS** |
| **G8** | Image Disk Integrity | Every `image_filename` matches file on disk; zero orphaned image files | 19 files | 0 | **PASS** |
| **G9** | License Attribution Audit | 100% of images have `license_url` and author populated | 19 images | 0 | **PASS** |

---

## 2. Statistical Findings & Coverage Analysis
- **Total Spots**: 20
- **Districts Evaluated**: 2 / 2 (North Goa: 10, South Goa: 10)
- **District Zero-Defect Rate**: 100% (No district with zero spots).
- **Photo Coverage**: 19 / 20 = **95.0%** (Exceeds contract target of $\ge 70\%$).
- **Multi-Source Union Depth**: Average **4.9 sources per spot** (OSM, Wikidata, Wikipedia, ASI, UNESCO, State Tourism, MoEFCC).
- **Unlicensed / Stock Photo Rejections**: 1 spot (*Mormugao Fort*) lacked open-license Commons media; `image_filename` left empty and queued in `data/needs_review.csv` (Zero data fabrication).
