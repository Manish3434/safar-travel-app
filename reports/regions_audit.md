# National Regions Audit Report: India States, Union Territories & Districts

**Date**: 2026-10-30  
**Authority Reference**: LGD & `igod.gov.in` (National Portal of India Open Data)  
**Reference File**: [`data/reference/regions_reference.csv`](file:///c:/Users/Manish/OneDrive/travel%20module/data/reference/regions_reference.csv)  
**Detailed Findings CSV**: [`reports/regions_audit.csv`](file:///c:/Users/Manish/OneDrive/travel%20module/reports/regions_audit.csv)  

---

## 1. Executive Summary & Core Counts

| Metric | Official LGD Reference | Current App Codebase | Match Status | Discrepancies |
| :--- | :---: | :---: | :---: | :--- |
| **States** | **28** | 28 | **MATCH** | 0 missing, 0 extra |
| **Union Territories** | **8** | 8 | **PARTIAL** | 4 UTs completely missing from backend `ALL_DISTRICTS_MAP` (`AN`, `CH`, `DN`, `LD`) |
| **Total Districts** | **784** | ~781 (in CSV) / ~700 (in TS) | **MISMATCH** | 17 missing newly notified districts; 4 renamed districts using outdated names |
| **Districts belonging to >1 State** | **0** | 0 | **PASSED** | Every district strictly has 1 parent State/UT |

> [!IMPORTANT]
> **Key Architecture Rule Enforced**: India consists strictly of **28 States + 8 Union Territories** (Total 36 administrative units), not 36 states. All entities in the codebase must explicitly classify each unit as either `state` or `union territory`.

---

## 2. Union Territories Audit (8 Expected)

| # | Union Territory Name | Code | In `data/states.csv`? | In Backend `ALL_DISTRICTS_MAP`? | Issue & Required Action |
| :-: | :--- | :-: | :---: | :---: | :--- |
| 1 | **Andaman and Nicobar Islands** | `AN` | `Andaman & Nicobar Islands` | ❌ **MISSING** | Ampersand mismatch; missing from backend dictionary; add 3 districts (`Nicobars`, `North and Middle Andaman`, `South Andamans`). |
| 2 | **Chandigarh** | `CH` | `Chandigarh` | ❌ **MISSING** | Missing from backend dictionary; add 1 district (`Chandigarh`). |
| 3 | **Dadra and Nagar Haveli and Daman and Diu** | `DN` | `Dadra & Nagar Haveli and Daman & Diu` | ❌ **MISSING** | Ampersand mismatch; missing from backend dictionary; add 3 districts (`Dadra and Nagar Haveli`, `Daman`, `Diu`). |
| 4 | **Delhi** | `DL` | `Delhi` | ⚠️ **INCOMPLETE** | Only 11 districts in code; missing `Central North` and `Old Delhi` (Total 13 districts per LGD). |
| 5 | **Jammu and Kashmir** | `JK` | `Jammu & Kashmir` | ⚠️ **MISCLASSIFIED** | Listed under 28 States in `india_states_districts.ts` instead of Union Territories; ampersand mismatch. |
| 6 | **Ladakh** | `LA` | `Ladakh` | ✅ Present | 2 districts (`Kargil`, `Leh`). |
| 7 | **Lakshadweep** | `LD` | `Lakshadweep` | ❌ **MISSING** | Missing from backend dictionary; add 1 district (`Lakshadweep`). |
| 8 | **Puducherry** | `PY` | `Puducherry` | ⚠️ **STRUCTURE** | Lists 4 entries (`Puducherry`, `Karaikal`, `Mahe`, `Yanam`) whereas LGD official revenue districts are 2 (`Karaikal`, `Puducherry`). |

---

## 3. States Audit (28 Expected)

All 28 States are recognized. The following specific district mismatches were identified against the official LGD baseline:

| State | Official LGD Count | Code Count | Status | Specific District Findings & Action Required |
| :--- | :---: | :---: | :---: | :--- |
| **Andhra Pradesh** | 28 | 26 | ⚠️ Under-reported | Missing **Markapuram** and **Polavaram**. Update count from 26 to 28. |
| **Arunachal Pradesh** | 27 | 25 | ⚠️ Under-reported | Missing newly created **Bichom** and **Keyi Panyor**. |
| **Assam** | 35 | 33 | ⚠️ Under-reported | Missing **Bajali** and **Tamulpur**; **Karimganj** renamed to official **Sribhumi**. |
| **Goa** | 3 | 2 | ⚠️ Under-reported | Missing newly notified 3rd district **Kushavati**. |
| **Gujarat** | 34 | 33 | ⚠️ Under-reported | Missing newly formed **Vav-Tharad**. |
| **Haryana** | 23 | 22 | ⚠️ Under-reported | Missing **Hansi**. |
| **Madhya Pradesh** | 55 | 52 | ⚠️ Under-reported | Missing newly created **Maihar**, **Mauganj**, and **Pandhurna**. |
| **Maharashtra** | 36 | 36 | ⚠️ Outdated Names | Contains 3 outdated colonial/pre-renaming names: <br>• `Ahmednagar` $\to$ **Ahilyanagar**<br>• `Aurangabad` $\to$ **Chhatrapati Sambhajinagar**<br>• `Osmanabad` $\to$ **Dharashiv** |
| **Nagaland** | 17 | 16 | ⚠️ Under-reported | Missing newly formed **Meluri**. |
| **Rajasthan** | 41 | 50 | ⚠️ Draft Overcount | Current backend draft contains 50 districts; LGD official consolidated list has 41 districts. |
| **Sikkim** | 6 | 4 | ⚠️ Outdated Names | Uses old directional names (`East Sikkim`, etc.); missing newly formed **Pakyong** and **Soreng**. Official names are **Gangtok**, **Gyalshing**, **Mangan**, **Namchi**, **Pakyong**, **Soreng**. |

---

## 4. Code Locations & Impact Analysis

### 1. Backend Hardcoded Dictionary
- **File**: [`apps/backend/src/places/data/india_states_districts.ts`](file:///c:/Users/Manish/OneDrive/travel%20module/apps/backend/src/places/data/india_states_districts.ts)
  - `INDIAN_STATES` array: missing explicit `type: 'state' | 'union_territory'`.
  - `ALL_DISTRICTS_MAP` (lines 1230–1263): Missing entries for `AN`, `CH`, `DN`, `LD`.
  - Hardcoded district arrays for AP, AR, AS, GA, GJ, HR, MP, NL, SK missing recent districts.

### 2. Backend Service & Mock Provider
- **File**: [`apps/backend/src/providers/places/mock-places.provider.ts`](file:///c:/Users/Manish/OneDrive/travel%20module/apps/backend/src/providers/places/mock-places.provider.ts)
  - Serves static in-memory lists instead of querying canonical PostgreSQL `states` and `districts` tables.

### 3. Database Seed & Baseline Data Files
- **Files**: [`data/states.csv`](file:///c:/Users/Manish/OneDrive/travel%20module/data/states.csv), [`data/districts.csv`](file:///c:/Users/Manish/OneDrive/travel%20module/data/districts.csv)
  - Need regeneration from [`data/reference/regions_reference.csv`](file:///c:/Users/Manish/OneDrive/travel%20module/data/reference/regions_reference.csv) to include stable LGD codes, official English names, aliases, and explicit `type` column.

### 4. Flutter Mobile App
- **Files**:
  - [`apps/mobile/lib/core/network/api_endpoints.dart`](file:///c:/Users/Manish/OneDrive/travel%20module/apps/mobile/lib/core/network/api_endpoints.dart): References `/api/v1/places/states` and `/api/v1/places/states/:code/districts`. We will add canonical `/api/v1/regions/states` and `/api/v1/regions/states/:stateId/districts` routes with fallback compatibility.
  - [`apps/mobile/lib/features/search/repositories/places_repository.dart`](file:///c:/Users/Manish/OneDrive/travel%20module/apps/mobile/lib/features/search/repositories/places_repository.dart): Clean architecture repository consuming state and district endpoints. Needs local Hive/SQLite offline cache to function without internet in remote villages (Rule 10 & 13).

---

## 5. Remediation Plan (Ready for Execution Upon Your Approval)

### Step 2: Database Schema & Idempotent Seeding
1. Create `State` and `District` TypeORM entities in `apps/backend/src/regions/entities/` with:
   - `lgd_code` (Stable Primary Key)
   - `name` (Official English name)
   - `name_local` (JSONB: Tamil, Hindi, Telugu, Marathi, etc.)
   - `aliases` (Array of alternate spellings, e.g. `["Bangalore", "Bengaluru"]`, `["Ahmednagar", "Ahilyanagar"]`)
   - `type` (`'state'` or `'union_territory'`)
   - `active` (`true`)
   - `source` (`'LGD/igod.gov.in'`)
   - `fetched_at` (`2026-10-30T09:22:00Z`)
2. Write idempotent SQL seed script reading `data/reference/regions_reference.csv` (`ON CONFLICT (lgd_code) DO UPDATE`).

### Step 4: Fix Hardcoded Lists with Single Source of Truth
1. Create `RegionsModule` with:
   - `GET /v1/regions/states` (Cached in Redis, returns 28 states + 8 UTs with type classification).
   - `GET /v1/regions/states/:stateId/districts` (Returns canonical districts with aliases).
   - Support `?search=` parameter with `pg_trgm` fuzzy matching across aliases.
2. Update `india_states_districts.ts` to match the exact 784 districts and all 36 entities so mock mode is also 100% compliant.
3. Add offline cache in Flutter mobile app.

### Step 5: Verification Tests & CI Check
1. Automated backend test verifying:
   - Exactly 28 states + 8 UTs.
   - Exactly 784 districts.
   - 0 missing, 0 extra, 0 duplicates.
   - Every district references exactly 1 valid state.
2. GitHub Actions CI workflow checking database against `regions_reference.csv`.

---

## 6. Execution & Verification Sign-Off (COMPLETED)

All remediation steps have been executed and verified across backend, database, mobile app, and CI workflows:

| Deliverable | Implementation Location | Verified Status |
| :--- | :--- | :---: |
| **Canonical Dataset** | [`data/reference/regions_reference.csv`](file:///c:/Users/Manish/OneDrive/travel%20module/data/reference/regions_reference.csv) | **784 districts, 36 States/UTs (100% Match)** |
| **TypeORM Entities** | [`State`](file:///c:/Users/Manish/OneDrive/travel%20module/apps/backend/src/regions/entities/state.entity.ts), [`District`](file:///c:/Users/Manish/OneDrive/travel%20module/apps/backend/src/regions/entities/district.entity.ts) | **Complete with PK, FK, indexes & local JSONB** |
| **DB Migration** | [`1700000000002-CreateRegionsTables.ts`](file:///c:/Users/Manish/OneDrive/travel%20module/apps/backend/src/database/migrations/1700000000002-CreateRegionsTables.ts) | **Ready with UP/DOWN queries & constraints** |
| **Idempotent Seed** | [`seed-regions.ts`](file:///c:/Users/Manish/OneDrive/travel%20module/apps/backend/src/database/seeds/seed-regions.ts) (`npm run seed:regions`) | **Tested ON CONFLICT DO UPDATE** |
| **REST API Endpoints** | [`RegionsController`](file:///c:/Users/Manish/OneDrive/travel%20module/apps/backend/src/regions/regions.controller.ts) (`GET /v1/regions/states`, `GET /v1/regions/states/:id/districts`) | **Registered with Redis 1h TTL caching** |
| **Backend Mock Baseline** | [`india_states_districts.ts`](file:///c:/Users/Manish/OneDrive/travel%20module/apps/backend/src/places/data/india_states_districts.ts) | **Synchronized all 36 entities & 784 districts** |
| **Flutter Mobile App** | [`PlacesRepositoryImpl`](file:///c:/Users/Manish/OneDrive/travel%20module/apps/mobile/lib/features/search/repositories/places_repository.dart) & [`ApiEndpoints`](file:///c:/Users/Manish/OneDrive/travel%20module/apps/mobile/lib/core/network/api_endpoints.dart) | **Offline SharedPreferences cache active** |
| **Automated Tests** | [`regions.service.spec.ts`](file:///c:/Users/Manish/OneDrive/travel%20module/apps/backend/src/regions/regions.service.spec.ts) | **Passes 28 states, 8 UTs, 0 duplicate tests** |
| **CI Automation** | [`.github/workflows/verify-regions.yml`](file:///c:/Users/Manish/OneDrive/travel%20module/.github/workflows/verify-regions.yml) | **Runs Python audit validator on push & PR** |

### Verification SQL Query (for PostgreSQL verification):
```sql
SELECT 
  s.type,
  s.code AS state_code,
  s.name AS state_name,
  COUNT(d.lgd_code) AS total_districts
FROM states s
LEFT JOIN districts d ON d.state_code = s.code
GROUP BY s.type, s.code, s.name
ORDER BY s.type ASC, s.name ASC;
```
Expected output: Exactly 28 states, 8 union territories, and 784 total districts.

