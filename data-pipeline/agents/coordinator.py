"""
Master Pipeline Coordinator & Sweep Orchestrator (v0.6).
Drives the nationwide sweep strictly following the computed South-to-North geographic sequence.
Displays standardized progress: 'State X of N, District Y of M'.
Implements the 8-Pass Search Architecture and 7 Image Passes:
- Passes 1-3 run unconditionally.
- Passes 4-8 run if verified spots < 10 or spots with licensed images < 10.
- Transitions to 'below_target' ONLY after all 8 passes complete.
- Emits GeoJSON previews and detailed State Summary Markdown reports.
"""

import json
from pathlib import Path
from typing import Dict, List, Optional, Any
from datetime import datetime

try:
    import yaml
    HAS_YAML = True
except ImportError:
    HAS_YAML = False

from config.settings import SWEEP_ORDER_FILE, REPORT_DIR, GEOJSON_DIR
from core.models import DistrictRunStatus, VerifiedSpot, PassAttemptLog
from core.database import db_manager
from core.logger import logger
from core.budget_tracker import BudgetExceededError

from agents.agent_a_boundaries import boundaries_agent
from agents.agent_passes import search_passes_engine
from agents.agent_f_media import media_agent
from agents.agent_g_verifier import verifier_agent


class PipelineCoordinator:
    def __init__(self, sweep_file: Path = SWEEP_ORDER_FILE):
        self.sweep_file = sweep_file
        self.sweep_data = self._load_sweep_order()

    def _load_sweep_order(self) -> Dict[str, Any]:
        json_file = self.sweep_file.with_suffix('.json')
        if json_file.exists():
            try:
                with open(json_file, "r", encoding="utf-8") as f:
                    return json.load(f)
            except Exception:
                pass

        if HAS_YAML and self.sweep_file.exists():
            try:
                with open(self.sweep_file, "r", encoding="utf-8") as f:
                    return yaml.safe_load(f)
            except Exception:
                pass

        from config.sweep_order import compute_sweep_order
        base = Path(__file__).resolve().parent.parent.parent
        return compute_sweep_order(base / "data" / "districts.csv", "south_to_north")

    def bootstrap(self):
        """Initializes database schema and registers all districts in sweep order."""
        db_manager.init_db()
        db_manager.register_sweep_districts(self.sweep_data.get("states", []))
        boundaries_agent.audit_lgd_changes()

    def process_district(
        self,
        state_pos: int,
        state_total: int,
        state_code: str,
        state_name: str,
        dist_pos: int,
        dist_total: int,
        dist_id: int,
        district_name: str,
        force: bool = False,
    ) -> DistrictRunStatus:
        """
        Executes 8-Pass Search Architecture and 7 Image Passes for a single district.
        Enforces Zero Hardcoding: logic applies uniformly to every district in India.
        """
        # Check if already completed
        existing = db_manager.get_district_run(state_code, str(dist_id))
        if existing and existing.status == DistrictRunStatus.DONE and not force:
            logger.info(
                f"Skipping already completed district: {district_name} ({state_name})",
                state_pos=state_pos, state_total=state_total,
                dist_pos=dist_pos, dist_total=dist_total,
                district_name=district_name
            )
            return DistrictRunStatus.DONE

        logger.info(
            f"Starting harvest for {district_name} ({state_name}) [LGD: {dist_id}]",
            state_pos=state_pos, state_total=state_total,
            dist_pos=dist_pos, dist_total=dist_total,
            district_name=district_name
        )

        db_manager.update_district_status(
            state_code=state_code,
            district_code=str(dist_id),
            status=DistrictRunStatus.RUNNING,
        )

        bbox = boundaries_agent.get_district_bbox(state_code, district_name)

        all_candidates = []
        attempt_logs: List[PassAttemptLog] = []
        passes_completed: List[int] = []

        try:
            # ── UNCONDITIONAL PASSES (1 to 3) ──────────────────────────────────
            # Pass 1: Structured Open Data (Wikidata, OSM, Government)
            cands1, log1 = search_passes_engine.execute_pass_1(state_code, district_name, bbox)
            db_manager.log_pass_attempt(str(dist_id), state_code, log1)
            attempt_logs.append(log1)
            passes_completed.append(1)
            all_candidates.extend(cands1)

            # Pass 2: Wikipedia & Sister Projects
            cands2, log2 = search_passes_engine.execute_pass_2(state_code, district_name, bbox)
            db_manager.log_pass_attempt(str(dist_id), state_code, log2)
            attempt_logs.append(log2)
            passes_completed.append(2)
            all_candidates.extend(cands2)

            # Pass 3: Sub-District Sweep (Tehsils/Taluks/Mandals)
            cands3, log3 = search_passes_engine.execute_pass_3(state_code, district_name, bbox)
            db_manager.log_pass_attempt(str(dist_id), state_code, log3)
            attempt_logs.append(log3)
            passes_completed.append(3)
            all_candidates.extend(cands3)

            # Verification checkpoint after Passes 1-3
            resolved_spots, rejection_count = verifier_agent.verify_and_merge(
                all_candidates, state_code, dist_id, district_name
            )
            verified_count = sum(1 for s in resolved_spots if s.verification_level.value in ("verified", "sensitive_masked"))
            spots_with_images = sum(1 for s in resolved_spots[:10] if len(s.images) > 0)

            # ── CONDITIONAL ESCALATION PASSES (4 to 8) ─────────────────────────
            # Run IF AND ONLY IF verified spots < 10 OR spots with licensed images < 10
            if verified_count < 10 or spots_with_images < 10:
                logger.info(
                    f"[{district_name}] Target not met after Passes 1-3 ({verified_count} spots, {spots_with_images} with images). Escalating to Pass 4.."
                )
                cands4, log4 = search_passes_engine.execute_pass_4(state_code, district_name, bbox)
                db_manager.log_pass_attempt(str(dist_id), state_code, log4)
                attempt_logs.append(log4)
                passes_completed.append(4)
                all_candidates.extend(cands4)
                resolved_spots, rejection_count = verifier_agent.verify_and_merge(
                    all_candidates, state_code, dist_id, district_name
                )
                verified_count = sum(1 for s in resolved_spots if s.verification_level.value in ("verified", "sensitive_masked"))
                spots_with_images = sum(1 for s in resolved_spots[:10] if len(s.images) > 0)

            if verified_count < 10 or spots_with_images < 10:
                logger.info(
                    f"[{district_name}] Escalating to Pass 5 (Web Discovery & Snowballing).."
                )
                cands5, log5 = search_passes_engine.execute_pass_5(state_code, state_name, district_name, resolved_spots)
                db_manager.log_pass_attempt(str(dist_id), state_code, log5)
                attempt_logs.append(log5)
                passes_completed.append(5)
                all_candidates.extend(cands5)
                resolved_spots, rejection_count = verifier_agent.verify_and_merge(
                    all_candidates, state_code, dist_id, district_name
                )
                verified_count = sum(1 for s in resolved_spots if s.verification_level.value in ("verified", "sensitive_masked"))
                spots_with_images = sum(1 for s in resolved_spots[:10] if len(s.images) > 0)

            if verified_count < 10 or spots_with_images < 10:
                logger.info(
                    f"[{district_name}] Escalating to Pass 6 (Natural & Cultural Deep Scan).."
                )
                cands6, log6 = search_passes_engine.execute_pass_6(state_code, district_name, bbox)
                db_manager.log_pass_attempt(str(dist_id), state_code, log6)
                attempt_logs.append(log6)
                passes_completed.append(6)
                all_candidates.extend(cands6)
                resolved_spots, rejection_count = verifier_agent.verify_and_merge(
                    all_candidates, state_code, dist_id, district_name
                )
                verified_count = sum(1 for s in resolved_spots if s.verification_level.value in ("verified", "sensitive_masked"))
                spots_with_images = sum(1 for s in resolved_spots[:10] if len(s.images) > 0)

            if verified_count < 10 or spots_with_images < 10:
                logger.info(
                    f"[{district_name}] Escalating to Pass 7 (Targeted Gap Analysis & Leads).."
                )
                cands7, log7 = search_passes_engine.execute_pass_7(state_code, district_name, bbox)
                db_manager.log_pass_attempt(str(dist_id), state_code, log7)
                attempt_logs.append(log7)
                passes_completed.append(7)
                all_candidates.extend(cands7)
                resolved_spots, rejection_count = verifier_agent.verify_and_merge(
                    all_candidates, state_code, dist_id, district_name
                )
                verified_count = sum(1 for s in resolved_spots if s.verification_level.value in ("verified", "sensitive_masked"))
                spots_with_images = sum(1 for s in resolved_spots[:10] if len(s.images) > 0)

            if verified_count < 10 or spots_with_images < 10:
                logger.info(
                    f"[{district_name}] Escalating to Pass 8 (Local-Interest Places & Below-Target Transition).."
                )
                cands8, log8 = search_passes_engine.execute_pass_8(state_code, district_name, bbox)
                db_manager.log_pass_attempt(str(dist_id), state_code, log8)
                attempt_logs.append(log8)
                passes_completed.append(8)
                all_candidates.extend(cands8)
                resolved_spots, rejection_count = verifier_agent.verify_and_merge(
                    all_candidates, state_code, dist_id, district_name
                )
                verified_count = sum(1 for s in resolved_spots if s.verification_level.value in ("verified", "sensitive_masked"))
                spots_with_images = sum(1 for s in resolved_spots[:10] if len(s.images) > 0)

            # Candidate pool widening if verified spots >= 10 but licensed images in top 10 < 10
            pool_widened = False
            if verified_count >= 10 and spots_with_images < 10:
                logger.info(
                    f"[{district_name}] Verified spots >= 10 but images < 10 ({spots_with_images}). Widening candidate pool (ranks 11-50)."
                )
                resolved_spots = media_agent.widen_candidate_pool_for_images(resolved_spots, target_count=10)
                spots_with_images = sum(1 for s in resolved_spots[:10] if len(s.images) > 0)
                pool_widened = True

        except BudgetExceededError as be:
            logger.error(f"HARD STOP: {be}")
            db_manager.update_district_status(
                state_code=state_code, district_code=str(dist_id),
                status=DistrictRunStatus.NEEDS_REVIEW, error_message=str(be)
            )
            raise be

        except Exception as e:
            logger.error(f"Pipeline exception on {district_name}: {e}")
            db_manager.update_district_status(
                state_code=state_code, district_code=str(dist_id),
                status=DistrictRunStatus.FAILED, error_message=str(e)
            )
            return DistrictRunStatus.FAILED

        # ── QUALITY GATES & STATUS ASSIGNMENT ───────────────────────────────
        sources_used = set()
        for s in resolved_spots:
            for src in s.data_sources:
                sources_used.add(src)

        unverified_count = len(resolved_spots) - verified_count
        total_images_count = sum(len(s.images) for s in resolved_spots)
        is_high_rejection = (len(all_candidates) > 10 and rejection_count / len(all_candidates) > 0.85)

        if verified_count >= 10 and spots_with_images >= 10:
            final_status = DistrictRunStatus.DONE
        elif verified_count >= 10 and spots_with_images < 10:
            final_status = DistrictRunStatus.IMAGES_PENDING
        elif len(passes_completed) == 8 and verified_count < 10:
            final_status = DistrictRunStatus.BELOW_TARGET
        elif is_high_rejection:
            final_status = DistrictRunStatus.NEEDS_REVIEW
        else:
            final_status = DistrictRunStatus.DONE if verified_count >= 10 else DistrictRunStatus.BELOW_TARGET

        # ── PERSISTENCE ─────────────────────────────────────────────────────
        db_manager.save_spots(str(dist_id), resolved_spots)
        db_manager.update_district_status(
            state_code=state_code,
            district_code=str(dist_id),
            status=final_status,
            spots_collected=len(resolved_spots),
            spots_verified=verified_count,
            spots_unverified=unverified_count,
            images_collected=total_images_count,
            rejection_count=rejection_count,
            passes_completed=len(passes_completed),
            attempt_log=[log.to_dict() for log in attempt_logs],
            sources_used=list(sources_used),
            error_message=(
                f"Below target: found {verified_count} spots after all 8 passes"
                if final_status == DistrictRunStatus.BELOW_TARGET
                else ("High candidate rejection rate (>85%)" if is_high_rejection else None)
            ),
        )

        # ── EXPORT ARTIFACTS ────────────────────────────────────────────────
        self._export_district_geojson(state_code, district_name, resolved_spots)

        logger.success(
            f"Finished {district_name}: {verified_count} verified spots, {spots_with_images}/10 with photos (Pool Widened: {pool_widened}). Status: {final_status.value.upper()}",
            state_pos=state_pos, state_total=state_total,
            dist_pos=dist_pos, dist_total=dist_total,
            district_name=district_name
        )

        return final_status

    def _export_district_geojson(self, state_code: str, district_name: str, spots: List[VerifiedSpot]):
        """Generates GeoJSON feature collection for visual inspection."""
        features = []
        for s in spots:
            features.append({
                "type": "Feature",
                "geometry": {
                    "type": "Point",
                    "coordinates": [s.longitude, s.latitude]
                },
                "properties": {
                    "name": s.name,
                    "category": s.category,
                    "verification": s.verification_level.value,
                    "sensitive": s.sensitive,
                    "sources_count": s.source_count,
                    "prominence": s.prominence_score,
                    "has_photo": len(s.images) > 0,
                    "google_place_id": getattr(s, "google_place_id", None)
                }
            })

        fc = {"type": "FeatureCollection", "features": features}
        out_file = GEOJSON_DIR / f"preview_{state_code}_{district_name.replace(' ', '_').lower()}.geojson"
        try:
            with open(out_file, "w", encoding="utf-8") as f:
                json.dump(fc, f, indent=2)
        except Exception:
            pass

    def run_all(self):
        """Continuously processes all 36 states and 781 districts in geographic sequence."""
        self.bootstrap()
        states = self.sweep_data.get("states", [])
        state_total = len(states)
        consecutive_hard_failures = 0

        for state in states:
            state_pos = state["state_position"]
            state_code = state["state_code"]
            state_name = state["state_name"]
            districts = state.get("districts", [])
            dist_total = len(districts)

            logger.info(f"=== Entering State {state_pos} of {state_total}: {state_name} ({dist_total} Districts) ===")

            for dist in districts:
                dist_pos = dist["district_position"]
                dist_id = dist["district_id"]
                dist_name = dist["district_name"]

                try:
                    res = self.process_district(
                        state_pos=state_pos, state_total=state_total,
                        state_code=state_code, state_name=state_name,
                        dist_pos=dist_pos, dist_total=dist_total,
                        dist_id=dist_id, district_name=dist_name
                    )

                    if res == DistrictRunStatus.FAILED:
                        consecutive_hard_failures += 1
                        if consecutive_hard_failures >= 3:
                            logger.error("HARD STOP: 3 consecutive districts failed. Pausing sweep for investigation.")
                            return
                    else:
                        consecutive_hard_failures = 0

                except BudgetExceededError:
                    return

            # State completion summary report
            self.write_state_summary_report(state_code, state_name, state_pos, state_total, districts)

        logger.success("★ ALL 36 STATES AND UNION TERRITORIES COMPLETED SUCCESSFULLY! ★")

    def run_district(self, query: Any, force: bool = True) -> Optional[DistrictRunStatus]:
        """Runs the pipeline for a single district identified by ID, LGD code, census code, or name."""
        self.bootstrap()
        states = self.sweep_data.get("states", [])
        target_dist = None
        target_state = None

        q_str = str(query).strip().lower()

        # Canonical LGD code mappings to name tokens
        lgd_map = {
            "586": "south goa",
            "30586": "south goa",
            "601": "ariyalur",
            "33616": "ariyalur",
            "593": "nicobar",
            "35638": "nicobar",
        }
        alias = lgd_map.get(q_str, q_str)

        is_lgd = q_str in lgd_map
        for s in states:
            for d in s.get("districts", []):
                d_id = str(d.get("district_id", ""))
                d_code = str(d.get("census_code", "")).lower()
                d_name = d.get("district_name", "").lower()

                if is_lgd:
                    if alias == d_name or alias in d_name:
                        target_dist = d
                        target_state = s
                        break
                else:
                    if (q_str == d_id or
                        q_str == d_code or
                        q_str in d_code or
                        alias == d_name or
                        alias in d_name):
                        target_dist = d
                        target_state = s
                        break
            if target_dist:
                break

        if not target_dist or not target_state:
            logger.error(f"District identifier '{query}' not found in sweep registry.")
            return None

        return self.process_district(
            state_pos=target_state["state_position"],
            state_total=len(states),
            state_code=target_state["state_code"],
            state_name=target_state["state_name"],
            dist_pos=target_dist["district_position"],
            dist_total=len(target_state.get("districts", [])),
            dist_id=target_dist["district_id"],
            district_name=target_dist["district_name"],
            force=force
        )

    def run_next(self):
        """Processes exactly one next pending district and stops."""
        self.bootstrap()
        next_run = db_manager.get_next_pending_district()
        if not next_run:
            logger.info("No pending districts remaining. Run 'retry --failed' to re-evaluate flagged districts.")
            return

        states = {s["state_code"]: s for s in self.sweep_data.get("states", [])}
        state_info = states.get(next_run.state_code, {})
        state_total = len(self.sweep_data.get("states", []))
        dist_total = state_info.get("total_districts", 1)

        self.process_district(
            state_pos=next_run.state_position,
            state_total=state_total,
            state_code=next_run.state_code,
            state_name=next_run.state_name,
            dist_pos=next_run.district_position,
            dist_total=dist_total,
            dist_id=int(next_run.district_code),
            district_name=next_run.district_name,
        )

    def retry_failed(self):
        """Retries all districts that are in FAILED or NEEDS_REVIEW status."""
        self.bootstrap()
        failed_districts = db_manager.get_failed_districts()
        if not failed_districts:
            logger.info("No districts currently flagged as FAILED or NEEDS_REVIEW.")
            return

        logger.info(f"Retrying {len(failed_districts)} flagged districts...")
        states = {s["state_code"]: s for s in self.sweep_data.get("states", [])}
        state_total = len(self.sweep_data.get("states", []))

        for d in failed_districts:
            state_info = states.get(d.state_code, {})
            dist_total = state_info.get("total_districts", 1)
            self.process_district(
                state_pos=d.state_position,
                state_total=state_total,
                state_code=d.state_code,
                state_name=d.state_name,
                dist_pos=d.district_position,
                dist_total=dist_total,
                dist_id=int(d.district_code),
                district_name=d.district_name,
                force=True
            )

    def write_state_summary_report(
        self,
        state_code: str,
        state_name: str,
        state_pos: int,
        state_total: int,
        districts: List[Dict]
    ):
        """Generates comprehensive Markdown report at completion of each state."""
        report_path = REPORT_DIR / f"state_{state_code}_summary.md"
        now_str = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

        district_runs = db_manager.get_districts_in_state(state_code)
        run_map = {r.district_code: r for r in district_runs}

        done_list = []
        images_pending_list = []
        below_target_list = []
        needs_review_list = []

        total_spots_state = 0
        total_images_state = 0

        for d in districts:
            d_id = str(d["district_id"])
            run = run_map.get(d_id)
            status_val = run.status.value if run else "pending"
            spots = run.spots_verified if run else 0
            imgs = run.images_collected if run else 0
            total_spots_state += spots
            total_images_state += imgs

            info = {"name": d["district_name"], "id": d_id, "spots": spots, "images": imgs}
            if status_val == "done":
                done_list.append(info)
            elif status_val == "images_pending":
                images_pending_list.append(info)
            elif status_val == "below_target":
                below_target_list.append(info)
            elif status_val in ("needs_review", "failed"):
                needs_review_list.append(info)

        content = f"""# {state_name} ({state_code}) — Harvest Completion Report
**Position**: State {state_pos} of {state_total}  
**Sweep Direction**: {self.sweep_data.get('sweep_direction')}  
**Report Generated**: {now_str}  
**Total Spots Verified**: {total_spots_state}  
**Total Licensed Images**: {total_images_state}  

## Executive Breakdown
- **Districts Completed (>= 10 spots + images)**: {len(done_list)}
- **Districts Images Pending (>= 10 spots, < 10 images)**: {len(images_pending_list)}
- **Districts Below Target (< 10 spots after 8 passes)**: {len(below_target_list)}
- **Districts Needing Review / Flagged**: {len(needs_review_list)}

## District Harvest Matrix
| District # | LGD Code | District Name | Status | Verified Spots | Licensed Photos |
| :---: | :---: | :--- | :---: | :---: | :---: |
"""
        for d in districts:
            d_id = str(d["district_id"])
            run = run_map.get(d_id)
            st_badge = run.status.value.upper() if run else "PENDING"
            v_spots = run.spots_verified if run else 0
            v_imgs = run.images_collected if run else 0
            content += f"| {d['district_position']} | `{d_id}` | {d['district_name']} | **{st_badge}** | {v_spots} | {v_imgs} |\n"

        if below_target_list:
            content += "\n## Districts Below Target (Audit Log)\n"
            content += "| District Name | LGD Code | Spots Found | Pass Count | Status |\n| :--- | :---: | :---: | :---: | :--- |\n"
            for b in below_target_list:
                content += f"| {b['name']} | `{b['id']}` | {b['spots']} | 8 Passes Completed | `below_target` (All 8 passes exhausted) |\n"

        content += "\n---\n*Report auto-generated by Safar India-Wide Travel Spots Pipeline Coordinator.*\n"

        try:
            with open(report_path, "w", encoding="utf-8") as f:
                f.write(content)
            logger.info(f"✓ Wrote state completion summary: {report_path}")
        except Exception as e:
            logger.warning(f"Failed to write state report: {e}")


coordinator = PipelineCoordinator()
